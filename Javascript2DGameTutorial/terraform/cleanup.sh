#!/bin/bash

# Wrapper script for cleanup - calls the actual cleanup script from the scripts directory
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the actual cleanup script
exec "${SCRIPT_DIR}/scripts/cleanup/cleanup.sh" "$@"
