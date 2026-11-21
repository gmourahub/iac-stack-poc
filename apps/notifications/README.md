# notifications

Stack da aplicação **notifications**. Dono: **team-engagement**. Implantado em `staging` e `prod` (uma
instância e um state por ambiente).

## Recursos

| Recurso | Nome na nuvem | Módulo |
|---|---|---|
| SQS (+ DLQ) assinando os tópicos de orders e payments | `notifications-<env>-inbound-events` | `messaging-queue` |
| S3 de templates (privado, versionado, TLS-only) | `acme-<env>-notifications-templates-<conta>` | `app-bucket` |
| IAM role via EKS Pod Identity (namespace e service account `notifications`) | `notifications-<env>` | `workload-identity` |

Permissões da role (menor privilégio): receive/delete/change visibility/get attributes na fila;
`s3:GetObject` e `s3:PutObject` só no prefixo `templates/` do bucket. Sem `s3:ListBucket`: objeto
inexistente devolve 403, não 404.

O nome do bucket leva o account ID porque nomes de bucket são globais.

## Registry lido (SSM, conta do ambiente)

- `/platform/<env>/eks/cluster_name`

## Contratos

**Consome** (Resource Matching por nome convencionado), na conta/região do próprio provider
(`aws_partition`, `aws_region`, `aws_caller_identity`):
- `arn:<partição>:sns:<região>:<conta>:orders-<env>-events`
- `arn:<partição>:sns:<região>:<conta>:payments-<env>-events`

Se `orders` ou `payments` renomearem o tópico, este stack quebra: a mudança precisa de expand/contract
coordenado com o time dono do tópico.

**Expõe** (outputs para os manifests K8s): `events_queue_url`, `templates_bucket_name`, `role_arn`.
Nenhum segredo é exposto. Nenhum outro stack depende deste.

## Ordem de deploy

`network` → `eks-platform` → `orders` → `payments` → **notifications** (em paralelo com `catalog`).
Os dois tópicos precisam existir no ambiente antes do apply.

## Como rodar

```bash
scripts/deploy.sh apps/notifications staging plan
scripts/deploy.sh apps/notifications staging apply
```
