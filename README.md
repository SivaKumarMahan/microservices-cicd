# microservices-cicd
Full Microservices CI/CD on AKS — Terraform + Helm + GitHub Actions

## Terraform
1. Data Sources — Reading Existing Azure Information
1.1 Resource Group (existing)
1.2 Client Config (Current User/Service Principal Info)
Retrieves details of the current authenticated Azure account:
    tenant_id
    client_id
    object_id
The Key Vault needs:
    tenant_id → mandatory
    later used for assigning access policies
2. Log Analytics Workspace
Creates a Log Analytics Workspace, used for:
    AKS logs
    Container logs
    Function App logs
    Azure Monitor Insights
The AKS cluster needs this for monitoring + diagnostics via OMS agent.
3. Azure Container Registry (ACR)
Creates an ACR where Docker images will be stored.
GitHub Actions will:
    build Docker image
    push to ACR
    AKS pulls image from ACR
4. Key Vault
Creates a Key Vault to store secrets such as:
    DB Connection Strings
    API Keys
    Certificates
    Storage Keys
Microservices and Function Apps will eventually retrieve secrets from Key Vault.
5. Storage Account (required for Function App)
Creates a storage account used by the Function App for:
    internal runtime storage
    log files
    function execution state
    triggers
Azure Functions cannot run without a storage account.
6. AKS (Azure Kubernetes Service)
Creates the AKS cluster with:
    default nodepool
    monitoring enabled
    system-assigned identity
    Azure CNI networking
This is the Kubernetes cluster where your microservices will run.
SystemAssigned identity → AKS gets an identity in Azure AD
OMS agent → sends cluster logs to Log Analytics
Azure CNI → provides Azure-native networking
7. Role Assignment — AKS Pull Images From ACR
Gives AKS the ability to pull container images from ACR.
Without this role assignment, AKS cannot pull images → Pods will fail with: ImagePullBackOff
What is kubelet_identity?
This is the managed identity used by AKS nodes to authenticate to Azure.
8. Function App (Serverless Component)
8.1 App Service Plan
Creates a Consumption-based serverless hosting plan.
    Auto-scaling
    Pay-per-execution
    No VM management
8.2 Function App
Creates the actual Azure Function App.
The Function App is used for:
    async background job
    event-driven operations
    notifications
    queue listeners
9. Key Vault Access Policy — Give Function Permission to Use Secrets
Allows the function app’s identity to read secrets from Key Vault.
If your function reads secrets like:
    DB passwords
    API keys
    Storage keys
    It must have Key Vault permissions.

Configure kubectl for AKS
az aks get-credentials \
  --resource-group aimsplus \
  --name <your_aks_cluster_name>

### TEST-1: ACR Push Test (Your local machine → ACR)
az acr login --name acrtest8943

docker build -t acrtest8943.azurecr.io/test:v1 .

docker images
REPOSITORY                                         TAG            IMAGE ID       CREATED          SIZE
acrtest8943.azurecr.io/test                        v1             6af17bdcd1cf   29 seconds ago   8.32MB

docker push acrtest8943.azurecr.io/test:v1

az acr repository list --name acrtest8943 --output table

### TEST-2: AKS Pull Test (Cluster pulling image from ACR)
Create a file named test-pod.yaml:
kubectl apply -f test-pod.yaml

### Issue: Pod goes into CrashLoopBackOff.
If the container exits, Kubernetes restarts it… again… again… again →
This means: container is crashing repeatedly after starting.

Your container runs:
echo "Hello from ACR test image!"
This prints once… and then immediately exits.
Kubernetes sees an exited container → tries to restart → it exits → restart → exit → restart…
→ CrashLoopBackOff

Before
Docker File 
# Use a small base image (Alpine Linux) 
FROM alpine:latest
# Add a simple command 
CMD ["echo", "Hello from ACR test image!"]

After 
FROM alpine:latest
CMD ["sh", "-c", "echo Hello from ACR test image! && sleep infinity"]

Fix happened because:
✅ CrashLoopBackOff happens when a container exits
✅ sleep infinity keeps the container running forever
→ No exit → No crash → Pod becomes Running

## Helm
helm upgrade --install aimsplus microservice/ --namespace default

helm list -n default
NAME    	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART      	APP VERSION
aimsplus	default  	1       	2025-11-18 15:59:46.519940373 +0530 IST	deployed	myapp-0.1.0	1.0    

kubectl run testpod --image=nginx -n default
or
kubectl run mytest \
  --image=acrtest8943.azurecr.io/test:v1 \
  -n default \
  --image-pull-policy=Always

