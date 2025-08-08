param location string = resourceGroup().location

resource firewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-07-01' = {
  name: 'waf-policy'
  location: location
  properties: {
    customRules: [
      {
        name: 'FinlandRateLimit'
        priority: 10
        ruleType: 'RateLimitRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            negationConditon: false
            matchValues: ['FI']
          }
        ]
        rateLimitThreshold: 4000
        rateLimitDuration: 'OneMin'
        groupByUserSession: [
          {
            groupByVariables: [
              {
                variableName: 'ClientAddr'
              }
            ]
          }
        ]
      }
      {
        name: 'NordicRateLimit'
        priority: 11
        ruleType: 'RateLimitRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            negationConditon: false
            matchValues: ['SE', 'NO', 'DK', 'IS']
          }
        ]
        rateLimitThreshold: 2000
        rateLimitDuration: 'OneMin'
        groupByUserSession: [
          {
            groupByVariables: [
              {
                variableName: 'ClientAddr'
              }
            ]
          }
        ]        
      }
      {
        name: 'OtherCountriesRateLimit'
        priority: 12
        ruleType: 'RateLimitRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            negationConditon: true
            matchValues: ['FI', 'SE', 'NO', 'DK', 'IS']
          }
        ]
        rateLimitThreshold: 1000
        rateLimitDuration: 'OneMin'
        groupByUserSession: [
          {
            groupByVariables: [
              {
                variableName: 'ClientAddr'
              }
            ]
          }
        ]        
      }
    ]
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.1'
        }
      ]
      exclusions: []
    }
  }
}

output wafPolicyId string = firewallPolicy.id
