# Terraform-Elasticsearch-Apache_Server-LB
___
# 1. Set up your own cluster (I used kops for AWS)
___
___
# 2. Apply terraform file for deployment of all infrastructure
___
* ``` terraform init && terraform apply -auto-approve ```
___
# 3. Check that all infrastucture is up and running in "default" and "kube-logging" namespaces
___
``` kubectl get all -n={namespace} ```
___
# 4. Review that set of StatefulSet is rollouted 
___
* ``` kubectl rollout status sts/es-cluster --namespace=kube-logging ```
___
# 5. Check that Elasticsearch is working properly
___
* ``` kubectl port-forward es-cluster-0 9200:9200 --namespace=kube-logging ``` and goes to new window ``` curl http://localhost:9200/_cluster/state?pretty ```
___
# 6. Upgrades. 
___
* In the same way I can configure Kibana with Fluentd for getting up full EFK stack.