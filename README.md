# kube-prometheus

## Overview

This repository contains my kube-prometheus manifests files for my [home cluster](https://github.com/budimanjojo/home-cluster). Manifests are generated from [kube-prometheus repository](https://github.com/prometheus-operator/kube-prometheus). Github Action is used to update the manifest files everyday.

---

## What is changed

These are the changes in [example.jsonnet](./example.jsonnet) file from the upstream:
- Grafana manifests are not here because I have my own grafana deployment manifests
- The namespace is changed from `monitoring` to `monitoring-system`
- CRDS and namespace manifests are in [manifests/setup](./manifests/setup) folder and the rest are in [manifests/deploy](./manifests/deploy) folder
- Added my own alertmanager config file to be able to send notification to Telegram using [alertmanager-notifier](https://github.com/ix-ai/alertmanager-notifier)
- Added `kustomization.yaml` file so I can source it to my flux managed [home cluster](https://github.com/budimanjojo/home-cluster)
- Alertmanager and prometheus deployment replicas set to 1
- Disabled `CPUThrottlingHigh` alert
- Disabled `KubeProxyDown` alert
- Allow ingress from `traefik` which is blocked by default with the latest `NetworkPolicy`

---

## Thanks

The [kube-prometheus project](https://github.com/prometheus-operator/kube-prometheus) for providing everything.
