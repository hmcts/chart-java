# chart-java
This chart is intended for simple Java microservices.

We will take small PRs and small features to this chart but more complicated needs should be handled in your own chart.

## Example configuration
```
applicationPort: 8080
environment:
  REFORM_TEAM: cnp
  REFORM_SERVICE_NAME: rhubarb-backend
  REFORM_ENVIRONMENT: preview
  ROOT_APPENDER: CNP
```

## Configuration

The following table lists the configurable parameters of the Java chart and their default values.

| Parameter          | Description                                               | Default                     |
|--------------------|-----------------------------------------------------------|-----------------------------|
| `applicationPort`  | The port your app runs on in its container                | `4550`                      |
| `image`            | Full image url                                            | `hmctssandbox.azurecr.io/hmcts/spring-boot-template` (but overridden by pipeline) |
| `environment`      | A map containing all environment values you wish to set   | `nil`                       |
| `configmap`        | A config map, can be used for environment specific config | `nil`                       |
| `memoryRequests`   | Requests for memory                                       | `512Mi`                     |
| `cpuRequests`      | Requests for cpu                                          | `100m`                      |
| `memoryLimits`     | Memory limits                                             | `1024Mi`                    |
| `cpuLimits`        | CPU limits                                                | `2500m`                     |
| `ingressHost`      | Host for ingress controller to map the container to       | `chart-java.service.core-compute-saat.internal` (but overridden by pipeline) |
| `readinessPath`    | Path of HTTP readiness probe                              | `/health`                   |
| `readinessDelay`   | Readiness probe inital delay (seconds)                    | `30`                        |
| `readinessTimeout` | Readiness probe timeout (seconds)                         | `3`                         |
| `readinessPeriod`  | Readiness probe period (seconds)                          | `15`                        |
| `livenessPath`     | Path of HTTP liveness probe                               | `/health`                   |
| `livenessDelay`    | Liveness probe inital delay (seconds)                     | `30`                        |
| `livenessTimeout`  | Liveness probe timeout (seconds)                          | `3`                         |
| `livenessPeriod`   | Liveness probe period (seconds)                           | `15`                        |
| `livenessFailureThreshold`| Liveness failure threshold                         | `3`                         |

## Development and Testing
Default configuration (e.g. default image and ingress host) is setup for sandbox.  This is suitable for local development and testing.
* For local development see the `Makefile` for available targets.
* To execute an end-to-end build, deploy and test in __sandbox__, run `make all`.
* to clean up deployed releases, charts, test pods and local charts, run `make clean`

`helm test` will deploy a busybox container alongside the release which performs a simple HTTP request against the service health endpoint.  If it doesn't return `HTTP 200` the test will fail.

## Azure DevOps Builds
### Pull Request Validation
A build is triggered when pull requests are created.  This build will run `helm lint`, deploy the chart using `ci-values.yaml` and run `helm test` on the __nonprod__ AKS cluster.

