This repo will include azure functions, azure service bus, azure event grid, IAC code and multiple programming languages

# Create a Service Principal (with Powershell) in Azure to connect to Azure from Github

az ad sp create-for-rbac `
  --name github-terraform-deployer `
  --role Contributor `
  --scopes /subscriptions/ed0eed35-e487-434c-8eed-1f15d8b0909f `
  --sdk-auth