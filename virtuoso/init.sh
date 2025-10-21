#!/usr/bin/env bash
set -euo pipefail

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
die() { log "ERROR: $*"; exit 1; }

: "${DBA_PASSWORD:?set DBA_PASSWORD}"

log "=== Virtuoso dataset loader start ==="

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

count=0
for var in "${DATASET_VARS[@]}"; do
  ((++count))
  IFS='|' read -r path graph <<< "$(printenv "$var")"
  [[ -n "${path:-}" && -n "${graph:-}" ]] || die "$var is malformed. Expect PATH|GRAPH"
  case "$path" in
    *.tar.gz)
      name=$(basename "$path" .tar.gz)
      target="/data/$name"
      log "$var → path='$path' graph='$graph'"
      log "  Extracting → $target"
      mkdir -p "$target"
      tar -xzf "$path" -C "$target" --strip-components=1
      load_path="$target"
      ;;
    *)
      load_path="$(dirname "$path")"
      log "#$count: $var → path='$path' graph='$graph' (no extract)"
      exit
      ;;
  esac

  log "  Files: $(ls "$load_path" | paste -sd, - 2>/dev/null || echo '<empty>')"
  # Clear load list
  printf 'DELETE FROM DB.DBA.LOAD_LIST;\n' >> "$SQL_FILE"
  
  # Load
  printf "ld_dir('%s','*','%s');\n" "$target" "$graph" >> "$SQL_FILE"
  printf "rdf_loader_run();\n" >> "$SQL_FILE"
  printf "checkpoint;\n" >> "$SQL_FILE"
  
  # Run
  isql virtuoso 1111 -U dba -P "$DBA_PASSWORD" < "$SQL_FILE"

  # Clear SQL file
  > "$SQL_FILE"
done
exit;

log "=== Summary ==="
log "Datasets processed : ${#DATASET_VARS[@]}"
for var in "${DATASET_VARS[@]}"; do
  value="$(printenv "$var")"
   printf '  - %-12s %s\n' "$var" "$value"
done

log "=== Done ==="
