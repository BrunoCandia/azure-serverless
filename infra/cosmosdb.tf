resource "azurerm_cosmosdb_account" "main" {
  name = "${var.project_name}-${var.environment}-cosmosdb"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  offer_type = "Standard"
  kind = "GlobalDocumentDB"

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location = azurerm_resource_group.main.location
    failover_priority = 0
  }

  tags = {
    environment = var.environment
    project = var.project_name
    "course" = "serverless"
  }
}