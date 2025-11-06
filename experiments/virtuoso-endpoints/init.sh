#!/usr/bin/env bash
set -euo pipefail

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
die() { log "ERROR: $*"; exit 1; }

isql_ok() {
  # Try a quick status probe; suppress output
  isql 1111 -U dba -P "$DBA_PASSWORD" "exec=status();" >/dev/null 2>&1
}

wait_for_virtuoso() {
  log "Waiting for Virtuoso..."
  local waited=0
  while ! isql_ok; do
    sleep 3
  done
  log "Virtuoso is ready."
}

log "=== Virtuoso dataset loader start ==="
wait_for_virtuoso

declare -a DATASET_VARS=()
while IFS= read -r var; do
  DATASET_VARS+=("$var")
done < <(env | awk -F= '/^DATASET_[0-9]+=/{print $1}' | sort -t _ -k2,2n)

if ((${#DATASET_VARS[@]}==0)); then
  log "No DATASET_* environment variables found. Nothing to do."
  exit 0
fi

SQL_FILE="$(mktemp)"
trap 'rm -f "$SQL_FILE"' EXIT

# Prepare: clear load list once
printf 'DELETE FROM DB.DBA.LOAD_LIST;\n' >> "$SQL_FILE"

count=0
for var in "${DATASET_VARS[@]}"; do
  ((++count))
  IFS='|' read -r path graph <<< "$(printenv "$var")"
  if [[ -d "$path" ]]; then
    log "#$count: $var → dir='$path' graph='$graph'"
  else
    die "#$count: $var → path does not exist: $path"
  fi

  # Load
  printf "ld_dir('%s','*.rdf','%s');\n" "$path" "$graph" >> "$SQL_FILE"
  printf "ld_dir('%s','*.owl','%s');\n" "$path" "$graph" >> "$SQL_FILE"
  printf "ld_dir('%s','*.ttl','%s');\n" "$path" "$graph" >> "$SQL_FILE"
  printf "ld_dir('%s','*.nt','%s');\n" "$path" "$graph" >> "$SQL_FILE"
  printf "ld_dir('%s','*.n3','%s');\n" "$path" "$graph" >> "$SQL_FILE"

  printf "rdf_loader_run();\n" >> "$SQL_FILE"
  printf "checkpoint;\n" >> "$SQL_FILE"
  
  # Run
  isql 1111 -U dba -P "$DBA_PASSWORD" < "$SQL_FILE"

  # Clear SQL file
  > "$SQL_FILE"
done

log "=== Summary ==="
log "Datasets processed : ${#DATASET_VARS[@]}"
for var in "${DATASET_VARS[@]}"; do
  value="$(printenv "$var")"
   printf '  - %-12s %s\n' "$var" "$value"
done

log "=== Done ==="
