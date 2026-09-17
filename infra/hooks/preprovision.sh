#!/usr/bin/env bash
set -euo pipefail

# Resolve the object ID of the user (or service principal) running azd up.
principalId=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
if [ -z "$principalId" ]; then
  # Fallback for service principals / CI where signed-in-user is unavailable.
  principalId=$(az account show --query user.name -o tsv)
fi
if [ -z "$principalId" ]; then
  echo "Could not resolve the current principal. Run 'az login' first." >&2
  exit 1
fi

azd env set AZURE_PRINCIPAL_ID "$principalId"
