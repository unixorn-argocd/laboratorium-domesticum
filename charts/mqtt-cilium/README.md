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
  ips: "10.0.1.46"
mosquittoSecrets:
  passwordData: "admin:$6$..."
```

### 3. Install the chart

#### ArgoCD

Here's an ArgoCD Application you can customize and use to install this chart.

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
    repoURL: 'https://github.com/your-username/your-repo.git'
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
          ips: "10.0.1.50"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Directly with `helm`

```bash
helm upgrade --install my-mqtt ./mqtt-cilium
```

## Configuration Reference

### Cilium Settings

| Parameter           | Description                                         | Default Value  |
| ------------------- | --------------------------------------------------- | -------------- |
| `cilium.poolName`   | The Cilium IPAM pool to draw from                   | `default-pool` |
| `cilium.ips`        | Static internal IP to request                       | `10.0.1.46`    |
| `cilium.sharingKey` | Key to allow multiple services to share the same IP | `mqtt`         |

### Mosquitto Settings

| Parameter                       | Description                   | Default Value     |
| ------------------------------- | ----------------------------- | ----------------- |
| `mosquittoDeployment.replicas`  | Number of broker instances	  | 1                 |
| `mosquittoConfig.mosquittoConf` | The raw `mosquitto.conf` text | (See values.yaml) |
| `pvc.storageRequest`            | Size of the data volume       | 1Gi               |

## Troubleshooting

* Check Logs: `kubectl logs -f deployment/my-mqtt-mqtt-cilium`
* Verify IP: `kubectl get svc my-mqtt-mqtt-cilium-lb`
* Permission Issues: If the pod fails to write to `/mosquitto/data`, ensure the `initPermissions` container successfully ran `chown`
