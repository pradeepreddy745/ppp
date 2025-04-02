# Step 1: Create the Resource Group
resource "azurerm_resource_group" "example" {
  name     = "pradeep7"
  location = "East US"
}

# Step 2: Create the Virtual Network (VNet) with a /24 CIDR block
resource "azurerm_virtual_network" "example" {
  name                = "vnetppr"
  location           = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/24"]
}

# Step 3: Create the two subnets with /26 CIDR blocks
resource "azurerm_subnet" "web_subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_subnet" "sql_subnet" {
  name                 = "sql-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.0.64/26"]
}

# Step 4: Create an App Service Plan (for Web App)
resource "azurerm_app_service_plan" "example" {
  name                = "example-app-service-plan"
  location           = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Basic"
    size = "B1"
  }
}

# Step 5: Create the Web App
resource "azurerm_linux_web_app" "example" {
  name                = "ppr-web-app"
  resource_group_name = azurerm_resource_group.example.name
  location           = azurerm_app_service_plan.example.location
  
  service_plan_id = azurerm_app_service_plan.example.id

  app_settings = {
    #"SOME_KEY" = "some_value"
  }
  site_config {
    
  }
}

# Step 6: Create the Azure SQL Server
resource "azurerm_sql_server" "example" {
  name                         = "examplesqlserver"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"
}

# Step 7: Create the Azure SQL Database
resource "azurerm_sql_database" "example" {
  name                = "example-sql-database"
  resource_group_name = azurerm_resource_group.example.name
  location           = azurerm_resource_group.example.location
  server_name        = azurerm_sql_server.example.name
  sku_name            = "Basic"
}

# Step 8: Create Private Endpoint for the Web App
resource "azurerm_private_endpoint" "web_private_endpoint" {
  name                 = "example-web-private-endpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.web_subnet.id

  private_service_connection {
    name                           = "example-web-connection"
    is_manual_connection          = false
    private_connection_resource_id = azurerm_linux_web_app.example.id
    subresource_names              = ["sites"]
  }
}

# Step 9: Create Private Endpoint for the Azure SQL Database
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                 = "example-sql-private-endpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.sql_subnet.id

  private_service_connection {
    name                           = "example-sql-connection"
    is_manual_connection          = false
    private_connection_resource_id = azurerm_sql_server.example.id
    subresource_names              = ["sqlServer"]
  }
}

# Step 10: Configure the Web App to use Private Endpoint for SQL connection
resource "azurerm_app_service_virtual_network_swift_connection" "example" {
  app_service_id          = azurerm_linux_web_app.example.id
  subnet_id              = azurerm_subnet.web_subnet.id
}