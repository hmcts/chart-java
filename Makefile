.DEFAULT_GOAL := all
CHART := java
RELEASE := chart-${CHART}-release
NAMESPACE := chart-tests
TEST := ${RELEASE}-${CHART}-test
ACR := hmctspublic
ACR_SUBSCRIPTION := DCD-CFTAPPS-DEV
AKS_RESOURCE_GROUP := cft-preview-00-rg
AKS_CLUSTER := cft-preview-00-aks

setup:
	az account set --subscription ${ACR_SUBSCRIPTION}
	az configure --defaults acr=${ACR}
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER}

clean:
	-helm uninstall ${RELEASE} -n ${NAMESPACE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}

lint:
	helm lint ${CHART} -f ci-values.yaml 
	helm lint ${CHART} -f ci-tests-values.yaml

template:
	helm template ${CHART} -f ci-values.yaml 
	helm template ${CHART} -f ci-tests-values.yaml

deploy:
	helm install ${RELEASE} ${CHART} --namespace ${NAMESPACE} -f ci-values.yaml --wait --timeout 60s

dry-run:
	helm dependency update ${CHART} 
	helm install ${RELEASE} ${CHART} --namespace ${NAMESPACE} -f ci-values.yaml --dry-run --debug
	helm install ${RELEASE} ${CHART} --namespace ${NAMESPACE} -f ci-tests-values.yaml --dry-run --debug

test:
	helm test ${RELEASE} --namespace ${NAMESPACE}

all: setup clean lint deploy test

.PHONY: setup clean lint deploy test all
