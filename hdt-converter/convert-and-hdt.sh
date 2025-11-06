#!/usr/bin/env bash
set -euo pipefail

DATASETS=()
# Loop through all environment variables
while IFS='=' read -r name value; do
  # Keep only variables that start with DATASET_
  if [[ "$name" =~ ^DATASET_[0-9]+$ ]]; then
    DATASETS+=("$value")
  fi
done < <(env)

# Check if we found any datasets
if ((${#DATASETS[@]} == 0)); then
  echo "No DATASET_* environment variables found."
  exit 0
fi

# Loop through each dataset directory
for dataset in "${DATASETS[@]}"; do
  echo "Processing dataset: $dataset"

  # Find all RDF files (NT, TTL, RDF, compressed versions)
  find "$dataset" -type f \( \
    -iname '*.nt' -o -iname '*.ttl' -o -iname '*.rdf' -o -iname '*.n3' \
  \) | while IFS= read -r filename; do
    echo "  Converting: $filename"

    # Build output path
    out_path="${filename}.hdt"

    # Run HDT conversion
    rdf2hdt.sh "$filename" "$out_path"
  done
done

echo "All datasets processed."
