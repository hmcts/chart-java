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

{{- define "java.tests.meta" -}}
metadata:
  name: {{ .Release.Name }}-{{ .Values.task }}{{ .Values.type }}-job
  labels:
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/instance: {{ .Release.Name }}-{{ .Values.task }}{{ .Values.type }}
    helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    app.kubernetes.io/name: {{ template "hmcts.java.releaseName" . }}-{{ .Values.task }}{{ .Values.type }}
{{- end -}}

{{- define "java.tests.header" -}}
apiVersion: v1
kind: Pod
{{ template "java.tests.meta" . }}
    {{- if .Values.aadIdentityName }}
    aadpodidbinding: {{ .Values.aadIdentityName }}
    {{- end }}
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-delete-policy": before-hook-creation 
{{- end -}}

{{- define "java.testscron.header" -}}
apiVersion: batch/v1beta1
kind: CronJob
{{ template "java.tests.meta" . }}
spec:
  schedule: "{{ .Values.schedule }}"
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        metadata:
          labels:
            app.kubernetes.io/name: {{ template "hmcts.java.releaseName" . }}-{{ .Values.task }}testscron
            {{- if .Values.aadIdentityName }}
            aadpodidbinding: {{ .Values.aadIdentityName }}
            {{- end }}
        spec:
{{- end -}}

{{- define "java.tests.spec" -}}
{{- if and .Values.testsConfig.keyVaults .Values.global.enableKeyVaults }}
volumes:
  {{- $globals := .Values.global }}
  {{- $aadIdentityName := .Values.aadIdentityName }}
  {{- range $key, $value := .Values.testsConfig.keyVaults }}
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
        keyvaultobjectnames: {{ keys $value.secrets | join ";" | quote }}  #"some-username;some-password"
        keyvaultobjecttypes: {{ trimSuffix ";" (repeat (len $value.secrets) "secret;") | quote }} # OPTIONS: secret, key, cert
  {{- end }}
{{- end }}
securityContext:
  runAsUser: 1000
  fsGroup: 1000
restartPolicy: Never
serviceAccountName: {{ .Values.testsConfig.serviceAccountName }}
containers:
  - name: tests
    image: {{ .Values.tests.image }}
    {{- if and .Values.testsConfig.keyVaults .Values.global.enableKeyVaults }}
    {{ $args := list }}
    {{- range $key, $value := .Values.testsConfig.keyVaults -}}{{- range $secret, $var := $value.secrets -}} {{ $args = append $args (printf "%s=/mnt/secrets/%s/%s" $var $key $secret | quote) }} {{- end -}}{{- end -}}
    args: [{{ $args | join "," }}]
    {{- end }}
    securityContext:
      allowPrivilegeEscalation: false
    {{- if or .Values.tests.environment .Values.testsConfig.environment }}
    {{- $envMap := dict "TEST_URL" "" -}}
    {{- if .Values.testsConfig.environment -}}{{- range $key, $value := .Values.testsConfig.environment -}}{{- $_ := set $envMap $key $value -}}{{- end -}}{{- end -}}
    {{- if .Values.tests.environment -}}{{- range $key, $value := .Values.tests.environment -}}{{- $_ := set $envMap $key $value -}}{{- end -}}{{- end }}
    env:
      - name: TASK
        value: {{ .Values.task | quote }}
      - name: TASK_TYPE
        value: {{ .Values.type | quote }}
      - name: SLACK_WEBHOOK
        valueFrom:
          secretKeyRef:
            name: tests-values
            key: slack-webhook
    {{- range $key, $val := $envMap }}
      - name: {{ $key }}
        value: {{ $val | quote }}
    {{- end }}
    {{- end }}
    {{- if and .Values.testsConfig.keyVaults .Values.global.enableKeyVaults }}
    volumeMounts:
      {{- range $key, $value := .Values.testsConfig.keyVaults }}
      - name: vault-{{ $key }}
        mountPath: /mnt/secrets/{{ $key }}
        readOnly: true
      {{- end }}
    {{- end }}
    resources:
      requests:
        memory: "{{ if .Values.tests.memoryRequests }}{{ .Values.tests.memoryRequests }}{{ else }}{{ .Values.testsConfig.memoryRequests }}{{ end }}"
        cpu: "{{ if .Values.tests.cpuRequests }}{{ .Values.tests.cpuRequests }}{{ else }}{{ .Values.testsConfig.cpuRequests }}{{ end }}"
      limits:
        memory: "{{ if .Values.tests.memoryLimits }}{{ .Values.tests.memoryLimits }}{{ else }}{{ .Values.testsConfig.memoryLimits }}{{ end }}"
        cpu: "{{ if .Values.tests.cpuLimits }}{{ .Values.tests.cpuLimits }}{{ else }}{{ .Values.testsConfig.cpuLimits }}{{ end }}"
{{- end -}}
