# Azure DevOps setup checklist (manual, one-time)

Everything below happens in Azure DevOps at https://dev.azure.com/brunocandia/My%20Project and/or via `az` CLI logged into the target Azure subscription. None of this can be done from the repo alone — it's a prerequisite for [azure-pipelines.yml](../azure-pipelines.yml) to run successfully.

Names below must match exactly what's hardcoded in [azure-pipelines.yml](../azure-pipelines.yml): resource groups `rg-order-system-{dev,staging,prod}`, service connections `sc-order-system-{dev,staging,prod}`, environments `dev`, `staging`, `prod`.

## 1. Bootstrap the 3 resource groups (one-time, subscription-scoped)

The pipeline itself deploys at resource-group scope and can't create its own resource group, so each RG must exist before the pipeline's RG-scoped service connections can be created.

- [ ] Log in to the target subscription: `az login` then `az account set --subscription <SUBSCRIPTION_ID>`
- [ ] Run the bootstrap template once per environment to create the resource groups:
  ```bash
  az deployment sub create \
    --location centralus \
    --template-file infra/bicep/bootstrap-rg.bicep \
    --parameters projectName=order-system environment=dev

  az deployment sub create \
    --location centralus \
    --template-file infra/bicep/bootstrap-rg.bicep \
    --parameters projectName=order-system environment=staging

  az deployment sub create \
    --location centralus \
    --template-file infra/bicep/bootstrap-rg.bicep \
    --parameters projectName=order-system environment=prod
  ```
- [ ] Confirm all three exist: `az group list --query "[?starts_with(name, 'rg-order-system-')].name" -o tsv`

## 2. Create Azure Resource Manager service connections

Project settings → Service connections → New service connection → Azure Resource Manager → Workload identity federation (recommended, no stored secret).

- [ ] `sc-order-system-dev` — scope: Resource Group `rg-order-system-dev`
- [ ] `sc-order-system-staging` — scope: Resource Group `rg-order-system-staging`
- [ ] `sc-order-system-prod` — scope: Resource Group `rg-order-system-prod`

For each: grant the connection's service principal the **Contributor** role on that specific resource group only (verify in the Azure Portal under the RG's Access control (IAM) if the wizard didn't already do it).

- [ ] Verify no service connection has subscription-wide scope (least privilege).

## 3. Create Azure DevOps Environments + approvals

Pipelines → Environments → New environment (no resources needed, just the name).

- [ ] Create environment `dev` (no approval check)
- [ ] Create environment `staging` → Approvals and checks → Approvals → add required approver(s)
- [ ] Create environment `prod` → Approvals and checks → Approvals → add required approver(s)

## 4. Create the pipeline

Pipelines → New pipeline → GitHub/Azure Repos Git (wherever this repo is hosted) → Existing Azure Pipelines YAML file → select [azure-pipelines.yml](../azure-pipelines.yml) at the repo root.

- [ ] Save (don't run yet) and confirm the pipeline parses without errors (Azure DevOps validates YAML on save).

## 5. First run — dev only

- [ ] Manually queue the pipeline.
- [ ] Watch the `Build` stage complete (3 function artifacts published).
- [ ] Watch `DeployInfra_dev` → `WhatIf` job output for a sane plan, then confirm the `DeployInfra` deployment job succeeds.
- [ ] Confirm resources exist in `rg-order-system-dev` and the 3 function apps show "Running".
- [ ] Watch `DeployFunctions_dev` succeed for all 3 function apps.
- [ ] Smoke test: POST [order-api-function/sample.json](../order-api-function/sample.json) to the deployed order-api endpoint and confirm the message flows through Service Bus → order-processor → receipts storage → Event Grid → order-tracker-logger → Cosmos DB.

## 6. Promote to staging, then prod

- [ ] Re-run/continue the pipeline; approve the `staging` environment check when prompted.
- [ ] Repeat the verification from step 5 against `rg-order-system-staging`.
- [ ] Approve the `prod` environment check when prompted.
- [ ] Repeat the verification from step 5 against `rg-order-system-prod`.

## Notes

- GitHub Actions workflows in `.github/workflows/` are untouched and keep deploying Terraform + function code separately — this Azure DevOps pipeline is additive, not a replacement.
- Variable groups were considered but aren't required: environment-specific values (resource group, service connection, param file) are hardcoded per stage directly in [azure-pipelines.yml](../azure-pipelines.yml).
