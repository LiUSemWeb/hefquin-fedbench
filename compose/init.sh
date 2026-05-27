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

# Add the unnumbered DATASET variable if defined
if env | grep -q '^DATASET='; then
  DATASET_VARS+=("DATASET")
fi

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

  for file in "$path"/*.nt "$path"/*.rdf "$path"/*.ttl "$path"/*.owl "$path"/*.n3; do
    [[ -f "$file" ]] || continue
    log "  Loading: $file"
    {
      printf "trace_on('user_log');\n"
      printf "trace_on('errors');\n"
      printf "DELETE FROM DB.DBA.LOAD_LIST;\n"
      printf "ld_dir_all('%s', '%s', '%s');\n" "$(dirname "$file")" "$(basename "$file")" "$graph"
      printf "rdf_loader_run(log_enable=>3);\n"
      printf "checkpoint;\n"
      printf "checkpoint_interval(0);\n"
    } | isql 1111 -U dba -P "$DBA_PASSWORD" 2>&1
  done
done

log "=== Summary ==="
log "Datasets processed : ${#DATASET_VARS[@]}"
for var in "${DATASET_VARS[@]}"; do
  value="$(printenv "$var")"
   printf '  - %-12s %s\n' "$var" "$value"
done

log "=== Done ==="
