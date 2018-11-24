# For local development only
.DEFAULT: all

CHART=java
RELEASE=chart-${CHART}-release
NAMESPACE=chart-tests
TEST=${RELEASE}-test-service
ACR=hmctssandbox

setup:
	az configure --defaults acr=${ACR}
	az acr helm repo add

clean:
	-helm delete --purge ${RELEASE}
	-kubectl delete pod ${TEST} -n ${NAMESPACE}
	-az acr helm delete ${CHART} -y # WARNING: Deletes the published chart from ACR!!!
	-rm ${CHART}-0.0.1.tgz

build:
	helm package ${CHART}
	helm lint ${CHART}

publish:
	az acr helm push ${CHART}-0.0.1.tgz

deploy:
	helm repo update
	helm install ${ACR}/${CHART} --name ${RELEASE} --namespace ${NAMESPACE} --wait

test:
	helm test ${RELEASE}

all: setup clean build publish deploy test
