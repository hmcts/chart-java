.DEFAULT: all

CHART=java
RELEASE=chart-${CHART}-release
NAMESPACE=chart-tests
TEST=${RELEASE}-test-service
ACR=hmctssandbox
AKS_RESOURCE_GROUP=cnp-aks-sandbox-rg
AKS_CLUSTER= cnp-aks-sandbox-cluster

setup:
	az configure --defaults acr=${ACR}
	az acr helm repo add

setup-ci: setup
	az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER}

clean:
	-helm delete --purge ${RELEASE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}
	-rm ${CHART}-0.0.1.tgz

lint:
	helm lint ${CHART}

package:
	helm package ${CHART}

publish:
	chartFile=$(ls java-*)
	az acr helm push $chartFile

deploy:
	helm install ${CHART} --name ${RELEASE} --namespace ${NAMESPACE} --wait

test:
	helm test ${RELEASE}

all: setup clean lint deploy test

ci-validate: setup-ci clean lint deploy test

ci-release: setup-ci package lint publish