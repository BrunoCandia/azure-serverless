resource "azurerm_linux_function_app" "order_tracker_logger_func" {
  name                       = "${var.project_name}-order-tracker-logger-${var.environment}-func100"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.my_plan.id

  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  site_config {
    application_stack {
      node_version = "20"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    AzureWebJobsStorage = azurerm_storage_account.main.primary_connection_string

    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.order_tracker_logger_insights.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
  }    
}

resource "azurerm_application_insights" "order_tracker_logger_insights" {
  name                = "${var.project_name}-order-tracker-logger-${var.environment}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "other"

  workspace_id        = azurerm_log_analytics_workspace.main.id  
}