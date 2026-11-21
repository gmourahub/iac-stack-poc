# workload-identity

Identidade AWS de um workload no EKS via Pod Identity: IAM role confiando só em `pods.eks.amazonaws.com`
(`sts:AssumeRole` + `sts:TagSession`), policy inline montada a partir dos statements e a
`aws_eks_pod_identity_association` ligando namespace/service account à role. O cluster precisa do add-on
`eks-pod-identity-agent`.

## Entradas

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `name` | string | - | Nome da role (ex.: `orders-staging-app`) |
| `cluster_name` | string | - | Cluster EKS |
| `namespace` | string | - | Namespace do service account |
| `service_account` | string | - | Service account ligado à role |
| `policy_statements` | map(object({ actions = list(string), resources = list(string) })) | - | Statements `Allow`, chave = Sid (só letras e dígitos); `"*"` puro é rejeitado |
| `tags` | map(string) | `{}` | Tags dos recursos |

## Saídas

| Nome | Descrição |
|---|---|
| `role_arn` | ARN da role |
| `role_name` | Nome da role |

## Uso

```hcl
module "identity" {
  source          = "../../modules/workload-identity"
  name            = "orders-${var.environment}-app"
  cluster_name    = local.cluster_name
  namespace       = "orders"
  service_account = "orders"
  policy_statements = {
    PublishEvents = {
      actions   = ["sns:Publish"]
      resources = [module.events.topic_arn]
    }
  }
}
```
