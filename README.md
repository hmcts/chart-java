# chart-java

[![Build Status](https://dev.azure.com/hmcts/CNP/_apis/build/status/Helm%20Charts/chart-java)](https://dev.azure.com/hmcts/CNP/_build/latest?definitionId=62)

This chart is intended for simple Java microservices.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

*NOTE*: /health/readiness and /health/liveness [exposed by spring boot 2.3.0 actuator](https://docs.spring.io/spring-boot/docs/2.3.0.BUILD-SNAPSHOT/reference/html/production-ready-features.html#production-ready-kubernetes-probes) are used for readiness and liveness checks.

This chart adds below templates from [chart-library](https://github.com/hmcts/chart-library/) based on the chosen configuration:

- [Deployment](https://github.com/hmcts/chart-library/tree/master#deployment)
- [Horizontal Pod Auto Scaler](https://github.com/hmcts/chart-library/tree/master#hpa-horizontal-pod-auto-scaler)
- [Ingress](https://github.com/hmcts/chart-library/tree/master#ingress)
- [Pod Disruption Budget](https://github.com/hmcts/chart-library/tree/master#pod-disruption-budget)
- [Service](https://github.com/hmcts/chart-library/tree/master#service)
- [Deployment Tests](https://github.com/hmcts/chart-library/tree/master#smoke-and-functional-tests)

## Example configuration

```yaml
applicationPort: 8080
environment:
  REFORM_TEAM: cnp
  REFORM_SERVICE_NAME: rhubarb-backend
  REFORM_ENVIRONMENT: preview
  ROOT_APPENDER: CNP
  CONFIG_TEMPLATE: "{{ .Release.Name }}-config"
configmap:
  VAR_A: VALUE_A
  VAR_B: VALUE_B
secrets: 
  ENVIRONMENT_VAR:
      secretRef: some-secret-reference
      key: connectionString
  ENVIRONMENT_VAR_OTHER:
      secretRef: some-secret-reference-other
      key: connectionStringOther
      disabled: true #ENVIRONMENT_VAR_OTHER will not be set to environment
keyVaults:
  "cmc":
    secrets:
      - smoke-test-citizen-username
      - smoke-test-user-password
  "s2s":
    secrets:
      - microservicekey-cmcLegalFrontend
applicationInsightsInstrumentKey: "some-key"
```

If you wish to use pod identity for accessing the key vaults instead of a service principal you need to set a flag `aadIdentityName: <identity-name>`
e.g.
```yaml
aadIdentityName: cmc
keyVaults:
  "cmc":
    usePodIdentity: true
    secrets:
      - smoke-test-citizen-username
      - smoke-test-user-password
```

## Language Settings
Language has been set to none on this chart to avoid every team having to do a changeover, 
but new apps will instead use chart-base with language set to java/nodejs etc.
```yaml
language: none
```

### Secrets
To add secrets such as passwords and service keys to the Java chart you can use the the secrets section.
The secrets section maps the secret to an environment variable in the container.
e.g :
```yaml
secrets: 
  CONNECTION_STRING:
      secretRef: some-secret-reference
      key: connectionString
      disabled: false
```
**Where:**
- **CONNECTION_STRING** is the environment variable to set to the value of the secret ( this has to be capitals and can contain numbers or "_" ).
- **secretRef** is the service instance ( as in the case of PaaS wrappers ) or reference to the secret volume. It supports templating in values.yaml . Example : secretRef: some-secret-reference-{{ .Release.Name }}
- **key** is the named secret in the secret reference.
- **disabled** is optional and used to disable setting this environment value. This can be used to override the behaviour of default chart secrets. 

## Postgresql

If you need to use a Postgresql database for testing then you can enable it 
by setting the following flag in your application config with:

```yaml
java:
  environment:
    DB_HOST: "{{ .Release.Name }}-postgresql"
    DB_USER_NAME: "{{ .Values.java.postgresql.postgresqlUsername}}"
    DB_PASSWORD: "{{ .Values.java.postgresql.postgresqlPassword}}"

postgresql:
  #Whether to deploy the Postgres Chart or not
  enabled: true
```      

### HPA Horizontal Pod Autoscaler
To adjust the number of pods in a deployment depending on CPU utilization AKS supports horizontal pod autoscaling.
To enable horizontal pod autoscaling you can enable the autoscaling section. 
https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-scale#autoscale-pods

```yaml
autoscaling:        # Default is false
  enabled: true 
  maxReplicas: 5    # Required setting
  targetCPUUtilizationPercentage: 80 # Default is 80% target CPU utilization
```

See the configuration section for more options if needed
Please refer to the Configuration section below on how to enable this.

## Smoke and functional tests

From version 2.15.0 of this chart you can configure your functional and smoke tests to run just after deployment or at scheduled times 
as cron jobs.

```yaml
java:
  testsConfig:
    keyVaults:
      cmc:
        excludeEnvironmentSuffix: false
        secretRef: "kvcreds"
        secrets:
          smoke-test-citizen-username: SMOKE_TEST_CITIZEN_USER
          smoke-test-user-password: SMOKE_TEST_CITIZEN_PASS
    environment:
      TEST_URL: http://plum-recipe-backend-java
      SLACK_CHANNEL: "platops-build-notices"
      SLACK_NOTIFY_SUCCESS: "true"
      CLUSTER_NAME: "aat-01-aks"

  smoketests:
    image: hmctspublic.azurecr.io/spring-boot/template-test
    enabled: true
    environment:
      TEST_URL: http://plum-recipe-backend-java-overridden

  functionaltests:
    image: hmctspublic.azurecr.io/spring-boot/template-test
    enabled: true

  smoketestscron:
    image: hmctspublic.azurecr.io/spring-boot/template-test
    enabled: true
    environment:
      TEST_URL: http://plum-recipe-backend-java-overridden2

  functionaltestscron:
    image: hmctspublic.azurecr.io/spring-boot/template-test
    enabled: true
    environment:
      TEST_URL: http://plum-recipe-backend-java-overridden2
      SOME_ENV: some-val
```

## Adding Azure Key Vault Secrets
Key vault secrets can be mounted to the container filesystem using what's called a [keyvault-flexvolume](https://github.com/Azure/kubernetes-keyvault-flexvol). A flexvolume is just a kubernetes volume from the user point of view. This means that the keyvault secrets are accessible as files after they have been mounted.
To do this you need to add the **keyVaults** section to the configuration.
```yaml
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
    <VAULT_NAME_2>:
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
```
**Where**:
- *<VAULT_NAME>*: Name of the vault to access without the environment tag i.e. `s2s` or `bulkscan`.
- *<SECRET_NAME>* Secret name as it is in the vault. Note this is case and punctuation sensitive. i.e. in s2s there is the `microservicekey-cmcLegalFrontend` secret.
- *excludeEnvironmentSuffix*: This is used for the global key vaults where there is not environment suffix ( e.g `-aat` ) required. It defaults to false if it is not there and should only be added if you are using a global key-vault.

**Note**: To enable `keyVaults` to be mounted as flexvolumes :
- When not using Jenkins, explicitly set global.enableKeyVaults to `true` .
- When not using pod identity, your service principal credentials need to be added to your namespace as a Kubernetes secret named `kvcreds` and accessible by the KeyVault FlexVolume driver. 


## Development and Testing

Default configuration (e.g. default image and ingress host) is setup for sandbox. This is suitable for local development and testing.

- Ensure you have logged in with `az cli` and are using `sandbox` subscription (use `az account show` to display the current one).
- For local development see the `Makefile` for available targets.
- To execute an end-to-end build, deploy and test run `make`.
- to clean up deployed releases, charts, test pods and local charts, run `make clean`

`helm test` will deploy a busybox container alongside the release which performs a simple HTTP request against the service health endpoint. If it doesn't return `HTTP 200` the test will fail. **NOTE:** it does NOT run with `--cleanup` so the test pod will be available for inspection.

## Azure DevOps Builds

Builds are run against the 'nonprod' AKS cluster.

### Pull Request Validation

A build is triggered when pull requests are created. This build will run `helm lint`, deploy the chart using `ci-values.yaml` and run `helm test`.

### Release Build

Triggered when the repository is tagged (e.g. when a release is created). Also performs linting and testing, and will publish the chart to ACR on success.
