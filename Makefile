PWD      					= $(shell pwd)
KUBE_PROMETHEUS_BASE_DIR	= $(shell pwd)/kube-prometheus
K3D_CLUSTER_NAME 			= $(or $(shell printenv K3D_CLUSTER_NAME), nginx-ingres-metrics)


.PHONY: kubectl-set-context
kubectl-set-context:
	kubectl config set-context k3d-nginx-ingres-metrics

.PHONY: k3d-cluster-create
k3d-cluster-create: start-k3d-local-registry
	k3d cluster create $(K3D_CLUSTER_NAME) --config $(PWD)/.k3d/local-cluster-configuration.yaml &&\
	kubectl config set-context k3d-nginx-ingres-metrics


.PHONY: start-k3d-local-registry
start-k3d-local-registry:
	k3d registry create registry-dev.localhost --port 5555

.PHONY: stop-k3d-local-registry
stop-k3d-local-registry:
	k3d registry delete k3d-registry-dev.localhost

.PHONY: k3d-cluster-delete
k3d-cluster-delete: stop-k3d-local-registry
	k3d cluster delete $(K3D_CLUSTER_NAME)


.PHONY: .deploy-nginx-ingress
.deploy-nginx-ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

.PHONY: .deploy-nginx-config
.deploy-nginx-config:
	kubectl apply -f manifests/ingress-nginx

.PHONY: .deploy-sample-app
.deploy-sample-app:
	kubectl apply -f manifests/sample-app/sample-app.namespace.yaml
	kubectl apply -f manifests/sample-app/sample-app.service.yaml
	kubectl apply -f manifests/sample-app/sample-app.deployment.yaml
	kubectl apply -f manifests/sample-app/sample-app.ingress.yaml

.PHONY: .deploy-fluentbit
.deploy-fluentbit:
	kubectl apply -f manifests/fluent-bit/fluent-bit.namespace.yaml
	kubectl apply -f manifests/fluent-bit/fluent-bit.cluster-role.yaml
	kubectl apply -f manifests/fluent-bit/fluent-bit.service-account.yaml
	kubectl apply -f manifests/fluent-bit/fluent-bit.cluster-role-binding.yaml
	kubectl apply -f manifests/fluent-bit/fluent-bit-config.configmap.yaml
	kubectl apply -f manifests/fluent-bit/fluent-bit.daemonset.yaml


.PHONY: .deploy-golang-log-parser
.deploy-golang-log-parser:	
	kubectl apply -f manifests/golang-log-parser/golang-log-parser.namespace.yaml
	kubectl apply -f manifests/golang-log-parser/golang-log-parser.service.yaml
	kubectl apply -f manifests/golang-log-parser/golang-log-parser.deployment.yaml


.PHONY: deploy-manifests
deploy-manifests: .deploy-nginx-ingress .deploy-fluentbit
	kubectl wait --for=condition=ready --timeout=600s pod -n ingress-nginx -l app.kubernetes.io/component=controller
	$(MAKE) .deploy-nginx-config 
	$(MAKE) .deploy-sample-app
	$(MAKE) .deploy-golang-log-parser


.PHONY: golang-env
golang-env:
	docker run --rm -ti -v $(PWD)/golang-log-parser:/go/src/giannoul/golang-log-parser --workdir /go/src/giannoul/golang-log-parser golang:1.16-alpine3.14 /bin/sh


# image operations
.PHONY: .build-and-tag-images
.build-and-tag-images: 
	docker build --no-cache -f ./golang-log-parser/Dockerfile -t k3d-registry-dev.localhost:5555/golang-log-parser ./golang-log-parser

.PHONY: .push-images-to-local-registry
.push-images-to-local-registry:
	docker push k3d-registry-dev.localhost:5555/golang-log-parser

.PHONY: images-create
images-create: .build-and-tag-images .push-images-to-local-registry


.PHONY: temp-fluentbit
temp-fluentbit:
	kubectl apply -f manifests/fluent-bit/fluent-bit-config.configmap.yaml
	kubectl delete pod -n logging -l k8s-app=fluent-bit-logging

