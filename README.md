# chart-java

[![Build Status](https://dev.azure.com/hmcts/CNP/_apis/build/status/Helm%20Charts/chart-java)](https://dev.azure.com/hmcts/CNP/_build/latest?definitionId=62)

This chart is intended for simple Java microservices.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

*NOTE*: The liveness heatlh checks check the enpoint /health/liveness by default. To use this you should include `compile group: 'uk.gov.hmcts.reform', name: 'health-spring-boot-starter', version: '0.0.3'` dependency into your gradle file to enable this endpoint. Otherwise change this to an endpoint that will always return `200`.

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
    resourceGroup: cmc   
    secrets:
      - smoke-test-citizen-username
      - smoke-test-user-password
  "s2s":
    resourceGroup: rpe-service-auth-provider   
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
    resourceGroup: cmc   
    secrets:
      - smoke-test-citizen-username
      - smoke-test-user-password
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
See the configuration section for more options if needed
Please refer to the Configuration section below on how to enable this.

## Configuration

The following table lists the configurable parameters of the Java chart and their default values.

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
| `releaseNameOverride`          | Will override the resource name - advised to use with pipeline variable SERVICE_NAME: `releaseNameOverride: ${SERVICE_NAME}-my-custom-name`      | `Release.Name-Chart.Name`     |
| `applicationPort`          | The port your app runs on in its container | `4550`|
| `replicas` | Number of pod replicas | `1` |
| `useInterpodAntiAffinity` | Always schedule replicas on different nodes | `false` | 
| `image`                    | Full image url | `hmctssandbox.azurecr.io/hmcts/spring-boot-template`<br>(but overridden by pipeline) |
| `environment`              |  A map containing all environment values you wish to set. <br> **Note**: environment variables (the key in KEY: value) must be uppercase and only contain letters,  "_", or numbers and value can be templated | `nil`|
| `configmap`                | A config map, can be used for environment specific config.| `nil`|
| `memoryRequests`           | Requests for memory | `512Mi`|
| `cpuRequests`              | Requests for cpu | `25m`|
| `memoryLimits`             | Memory limits| `1024Mi`|
| `cpuLimits`                | CPU limits | `2500m`|
| `ingressHost`              | Host for ingress controller to map the container to | `nil`|
| `registerAdditionalDns.enabled`            | If you want to use this chart as a secondary dependency - e.g. providing a frontend to a backend, and the backend is using primary ingressHost DNS mapping. Note: you will also need to define: `ingressIP: ${INGRESS_IP}` and `consulIP: ${CONSUL_LB_IP}` - this will be populated by pipeline                           | `false`      
| `registerAdditionalDns.primaryIngressHost`            | The hostname for primary chart                            | `nil`      
| `registerAdditionalDns.prefix`            | DNS prefix for this chart - will resolve as: `prefix-{registerAdditionalDns.primaryIngressHost}`                         | `nil`      
| `readinessPath`            | Path of HTTP readiness probe | `/health`|
| `readinessDelay`           | Readiness probe inital delay (seconds)| `30`|
| `readinessTimeout`         | Readiness probe timeout (seconds)| `3`|
| `readinessPeriod`          | Readiness probe period (seconds) | `15`|
| `livenessPath`             | Path of HTTP liveness probe | `/health/liveness`|
| `livenessDelay`            | Liveness probe inital delay (seconds)  | `30`|
| `livenessTimeout`          | Liveness probe timeout (seconds) | `3`|
| `livenessPeriod`           | Liveness probe period (seconds) | `15`|
| `livenessFailureThreshold` | Liveness failure threshold | `3` |
| `secrets`                  | Mappings of environment variables to service objects or pre-configured kubernetes secrets |  nil |
| `keyVaults`                | Mappings of keyvaults to be mounted as flexvolumes (see Example Configuration) |  nil |
| `applicationInsightsInstrumentKey` | Instrumentation Key for App Insights , It is mapped to `AZURE_APPLICATIONINSIGHTS_INSTRUMENTATIONKEY` as environment variable | `00000000-0000-0000-0000-000000000000`
| `pdb.enabled` | To enable PodDisruptionBudget on the pods for handling disruptions | `true` |
| `pdb.maxUnavailable` |  To configure the number of pods from the set that can be unavailable after the eviction. It can be either an absolute number or a percentage. pdb.minAvailable takes precedence over this if not nil | `50%` means evictions are allowed as long as no more than 50% of the desired replicas are unhealthy. It will allow disruption if you have only 1 replica.|
| `pdb.minAvailable` |  To configure the number of pods from that set that must still be available after the eviction, even in the absence of the evicted pod. minAvailable can be either an absolute number or a percentage. This takes precedence over pdb.maxUnavailable if not nil. | `nil`|
| `postgresql.enabled` | To enable installation of Postgres Chart | `false` |
| `postgresql.persistence.enabled` | To enable persistence of Postgres Data | `false` |
| `postgresql.postgresqlUsername` | Postgres Username | `javapostgres` |
| `postgresql.postgresqlPassword` | Postgres Password | `javapassword` |
| `postgresql.postgresqlDatabase` | Postgres Database | `javadatabase` |

## Adding Azure Key Vault Secrets
Key vault secrets can be mounted to the container filesystem using what's called a [keyvault-flexvolume](https://github.com/Azure/kubernetes-keyvault-flexvol). A flexvolume is just a kubernetes volume from the user point of view. This means that the keyvault secrets are accessible as files after they have been mounted.
To do this you need to add the **keyVaults** section to the configuration.
```yaml
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      resourceGroup: <VAULT_RESOURCE_GROUP>
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
    <VAULT_NAME_2>:
      resourceGroup: <VAULT_RESOURCE_GROUP_2>
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
```
**Where**:
- *<VAULT_NAME>*: Name of the vault to access without the environment tag i.e. `s2s` or `bulkscan`.
- *<VAULT_RESOURCE_GROUP>*: Resource group for the vault. This also does not need the environment tag (i.e. for s2s vault it is `rpe-service-auth-provider`).
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
