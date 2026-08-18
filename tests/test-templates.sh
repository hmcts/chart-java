#!/usr/bin/env bash

set -e

# Vendor the chart-library (and other) dependencies (required for the hmcts.* templates
# used by java/templates/*.yaml to resolve during rendering/tests).
helm dependency build java/

helm lint java/ --values ci-values.yaml
helm lint java/ --values ci-tests-values.yaml

# Unit tests: verify conditional rendering paths (autoscaling vs static replicas, PDB,
# Ingress, ConfigMap, SecretProviderClass keyvault wiring, smoke/functional test jobs).
# ci-values-minimal.yaml supplies only the required `image` field so each test's own
# `set:` values are the sole driver — preventing chart defaults from silently satisfying
# a condition under test.
helm unittest --values "$(pwd)/ci-values-minimal.yaml" java -q -f 'tests/unit-tests/*.yaml'

