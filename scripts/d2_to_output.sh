#!/usr/bin/env bash

set -euo pipefail

# Usage: bash scripts/d2_to_output.sh <input.d2>
in="${1:-}"
if [[ -z "$in" ]]; then
  echo "Usage: $0 <input.d2>" >&2
  exit 2
fi

name="$(basename "${in%.*}")"
mkdir -p docs/assets/images
d2 "$in" "docs/assets/images/$name.svg"
