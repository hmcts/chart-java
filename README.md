# chart-java

This chart is intended for simple Java microservices.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

## Example configuration

```yaml
applicationPort: 8080
environment:
  REFORM_TEAM: cnp
  REFORM_SERVICE_NAME: rhubarb-backend
  REFORM_ENVIRONMENT: preview
  ROOT_APPENDER: CNP
configmap:
  VAR_A: VALUE_A
  VAR_B: VALUE_B
secrets: 
  ENVIRONMENT_VAR:
      secretRef: some-secret-reference
      key: connectionString
```

### secrets
Secret objects in this configuration consist of name secretRef and key. These need to be put into the secrets array in the following manner:
```yaml
secrets: 
  ENVIRONMENT_VAR:
      secretRef: some-secret-reference
      key: connectionString
```
*Where:*
- **ENVIRONMENT_VAR** is the environment variable name to reference ( this has to be capitals and can contain numbers or "_" ).
- **secretRef** is the service instance ( as in the case of PaaS wrappers ) or reference to the secret volume
- **key** is the named secret in the secret reference.


## Configuration

The following table lists the configurable parameters of the Java chart and their default values.

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
| `applicationPort`          | The port your app runs on in its container | `4550`|
| `image`                    | Full image url | `hmctssandbox.azurecr.io/hmcts/spring-boot-template`<br>(but overridden by pipeline) |
| `environment`              |  A map containing all environment values you wish to set. <br> **Note**: environment variables (the key in KEY: value) must be uppercase and only contain letters,  "_", or numbers | `nil`|
| `configmap`                | A config map, can be used for environment specific config.| `nil`|
| `memoryRequests`           | Requests for memory | `512Mi`|
| `cpuRequests`              | Requests for cpu | `100m`|
| `memoryLimits`             | Memory limits| `1024Mi`|
| `cpuLimits`                | CPU limits | `2500m`|
| `ingressHost`              | Host for ingress controller to map the container to | `chart-java.service.core-compute-saat.internal`<br>(but overridden by pipeline)|
| `readinessPath`            | Path of HTTP readiness probe | `/health`|
| `readinessDelay`           | Readiness probe inital delay (seconds)| `30`|
| `readinessTimeout`         | Readiness probe timeout (seconds)| `3`|
| `readinessPeriod`          | Readiness probe period (seconds) | `15`|
| `livenessPath`             | Path of HTTP liveness probe | `/health`|
| `livenessDelay`            | Liveness probe inital delay (seconds)  | `30`|
| `livenessTimeout`          | Liveness probe timeout (seconds) | `3`|
| `livenessPeriod`           | Liveness probe period (seconds) | `15`|
| `livenessFailureThreshold` | Liveness failure threshold | `3` |
| `secrets`                  | Mappings of environment variables to service objects or pre-configured kubernetes secrets |  nil |

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
