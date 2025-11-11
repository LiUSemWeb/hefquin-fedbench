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

  # Build output path
  out_path="/datasets/${dataset}/combined/combined.hdt"

  # Run HDT conversion
  rdf2hdt.sh "/datasets/${dataset}/combined/combined.nt" "$out_path"
done

echo "All datasets processed."
