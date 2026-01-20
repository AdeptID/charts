{{- define "cluster.externalSourceCluster" -}}
connectionParameters:
  host: {{ .host | quote }}
  port: {{ .port | quote }}
  user: {{ .username | quote }}
  {{- with .database }}
  dbname: {{ . | quote }}
  {{- end }}
  sslmode: {{ .sslMode | quote }}
{{- if and .passwordSecret .passwordSecret.name }}
password:
  name: {{ .passwordSecret.name }}
  key: {{ .passwordSecret.key }}
{{- end }}
{{- if and .sslKeySecret .sslKeySecret.name }}
sslKey:
  name: {{ .sslKeySecret.name }}
  key: {{ .sslKeySecret.key }}
{{- end }}
{{- if and .sslCertSecret .sslCertSecret.name }}
sslCert:
  name: {{ .sslCertSecret.name }}
  key: {{ .sslCertSecret.key }}
{{- end }}
{{- if and .sslRootCertSecret .sslRootCertSecret.name }}
sslRootCert:
  name: {{ .sslRootCertSecret.name }}
  key: {{ .sslRootCertSecret.key }}
{{- end }}
{{- end }}
