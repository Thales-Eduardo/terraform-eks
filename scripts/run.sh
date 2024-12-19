docker build -t thaleseduardo/hello-go .
docker push thaleseduardo/hello-go

# para testar
docker run --rm -p 3000:3333 thaleseduardo/hello-go
#localhost:3000

#colar no terminal
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

terraform init && terraform fmt && terraform validate && \
 terraform plan -out plan.out && terraform apply plan.out

# conectar ao cluster eks
# cli aws instalado e configurado
# aws eks --region <região> update-kubeconfig --name <nome_do_cluster> 
aws eks --region us-east-1 update-kubeconfig --name cluster-ks8-terraform 

# ao se conectar com o cluster
kubectl config get-contexts
kubectl config use-context <nome-do-contexto>
kubectl get nodes


kubectl apply -f deployments.yaml && \
 kubectl apply -f service.yaml && \
 kubectl apply -f hpa.yaml

# verificar
kubectl get pods
kubectl get services

# acesse o valor de EXTERNAL-IP