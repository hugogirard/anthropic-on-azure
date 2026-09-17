import { modelParameters } from '../../types/customType.bicep'

param location string
param foundryResourceName string
param tags object
param anthropicModelParameters modelParameters

@description('Legal entity name sent to Anthropic via modelProviderData.')
param anthropicOrganizationName string
@description('Two-letter ISO country code the organization operates from.')
param anthropicCountryCode string
@description('Industry (lowercase) matching the Foundry portal dropdown.')
param anthropicIndustry string

resource foundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: foundryResourceName
  location: location
  kind: 'AIServices'
  tags: tags
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: foundryResourceName
    allowProjectManagement: true
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
      bypass: 'AzureServices'
    }
    networkInjections: null
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: foundry
  name: '${foundryResourceName}-demo'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Demo'
    description: 'Demo project'
  }
}

resource anthropicModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview' = {
  parent: foundry
  dependsOn: [
    project
  ]
  name: anthropicModelParameters.modelProperties.name
  sku: {
    name: anthropicModelParameters.sku.name
    capacity: anthropicModelParameters.sku.capacity
  }
  properties: {
    model: anthropicModelParameters.modelProperties
    // Required by Foundry for Anthropic deployments; auto-signs the marketplace terms.
    #disable-next-line BCP037
    modelProviderData: {
      organizationName: anthropicOrganizationName
      countryCode: anthropicCountryCode
      industry: anthropicIndustry
    }
    versionUpgradeOption: anthropicModelParameters.versionUpgradeOption
    currentCapacity: anthropicModelParameters.sku.capacity
  }
}

output foundryResourceId string = foundry.id
