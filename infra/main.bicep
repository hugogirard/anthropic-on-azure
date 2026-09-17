import { modelParameters } from './types/customType.bicep'

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
// US regions where Claude (Anthropic) models are available on Foundry (Global Standard).
@allowed([
  'eastus2'
  'westcentralus'
])
@description('Primary location for all resources')
param location string

param resourceGroupName string

@description('Object ID of the user running azd up, used for role assignments.')
param principalId string = ''

// modelProviderData attestation fields — required by Foundry for Anthropic deployments.
@description('Legal entity name sent to Anthropic via modelProviderData.')
param anthropicOrganizationName string

@minLength(2)
@maxLength(2)
@description('Two-letter ISO country code the organization operates from.')
@allowed([
  'US'
  'CA'
])
param anthropicCountryCode string

@allowed([
  'technology'
  'finance'
  'healthcare'
  'education'
  'retail'
  'manufacturing'
  'government'
  'media'
  'other'
])
@description('Industry (lowercase) matching the Foundry portal dropdown.')
param anthropicIndustry string

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
  SecurityControl: 'ignore'
}

var anthropicModelProperties modelParameters = {
  deploymentName: 'claude-opus-5'
  modelProperties: {
    name: 'claude-opus-5'
    format: 'Anthropic'
    version: '2'
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 40
  }
  versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource, such as:
//   Microsoft.Web/sites for appservice, function
// Example usage:
//   tags: union(tags, { 'azd-service-name': apiServiceName })
#disable-next-line no-unused-vars
var apiServiceName = 'python-api'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${resourceGroupName}'
  location: location
  tags: tags
}

module foundry 'core/ai/foundry.bicep' = {
  scope: rg
  params: {
    location: location
    tags: tags
    foundryResourceName: '${abbrs.cognitiveServicesAccounts}foundry-${resourceToken}'
    anthropicModelParameters: anthropicModelProperties
    anthropicOrganizationName: anthropicOrganizationName
    anthropicCountryCode: anthropicCountryCode
    anthropicIndustry: anthropicIndustry
  }
}

module rbac 'core/rbac/roles.bicep' = {
  scope: rg
  params: {
    foundryResourceId: foundry.outputs.foundryResourceId
    userPrincipalId: principalId
  }
}

// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
