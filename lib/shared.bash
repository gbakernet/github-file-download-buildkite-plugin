#!/bin/bash

plugin_read_list() {
  local prefix="BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_${1}"
  local parameter="${prefix}_0"

  if [[ -n "${!parameter:-}" ]]; then
    local i=0
    while IFS= read -r value; do
      [[ -n "$value" ]] && echo "$value"
      i=$((i+1))
      parameter="${prefix}_${i}"
    done < <(
      while [[ -n "${!parameter:-}" ]]; do
        echo "${!parameter}"
        i=$((i+1))
        parameter="${prefix}_${i}"
      done
    )
  elif [[ -n "${!prefix:-}" ]]; then
    echo "${!prefix}"
  fi
}
