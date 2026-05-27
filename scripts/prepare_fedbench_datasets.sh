#!/bin/bash
# -----------------------------------------------------------------------------
# FedBench Dataset Validation Pipeline
#
# This script automates the extraction, cleaning of the FedBench
# datasets and validates them using Apache Jena RIOT.
#
# Main Steps
#   1. Downloads all FedBench datasets
#   2. Extracts *.tar.gz archives
#   3. Runs dataset-specific cleaning scripts to normalize RDF content.
#   4. Validates each dataset file with Apache Jena RIOT, filtering out
#      timestamped WARN/INFO messages and JVM noise.
#   5. Combine RDF files as NT (for HDT conversion)
#
# Requirements
#   - Apache Jena (riot command in PATH)
#   - Python
#
# Notes
#   - JAVA_TOOL_OPTIONS is configured to increase XML entity expansion limits.
#   - For riot validation, WARN/INFO lines are filtered out.
#   - Run this script from the repo root.
# -----------------------------------------------------------------------------

set -euo pipefail # <add comment here>

set -e  # stop on first error
set -o pipefail  # catch pipeline errors

# -------------------------------------------------------------
# CONFIG
# -------------------------------------------------------------
export JAVA_TOOL_OPTIONS="-Djdk.xml.entityExpansionLimit=0  -Djdk.xml.totalEntitySizeLimit=0  -Djdk.xml.maxGeneralEntitySizeLimit=0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper for pretty section headers
section() { echo -e "\n${BLUE}=== $1 ===${NC}\n"; }

# Helper for success and error messages
ok()    { echo -e "${GREEN}✔ $1${NC}"; }
info()  { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}✖ $1${NC}"; }

# RDF datasets
declare -A RDF_DATASETS=(
  [ChEBI]="https://users.iit.demokritos.gr/~gmouchakis/dumps/ChEBI.tar.gz"
  [DBPedia-Subset]="https://users.iit.demokritos.gr/~gmouchakis/dumps/DBPedia-Subset.tar.gz"
  [DrugBank]="https://users.iit.demokritos.gr/~gmouchakis/dumps/DrugBank.tar.gz"
  [GeoNames]="https://users.iit.demokritos.gr/~gmouchakis/dumps/GeoNames.tar.gz"
  [Jamendo]="https://users.iit.demokritos.gr/~gmouchakis/dumps/Jamendo.tar.gz"
  [KEGG]="https://users.iit.demokritos.gr/~gmouchakis/dumps/KEGG.tar.gz"
  [LMDB]="https://users.iit.demokritos.gr/~gmouchakis/dumps/LMDB.tar.gz"
  [NYT]="https://users.iit.demokritos.gr/~gmouchakis/dumps/NYT.tar.gz"
  [SP2B]="https://www.ida.liu.se/~robke04/dump/SP2B.tar.gz"
  [SWDFood]="https://users.iit.demokritos.gr/~gmouchakis/dumps/SWDFood.tar.gz"
)

# -------------------------------------------------------------
# STEP 1: Download RDF dataset archives (if missing)
# -------------------------------------------------------------
section "Downloading RDF dataset archives"
mkdir -p datasets

for dataset in "${!RDF_DATASETS[@]}"; do
  url="${RDF_DATASETS[$dataset]}"
  path="datasets/${url##*/}"
  if [[ -f "$path" ]]; then
      ok "${path} already exists, skipping."
  else
      info "Downloading ${url}..."
      if wget -O "$path" "$url"; then
          ok "Downloaded ${url}"
      else
          error "Failed to download ${url}"
      fi
  fi
done

# -------------------------------------------------------------
# STEP 2: Extract datasets (if not already extracted)
# -------------------------------------------------------------
section "Extracting RDF datasets"
for dataset in "${!RDF_DATASETS[@]}"; do
  url="${RDF_DATASETS[$dataset]}"
  path="datasets/${url##*/}"
  archive="datasets/${dataset}"
  if [[ -d "${archive}" ]]; then
    ok "Directory ${archive}/ already exists, skipping extraction."
    continue
  fi

  if [[ -f "${path}" ]]; then
    echo "Extracting ${path}..."
    tar -xzf "${path}" -C "datasets/"
    ok "Extracted ${path} to ${archive}"
  else
    error "Dataset ${path}.tar.gz not found"
  fi
done

# -------------------------------------------------------------
# STEP 3: Clean datasets
# -------------------------------------------------------------
section "Cleaning datasets"

# CheBI
if [[ -v RDF_DATASETS[ChEBI] ]]; then
  info "Cleaning ChEBI..."
  ./scripts/clean_nt.py datasets/ChEBI/chebi.n3
