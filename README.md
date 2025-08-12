# CST8918 Final Project

## IaC and Github CI/CD with Remix Weather App

## Team Members
- Simar Singh (sing1883) [GitHub Profile](https://github.com/supersuper2)
- Abdulrafay Mohammed (abdulRafay2325) [GitHub Profile](https://github.com/AbdulRafay2325)
- Yvanvictorie Niyonzimanshuti (yvanniyonzima-ac) [GitHub Profile](https://github.com/yvanniyonzima-ac)

# Project Overview
This project demonstrates robust Infrastructure as Code (IaC) principles by deploying the Remix Weather Application onto Azure Kubernetes Service (AKS) clusters. Leveraging Terraform for infrastructure provisioning and GitHub Actions for comprehensive CI/CD automation, this project simulates a real-world multi-environment (test and production) development and deployment pipeline. It focuses on automating infrastructure provisioning, application containerization, and deployment, ensuring a consistent and reproducible setup.

## Key Technologies & Services

- Infrastructure as Code (IaC): Terraform
- Cloud Provider: Azure
- Container Orchestration: Azure Kubernetes Service (AKS)
- Database/Cache: Azure Cache for Redis (managed Redis DB)
- Container Registry: Azure Container Registry (ACR)
- CI/CD Automation: GitHub Actions
- Application Framework: Remix (Node.js)
- Terraform Backend: Azure Blob Storage

## Infrastructure Architecture

The project defines and manages Azure infrastructure through a modular Terraform setup, with state stored securely in Azure Blob Storage. The core network infrastructure is designed with a `10.0.0.0/14` Virtual Network, segmented into four dedicated subnets:
- `prod` (10.0.0.0/16)
- `test` (10.1.0.0/16)
- `dev` (10.2.0.0/16)
- `admin` (10.3.0.0/16)

Separate AKS clusters are provisioned for both test (1 node, Standard B2s) and prod (min 1, max 3 nodes, Standard B2s) environments, ensuring isolation. Each environment also has its own managed Azure Cache for Redis instance for application data caching. The Remix Weather Application is containerized and deployed to these AKS clusters, using Kubernetes Deployments and Services.

## Automated Workflows (CI/CD with GitHub Actions)

The project implements a comprehensive CI/CD strategy using GitHub Actions to automate various stages of the development and deployment lifecycle. Azure Federated Identities are configured for secure authentication.

### Static Code Analysis

- Terraform fmt & validate: Run on every push to any branch.
- TFLint & TFSec: Run on every push to any branch to ensure code quality and security best practices.

### Pull Request Workflows

- **Terraform Plan & TFLint**: Executed on every pull request to the main branch, providing a clear review of infrastructure changes before merging.

- **Application Build & Test Deployment**:

  - If application code changes in a pull request to main, the Docker image for the Remix Weather App is built and pushed to ACR (tagged with commit SHA).

  - The application is then automatically deployed to the test AKS environment. This provides immediate testing of new application features in a deployed environment for PR validation.

### Deployment to Production

- **Infrastructure Deployment**: Any infrastructure changes are applied via terraform apply only upon merge (push) to the main branch, signifying approval.

- **Application Production Deployment**: If application code changes were part of the merged pull request, the Remix Weather Application is deployed to the production AKS environment upon merge to main.

This setup ensures that infrastructure changes and application changes are managed carefully, with infrastructure updates happening after PR approval, and application deployments occurring to test environments on PR for review, and to production upon merge.

## Running the app locally

To run the Remix Weather Application locally, follow these steps:

### 1. Download the Repository

First, you need to get a copy of the project files. You can do this by cloning the GitHub repository:

```bash
git clone https://github.com/supersuper2-org/cst8918-final-project.git
cd cst8918-final-project/app
```
### 2. Install Node.js

The Remix Weather Application is a Node.js application, so you'll need Node.js and npm (Node Package Manager) installed on your system.

**Check if Node.js is installed**:
Open your terminal or command prompt and run:

```bash
node -v
npm -v
```

If you see version numbers (e.g., v18.x.x for Node.js and 9.x.x for npm), you're all set.

**If Node.js is not installed**:
Download and install the recommended LTS (Long Term Support) version of Node.js from the official website: nodejs.org. The installer typically includes npm.

### 3. Obtain an OpenWeatherMap API Key 

The application requires an API key to fetch weather data.
- Navigate to the [OpenWeatherMap website](https://openweathermap.org/api) website.
- Sign up for a free account.
- Generate an API key from your account dashboard.

### 4. Configure Environment Variables 
You'll need to provide your OpenWeatherMap API key to the application.
- In the root directory of the `app/` folder (where the `package.json` for the Remix app is located), create a new file named `.env `.
- Add your OpenWeatherMap API key to this file in the following format:
```bash
WEATHER_API_KEY=YOUR_OPENWEATHER_API_KEY_HERE
```
Replace `YOUR_OPENWEATHER_API_KEY_HERE` with the actual key you obtained.

### 5. Install Dependencies and Run the App
Finally, install the application's dependencies and start the development server.
- From within the `app/` directory in your terminal, install the necessary Node.js dependencies:

```bash
npm install
```

Start the Remix development server:

```bash
npm run dev
```

Your Remix Weather Application should now be running locally, typically accessible in your web browser at [`http://localhost:3000`](http://localhost:3000).

# Challenges
During the development and deployment process, we encountered several persistent issues that we were unable to fully resolve by the time of project completion.

### 1. Invalid .dockerconfigjson in Kubernetes Secret
When creating a Kubernetes secret for pulling images from Azure Container Registry (ACR), Terraform consistently failed with the error:

```bash
Secret "acr-auth" is invalid: data[.dockerconfigjson]: Invalid value: "<secret contents redacted>": invalid character 'e' looking for beginning of value
```

#### Debugging steps attempted:

- Verified that the secret type was set to `kubernetes.io/dockerconfigjson` and followed the expected JSON structure for Docker registry authentication.

- Encoded the credentials using base64encode and confirmed that the format matched the output of `kubectl create secret docker-registry`.

- Hardcoded the ACR username and password directly in the Terraform resource to rule out CI/CD variable substitution issues.

- Fetched ACR credentials in the GitHub Actions workflow and passed them via environment variables to Terraform using:


```bash
az acr credential show --name $ACR_NAME --query "username" -o tsv
az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv
```

- Verified that the credentials worked by manually running `docker login $ACR_LOGIN_SERVER` in the CI job.

- Attempted using `kubernetes_secret` with `stringData` instead of `data` to see if decoding behavior was causing corruption.

Despite these steps, the error persisted in Terraform when applying the Kubernetes secret resource.

### 2. ImagePullBackOff errors from AKS

Even when the Terraform apply succeeded, Kubernetes pods in AKS would intermittently fail to start, showing the following error:


```
Back-off pulling image "<acr-login-server>/weather-app:<commit-sha>"
```

#### Debugging steps attempted:

- Verified that the image existed in ACR and was tagged correctly.

- Confirmed that the AKS cluster had `acrPull` permissions to the ACR resource via Azure role assignments.

- Tested pulling the image manually from a different environment using the same credentials (success).

- Checked that the `.dockerconfigjson` secret was mounted correctly in the namespace.

- Deleted and recreated pods to test if the error was transient (it persisted sporadically).

### 3. Terraform remote state lease lock not releasing
We also ran into a problem with our remote Terraform state lock in Azure Storage.
When a job failed during terraform apply, the state lock would sometimes remain active, blocking future runs.


#### Debugging steps attempted:

- Waited for the lease lock to expire automatically (did not always happen).

- Used `az storage blob lease break` manually to release the lock.

- Added retries and timeouts in CI/CD to give Terraform a chance to clean up before the job ended.

- Reviewed Terraform's `-lock-timeout` flag usage, but it did not address cases where the process terminated unexpectedly.

These issues highlight the complexity of integrating Terraform, GitHub Actions, AKS, and ACR in a fully automated CI/CD pipeline.
Although we were able to work around some problems manually, we were not able to fully eliminate these failures within the project timeline.

Changes that were not merged to main due to failing CI/CD because of the above metioned errors are on the branch [`refactor_weather_app`](https://github.com/supersuper2-org/cst8918-final-project/tree/refactor_weather_app)

### 4. Resources that successfully deployed:

Below are screenshots that were succefully deployed via CLI and GitHub Actions

#### Backend Storage with 3 tfstate (prod, infra, test)
- The infra state was deployed using CLI and
- The prod and test stateswere deployed  via GitHubb Actions on the first merge to main before we added the weather application module to the test and prod environment
<img width="1423" height="357" alt="image" src="https://github.com/user-attachments/assets/439057d8-05c6-47bc-aec3-4e29606677c8" />
<img width="1440" height="455" alt="image" src="https://github.com/user-attachments/assets/c05a7c65-216f-41d6-8ccb-74338520c20c" />

#### The VNet with 4 subnets 
<img width="1439" height="352" alt="image" src="https://github.com/user-attachments/assets/ad622889-19be-41ee-9532-b97b0f938426" />
<img width="1440" height="429" alt="image" src="https://github.com/user-attachments/assets/9c01747f-bc84-47ca-9ff3-c41e9b658e43" />

#### The ACR with the weather image
- The ACR was deployed via CLI as part of the infra deployment, along side the VNet
- The image was pushed to the ACR via the weather-app-ci-cd workflow
<img width="1435" height="751" alt="image" src="https://github.com/user-attachments/assets/7b468f8a-7e23-4075-a3f9-89d84e652184" />

#### The AKS with 1 node in test environment
- AKS was already deleted at the time of this README update but below is the last state of it from the `test.tfstate` file in the backend
<details><summary>Show AKS state from test.tfstate</summary>

```json
    {
      "module": "module.aks",
      "mode": "managed",
      "type": "azurerm_kubernetes_cluster",
      "name": "aks",
      "provider": "provider[\"registry.terraform.io/hashicorp/azurerm\"]",
      "instances": [
        {
          "schema_version": 2,
          "attributes": {
            "aci_connector_linux": [],
            "api_server_access_profile": [],
            "auto_scaler_profile": [],
            "automatic_upgrade_channel": "",
            "azure_active_directory_role_based_access_control": [],
            "azure_policy_enabled": null,
            "confidential_computing": [],
            "cost_analysis_enabled": true,
            "current_kubernetes_version": "1.32.6",
            "default_node_pool": [
              {
                "auto_scaling_enabled": false,
                "capacity_reservation_group_id": "",
                "fips_enabled": false,
                "gpu_instance": "",
                "host_encryption_enabled": false,
                "host_group_id": "",
                "kubelet_config": [],
                "kubelet_disk_type": "OS",
                "linux_os_config": [],
                "max_count": 0,
                "max_pods": 110,
                "min_count": 0,
                "name": "masterpool",
                "node_count": 1,
                "node_labels": {},
                "node_network_profile": [],
                "node_public_ip_enabled": false,
                "node_public_ip_prefix_id": "",
                "only_critical_addons_enabled": false,
                "orchestrator_version": "1.32",
                "os_disk_size_gb": 128,
                "os_disk_type": "Managed",
                "os_sku": "Ubuntu",
                "pod_subnet_id": "",
                "proximity_placement_group_id": "",
                "scale_down_mode": "Delete",
                "snapshot_id": "",
                "tags": {},
                "temporary_name_for_rotation": "",
                "type": "VirtualMachineScaleSets",
                "ultra_ssd_enabled": false,
                "upgrade_settings": [
                  {
                    "drain_timeout_in_minutes": 0,
                    "max_surge": "10%",
                    "node_soak_duration_in_minutes": 0
                  }
                ],
                "vm_size": "Standard_B2s",
                "vnet_subnet_id": "/subscriptions/431fca8d-e614-4268-aa3c-22a2e684933a/resourceGroups/cst8918-final-project-group-2/providers/Microsoft.Network/virtualNetworks/cst8918-final-project-vnet/subnets/cst8918-final-project-test-subnet",
                "workload_runtime": "",
                "zones": []
              }
            ],
            "disk_encryption_set_id": "",
            "dns_prefix": "test-aks",
            "dns_prefix_private_cluster": "",
            "edge_zone": "",
            "fqdn": "test-aks-0wesh6hk.hcp.canadacentral.azmk8s.io",
            "http_application_routing_enabled": null,
            "http_application_routing_zone_name": null,
            "http_proxy_config": [],
            "id": "/subscriptions/431fca8d-e614-4268-aa3c-22a2e684933a/resourceGroups/cst8918-final-project-group-2/providers/Microsoft.ContainerService/managedClusters/test-aks",
            "identity": [
              {
                "identity_ids": [],
                "principal_id": "fc44ed70-26ca-4839-93ae-6649689f7c7e",
                "tenant_id": "e39de75c-b796-4bdd-888d-f3d21250910c",
                "type": "SystemAssigned"
              }
            ],
            "image_cleaner_enabled": null,
            "image_cleaner_interval_hours": null,
            "ingress_application_gateway": [],
            "key_management_service": [],
            "key_vault_secrets_provider": [],
            "kube_admin_config": [],
            "kube_admin_config_raw": "",
            "kube_config": [
              {
                "client_certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZIVENDQXdXZ0F3SUJBZ0lRUjc2YXovQ3pNRFhYYWlhU2ZHZUJYekFOQmdrcWhraUc5dzBCQVFzRkFEQU4KTVFzd0NRWURWUVFERXdKallUQWVGdzB5TlRBNE1UQXdOREl3TXpsYUZ3MHlOekE0TVRBd05ETXdNemxhTURBeApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1SVXdFd1lEVlFRREV3eHRZWE4wWlhKamJHbGxiblF3CmdnSWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUNEd0F3Z2dJS0FvSUNBUURlb3VwUmVZUjFPREtlQStoMlZvTVkKOFJTL3JGR1BJaWVOOUo2Q3p5UW90aEt0azQ5U2Myd1FLdDFuQ0k3SnIremNlT0RLY3VVaXArNmE4NHBmZk83aQptd2YzRXpzWDZFZVJWQWVNZTBQL3V2REVFSjRBYnd1VCtUMzJjMjl5L1BJM0pJYTExN2cvc1I4RllTQ2JYM25tCnJnOFM4OCtuWFo5dkVJZHA2cFg3Z3FQcDY4bXJvYWkrUWJYbEVwNzJSQ1BIeHVLanpxM1FsZFFxcjlFL1pBaE4KUlByVytaV1doL1VSNldlR3pRQzgzQ3oyallZbXpjYTlxQnVRR3NEYVZBTDFzZXg4RW1oNlpQMk9Ya1VtM01Kegp1OFlJSWZQSXU2ei9ISWdaWVJKUFdOVzIrVlN5ejgxdjFKREpoS3NDNVFwcnlMZzlPdzVKOHdsQWxZNW1wb2Z2Cmhxa3B1dllkODBUMldYUzN5eWcvb2lsVDRQc3k1THJLUmQzN2VmM2lQVTBSOGJkTktlWkliTXJpU2haREpuaDQKTjhFWkNwTXBLcDNlejBpOWU1TmhrT0Q0ZlNtS0dEMHlPb0owY2ZXak9nR2RXSHJ2KzBpUGM4alR4U0JKY0orNgpHajNhdDJlYVhDUUwrUkRmSTJZTzU1RG1DUnc4bk84S3pJNWRwMXd6QldpVVFFLzVsTFN0VWlDSSt6cEtkZWVaCmViZjI4MGxxaS83ZzZQeEVHbjNMQ3NNdUZ6Yi9CRGowNjBSRWkrSTFXSVNMLzJ0VkdhVGNwOEtTSTZKVWZsZUYKTnZTdWVlM2tMdXVyNldBTy9EbFJ2dTdwczdtTUZLNDhmTUZSdUlOWlM0K3oxNkk4dnFtdm5oVG5QSzB5bE8wYQppcEtkdEN4c0U3RFd3anBHaDJsd0F3SURBUUFCbzFZd1ZEQU9CZ05WSFE4QkFmOEVCQU1DQmFBd0V3WURWUjBsCkJBd3dDZ1lJS3dZQkJRVUhBd0l3REFZRFZSMFRBUUgvQkFJd0FEQWZCZ05WSFNNRUdEQVdnQlJzaGtXVXoxaWsKdnRQY2NWdDA3RC9yc0VyQzVEQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FnRUFkeGNVVStyWnZzNVk5dHptU3FmcApzOE9jZURtVkFZaVRUUTdBbnFCbVkzbjZlOFpjWUNhMytoV3d0Y1FQc09xNWdSQmR4Q29vTUZNS1dIQmRoazdwCjlLN1NHVGRSK0VqMDBIckZ3anZvS0NZY3ZDOTYvcTh6RDJqTkhLbFhJQ2lLL3FacXdFS1NkdzlpV01NNmEzcVQKQU9JVk5hdGVOOURpS1ZiUGFuZ2NGOTBkVGNUYnNueUdWWXY3QlRCc2pRamdid1phYnNpSWJKTkp3UCtHU3RLdwpsV04xckt5UjZGenRlbFBFVzFnTVdGeXJ2YitlaDlmMXRNbjg0NXE4NmNjd3RkOG13cm9BK3dZc01wMUsvSzFGClQ0bVhUanBwQmJQN2swZlhndFZRYU9CMTI4NGxIVFE2TDNrNWZVelRveFFUR1dUZUJhbDdHWVFZbVpYY09MZW0KRldxV3o5VGNZMU1vN0FVWURiRzl0QmxwR3pqa1lRcWpBSVBpOXNsb3I3bnJ3U3UwWC9jL2JnUWt0ZlcxMWxTMQpqUXU2YVlMRWpqZWNXMnFXVmp4M1o5eFFLYXpWVmpUaGJWS09YOFVvR3NYOG1oNHRJdldISmNKK3ZMcWlwMGNNCnRMY3RrN3NZSjJSeVJEZTdpVGxWT2VRUTlROXVaV2p1U2ZBOXpJZXlZQmVxS0RNNWJLSldGc1BhMzY0R2N5azkKUEtyaGo3SVdEcUZVejRJenV4WHJuemZUSDAyeU1OaXE2NDU2NkRYUCtmczJzMzE3U2FCTEJXemhJMUxEbXI2LwpCeHQ0TGdSeVdhT0dSSy9nbjZUanZjSldIRldYRzNaWjViNHMxdzhlNkJjMVFtWnB3Z3JUVDRJa2ZxMW9RWXpaCnJ5RWVqenlKYWVnaHdSeEJLWEFkVE5ZPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==",
                "client_key": "LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlKS0FJQkFBS0NBZ0VBM3FMcVVYbUVkVGd5bmdQb2RsYURHUEVVdjZ4Ump5SW5qZlNlZ3M4a0tMWVNyWk9QClVuTnNFQ3JkWndpT3lhL3MzSGpneW5MbElxZnVtdk9LWDN6dTRwc0g5eE03RitoSGtWUUhqSHRELzdyd3hCQ2UKQUc4TGsvazk5bk52Y3Z6eU55U0d0ZGU0UDdFZkJXRWdtMTk1NXE0UEV2UFBwMTJmYnhDSGFlcVYrNEtqNmV2SgpxNkdvdmtHMTVSS2U5a1FqeDhiaW84NnQwSlhVS3EvUlAyUUlUVVQ2MXZtVmxvZjFFZWxuaHMwQXZOd3M5bzJHCkpzM0d2YWdia0JyQTJsUUM5YkhzZkJKb2VtVDlqbDVGSnR6Q2M3dkdDQ0h6eUx1cy94eUlHV0VTVDFqVnR2bFUKc3MvTmI5U1F5WVNyQXVVS2E4aTRQVHNPU2ZNSlFKV09acWFINzRhcEticjJIZk5FOWxsMHQ4c29QNklwVStENwpNdVM2eWtYZCszbjk0ajFORWZHM1RTbm1TR3pLNGtvV1F5WjRlRGZCR1FxVEtTcWQzczlJdlh1VFlaRGcrSDBwCmloZzlNanFDZEhIMW96b0JuVmg2Ny90SWozUEkwOFVnU1hDZnVobzkycmRubWx3a0Mva1EzeU5tRHVlUTVna2MKUEp6dkNzeU9YYWRjTXdWb2xFQlArWlMwclZJZ2lQczZTblhubVhtMzl2Tkphb3YrNE9qOFJCcDl5d3JETGhjMgovd1E0OU90RVJJdmlOVmlFaS85clZSbWszS2ZDa2lPaVZINVhoVGIwcm5udDVDN3JxK2xnRHZ3NVViN3U2Yk81CmpCU3VQSHpCVWJpRFdVdVBzOWVpUEw2cHI1NFU1enl0TXBUdEdvcVNuYlFzYkJPdzFzSTZSb2RwY0FNQ0F3RUEKQVFLQ0FnQUJYT3c2VUZWYU4rejgrRG95NGd5MEcvT2pzb0FiN3FiODU2cW1VMmUxY0hHbm5LVUxHNmdNZlIybAo0T0FPTnRLTWt0QXRmYzZVRnQzaXZhaUR1clJyc0hlaHdWWk1KWnN5NkF1KzZsWnlmckgzaEJsNzRKWlZOZTFxClVIMEpmRGpiNmJ6UHBoaUdxMHVlNHo2NkhvVnQ2NVZQTEF2UDFjd2M4aUNjaVFublBWSXo2K08waHdZNW5QL08KZ3R4cFowb1ZxRHYxd0Q4SmpxYlQ5R3ZGRnJYR1RSRER0M1hoYXJ4YnlVZG96TG83Tmh2RjdPWWp5UnhJb01obgpvZmNxaTRnVVBOQmFnMzEzanVET2dsSWJHZTZKbTE0L1dKWGRxUlQvUTk4RU5xd1lvZi84UC8rN2h4NnNhdHFqCjQva1QzeHg4TFh2SzZ5REVlOU5mWHVRUXp6K3FUcmZEeFpXM1d2U0R4aFNxbjRQZ2NEZ0lUNkU3dzRYZGV6WUYKbGxZTVU2ZENzS25CNXNTYUNkUktCazVNLy9aZUtFWVUzMnNyWXJ2TlJvUWZzSFo4YTNLRVZwMHpkeVJoRDcrVwpaT2dhM2lnd0kxWVhnM29HSHRZUkJXS3ZLYWNjenBNZktoZU4zQmRGcFVDdzcwbDNMcEVnQTB3ZzdvMlIzaDQzCjdBbEVYd3RmcnlNM2p5QWhYL1d1UVcxaUgvY0QzTm5uWXYxVHN5Wit3NGEvbWRpQmhxUW9sc0Q2Vmo0SUF3Yk0KVUpzNlROQ2l3enBDMTRVRFlHQkpmM055VXBxY2tzMFMrK3MyMjVtU1Q0UW1EcDRNLytRSGdIeVZrbDdxeFV6Twp5N2NPeldNR3VOalU2S3I1c1BlNEtheDVaaTB5S3ZPOUZqWnBHaU1JV3h1cWpNdVRJUUtDQVFFQS9ZUVpkUXJKCml5dG1MMEViL3RlU2Jkc1ZkREpkN1pZb2cwdFpCS0VVM3ZMQ2VaNEdHeXhGSVhSTnNFMFRWdVd5UU90UTk3eDkKL1liTjFNbERKYjl5K0UvTFgxZ3AvK3lsZGJHSm5EMzBDc2I1dnlYVndsNGREdVBFVVFTMFdsUFdiTUtQcFZpSgpVMStXUHZuaEY2bkFjL3dEdWVRTFAveFF0NE1pcFRlOFNFL0ZmTXhka1phQUFQdlhCWUVUeWVJUjdXMDJiSTE5ClR2ek8zcmtRN1F5UlJtWjRLOS9SK3NKRzI3aEZ1TnErY2llbGZuZU9wWmlPbElWSTVabVZaUXNkbG9KNzZqYW8KNHMvS0dPbi80RXZRQTBQdzRCYktTbTdzOWZ3OVY0Y09OVFFHM05nNHp0U0V6YUR3VHlzWFQzdTNtUlpjeWR6dApmQ0ZpRld0MFBLR2lqUUtDQVFFQTRORmNGd2VVeUdRT1Y2T1JsWkV0aUI0d3FKdlZYdHN5Y0kxMjgveHkyQU43CldZVHhmL3Jia2hlbENGS3NiTVhNQytDWExjYkpYWXZNSkl5YmVROFJwZ0c0NE9ublhjU2FIVWxIMTZ5Q2R0bWgKNTdIVDNnMUZJREszbGJKZWY1ZzM3emdvaisrVk16WVhaMEttTEpxTkJCWVJUOHVGYmVJbGVhSzYySXhLWUF3eApKR3hjZkxhb3A0WHVWd3k1YXd0bzVVVU5UTXhNWFhQUGdIbk1KMzRxY1dUYnlYNm1ZSTgxTlhyaUJTVWYzL0NsCkFuYUJTMnB4ZVlzWlAvdmFNcXNqN0dmWko0N1g5a2VheEhZTnliNWVVUW5LeDN4RkVJS2EyR0NYL0FzNG11ZjYKb0UyY2NtYy9ZU1Fmd3lnSjBwbmtQR1JlOW9FemM0VnVpWjRNUVZNQXp3S0NBUUFjYnBKRVZCOWlZazJsZ3hIVwp0T3FSTTM3bWR6ZWRpN2VqY2ZIYjJRejBMQm12ZGcrTlFKdklNcmo3eXNrZWQ4aFVDNUFiR0tLd3FrdXZUNXNlClFxaHNQTmE4TExFWktMc3R4ZWwvQWx1NlViSjB3NU9EcHZadlV4QVRYZ20wRDY3K3A1dGdtZHRjNUYxL1ZwcnUKQW5XNURFeUdycEtzYkduSkN3WDVyWlNLTDVnZ2RQTVJmdVdBTnI1WXVhODBkd3czcW9YdUNyaEJBWTFaNFR1Swp1bHdZbnlsZkVrMEVhSUYxNXVhNjRwMTFSQWtGYy9jbGowUitWNnhqUTZSRG5zbUV0Y0diOU9GZi9wblZ6WGlLCitUV3RDQk9kcmpDbHhHY0M5M1VSdWUzWC9hdS9YT2lTR2JlRE1FZURPWHYxeUJSQk1RYmJCTklGbCtEZU1oenAKSjkrSkFvSUJBQ3ZnMEw5eDdGajhKa3gya1RpRzRFTWIyVlZmTE5MWnAwdU9ZTFFZQm5ZZ245ZUYrZmlIaG9sSgo4aHpndmVSdzZuVTYvV2FpMExSZ1Q1U21tTVdVNmxYaktpbERuYk9RWnAvbXFJM3dqbm9SMmVhMXIyczhYY3g5CitaVE8vbUNhM2Zmamx3OFlySjhWSkpZenpPa1J0UW9pSUhqWmVRNU1RQkl3YjVWS05FM3dzenF2cDVGenVSRVIKTThacnBsaTlIbGo1RkRKMEFVZVFEZVMrWU5rb1o3SkFCQ0djaFc1OUpONXVRR1RPclJ6eEE5T3FPMnZ6dDNnSQpiUUl1N3BSTEVMVFlRK3JUbDFUcS9zcnZXNXVQZXlzSDVUcndCeTdFdnVJU1lEZUNIU2NtdGFUSjRRbjNHc2lqCjIwc2txbDRmU1F0OGI0aGZDU0szM1M0ZzJiVjZOTU1DZ2dFQkFPWDhHMzd0MVJCRHZ6cTZobnJ0ZXBnbFNURXUKeDg2RDE3c1czcGNqT0hUSkUvcGRTaTRab1dFTWR6UnZRcWVwUGQzN1RjRXJoWi80ekdTTTRVd3hiZnZ1eFIvSQpNR21xNkYveVR4TTdrY0lJQmlFVk0yNUtxUlhWZ3doZzNpUDYvazZvczV2a2t0L1doeGs0ejFxcFBkUzZVMEJSCkI5MFZtQ3AramhGY1V2SEplbWpSZ25rK1JnU2lLcUtVTjg5eG1HNEFyRVJhV3NqQklXcU82RW1UUnRvVTJjdzUKd0dKYWRxbFk3Wk1TZFd3NU1CMEMvUjFrR0syN1YwZGY1SDkxWWc4QUIraVVRSWNzWllVRjdZbUpmRDJlSEhRaAovS2hML2h3YjFsUlBUenZSdEhHbmtIbEdsM2w3MUhIcnlJVHllWXIydjNnTDBveWw3WnU1SzFRMlZIVT0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0K",
                "cluster_ca_certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUU2RENDQXRDZ0F3SUJBZ0lRQmxmYTRNdTc4U0xHQUkzU1d3RTlkakFOQmdrcWhraUc5dzBCQVFzRkFEQU4KTVFzd0NRWURWUVFERXdKallUQWdGdzB5TlRBNE1UQXdOREl3TXpsYUdBOHlNRFUxTURneE1EQTBNekF6T1ZvdwpEVEVMTUFrR0ExVUVBeE1DWTJFd2dnSWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUNEd0F3Z2dJS0FvSUNBUURlCkgzdTZhWFVvZ0lwcUtFZ3VLcWNMNVRnMkh5Ri81WXNEbTgzSXlGNHZ1TkU3Mi9CMjdBOTJhVXNSNXQwNDlKeWYKSHhBSFplZTYvS0FtUUxtc09hRDl2QjJLeUpaSjBvV05DaENCN1hxck5WQlNKSW5qU0haMm9HaEs5N3AyclJPbwpqSTdFNU5mTjlLTHYySytGVnhoT09HVG15OGZJY3k1ZW53cFdOUlovL2NFRGVpbDhSZGlwUmFFMDFXYXd5Ri9sClB2OWozMHorOEFnWHdUU0NoY3FzR0EwTjZXakhJTndMMFpMZEVaakpzMDhDWWUzZmFBSGxibVExM0wyb0R2MVcKdURSUTM5YjdRWkxhZGZpRjFyOUxGMjczdHZhRzBGaUNWQ21FVWRsWGpWNzJyclpuaWRXTUZUdEdxelJjQm4reQozRzVKdVllYmh4TFg5T1piYVloK1FJQmEra1ZpSWMwTk1JbkhDandsdFFvalBEOWpTeURWY2lmYVAwdGdtamEzCnJWdzR2MThXa3ozVGRTcU0vbXROSGU4TmNGTzBXR2t4S1BzUW1CVFhLL2ZiNjNoTXVwRWt6TDc2eGM1OFBCcTkKa1pXZ1drVU1TdnBhc25xNmw4RUVaL2IwK0gyUDdyZHY1bG5IMG5JQlRDUURsVUpKdDdIc3BqSE9jdFY2c1dKZgpkTGpDSy9oUUtUVGh3YjZCTGVYVGJ2TmJxMXF4N0VKRlFBNi9Dbkp1dUROM25mL25kVWtzZzVFQXBEeWxtYXNXCmhvdmtVTmZmOTVqNGt6c0VLeUFkMVZtTjc4anBYdVN5K2JSR0ZOaDRocFIrZk1OT3ZVK3NWU3VVSjR1UC9TYTMKbFVUNjZzY0JsQktQUEI2UFNia1ZWU1ZUUHgrZUZETzllQXNONisvblB3SURBUUFCbzBJd1FEQU9CZ05WSFE4QgpBZjhFQkFNQ0FxUXdEd1lEVlIwVEFRSC9CQVV3QXdFQi96QWRCZ05WSFE0RUZnUVViSVpGbE05WXBMN1QzSEZiCmRPdy82N0JLd3VRd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dJQkFGak9vV1dyNUprVjZQdmFLT011WWJ0N0hkVjEKd1FBQkxkVElVVk5yK0FFNExGUDZRdEVaUHBxNmhUV3pBdk9oY0hZMEdQUVIwMEdsaFV5eFhQREt6OUZUU2RJNgoxbGVnQWlKL21WYUs1d2I4UFd5RjJZQkZDRytLZmVBRm5xNW0veXcyMVU3VjRBbllxTUZ1TjVzWStvekc2cWRICk55aW11VFB2d1VoVE9MR09PRUt2UUl4YUNtTWdwSGt0MHovaFlYSGhjZ0lOK2dlcVBOOVZ2K08wWHJPdGRWNjYKQ3BnNVlwa3phTUdTV2x2Q1hwSVd5cTluc05ic1VwWlNaRkN5aFMzd05OYmgyU0VsZUsxTnZ5ZVQ5YmpLVDBRNQpBRmFTMExEeERUdWk1UHU1bXRlVVZOeitNM2NVNGRHZmJZUVZpWWhBYzVCS2JxdVhUQTFRb0doaVNCa204aE5zCjk2ak5EbENrTVp0SjFpZi9OKzRCYjdVS2FVZ2t3OUJGRG1yTHQ1aFhhL2dOZEt1M0JlOXJsaXdkSml5eVVuT2oKeTBkcHF2TzArd1lOUy93TzNrWGgyVGxQOWs1Sm5XdkZhd3JMa0E2bmtMTm50bjBBZUxPWmRBa1pEbWI4WGw1VApWUkoveDk2cDRsNmYrNXdPazRUZFJrZ2JVRTB2M2oweDdvZDkzbVUyT3RYeFVGOFRLbk9kZWNmVmtrb24vSm51ClR5SEZ5cXdoNEsxMytTczdLMHhoV1hIRk8weWVlSVY0RTI1bFRtU1oxZm04WVZPeUsvbFJUbWEzVzFwdDF0aVgKT0tSaGZLY2N6UmZXdStDaWlnS3Mrd25vcGxWc00wK0xCSi9kNytaVjZPOEpCSkErL2pYc0FocVl3U3Q0NHNHbQpuaS9hZS9JYlJqamNCeFZHCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
                "host": "https://test-aks-0wesh6hk.hcp.canadacentral.azmk8s.io:443",
                "password": "1as0q1jh2fq6nnde39dr3r0xvyd079px54cgqnqnlyrtfbwjgfg0xxcfl08j7grrrcuict5euvgec3t38kbyc8puvj7m54bbsasaq5z4y9vkchxk34dex6s1ad4r30o0",
                "username": "clusterUser_cst8918-final-project-group-2_test-aks"
              }
            ],
            "kube_config_raw": "apiVersion: v1\nclusters:\n- cluster:\n    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUU2RENDQXRDZ0F3SUJBZ0lRQmxmYTRNdTc4U0xHQUkzU1d3RTlkakFOQmdrcWhraUc5dzBCQVFzRkFEQU4KTVFzd0NRWURWUVFERXdKallUQWdGdzB5TlRBNE1UQXdOREl3TXpsYUdBOHlNRFUxTURneE1EQTBNekF6T1ZvdwpEVEVMTUFrR0ExVUVBeE1DWTJFd2dnSWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUNEd0F3Z2dJS0FvSUNBUURlCkgzdTZhWFVvZ0lwcUtFZ3VLcWNMNVRnMkh5Ri81WXNEbTgzSXlGNHZ1TkU3Mi9CMjdBOTJhVXNSNXQwNDlKeWYKSHhBSFplZTYvS0FtUUxtc09hRDl2QjJLeUpaSjBvV05DaENCN1hxck5WQlNKSW5qU0haMm9HaEs5N3AyclJPbwpqSTdFNU5mTjlLTHYySytGVnhoT09HVG15OGZJY3k1ZW53cFdOUlovL2NFRGVpbDhSZGlwUmFFMDFXYXd5Ri9sClB2OWozMHorOEFnWHdUU0NoY3FzR0EwTjZXakhJTndMMFpMZEVaakpzMDhDWWUzZmFBSGxibVExM0wyb0R2MVcKdURSUTM5YjdRWkxhZGZpRjFyOUxGMjczdHZhRzBGaUNWQ21FVWRsWGpWNzJyclpuaWRXTUZUdEdxelJjQm4reQozRzVKdVllYmh4TFg5T1piYVloK1FJQmEra1ZpSWMwTk1JbkhDandsdFFvalBEOWpTeURWY2lmYVAwdGdtamEzCnJWdzR2MThXa3ozVGRTcU0vbXROSGU4TmNGTzBXR2t4S1BzUW1CVFhLL2ZiNjNoTXVwRWt6TDc2eGM1OFBCcTkKa1pXZ1drVU1TdnBhc25xNmw4RUVaL2IwK0gyUDdyZHY1bG5IMG5JQlRDUURsVUpKdDdIc3BqSE9jdFY2c1dKZgpkTGpDSy9oUUtUVGh3YjZCTGVYVGJ2TmJxMXF4N0VKRlFBNi9Dbkp1dUROM25mL25kVWtzZzVFQXBEeWxtYXNXCmhvdmtVTmZmOTVqNGt6c0VLeUFkMVZtTjc4anBYdVN5K2JSR0ZOaDRocFIrZk1OT3ZVK3NWU3VVSjR1UC9TYTMKbFVUNjZzY0JsQktQUEI2UFNia1ZWU1ZUUHgrZUZETzllQXNONisvblB3SURBUUFCbzBJd1FEQU9CZ05WSFE4QgpBZjhFQkFNQ0FxUXdEd1lEVlIwVEFRSC9CQVV3QXdFQi96QWRCZ05WSFE0RUZnUVViSVpGbE05WXBMN1QzSEZiCmRPdy82N0JLd3VRd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dJQkFGak9vV1dyNUprVjZQdmFLT011WWJ0N0hkVjEKd1FBQkxkVElVVk5yK0FFNExGUDZRdEVaUHBxNmhUV3pBdk9oY0hZMEdQUVIwMEdsaFV5eFhQREt6OUZUU2RJNgoxbGVnQWlKL21WYUs1d2I4UFd5RjJZQkZDRytLZmVBRm5xNW0veXcyMVU3VjRBbllxTUZ1TjVzWStvekc2cWRICk55aW11VFB2d1VoVE9MR09PRUt2UUl4YUNtTWdwSGt0MHovaFlYSGhjZ0lOK2dlcVBOOVZ2K08wWHJPdGRWNjYKQ3BnNVlwa3phTUdTV2x2Q1hwSVd5cTluc05ic1VwWlNaRkN5aFMzd05OYmgyU0VsZUsxTnZ5ZVQ5YmpLVDBRNQpBRmFTMExEeERUdWk1UHU1bXRlVVZOeitNM2NVNGRHZmJZUVZpWWhBYzVCS2JxdVhUQTFRb0doaVNCa204aE5zCjk2ak5EbENrTVp0SjFpZi9OKzRCYjdVS2FVZ2t3OUJGRG1yTHQ1aFhhL2dOZEt1M0JlOXJsaXdkSml5eVVuT2oKeTBkcHF2TzArd1lOUy93TzNrWGgyVGxQOWs1Sm5XdkZhd3JMa0E2bmtMTm50bjBBZUxPWmRBa1pEbWI4WGw1VApWUkoveDk2cDRsNmYrNXdPazRUZFJrZ2JVRTB2M2oweDdvZDkzbVUyT3RYeFVGOFRLbk9kZWNmVmtrb24vSm51ClR5SEZ5cXdoNEsxMytTczdLMHhoV1hIRk8weWVlSVY0RTI1bFRtU1oxZm04WVZPeUsvbFJUbWEzVzFwdDF0aVgKT0tSaGZLY2N6UmZXdStDaWlnS3Mrd25vcGxWc00wK0xCSi9kNytaVjZPOEpCSkErL2pYc0FocVl3U3Q0NHNHbQpuaS9hZS9JYlJqamNCeFZHCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K\n    server: https://test-aks-0wesh6hk.hcp.canadacentral.azmk8s.io:443\n  name: test-aks\ncontexts:\n- context:\n    cluster: test-aks\n    user: clusterUser_cst8918-final-project-group-2_test-aks\n  name: test-aks\ncurrent-context: test-aks\nkind: Config\npreferences: {}\nusers:\n- name: clusterUser_cst8918-final-project-group-2_test-aks\n  user:\n    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZIVENDQXdXZ0F3SUJBZ0lRUjc2YXovQ3pNRFhYYWlhU2ZHZUJYekFOQmdrcWhraUc5dzBCQVFzRkFEQU4KTVFzd0NRWURWUVFERXdKallUQWVGdzB5TlRBNE1UQXdOREl3TXpsYUZ3MHlOekE0TVRBd05ETXdNemxhTURBeApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1SVXdFd1lEVlFRREV3eHRZWE4wWlhKamJHbGxiblF3CmdnSWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUNEd0F3Z2dJS0FvSUNBUURlb3VwUmVZUjFPREtlQStoMlZvTVkKOFJTL3JGR1BJaWVOOUo2Q3p5UW90aEt0azQ5U2Myd1FLdDFuQ0k3SnIremNlT0RLY3VVaXArNmE4NHBmZk83aQptd2YzRXpzWDZFZVJWQWVNZTBQL3V2REVFSjRBYnd1VCtUMzJjMjl5L1BJM0pJYTExN2cvc1I4RllTQ2JYM25tCnJnOFM4OCtuWFo5dkVJZHA2cFg3Z3FQcDY4bXJvYWkrUWJYbEVwNzJSQ1BIeHVLanpxM1FsZFFxcjlFL1pBaE4KUlByVytaV1doL1VSNldlR3pRQzgzQ3oyallZbXpjYTlxQnVRR3NEYVZBTDFzZXg4RW1oNlpQMk9Ya1VtM01Kegp1OFlJSWZQSXU2ei9ISWdaWVJKUFdOVzIrVlN5ejgxdjFKREpoS3NDNVFwcnlMZzlPdzVKOHdsQWxZNW1wb2Z2Cmhxa3B1dllkODBUMldYUzN5eWcvb2lsVDRQc3k1THJLUmQzN2VmM2lQVTBSOGJkTktlWkliTXJpU2haREpuaDQKTjhFWkNwTXBLcDNlejBpOWU1TmhrT0Q0ZlNtS0dEMHlPb0owY2ZXak9nR2RXSHJ2KzBpUGM4alR4U0JKY0orNgpHajNhdDJlYVhDUUwrUkRmSTJZTzU1RG1DUnc4bk84S3pJNWRwMXd6QldpVVFFLzVsTFN0VWlDSSt6cEtkZWVaCmViZjI4MGxxaS83ZzZQeEVHbjNMQ3NNdUZ6Yi9CRGowNjBSRWkrSTFXSVNMLzJ0VkdhVGNwOEtTSTZKVWZsZUYKTnZTdWVlM2tMdXVyNldBTy9EbFJ2dTdwczdtTUZLNDhmTUZSdUlOWlM0K3oxNkk4dnFtdm5oVG5QSzB5bE8wYQppcEtkdEN4c0U3RFd3anBHaDJsd0F3SURBUUFCbzFZd1ZEQU9CZ05WSFE4QkFmOEVCQU1DQmFBd0V3WURWUjBsCkJBd3dDZ1lJS3dZQkJRVUhBd0l3REFZRFZSMFRBUUgvQkFJd0FEQWZCZ05WSFNNRUdEQVdnQlJzaGtXVXoxaWsKdnRQY2NWdDA3RC9yc0VyQzVEQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FnRUFkeGNVVStyWnZzNVk5dHptU3FmcApzOE9jZURtVkFZaVRUUTdBbnFCbVkzbjZlOFpjWUNhMytoV3d0Y1FQc09xNWdSQmR4Q29vTUZNS1dIQmRoazdwCjlLN1NHVGRSK0VqMDBIckZ3anZvS0NZY3ZDOTYvcTh6RDJqTkhLbFhJQ2lLL3FacXdFS1NkdzlpV01NNmEzcVQKQU9JVk5hdGVOOURpS1ZiUGFuZ2NGOTBkVGNUYnNueUdWWXY3QlRCc2pRamdid1phYnNpSWJKTkp3UCtHU3RLdwpsV04xckt5UjZGenRlbFBFVzFnTVdGeXJ2YitlaDlmMXRNbjg0NXE4NmNjd3RkOG13cm9BK3dZc01wMUsvSzFGClQ0bVhUanBwQmJQN2swZlhndFZRYU9CMTI4NGxIVFE2TDNrNWZVelRveFFUR1dUZUJhbDdHWVFZbVpYY09MZW0KRldxV3o5VGNZMU1vN0FVWURiRzl0QmxwR3pqa1lRcWpBSVBpOXNsb3I3bnJ3U3UwWC9jL2JnUWt0ZlcxMWxTMQpqUXU2YVlMRWpqZWNXMnFXVmp4M1o5eFFLYXpWVmpUaGJWS09YOFVvR3NYOG1oNHRJdldISmNKK3ZMcWlwMGNNCnRMY3RrN3NZSjJSeVJEZTdpVGxWT2VRUTlROXVaV2p1U2ZBOXpJZXlZQmVxS0RNNWJLSldGc1BhMzY0R2N5azkKUEtyaGo3SVdEcUZVejRJenV4WHJuemZUSDAyeU1OaXE2NDU2NkRYUCtmczJzMzE3U2FCTEJXemhJMUxEbXI2LwpCeHQ0TGdSeVdhT0dSSy9nbjZUanZjSldIRldYRzNaWjViNHMxdzhlNkJjMVFtWnB3Z3JUVDRJa2ZxMW9RWXpaCnJ5RWVqenlKYWVnaHdSeEJLWEFkVE5ZPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==\n    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlKS0FJQkFBS0NBZ0VBM3FMcVVYbUVkVGd5bmdQb2RsYURHUEVVdjZ4Ump5SW5qZlNlZ3M4a0tMWVNyWk9QClVuTnNFQ3JkWndpT3lhL3MzSGpneW5MbElxZnVtdk9LWDN6dTRwc0g5eE03RitoSGtWUUhqSHRELzdyd3hCQ2UKQUc4TGsvazk5bk52Y3Z6eU55U0d0ZGU0UDdFZkJXRWdtMTk1NXE0UEV2UFBwMTJmYnhDSGFlcVYrNEtqNmV2SgpxNkdvdmtHMTVSS2U5a1FqeDhiaW84NnQwSlhVS3EvUlAyUUlUVVQ2MXZtVmxvZjFFZWxuaHMwQXZOd3M5bzJHCkpzM0d2YWdia0JyQTJsUUM5YkhzZkJKb2VtVDlqbDVGSnR6Q2M3dkdDQ0h6eUx1cy94eUlHV0VTVDFqVnR2bFUKc3MvTmI5U1F5WVNyQXVVS2E4aTRQVHNPU2ZNSlFKV09acWFINzRhcEticjJIZk5FOWxsMHQ4c29QNklwVStENwpNdVM2eWtYZCszbjk0ajFORWZHM1RTbm1TR3pLNGtvV1F5WjRlRGZCR1FxVEtTcWQzczlJdlh1VFlaRGcrSDBwCmloZzlNanFDZEhIMW96b0JuVmg2Ny90SWozUEkwOFVnU1hDZnVobzkycmRubWx3a0Mva1EzeU5tRHVlUTVna2MKUEp6dkNzeU9YYWRjTXdWb2xFQlArWlMwclZJZ2lQczZTblhubVhtMzl2Tkphb3YrNE9qOFJCcDl5d3JETGhjMgovd1E0OU90RVJJdmlOVmlFaS85clZSbWszS2ZDa2lPaVZINVhoVGIwcm5udDVDN3JxK2xnRHZ3NVViN3U2Yk81CmpCU3VQSHpCVWJpRFdVdVBzOWVpUEw2cHI1NFU1enl0TXBUdEdvcVNuYlFzYkJPdzFzSTZSb2RwY0FNQ0F3RUEKQVFLQ0FnQUJYT3c2VUZWYU4rejgrRG95NGd5MEcvT2pzb0FiN3FiODU2cW1VMmUxY0hHbm5LVUxHNmdNZlIybAo0T0FPTnRLTWt0QXRmYzZVRnQzaXZhaUR1clJyc0hlaHdWWk1KWnN5NkF1KzZsWnlmckgzaEJsNzRKWlZOZTFxClVIMEpmRGpiNmJ6UHBoaUdxMHVlNHo2NkhvVnQ2NVZQTEF2UDFjd2M4aUNjaVFublBWSXo2K08waHdZNW5QL08KZ3R4cFowb1ZxRHYxd0Q4SmpxYlQ5R3ZGRnJYR1RSRER0M1hoYXJ4YnlVZG96TG83Tmh2RjdPWWp5UnhJb01obgpvZmNxaTRnVVBOQmFnMzEzanVET2dsSWJHZTZKbTE0L1dKWGRxUlQvUTk4RU5xd1lvZi84UC8rN2h4NnNhdHFqCjQva1QzeHg4TFh2SzZ5REVlOU5mWHVRUXp6K3FUcmZEeFpXM1d2U0R4aFNxbjRQZ2NEZ0lUNkU3dzRYZGV6WUYKbGxZTVU2ZENzS25CNXNTYUNkUktCazVNLy9aZUtFWVUzMnNyWXJ2TlJvUWZzSFo4YTNLRVZwMHpkeVJoRDcrVwpaT2dhM2lnd0kxWVhnM29HSHRZUkJXS3ZLYWNjenBNZktoZU4zQmRGcFVDdzcwbDNMcEVnQTB3ZzdvMlIzaDQzCjdBbEVYd3RmcnlNM2p5QWhYL1d1UVcxaUgvY0QzTm5uWXYxVHN5Wit3NGEvbWRpQmhxUW9sc0Q2Vmo0SUF3Yk0KVUpzNlROQ2l3enBDMTRVRFlHQkpmM055VXBxY2tzMFMrK3MyMjVtU1Q0UW1EcDRNLytRSGdIeVZrbDdxeFV6Twp5N2NPeldNR3VOalU2S3I1c1BlNEtheDVaaTB5S3ZPOUZqWnBHaU1JV3h1cWpNdVRJUUtDQVFFQS9ZUVpkUXJKCml5dG1MMEViL3RlU2Jkc1ZkREpkN1pZb2cwdFpCS0VVM3ZMQ2VaNEdHeXhGSVhSTnNFMFRWdVd5UU90UTk3eDkKL1liTjFNbERKYjl5K0UvTFgxZ3AvK3lsZGJHSm5EMzBDc2I1dnlYVndsNGREdVBFVVFTMFdsUFdiTUtQcFZpSgpVMStXUHZuaEY2bkFjL3dEdWVRTFAveFF0NE1pcFRlOFNFL0ZmTXhka1phQUFQdlhCWUVUeWVJUjdXMDJiSTE5ClR2ek8zcmtRN1F5UlJtWjRLOS9SK3NKRzI3aEZ1TnErY2llbGZuZU9wWmlPbElWSTVabVZaUXNkbG9KNzZqYW8KNHMvS0dPbi80RXZRQTBQdzRCYktTbTdzOWZ3OVY0Y09OVFFHM05nNHp0U0V6YUR3VHlzWFQzdTNtUlpjeWR6dApmQ0ZpRld0MFBLR2lqUUtDQVFFQTRORmNGd2VVeUdRT1Y2T1JsWkV0aUI0d3FKdlZYdHN5Y0kxMjgveHkyQU43CldZVHhmL3Jia2hlbENGS3NiTVhNQytDWExjYkpYWXZNSkl5YmVROFJwZ0c0NE9ublhjU2FIVWxIMTZ5Q2R0bWgKNTdIVDNnMUZJREszbGJKZWY1ZzM3emdvaisrVk16WVhaMEttTEpxTkJCWVJUOHVGYmVJbGVhSzYySXhLWUF3eApKR3hjZkxhb3A0WHVWd3k1YXd0bzVVVU5UTXhNWFhQUGdIbk1KMzRxY1dUYnlYNm1ZSTgxTlhyaUJTVWYzL0NsCkFuYUJTMnB4ZVlzWlAvdmFNcXNqN0dmWko0N1g5a2VheEhZTnliNWVVUW5LeDN4RkVJS2EyR0NYL0FzNG11ZjYKb0UyY2NtYy9ZU1Fmd3lnSjBwbmtQR1JlOW9FemM0VnVpWjRNUVZNQXp3S0NBUUFjYnBKRVZCOWlZazJsZ3hIVwp0T3FSTTM3bWR6ZWRpN2VqY2ZIYjJRejBMQm12ZGcrTlFKdklNcmo3eXNrZWQ4aFVDNUFiR0tLd3FrdXZUNXNlClFxaHNQTmE4TExFWktMc3R4ZWwvQWx1NlViSjB3NU9EcHZadlV4QVRYZ20wRDY3K3A1dGdtZHRjNUYxL1ZwcnUKQW5XNURFeUdycEtzYkduSkN3WDVyWlNLTDVnZ2RQTVJmdVdBTnI1WXVhODBkd3czcW9YdUNyaEJBWTFaNFR1Swp1bHdZbnlsZkVrMEVhSUYxNXVhNjRwMTFSQWtGYy9jbGowUitWNnhqUTZSRG5zbUV0Y0diOU9GZi9wblZ6WGlLCitUV3RDQk9kcmpDbHhHY0M5M1VSdWUzWC9hdS9YT2lTR2JlRE1FZURPWHYxeUJSQk1RYmJCTklGbCtEZU1oenAKSjkrSkFvSUJBQ3ZnMEw5eDdGajhKa3gya1RpRzRFTWIyVlZmTE5MWnAwdU9ZTFFZQm5ZZ245ZUYrZmlIaG9sSgo4aHpndmVSdzZuVTYvV2FpMExSZ1Q1U21tTVdVNmxYaktpbERuYk9RWnAvbXFJM3dqbm9SMmVhMXIyczhYY3g5CitaVE8vbUNhM2Zmamx3OFlySjhWSkpZenpPa1J0UW9pSUhqWmVRNU1RQkl3YjVWS05FM3dzenF2cDVGenVSRVIKTThacnBsaTlIbGo1RkRKMEFVZVFEZVMrWU5rb1o3SkFCQ0djaFc1OUpONXVRR1RPclJ6eEE5T3FPMnZ6dDNnSQpiUUl1N3BSTEVMVFlRK3JUbDFUcS9zcnZXNXVQZXlzSDVUcndCeTdFdnVJU1lEZUNIU2NtdGFUSjRRbjNHc2lqCjIwc2txbDRmU1F0OGI0aGZDU0szM1M0ZzJiVjZOTU1DZ2dFQkFPWDhHMzd0MVJCRHZ6cTZobnJ0ZXBnbFNURXUKeDg2RDE3c1czcGNqT0hUSkUvcGRTaTRab1dFTWR6UnZRcWVwUGQzN1RjRXJoWi80ekdTTTRVd3hiZnZ1eFIvSQpNR21xNkYveVR4TTdrY0lJQmlFVk0yNUtxUlhWZ3doZzNpUDYvazZvczV2a2t0L1doeGs0ejFxcFBkUzZVMEJSCkI5MFZtQ3AramhGY1V2SEplbWpSZ25rK1JnU2lLcUtVTjg5eG1HNEFyRVJhV3NqQklXcU82RW1UUnRvVTJjdzUKd0dKYWRxbFk3Wk1TZFd3NU1CMEMvUjFrR0syN1YwZGY1SDkxWWc4QUIraVVRSWNzWllVRjdZbUpmRDJlSEhRaAovS2hML2h3YjFsUlBUenZSdEhHbmtIbEdsM2w3MUhIcnlJVHllWXIydjNnTDBveWw3WnU1SzFRMlZIVT0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0K\n    token: 1as0q1jh2fq6nnde39dr3r0xvyd079px54cgqnqnlyrtfbwjgfg0xxcfl08j7grrrcuict5euvgec3t38kbyc8puvj7m54bbsasaq5z4y9vkchxk34dex6s1ad4r30o0\n",
            "kubelet_identity": [
              {
                "client_id": "7af69dd0-79a7-404f-a349-263320c69a61",
                "object_id": "cf7829be-13ac-41c9-8aea-8512e63ccd8a",
                "user_assigned_identity_id": "/subscriptions/431fca8d-e614-4268-aa3c-22a2e684933a/resourceGroups/MC_cst8918-final-project-group-2_test-aks_canadacentral/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-aks-agentpool"
              }
            ],
            "kubernetes_version": "1.32",
            "linux_profile": [],
            "local_account_disabled": false,
            "location": "canadacentral",
            "maintenance_window": [],
            "maintenance_window_auto_upgrade": [],
            "maintenance_window_node_os": [],
            "microsoft_defender": [],
            "monitor_metrics": [],
            "name": "test-aks",
            "network_profile": [
              {
                "dns_service_ip": "10.4.0.10",
                "ip_versions": [
                  "IPv4"
                ],
                "load_balancer_profile": [
                  {
                    "backend_pool_type": "NodeIPConfiguration",
                    "effective_outbound_ips": [
                      "/subscriptions/431fca8d-e614-4268-aa3c-22a2e684933a/resourceGroups/MC_cst8918-final-project-group-2_test-aks_canadacentral/providers/Microsoft.Network/publicIPAddresses/9b36bc0c-b4bf-47ac-a180-50c0721f8bcb"
                    ],
                    "idle_timeout_in_minutes": 0,
                    "managed_outbound_ip_count": 1,
                    "managed_outbound_ipv6_count": 0,
                    "outbound_ip_address_ids": [],
                    "outbound_ip_prefix_ids": [],
                    "outbound_ports_allocated": 0
                  }
                ],
                "load_balancer_sku": "standard",
                "nat_gateway_profile": [],
                "network_data_plane": "azure",
                "network_mode": "",
                "network_plugin": "kubenet",
                "network_plugin_mode": "",
                "network_policy": "",
                "outbound_type": "loadBalancer",
                "pod_cidr": "10.244.0.0/16",
                "pod_cidrs": [
                  "10.244.0.0/16"
                ],
                "service_cidr": "10.4.0.0/16",
                "service_cidrs": [
                  "10.4.0.0/16"
                ]
              }
            ],
            "node_os_upgrade_channel": "NodeImage",
            "node_resource_group": "MC_cst8918-final-project-group-2_test-aks_canadacentral",
            "node_resource_group_id": "/subscriptions/431fca8d-e614-4268-aa3c-22a2e684933a/resourceGroups/MC_cst8918-final-project-group-2_test-aks_canadacentral",
            "oidc_issuer_enabled": false,
            "oidc_issuer_url": "",
            "oms_agent": [],
            "open_service_mesh_enabled": null,
            "portal_fqdn": "test-aks-0wesh6hk.portal.hcp.canadacentral.azmk8s.io",
            "private_cluster_enabled": false,
            "private_cluster_public_fqdn_enabled": false,
            "private_dns_zone_id": "",
            "private_fqdn": "",
            "resource_group_name": "cst8918-final-project-group-2",
            "role_based_access_control_enabled": true,
            "run_command_enabled": true,
            "service_mesh_profile": [],
            "service_principal": [],
            "sku_tier": "Standard",
            "storage_profile": [],
            "support_plan": "KubernetesOfficial",
            "tags": {
              "environment": "test"
            },
            "timeouts": null,
            "upgrade_override": [],
            "web_app_routing": [],
            "windows_profile": [],
            "workload_autoscaler_profile": [],
            "workload_identity_enabled": false
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo1NDAwMDAwMDAwMDAwLCJkZWxldGUiOjU0MDAwMDAwMDAwMDAsInJlYWQiOjMwMDAwMDAwMDAwMCwidXBkYXRlIjo1NDAwMDAwMDAwMDAwfSwic2NoZW1hX3ZlcnNpb24iOiIyIn0=",
          "dependencies": [
            "data.terraform_remote_state.infra"
          ]
        }
      ]
    }
```
</details>


#### The Redis cache instance
- Redis was already deleted at the time of this README update but below is the last state of it from the `test.tfstate` file in the backend

<details><summary>Show Redis state from test.tfstate</summary>

```json
{
      "module": "module.redis",
      "mode": "managed",
      "type": "azurerm_redis_cache",
      "name": "main_cache",
      "provider": "provider[\"registry.terraform.io/hashicorp/azurerm\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "access_keys_authentication_enabled": true,
            "capacity": 1,
            "family": "C",
            "hostname": "cst8918-g2-test-redis.redis.cache.windows.net",
            "id": "/subscriptions/431fca8d-e614-4268-aa3c-22a2e684933a/resourceGroups/cst8918-final-project-group-2/providers/Microsoft.Cache/redis/cst8918-g2-test-redis",
            "identity": [],
            "location": "canadacentral",
            "minimum_tls_version": "1.2",
            "name": "cst8918-g2-test-redis",
            "non_ssl_port_enabled": false,
            "patch_schedule": [],
            "port": 6379,
            "primary_access_key": "XbvNR0Ew3ImVL3JnUgp3nL5Kf0R24ksooAzCaFL7C6s=",
            "primary_connection_string": "cst8918-g2-test-redis.redis.cache.windows.net:6380,password=XbvNR0Ew3ImVL3JnUgp3nL5Kf0R24ksooAzCaFL7C6s=,ssl=true,abortConnect=False",
            "private_static_ip_address": "",
            "public_network_access_enabled": true,
            "redis_configuration": [
              {
                "active_directory_authentication_enabled": false,
                "aof_backup_enabled": false,
                "aof_storage_connection_string_0": "",
                "aof_storage_connection_string_1": "",
                "authentication_enabled": true,
                "data_persistence_authentication_method": "",
                "maxclients": 1000,
                "maxfragmentationmemory_reserved": 125,
                "maxmemory_delta": 125,
                "maxmemory_policy": "",
                "maxmemory_reserved": 125,
                "notify_keyspace_events": "",
                "rdb_backup_enabled": false,
                "rdb_backup_frequency": 0,
                "rdb_backup_max_snapshot_count": 0,
                "rdb_storage_connection_string": "",
                "storage_account_subscription_id": ""
              }
            ],
            "redis_version": "6.0",
            "replicas_per_master": 0,
            "replicas_per_primary": 0,
            "resource_group_name": "cst8918-final-project-group-2",
            "secondary_access_key": "S3P079iyoQVOZ16IYiC07tHbsopSUbcugAzCaFAPZVI=",
            "secondary_connection_string": "cst8918-g2-test-redis.redis.cache.windows.net:6380,password=S3P079iyoQVOZ16IYiC07tHbsopSUbcugAzCaFAPZVI=,ssl=true,abortConnect=False",
            "shard_count": 0,
            "sku_name": "Basic",
            "ssl_port": 6380,
            "subnet_id": "",
            "tags": {
              "environment": "test"
            },
            "tenant_settings": {},
            "timeouts": null,
            "zones": []
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjoxMDgwMDAwMDAwMDAwMCwiZGVsZXRlIjoxMDgwMDAwMDAwMDAwMCwicmVhZCI6MzAwMDAwMDAwMDAwLCJ1cGRhdGUiOjEwODAwMDAwMDAwMDAwfSwic2NoZW1hX3ZlcnNpb24iOiIxIn0=",
          "dependencies": [
            "data.terraform_remote_state.infra"
          ]
        }
      ]
    }
```
</details>

#### Weather app: Partial deployment
- Lastly, our weather app deployed partially but due to the above mentioned challanges, we were not able to get it in a working state
<details><summary>Show Weather App state from test.tfstate</summary>

```json
{
      "module": "module.weather_app",
      "mode": "managed",
      "type": "kubernetes_config_map",
      "name": "weather_app_config",
      "provider": "module.weather_app.provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "binary_data": {},
            "data": {
              "REDIS_HOST": "cst8918-g2-test-redis.redis.cache.windows.net",
              "REDIS_KEY": "XbvNR0Ew3ImVL3JnUgp3nL5Kf0R24ksooAzCaFL7C6s=",
              "REDIS_PORT": "6380"
            },
            "id": "weather-app/weather-app-config",
            "immutable": false,
            "metadata": [
              {
                "annotations": {},
                "generate_name": "",
                "generation": 0,
                "labels": {},
                "name": "weather-app-config",
                "namespace": "weather-app",
                "resource_version": "2037",
                "uid": "87c938b4-c0ac-452a-9374-3184e1156048"
              }
            ]
          },
          "sensitive_attributes": [
            [
              {
                "type": "get_attr",
                "value": "data"
              },
              {
                "type": "index",
                "value": {
                  "value": "REDIS_KEY",
                  "type": "string"
                }
              }
            ]
          ],
          "private": "bnVsbA==",
          "dependencies": [
            "data.terraform_remote_state.infra",
            "module.aks.azurerm_kubernetes_cluster.aks",
            "module.redis.azurerm_redis_cache.main_cache",
            "module.weather_app.kubernetes_namespace.weather_app"
          ]
        }
      ]
    },
    {
      "module": "module.weather_app",
      "mode": "managed",
      "type": "kubernetes_deployment",
      "name": "weather_app",
      "provider": "module.weather_app.provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "status": "tainted",
          "schema_version": 1,
          "attributes": {
            "id": "weather-app/weather-app",
            "metadata": [
              {
                "annotations": null,
                "generate_name": "",
                "generation": 0,
                "labels": null,
                "name": "weather-app",
                "namespace": "weather-app",
                "resource_version": "",
                "uid": ""
              }
            ],
            "spec": [
              {
                "min_ready_seconds": 0,
                "paused": false,
                "progress_deadline_seconds": 600,
                "replicas": "1",
                "revision_history_limit": 10,
                "selector": [
                  {
                    "match_expressions": [],
                    "match_labels": {
                      "app": "weather-app"
                    }
                  }
                ],
                "strategy": [],
                "template": [
                  {
                    "metadata": [
                      {
                        "annotations": null,
                        "generate_name": "",
                        "generation": 0,
                        "labels": {
                          "app": "weather-app"
                        },
                        "name": "",
                        "namespace": "",
                        "resource_version": "",
                        "uid": ""
                      }
                    ],
                    "spec": [
                      {
                        "active_deadline_seconds": 0,
                        "affinity": [],
                        "automount_service_account_token": true,
                        "container": [
                          {
                            "args": null,
                            "command": null,
                            "env": [
                              {
                                "name": "WEATHER_API_KEY",
                                "value": "",
                                "value_from": [
                                  {
                                    "config_map_key_ref": [],
                                    "field_ref": [],
                                    "resource_field_ref": [],
                                    "secret_key_ref": [
                                      {
                                        "key": "WEATHER_API_KEY",
                                        "name": "weather-api-secret",
                                        "optional": false
                                      }
                                    ]
                                  }
                                ]
                              }
                            ],
                            "env_from": [
                              {
                                "config_map_ref": [
                                  {
                                    "name": "weather-app-config",
                                    "optional": false
                                  }
                                ],
                                "prefix": "",
                                "secret_ref": []
                              }
                            ],
                            "image": "cst8918finalprojectacr.azurecr.io/weather-app:3e9870c144e2323f241d38a56a238e51b0775bde",
                            "image_pull_policy": "",
                            "lifecycle": [],
                            "liveness_probe": [
                              {
                                "exec": [],
                                "failure_threshold": 3,
                                "grpc": [],
                                "http_get": [
                                  {
                                    "host": "",
                                    "http_header": [],
                                    "path": "/health",
                                    "port": "3000",
                                    "scheme": "HTTP"
                                  }
                                ],
                                "initial_delay_seconds": 30,
                                "period_seconds": 10,
                                "success_threshold": 1,
                                "tcp_socket": [],
                                "timeout_seconds": 1
                              }
                            ],
                            "name": "weather-app",
                            "port": [
                              {
                                "container_port": 3000,
                                "host_ip": "",
                                "host_port": 0,
                                "name": "",
                                "protocol": "TCP"
                              }
                            ],
                            "readiness_probe": [
                              {
                                "exec": [],
                                "failure_threshold": 3,
                                "grpc": [],
                                "http_get": [
                                  {
                                    "host": "",
                                    "http_header": [],
                                    "path": "/health",
                                    "port": "3000",
                                    "scheme": "HTTP"
                                  }
                                ],
                                "initial_delay_seconds": 5,
                                "period_seconds": 5,
                                "success_threshold": 1,
                                "tcp_socket": [],
                                "timeout_seconds": 1
                              }
                            ],
                            "resources": [
                              {
                                "limits": {
                                  "cpu": "500m",
                                  "memory": "512Mi"
                                },
                                "requests": {
                                  "cpu": "250m",
                                  "memory": "256Mi"
                                }
                              }
                            ],
                            "security_context": [],
                            "startup_probe": [],
                            "stdin": false,
                            "stdin_once": false,
                            "termination_message_path": "/dev/termination-log",
                            "termination_message_policy": "",
                            "tty": false,
                            "volume_device": [],
                            "volume_mount": [],
                            "working_dir": ""
                          }
                        ],
                        "dns_config": [],
                        "dns_policy": "ClusterFirst",
                        "enable_service_links": true,
                        "host_aliases": [],
                        "host_ipc": false,
                        "host_network": false,
                        "host_pid": false,
                        "hostname": "",
                        "image_pull_secrets": [
                          {
                            "name": "acr-auth"
                          }
                        ],
                        "init_container": [],
                        "node_name": "",
                        "node_selector": null,
                        "os": [],
                        "priority_class_name": "",
                        "readiness_gate": [],
                        "restart_policy": "Always",
                        "runtime_class_name": "",
                        "scheduler_name": "",
                        "security_context": [],
                        "service_account_name": "",
                        "share_process_namespace": false,
                        "subdomain": "",
                        "termination_grace_period_seconds": 30,
                        "toleration": [],
                        "topology_spread_constraint": [],
                        "volume": []
                      }
                    ]
                  }
                ]
              }
            ],
            "timeouts": null,
            "wait_for_rollout": true
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo2MDAwMDAwMDAwMDAsImRlbGV0ZSI6NjAwMDAwMDAwMDAwLCJ1cGRhdGUiOjYwMDAwMDAwMDAwMH0sInNjaGVtYV92ZXJzaW9uIjoiMSJ9",
          "dependencies": [
            "data.terraform_remote_state.infra",
            "module.aks.azurerm_kubernetes_cluster.aks",
            "module.weather_app.kubernetes_config_map.weather_app_config",
            "module.weather_app.kubernetes_namespace.weather_app",
            "module.weather_app.kubernetes_secret.acr_auth",
            "module.weather_app.kubernetes_secret.weather_api_key_secret"
          ]
        }
      ]
    },
    {
      "module": "module.weather_app",
      "mode": "managed",
      "type": "kubernetes_namespace",
      "name": "weather_app",
      "provider": "module.weather_app.provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "weather-app",
            "metadata": [
              {
                "annotations": {},
                "generate_name": "",
                "generation": 0,
                "labels": {},
                "name": "weather-app",
                "resource_version": "2031",
                "uid": "1783d808-4198-4ff8-9ba9-8e77760663fe"
              }
            ],
            "timeouts": null,
            "wait_for_default_service_account": false
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiZGVsZXRlIjozMDAwMDAwMDAwMDB9fQ==",
          "dependencies": [
            "data.terraform_remote_state.infra",
            "module.aks.azurerm_kubernetes_cluster.aks"
          ]
        }
      ]
    },
    {
      "module": "module.weather_app",
      "mode": "managed",
      "type": "kubernetes_secret",
      "name": "acr_auth",
      "provider": "module.weather_app.provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "binary_data": null,
            "binary_data_wo": null,
            "binary_data_wo_revision": null,
            "data": {
              ".dockerconfigjson": "{\"auths\":{\"cst8918finalprojectacr.azurecr.io\":{\"auth\":\"Y3N0ODkxOGZpbmFscHJvamVjdGFjcjo1U1kzeml5aFI0OURURVRWRGZ4K05QNVUwdVo5clVhT2t4dStVM0xwMnkrQUNSQ2RSdi8y\",\"password\":\"5SY3ziyhR49DTETVDfx+NP5U0uZ9rUaOkxu+U3Lp2y+ACRCdRv/2\",\"username\":\"cst8918finalprojectacr\"}}}"
            },
            "data_wo": null,
            "data_wo_revision": null,
            "id": "weather-app/acr-auth",
            "immutable": false,
            "metadata": [
              {
                "annotations": null,
                "generate_name": "",
                "generation": 0,
                "labels": null,
                "name": "acr-auth",
                "namespace": "weather-app",
                "resource_version": "447909",
                "uid": "ec30432a-a64e-4dae-bca5-35da1fd5931e"
              }
            ],
            "timeouts": null,
            "type": "kubernetes.io/dockerconfigjson",
            "wait_for_service_account_token": true
          },
          "sensitive_attributes": [
            [
              {
                "type": "get_attr",
                "value": "data"
              },
              {
                "type": "index",
                "value": {
                  "value": ".dockerconfigjson",
                  "type": "string"
                }
              }
            ]
          ],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo2MDAwMDAwMDAwMH19",
          "dependencies": [
            "data.terraform_remote_state.infra",
            "module.aks.azurerm_kubernetes_cluster.aks",
            "module.weather_app.kubernetes_namespace.weather_app"
          ]
        }
      ]
    },
    {
      "module": "module.weather_app",
      "mode": "managed",
      "type": "kubernetes_secret",
      "name": "redis_secret",
      "provider": "module.weather_app.provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "binary_data": null,
            "binary_data_wo": null,
            "binary_data_wo_revision": null,
            "data": {
              "redis-host": "cst8918-g2-test-redis.redis.cache.windows.net",
              "redis-key": "XbvNR0Ew3ImVL3JnUgp3nL5Kf0R24ksooAzCaFL7C6s=",
              "redis-port": "6380"
            },
            "data_wo": null,
            "data_wo_revision": null,
            "id": "weather-app/redis-secret",
            "immutable": false,
            "metadata": [
              {
                "annotations": {},
                "generate_name": "",
                "generation": 0,
                "labels": {},
                "name": "redis-secret",
                "namespace": "weather-app",
                "resource_version": "2039",
                "uid": "c33df0e2-789d-4047-bbed-b85952c8ead4"
              }
            ],
            "timeouts": null,
            "type": "Opaque",
            "wait_for_service_account_token": true
          },
          "sensitive_attributes": [
            [
              {
                "type": "get_attr",
                "value": "data"
              },
              {
                "type": "index",
                "value": {
                  "value": "redis-key",
                  "type": "string"
                }
              }
            ]
          ],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo2MDAwMDAwMDAwMH19",
          "dependencies": [
            "data.terraform_remote_state.infra",
            "module.aks.azurerm_kubernetes_cluster.aks",
            "module.redis.azurerm_redis_cache.main_cache",
            "module.weather_app.kubernetes_namespace.weather_app"
          ]
        }
      ]
    },
    {
      "module": "module.weather_app",
      "mode": "managed",
      "type": "kubernetes_secret",
      "name": "weather_api_key_secret",
      "provider": "module.weather_app.provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "binary_data": null,
            "binary_data_wo": null,
            "binary_data_wo_revision": null,
            "data": {
              "WEATHER_API_KEY": "NWY1ZDg5OWJiYWJiMDZlOWYyMWM0NWRhZDI4YjA4ZTk="
            },
            "data_wo": null,
            "data_wo_revision": null,
            "id": "weather-app/weather-api-secret",
            "immutable": false,
            "metadata": [
              {
                "annotations": {},
                "generate_name": "",
                "generation": 0,
                "labels": {},
                "name": "weather-api-secret",
                "namespace": "weather-app",
                "resource_version": "2042",
                "uid": "e793d3e0-5368-4e45-a25d-b64353f4e71f"
              }
            ],
            "timeouts": null,
            "type": "Opaque",
            "wait_for_service_account_token": true
          },
          "sensitive_attributes": [
            [
              {
                "type": "get_attr",
                "value": "data"
              },
              {
                "type": "index",
                "value": {
                  "value": "WEATHER_API_KEY",
                  "type": "string"
                }
              }
            ]
          ],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo2MDAwMDAwMDAwMH19",
          "dependencies": [
            "data.terraform_remote_state.infra",
            "module.aks.azurerm_kubernetes_cluster.aks",
            "module.weather_app.kubernetes_namespace.weather_app"
          ]
        }
      ]
    },
    {
      "module": "module.weather_app",
      "mode": "managed",
      "type": "kubernetes_service",
      "name": "weather_app",
      "provider": "module.weather_app.provider[\"registry.terraform.io/hashicorp/kubernetes\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "weather-app/weather-app-service",
            "metadata": [
              {
                "annotations": {},
                "generate_name": "",
                "generation": 0,
                "labels": {},
                "name": "weather-app-service",
                "namespace": "weather-app",
                "resource_version": "2134",
                "uid": "03e33a19-b9d0-4b1f-83d8-9da1d12ff0e1"
              }
            ],
            "spec": [
              {
                "allocate_load_balancer_node_ports": true,
                "cluster_ip": "10.4.193.219",
                "cluster_ips": [
                  "10.4.193.219"
                ],
                "external_ips": [],
                "external_name": "",
                "external_traffic_policy": "Cluster",
                "health_check_node_port": 0,
                "internal_traffic_policy": "Cluster",
                "ip_families": [
                  "IPv4"
                ],
                "ip_family_policy": "SingleStack",
                "load_balancer_class": "",
                "load_balancer_ip": "",
                "load_balancer_source_ranges": [],
                "port": [
                  {
                    "app_protocol": "",
                    "name": "",
                    "node_port": 31915,
                    "port": 80,
                    "protocol": "TCP",
                    "target_port": "3000"
                  }
                ],
                "publish_not_ready_addresses": false,
                "selector": {
                  "app": "weather-app"
                },
                "session_affinity": "None",
                "session_affinity_config": [],
                "type": "LoadBalancer"
              }
            ],
            "status": [
              {
                "load_balancer": [
                  {
                    "ingress": [
                      {
                        "hostname": "",
                        "ip": "130.107.169.128"
                      }
                    ]
                  }
                ]
              }
            ],
            "timeouts": null,
            "wait_for_load_balancer": true
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo2MDAwMDAwMDAwMDB9LCJzY2hlbWFfdmVyc2lvbiI6IjEifQ==",
          "dependencies": [
            "data.terraform_remote_state.infra",
            "module.aks.azurerm_kubernetes_cluster.aks",
            "module.weather_app.kubernetes_namespace.weather_app"
          ]
        }
      ]
    }
```
</details>



