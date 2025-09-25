{{- define "base-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "base-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "base-chart.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}
