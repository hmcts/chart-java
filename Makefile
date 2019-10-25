.DEFAULT_GOAL := all
CHART := java
RELEASE := chart-${CHART}-release
NAMESPACE := chart-tests
TEST := ${RELEASE}-test-service
ACR := hmctspublic
ACR_SUBSCRIPTION := DCD-CFT-Sandbox
AKS_RESOURCE_GROUP := cnp-aks-sandbox-rg
AKS_CLUSTER := cnp-aks-sandbox-cluster

setup:
	az account set --subscription ${ACR_SUBSCRIPTION}
	az configure --defaults acr=${ACR}
	az acr helm repo add
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER}

clean:
	-helm delete --purge ${RELEASE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}

lint:
	helm lint ${CHART} -f ci-values.yaml -f ci-tests-values.yaml

template:
	helm template ${CHART} -f ci-values.yaml -f ci-tests-values.yaml

deploy:
	helm install ${CHART} --name ${RELEASE} --namespace ${NAMESPACE} -f ci-values.yaml --wait --timeout 60

dry-run:
	helm dependency update ${CHART} 
	helm install ${CHART} --name ${RELEASE} --namespace ${NAMESPACE} -f ci-values.yaml -f ci-tests-values.yaml --dry-run --debug

test:
	helm test ${RELEASE}

all: setup clean lint deploy test

.PHONY: setup clean lint deploy test all
