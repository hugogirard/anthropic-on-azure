@description('The user principal running the Azd Up command')
param userPrincipalId string

@description('The resource id of the Foundry service')
param foundryResourceId string

// Load all roles definition
var roles = loadJsonContent('../rbac/roles.json')

module foundry_user 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: 'foundry_user_principal_id'
  params: {
    principalId: userPrincipalId
    resourceId: foundryResourceId
    roleDefinitionId: roles.FoundryUser.guid
    principalType: 'User'
  }
}
