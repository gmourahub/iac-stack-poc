# app-bucket

Bucket S3 privado de uma app: block public access completo, ACLs desligadas (`BucketOwnerEnforced`),
versionamento, SSE-KMS com Bucket Key (ou SSE-S3 sem CMK), bucket policy que nega acesso sem TLS e
lifecycle que expira versões antigas e aborta multipart uploads incompletos após 7 dias.

## Entradas

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `name` | string | - | Nome global do bucket (ex.: `acme-staging-catalog-images`) |
| `kms_key_arn` | string | `null` | CMK; `null` usa SSE-S3 |
| `noncurrent_version_expiration_days` | number | `90` | Dias até apagar versões antigas |
| `force_destroy` | bool | `false` | Permite destruir com objetos dentro |
| `tags` | map(string) | `{}` | Tags dos recursos |

## Saídas

| Nome | Descrição |
|---|---|
| `bucket_name` | Nome do bucket |
| `bucket_arn` | ARN do bucket |

## Uso

```hcl
module "templates" {
  source = "../../modules/app-bucket"
  name   = "acme-${var.environment}-notifications-templates"
}
```
