{{/*
Expand the name of the chart.
*/}}
{{- define "mqtt-cilium.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mqtt-cilium.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mqtt-cilium.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mqtt-cilium.labels" -}}
helm.sh/chart: {{ include "mqtt-cilium.chart" . }}
{{ include "mqtt-cilium.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mqtt-cilium.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mqtt-cilium.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Cilium IPAM Helpers
These handle the hyphenated keys in values.yaml safely.
*/}}
{{- define "cilium.assignInternalIp" -}}
{{- index .Values.cilium "assign-internal-ip" | default "true" -}}
{{- end }}

{{- define "cilium.poolName" -}}
{{- index .Values.cilium "pool-name" | default "default-pool" -}}
{{- end }}

{{- define "cilium.ips" -}}
{{- .Values.cilium.ips | default "" -}}
{{- end }}

{{- define "cilium.sharingKey" -}}
{{- index .Values.cilium "sharing-key" | default "mqtt" -}}
{{- end }}