fi

# DBPedia
if [[ -v RDF_DATASETS[DBPedia-Subset] ]]; then
  info "Cleaning DBPedia-Subset..."
  for i in {0..18}; do
    file="datasets/DBPedia-Subset/out${i}.nt"

    if [[ -f "$file" ]]; then
      info "Cleaning $file..."
      ./scripts/clean_dbpedia.py "$file"
    fi
  done
fi

# KEGG
if [[ -v RDF_DATASETS[KEGG] ]]; then
  info "Cleaning KEGG..."
  echo "Step 1 of 4"
  ./scripts/clean_nt.py datasets/KEGG/kegg.cpd.n3
  echo "Step 2 of 4"
  ./scripts/clean_nt.py datasets/KEGG/kegg.dr.n3
  echo "Step 3 of 4"
  ./scripts/clean_nt.py datasets/KEGG/kegg.ec.n3
  echo "Step 4 of 4"
  ./scripts/clean_nt.py datasets/KEGG/kegg.rn.n3
fi

# Jamendo
if [[ -v RDF_DATASETS[Jamendo] ]]; then
info "Cleaning Jamendo..."
  echo "Step 1 of 2"
  ./scripts/clean_jamendo.py datasets/Jamendo/jamendo.rdf
  echo "Step 2 of 2"
  ./scripts/clean_jamendo.py datasets/Jamendo/mbz_jamendo.rdf
fi

# LMDB
if [[ -v RDF_DATASETS[LMDB] ]]; then
  info "Cleaning LMDB..."
  ./scripts/clean_nt.py datasets/LMDB/linkedmdb-latest-dump.nt
fi

# NYT
if [[ -v RDF_DATASETS[NYT] ]]; then
  info "Cleaning NYT..."
  ./scripts/clean_rdf.py datasets/NYT/locations.rdf
fi

# NYT
if [[ -v RDF_DATASETS[SWDFood] ]]; then
  info "Cleaning SWDFood..."
  echo "Step 1 of 3"
  ./scripts/clean_rdf.py datasets/SWDFood/eswc-2006-complete.rdf
  echo "Step 2 of 3"
  ./scripts/clean_rdf.py datasets/SWDFood/fis-2010-complete.rdf
  echo "Step 3 of 3"
  ./scripts/clean_rdf.py datasets/SWDFood/iswc-2008-complete.rdf
fi

# -------------------------------------------------------------
# STEP 4: Validate with RIOT
# -------------------------------------------------------------
section "Validating RDF datasets with Apache Jena RIOT"

# Pattern to hide timestamp WARN/INFO lines
FILTER='^(Picked up JAVA_TOOL_OPTIONS|[0-9]{2}:[0-9]{2}:[0-9]{2} (WARN|INFO))'

validate_dataset() {
  local dir="$1"
  info "Validating ${dir}..."

  shopt -s nullglob   # avoid literal * if no matches
  local files=("$dir"/*.rdf "$dir"/*.n3 "$dir"/*.nt "$dir"/*.ttl "$dir"/*.owl)
  shopt -u nullglob

  if ((${#files[@]} == 0)); then
      error "No files found in ${dir}"
      echo
      return
  fi

  for file in "${files[@]}"; do
      local fname
      fname=$(basename "$file")
      info "Checking ${fname}..."
      output=$(riot --validate "$file" 2>&1 | grep -Ev "$FILTER" || true)

      if [[ -z "$output" ]]; then
          ok "${fname}: OK"
      else
          error "${fname}: Errors found"
          error "$output"
      fi
  done

  echo
}

for dataset in "${!RDF_DATASETS[@]}"; do
  dir="datasets/${dataset}"
  validate_dataset "${dir}"
done

# -------------------------------------------------------------
# STEP 5: Combine RDF files as NT (for HDT conversion)
# -------------------------------------------------------------
section "Combining RDF datasets with Apache Jena RIOT"

# for dataset in "${!RDF_DATASETS[@]}"; do
#   dir="datasets/${dataset}"
#   info "Combining ${dir}..."
#   mkdir -p "${dir}/combined"
#   file="${dir}/combined/combined.nt"
#   {
#       find "${dir}" -maxdepth 1 -type f \( \
#           -name "*.ttl" -o -name "*.nt" -o -name "*.rdf" -o -name "*.owl" -o -name "*.n3" \
#       \) -print0 | xargs -0 riot --output=NT 2>/dev/null || true;
#   } | LC_ALL=C sort -u > "${file}"

#   echo "File: $file ($(wc -l < "$file") lines)"
# done

# -------------------------------------------------------------
# DONE
# -------------------------------------------------------------
section "All tasks complete"
