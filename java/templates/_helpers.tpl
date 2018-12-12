{{/*
This template is for adding the environment variable list and checking the format of the keys
The key or "environment variable" must be uppercase and contain only numbers or "_".
*/}}
{{- define "java.environment" -}}
  {{- if . -}}
    {{- range $key, $val := . }}
- name: {{ if $key | regexMatch "^[^.-]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
        {{- end }}
  value: {{ $val | quote }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Adding in the helper here where we can use a secret object to include secrets to for the deployed service.
The key or "environment variable" must be uppercase and contain only numbers or "_".
Example format:
"
 ENVIRONMENT_VAR:
    secretRef: secret-vault 
    key: connectionString
"
*/}}
{{- define "java.secrets" -}}
  {{- if . -}}
    {{- range $key, $val := . }}
      {{- if $val }}
- name: {{ if $key | regexMatch "^[^.-]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
        {{- end }}
  valueFrom:
    secretKeyRef:
      name: {{ required "Each item in \"secrets:\" needs a secretRef member" $val.secretRef }}
      key: {{ required "Each item in \"secrets:\" needs a key member" $val.key }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end }}
