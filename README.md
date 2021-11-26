# chart-java

[![Build Status](https://dev.azure.com/hmcts/CNP/_apis/build/status/Helm%20Charts/chart-java)](https://dev.azure.com/hmcts/CNP/_build/latest?definitionId=62)

This chart is intended for simple Java microservices.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

*NOTE*: /health/readiness and /health/liveness [exposed by spring boot 2.3.0 actuator](https://docs.spring.io/spring-boot/docs/2.3.0.BUILD-SNAPSHOT/reference/html/production-ready-features.html#production-ready-kubernetes-probes) are used for readiness and liveness checks.

This chart adds below templates from [chart-library](https://github.com/hmcts/chart-library/) based on the chosen configuration:

- [Deployment](https://github.com/hmcts/chart-library/tree/master#deployment)
- [Keyvault Secrets](https://github.com/hmcts/chart-library#keyvault-secret-csi-volumes)
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

## Startup probes
Startup probes are defined in the [library template](https://github.com/hmcts/chart-library/tree/dtspo-2201-startup-probes#startup-probes) and should be configured for slow starting applications. 
The default values below (defined in the chart) should be sufficient for most applications but can be overriden as required.
```yaml
startupPath: '/health/liveness'
startupDelay: 5
startupTimeout: 3
startupPeriod: 10
startupFailureThreshold: 3
```

To use startup probes for a slow starting application, configure the value of `(startupFailureThreshold x startupPeriodSeconds)` to cover the longest startup time required by the application.  

### Example configuration
The below example will allow the application 360 seconds to complete startup
```yaml
java:
  startupPeriod: 120
  startupFailureThreshold: 3
```
Also see example [pull request](https://github.com/hmcts/cnp-flux-config/pull/12891/files).  

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
