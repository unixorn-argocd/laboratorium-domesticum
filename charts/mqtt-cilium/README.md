<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Mosquitto MQTT Chart (Cilium Optimized)](#mosquitto-mqtt-chart-cilium-optimized)
  - [🚀 Features](#-features)
  - [🛠 Quick Start](#%F0%9F%9B%A0-quick-start)
    - [1. Generate a Password Hash](#1-generate-a-password-hash)
    - [2. Configuration](#2-configuration)
    - [3. Install the chart](#3-install-the-chart)
      - [ArgoCD](#argocd)
        - [Inline configuration](#inline-configuration)
        - [Argo CD Multi-Source Application](#argo-cd-multi-source-application)
      - [Install directly with `helm`](#install-directly-with-helm)
  - [Configuration Reference](#configuration-reference)
    - [Cilium Settings](#cilium-settings)
    - [Mosquitto Settings](#mosquitto-settings)
    - [`livenessProbe` settings](#livenessprobe-settings)
    - [`readinessProbe` settings](#readinessprobe-settings)
  - [Troubleshooting](#troubleshooting)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Mosquitto MQTT Chart (Cilium Optimized)

This Helm chart deploys an **Eclipse Mosquitto** MQTT broker on Kubernetes, specifically configured for homelabs using **Cilium LoadBalancer IPAM**.

## 🚀 Features

* **Cilium Integration**: Automated IP assignment and sharing keys for the LoadBalancer.
* **Security**: Runs as non-root (UID 1883) with restricted filesystem permissions.
* **Authentication**: Supports password file authentication via Kubernetes Secrets.
* **Persistence**: Retains MQTT messages and topics across restarts via PVC.
* **Lifecycle**: Automated pod restarts on configuration changes using SHA256 checksums.

---

## 🛠 Quick Start

### 1. Generate a Password Hash
Mosquitto requires hashed passwords. Generate one using the `mosquitto_passwd` utility:

```bash
mosquitto_passwd -b /dev/stdout <username> <password>
```

### 2. Configuration

Update your `values.yaml` with the generated hash and your desired Cilium IP:

```yaml
cilium:
  ips: "10.9.8.7"
mosquittoSecrets:
  passwordData: "admin:$6$..."
```

### 3. Install the chart

#### ArgoCD

##### Inline configuration

Here's an ArgoCD Application you can customize with inline settings and use to install this chart.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mosquitto-mqtt
  namespace: argocd
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: iot
  source:
    repoURL: 'https://github.com/unixorn-argocd/laboratorium-domesticum.git'
    targetRevision: HEAD
    path: charts/mqtt-cilium
    helm:
      values: |
        # 1. Customize the ConfigMap content
        mosquittoConfig:
          mosquittoConf: |-
            persistence true
            persistence_location /mosquitto/data
            log_dest stdout
            listener 1883 0.0.0.0
            allow_anonymous false
            password_file /mosquitto/config/password.txt
            # Custom addition via ArgoCD
            max_connections 100
            connection_messages true

        # 2. Tell the chart NOT to make a secret, use an existing one
        mosquittoSecrets:
          create: false
          existingSecret: "my-manually-created-mqtt-secret"

        # 3. Networking Overrides
        cilium:
          ips: "10.9.8.7"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

##### Argo CD Multi-Source Application

This manifest lets you keep the `values.yaml` in one repository, and use the chart from another.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mosquitto-mqtt-multisource
  namespace: argocd
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: iot
  sources:
    # Source 1: The Helm Chart
    - repoURL: 'https://github.com/unixorn-argocd/laboratorium-domesticum.git'
      targetRevision: main
      path: charts/mqtt-cilium

    # Source 2: The Configuration (Values)
    - repoURL: 'https://github.com/your-org/cluster-config.git'
      targetRevision: HEAD
      # We give this source an alias 'config' so we can reference it
      ref: config

  sourceHydrator: # This section links them
    helm:
      valueFiles:
        # '$config' refers to the 'ref: config' source above
        - $config/mosquitto/values.yaml

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### Install directly with `helm`

If you prefer to install via `helm` directly

```bash
helm upgrade --install my-mqtt ./mqtt-cilium
```

## Configuration Reference

### Cilium Settings

| Parameter                            | Description                                         | Default Value     |
| ------------------------------------ | --------------------------------------------------- | ----------------- |
| `cilium.poolName`                    | The Cilium IPAM pool to draw from                   | `default-pool`    |
| `cilium.ips`                         | Static internal IP to request                       | `10.0.1.46`       |
| `cilium.sharingKey`                  | Key to allow multiple services to share the same IP | `mqtt`            |

### Mosquitto Settings

| Parameter                            | Description                                         | Default Value     |
| ------------------------------------ | --------------------------------------------------- | ----------------- |
| `mosquittoDeployment.replicas`       | Number of broker instances                          | 1                 |
| `mosquittoConfig.mosquittoConf`      | The raw `mosquitto.conf` text                       | See `values.yaml` |
| `pvc.storageRequest`                 | Size of the data volume                             | 1Gi               |

### `livenessProbe` settings

| Parameter                            | Description                                         | Default Value     |
| ------------------------------------ | --------------------------------------------------- | ----------------- |
| `livenessProbe.initialDelaySeconds`  | Liveness probe initial delay in seconds             | 30                |
| `livenessProbe.periodSeconds`        | Time between probes                                 | 10                |
| `livenessProbe.timeoutSeconds`       | How many seconds before timing out                  | 5                 |

### `readinessProbe` settings

| Parameter                            | Description                                         | Default Value     |
| --------------------------------=--- | --------------------------------------------------- | ----------------- |
| `readinessProbe.initialDelaySeconds` | Liveness probe initial delay in seconds             | 30                |
| `readinessProbe.periodSeconds`       | Time between probes                                 | 10                |
| `readinessProbe.timeoutSeconds`      | How many seconds before timing out                  | 5                 |

## Troubleshooting

* Check Logs: `kubectl logs -f deployment/my-mqtt-mqtt-cilium`
* Verify IP: `kubectl get svc my-mqtt-mqtt-cilium-lb`
* Permission Issues: If the pod fails to write to `/mosquitto/data`, ensure the `initPermissions` container successfully ran `chown`
