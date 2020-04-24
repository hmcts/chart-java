# chart-dynatrace-automation

[![Build Status](https://dev.azure.com/hmcts/CNP/_apis/build/status/Helm%20Charts/chart-dynatrace-automation)](https://dev.azure.com/hmcts/CNP/_build/latest?definitionId=62)

This chart is intended for automating dynatrace setup

## Features

- create cluster connection in dynatrace

## Azure DevOps Builds

Builds are run against the 'nonprod' AKS cluster.

### Pull Request Validation

A build is triggered when pull requests are created. This build will run `helm lint`, deploy the chart using `ci-values.yaml` and run `helm test`.

### Release Build

Triggered when the repository is tagged (e.g. when a release is created). Also performs linting and testing, and will publish the chart to ACR on success.
