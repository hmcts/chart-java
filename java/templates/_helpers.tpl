{{/*
For adding the environment variable list and checking the format of the keys 
They must be uper case and contain only numbers or "_"
*/}}
{{- define "java.environment" -}}
  {{- if . -}}
    {{- range $key, $val := . }}
- name: {{ if $key | regexMatch "^[A-Z_0-9]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables have to upper case  and match \"[A-Z_0-9]+\" given: " ($key|quote)) -}}
        {{- end }}
  value: {{ $val | quote }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Adding in the helper heare where we can use a secret object to include secrets to for the deployed servce.
 the secret must be in the format of 
 ENVIRONMENT_VAR:
    secretRef: secret-vault 
    key: connectionString
*/}}
{{- define "java.secrets" -}}
  {{- if . -}}
    {{- range $key, $val := . }}
      {{- if $val }}
- name: {{ if $key | regexMatch "^[A-Z_0-9]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables have to upper case  and match \"[A-Z_0-9]+\" given: " ($key|quote)) -}}
        {{- end }}
  valueFrom:
    secretKeyRef:
      name: {{ required "Each item in \"secrets:\" needs a secretRef member" $val.secretRef   }}
      key: {{ required "Each item in \"secrets:\" needs a key member" $val.key }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end }}
