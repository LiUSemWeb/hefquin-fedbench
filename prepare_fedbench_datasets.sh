#!/bin/bash
# -----------------------------------------------------------------------------
# FedBench Dataset Validation Pipeline
#
# This script automates the extraction, cleaning, and of the FedBench
# datasets and validate them using Apache Jena RIOT.
#
# Main Steps
#   1. Extracts all *.tar.gz archives for known datasets.
#   2. Runs dataset-specific cleaning scripts to normalize RDF content.
#   3. Validates each dataset file with Apache Jena RIOT, filtering out
#      timestamped WARN/INFO messages and JVM noise lines.
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
set -e  # stop on first error
set -o pipefail  # catch pipeline errors

# -------------------------------------------------------------
# CONFIG
# -------------------------------------------------------------
export JAVA_TOOL_OPTIONS="-Djdk.xml.entityExpansionLimit=200000"

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

# -------------------------------------------------------------
# STEP 0: Download RDF dataset archives (if missing)
# -------------------------------------------------------------
section "Downloading RDF dataset archives"

mkdir -p datasets

urls=(
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/ChEBI.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/DrugBank.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/KEGG.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/GeoNames.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/Jamendo.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/LMDB.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/NYT.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/SWDFood.tar.gz"
    "https://users.iit.demokritos.gr/~gmouchakis/dumps/DBPedia-Subset.tar.gz"
    "https://www.ida.liu.se/~robke04/dump/SP2B.tar.gz"
)

for url in "${urls[@]}"; do
  filename="${url##*/}"
  localpath="datasets/${filename}"

  if [[ -f "$localpath" ]]; then
      ok "${filename} already exists, skipping."
  else
      info "Downloading ${filename}..."
      if wget -O "$localpath" "$url"; then
          ok "Downloaded ${filename}"
      else
          error "Failed to download ${filename}"
      fi
  fi
done

# -------------------------------------------------------------
# STEP 1: Extract datasets
# -------------------------------------------------------------
section "Extracting RDF datasets"
for archive in ChEBI DBPedia-Subset DrugBank GeoNames Jamendo KEGG LMDB NYT SP2B SWDFood; do
    if [[ -d "datasets/$archive" ]]; then
        ok "Directory ${archive}/ already exists, skipping extraction."
        continue
    fi

    if [[ -f "datasets/${archive}.tar.gz" ]]; then
        echo "Extracting datasets/${archive}.tar.gz..."
        tar -xzf "datasets/${archive}.tar.gz" -C datasets/
        ok "Extracted ${archive}"
    else
        error "Archive datasets/${archive}.tar.gz not found"
    fi
done

# -------------------------------------------------------------
# STEP 2: Clean datasets
# -------------------------------------------------------------
section "Cleaning datasets"

# info "Cleaning ChEBI..."
# ./scripts/clean.py datasets/ChEBI/chebi.n3
info "Cleaning Jamendo..."
./scripts/clean_jamendo.py datasets/Jamendo/jamendo.rdf
./scripts/clean_jamendo.py datasets/Jamendo/mbz_jamendo.rdf
info "Cleaning KEGG..."
./scripts/clean.py datasets/KEGG/kegg.cpd.n3
./scripts/clean.py datasets/KEGG/kegg.dr.n3
./scripts/clean.py datasets/KEGG/kegg.ec.n3
./scripts/clean.py datasets/KEGG/kegg.rn.n3
info "Cleaning LMDB..."
./scripts/clean.py datasets/LMDB/linkedmdb-latest-dump.nt
info "Cleaning NYT..."
./scripts/clean_rdf.py datasets/NYT/locations.rdf
info "Cleaning SWDFood..."
./scripts/clean_rdf.py datasets/SWDFood/eswc-2006-complete.rdf
./scripts/clean_rdf.py datasets/SWDFood/fis-2010-complete.rdf
./scripts/clean_rdf.py datasets/SWDFood/iswc-2008-complete.rdf

ok "All cleaning scripts executed"

# -------------------------------------------------------------
# STEP 3: Validate with RIOT
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
        warn "No files found in ${dir}"
        echo
        return
    fi

    for file in "${files[@]}"; do
        local fname
        fname=$(basename "$file")
        info "→ Checking ${fname}..."
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

for dir in ChEBI DBPedia-Subset DrugBank GeoNames Jamendo KEGG LMDB NYT SP2B SWDFood; do
    validate_dataset datasets/"$dir"
done

# -------------------------------------------------------------
# DONE
# -------------------------------------------------------------
section "All tasks complete"
ok "Validation pipeline finished successfully!"
