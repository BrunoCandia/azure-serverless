param location string
param namespaceName string
param queueName string = 'notification-queue'
param maxDeliveryCount int = 5
param sendRuleName string = 'send-policy'
param listenRuleName string = 'listen-rule'
param tags object = {
  course: 'serverless'
}

resource namespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: namespace
  name: queueName
  properties: {
    maxDeliveryCount: maxDeliveryCount
  }
}

// Used by the order-api function to send messages
resource sendRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
  parent: namespace
  name: sendRuleName
  properties: {
    rights: [
      'Send'
    ]
  }
}

// Used by the order-processor function to receive messages
resource listenRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
  parent: namespace
  name: listenRuleName
  properties: {
    rights: [
      'Listen'
    ]
  }
}

output namespaceName string = namespace.name
output queueName string = queue.name
output sendRuleName string = sendRule.name
output listenRuleName string = listenRule.name
