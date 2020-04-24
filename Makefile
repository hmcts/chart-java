.DEFAULT_GOAL := all
CHART := dynatrace-automation
RELEASE := chart-${CHART}-release
NAMESPACE := rpe
TEST := ${RELEASE}-test-service
ACR := hmctspublic
ACR_SUBSCRIPTION := DCD-CFTAPPS-STG
AKS_RESOURCE_GROUP := aat-00-rg
AKS_CLUSTER := aat-00-aks

setup:
	az account set --subscription ${ACR_SUBSCRIPTION}
	az configure --defaults acr=${ACR}
	az acr helm repo add
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER}

clean:
	-helm uninstall ${RELEASE} -n ${NAMESPACE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}

lint:
	helm lint ${CHART} -f ci-values.yaml

template:
	helm template ${CHART} -f ci-values.yaml

deploy:
	helm install ${RELEASE} ${CHART} --namespace ${NAMESPACE} -f ci-values.yaml --wait --timeout 60s

dry-run:
	helm dependency update ${CHART} 
	helm install ${CHART} --name ${RELEASE} --namespace ${NAMESPACE} -f ci-values.yaml -f ci-tests-values.yaml --dry-run --debug

test:
	helm test ${RELEASE}

all: setup clean lint deploy test

.PHONY: setup clean lint deploy test all
