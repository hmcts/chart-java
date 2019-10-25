{{/*
This template is for adding the environment variable list and checking the format of the keys
The key or "environment variable" must be uppercase and contain only numbers or "_".
*/}}
{{- define "java.environment" -}}
  {{- if .Values.environment -}}
    {{- range $key, $val := .Values.environment }}
- name: {{ if $key | regexMatch "^[^.-]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
        {{- end }}
  value: {{ tpl ($val | quote) $ }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
All the common labels needed for the labels sections of the definitions.
*/}}
{{- define "java.labels" }}
app.kubernetes.io/name: {{ template "hmcts.java.releaseName" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ template "hmcts.java.releaseName" . }}
{{- if .Values.aadIdentityName }}
aadpodidbinding: {{ .Values.aadIdentityName }}
{{- end }}
{{- if .Values.draft }}
draft: {{ .Values.draft }}
{{- end }}
{{- end -}}

{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "java.annotations" }}
{{- if .Values.prometheus.enabled }}
prometheus.io/scrape: "true"
prometheus.io/path: {{ .Values.prometheus.path | quote }}
prometheus.io/port: {{ .Values.applicationPort | quote }}
{{- end }}
{{- if .Values.buildID }}
buildID: {{ .Values.buildID }}
{{- end }}
{{- end -}}

{{/*
Adding in the helper here where we can use a secret object to include secrets to for the deployed service.
The key or "environment variable" must be uppercase and contain only numbers or "_".
Example format:
"
 ENVIRONMENT_VAR:
    secretRef: secret-vault 
    key: connectionString
    disabled: false
"
*/}}
{{- define "java.secrets" -}}

  {{- if .Values.secrets -}}
    {{- range $key, $val := .Values.secrets }}
      {{- if and $val (not $val.disabled) }}
- name: {{ if $key | regexMatch "^[^.-]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
        {{- end }}
  valueFrom:
    secretKeyRef:
      name: {{  tpl (required "Each item in \"secrets:\" needs a secretRef member" $val.secretRef) $ }}
      key: {{ required "Each item in \"secrets:\" needs a key member" $val.key }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end }}

{{/*
ref: https://github.com/helm/charts/blob/master/stable/postgresql/templates/_helpers.tpl
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "hmcts.java.releaseName" -}}
{{- if .Values.releaseNameOverride -}}
{{- tpl .Values.releaseNameOverride $ | trunc 53 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 53 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "java.tests.spec" -}}
{{- if and .Values.tests.keyVaults .Values.global.enableKeyVaults }}
volumes:
  {{- $globals := .Values.global }}
  {{- $aadIdentityName := .Values.aadIdentityName }}
  {{- range $key, $value := .Values.tests.keyVaults }}
  - name: vault-{{ $key }}
    flexVolume:
      driver: "azure/kv"
      {{- if not $aadIdentityName }}
      secretRef:
        name: {{ default "kvcreds" $value.secretRef }}
      {{- end }}
      options:
        usepodidentity: "{{ if $aadIdentityName }}true{{ else }}false{{ end}}"
        tenantid: {{ $globals.tenantId }}
        keyvaultname: {{if $value.excludeEnvironmentSuffix }}{{ $key | quote }}{{else}}{{ printf "%s-%s" $key $globals.environment }}{{ end }}
        keyvaultobjectnames: {{ $value.secrets | join ";" | quote }}  #"some-username;some-password"
        keyvaultobjecttypes: {{ trimSuffix ";" (repeat (len $value.secrets) "secret;") | quote }} # OPTIONS: secret, key, cert
  {{- end }}
{{- end }}
securityContext:
  runAsUser: 1000
  fsGroup: 1000
restartPolicy: Never
containers:
  - name: tests
    image: {{ .Values.tests.image }}
    securityContext:
      allowPrivilegeEscalation: false
    {{- if .Values.tests.environment }}
    env:
    {{- range $key, $val := .Values.tests.environment }}
      - name: {{ $key }}
        value: {{ $val }}
    {{- end }}
    {{- end }}
    {{- if and .Values.tests.keyVaults .Values.global.enableKeyVaults }}
    volumeMounts:
      {{- range $key, $value := .Values.keyVaults }}
      - name: vault-{{ $key }}
        mountPath: /mnt/secrets/{{ $key }}
        readOnly: true
      {{- end }}
    {{- end }}
    resources:
      requests:
        memory: {{ .Values.tests.memoryRequests }}
        cpu: {{ .Values.tests.cpuRequests }}
      limits:
        memory: {{ .Values.tests.memoryLimits }}
        cpu: {{ .Values.tests.cpuLimits }}
{{- end -}}
