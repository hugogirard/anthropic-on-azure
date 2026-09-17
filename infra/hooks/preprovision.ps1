#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

# Resolve the object ID of the user (or service principal) running azd up.
$principalId = az ad signed-in-user show --query id -o tsv 2>$null
if (-not $principalId) {
    # Fallback for service principals / CI where signed-in-user is unavailable.
    $principalId = az account show --query user.name -o tsv
}
if (-not $principalId) {
    Write-Error 'Could not resolve the current principal. Run `az login` first.'
    exit 1
}

azd env set AZURE_PRINCIPAL_ID $principalId
