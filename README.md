This repo will include azure functions, azure service bus, azure event grid, IAC code and multiple programming languages

# Create a Service Principal (with Powershell) in Azure to connect to Azure from Github

az ad sp create-for-rbac `
  --name github-terraform-deployer `
  --role Contributor `
  --scopes /subscriptions/ed0eed35-e487-434c-8eed-1f15d8b0909f `
  --sdk-auth

- Create a repository secret in Github with the name "AZURE_CREDENTIALS" and the value is the output of the previous command  

# For executing azure functions locally, run "azurite.exe". In Visual Studio 2026 is located in:

C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator

# For deploying the Azure Function to Azure

- Download the publish profile following the link https://learn.microsoft.com/en-us/visualstudio/azure/how-to-get-publish-profile-from-azure-app-service?view=visualstudio
- Create a repository secret in Github with the name "ORDER_API_AZURE_FUNCTION_APP_PUBLISH_PROFILE" and the value from the downloaded file