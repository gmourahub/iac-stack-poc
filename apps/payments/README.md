# payments

Stack da aplicação **payments**. Dono: **team-payments**. Implantado em `staging` e `prod` (uma instância e
um state por ambiente).

## Recursos

| Recurso | Nome na nuvem | Módulo |
|---|---|---|
| RDS PostgreSQL (senha master gerenciada pelo RDS no Secrets Manager) | `payments-<env>` | `app-database` |
| SQS (+ DLQ) assinando o tópico de orders | `payments-<env>-orders-events` | `messaging-queue` |
| SNS de eventos de domínio (a app publica) | `payments-<env>-events` | `event-topic` |
| IAM role via EKS Pod Identity (namespace e service account `payments`) | `payments-<env>` | `workload-identity` |

Permissões da role (menor privilégio): `sns:Publish` no tópico `payments-<env>-events`; receive/delete/
change visibility/get attributes na fila de eventos de orders; `rds-db:connect` como o usuário `payments` no banco (autenticação IAM, token gerado pela app; a role
não lê o secret master).

## Registry lido (SSM, conta do ambiente)

- `/platform/<env>/network/vpc_id`
- `/platform/<env>/network/data_subnet_ids`
- `/platform/<env>/eks/cluster_name`
- `/platform/<env>/eks/node_security_group_id` (SG liberado no banco; shortcut: trocar por Security Groups
  for Pods quando precisar isolar por app)

## Contratos

**Consome** (Resource Matching por nome convencionado): o tópico `orders-<env>-events`. O ARN é montado
com a partição, a região e a conta do próprio provider (`aws_partition`, `aws_region`,
`aws_caller_identity`): `arn:<partição>:sns:<região>:<conta>:orders-<env>-events`. Se `orders` renomear o
tópico, este stack quebra: a mudança precisa de expand/contract coordenado com o time de orders.

**Expõe**:
- **Tópico `payments-<env>-events`**, assinado por `notifications` pelo mesmo esquema de nome. É API
  pública: renomear ou remover exige expand/contract.
- Outputs para os manifests K8s: `orders_events_queue_url`, `events_topic_arn`, `database_address`,
  `database_port`, `database_name`, `database_secret_arn` (só o ARN; uso exclusivo de operadores/jobs de migração, o pod não tem acesso), `role_arn`. Nenhum segredo é exposto.

## Usuário do banco (passo único, fora do Terraform)

A app conecta como o usuário `payments` com token IAM (`rds-db:connect`), não com o secret master. Depois do
primeiro apply em cada ambiente, um operador ou job de migração conecta com o secret master
(`database_secret_arn`) e cria o usuário uma vez:

```sql
CREATE USER payments;
GRANT rds_iam TO payments;
GRANT ALL ON DATABASE payments TO payments;  -- ajuste aos privilégios que a app precisa
```

Sem esse passo a app recebe `PAM authentication failed`. O Terraform não gerencia usuários do PostgreSQL.

## Ordem de deploy

`network` → `eks-platform` → `orders` → **payments** → `notifications`/`catalog`.
O tópico de orders precisa existir no ambiente antes do apply (a subscription falha sem ele).

## Como rodar

```bash
scripts/deploy.sh apps/payments staging plan
scripts/deploy.sh apps/payments staging apply
```

Tamanhos e `deletion_protection` vêm de `environments/<env>.tfvars`; o `prevent_destroy` fica nos módulos.
