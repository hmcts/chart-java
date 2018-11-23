# For local development only

.DEFAULT=build

clean:
	helm delete --purge chart-java-release
	az acr helm delete java -y
	rm java-0.0.1.tgz

build:
	helm package java
	helm lint java

publish:
	az acr helm push java-0.0.1.tgz

deploy:
	az acr helm repo add
	helm install hmctssandbox/java --name chart-java-release --namespace helm-tests --wait