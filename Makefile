EMAIL:=philip.bui.developer@gmail.com
F_NAME:=istio.yaml
NAME:=wilde
IP_NAME:=${NAME}-ip
STATIC_IP:=35.201.16.87
GRPC_PORT:=443
COMPUTE_ZONE:=australia-southeast1
DOMAIN:=${STATIC_IP}
PROJECT_ID:=wilde-219609
COMPUTE_ZONE:=australia-southeast1-a
CLUSTER_NAME:=staging
SIZE?=2

help: ## Display this help screen
	grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

debug: ## Debug a gRPC Service.
	export GRPC_VERBOSITY=DEBUG
	grpc_cli ls ${DOMAIN}:${GRPC_PORT}

ip: ## Create IP Address 
	gcloud compute addresses create ${IP_NAME} --region ${REGION}
	gcloud compute addresses describe ${IP_NAME} --region ${REGION}

istio: ## Run Helm command to output 
	helm template install/kubernetes/helm/istio --name istio --namespace istio-system --set telemetry-gateway.grafanaEnabled=true --set telemetry-gateway.prometheusEnabled=true --set grafana.enabled=true --set grafana.security.enabled=true --set servicegraph.enabled=true --set tracing.enabled=true --set kiali.enabled=true --set global.mlts.enabled=true --set gateways.istio-ingressgateway.loadBalancerIP=${STATIC_IP} > ${F_NAME}
	kubectl label namespace default istio-injection=enabled --overwrite=true
	kubectl apply -f ${F_NAME}

cert: ## Create Certs TODO
	# kubectl create -n istio-system secret tls istio-ingressgateway-certs --key certs/3_application/private/${DOMAIN}.key.pem --cert certs/3_application/certs/${DOMAIN}.cert.pem
	kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=certs/2_intermediate/certs/ca-chain.cert.pem

kiali: ## Visit Kiali - Realtime Traffic
	open "http://localhost:20001/console/service-graph/istio-apps?layout=cose-bilkent&duration=10800&edges=responseTime95thPercentile&graphType=versionedApp"
	kubectl -n istio-system port-forward $(shell kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001

jaeger: ## Visit Jaeger - Monitoring
	open "http://localhost:16686"
	kubectl port-forward -n istio-system $(shell kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686

grafana: ## Visit Grafana
	open "http://localhost:3000"
	kubectl -n istio-system port-forward $(shell kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000

prometheus: ## Visit Prometheus
	open "http://localhost:9090"
	kubectl -n istio-system port-forward $(shell kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090

service-graph: ## Visit Service Graph
	open "http://localhost:8088/force/forcegraph.html?time_horizon=3000s&filter_empty=true"
	kubectl -n istio-system port-forward $(shell kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088

delete: ## Delete Helm
	kubectl delete -f ${F_NAME}

gke: ## Setup GKE
	gcloud config set project ${PROJECT_ID}
	gcloud config set compute/zone ${COMPUTE_ZONE}
	gcloud container clusters get-credentials ${CLUSTER_NAME}

scale: ## Scale GKE
	echo Y|gcloud container clusters resize ${CLUSTER_NAME} --node-pool cpu --size=${SIZE}
	echo Y|gcloud container clusters resize ${CLUSTER_NAME} --node-pool memory --size=${SIZE}
	
teardown: ## Scale down GKE to 0
	make scale SIZE=0

ingress-gateway-logs: ## Logs Ingress Gateway
	kubectl logs -l app=istio-ingressgateway -n istio-system
