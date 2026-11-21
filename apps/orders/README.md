# orders

Stack da aplicação **orders**. Dono: **team-orders**. Implantado em `staging` e `prod` (uma instância e um
state por ambiente).

## Recursos

| Recurso | Nome na nuvem | Módulo |
|---|---|---|
| RDS PostgreSQL (senha master gerenciada pelo RDS no Secrets Manager) | `orders-<env>` | `app-database` |
| ElastiCache Valkey | `orders-<env>` | `app-cache` |
| SNS de eventos de domínio (a app publica) | `orders-<env>-events` | `event-topic` |
| SQS de comandos (+ DLQ) | `orders-<env>-commands` | `messaging-queue` |
| IAM role via EKS Pod Identity (namespace e service account `orders`) | `orders-<env>` | `workload-identity` |

Permissões da role (menor privilégio): `sns:Publish` no tópico `orders-<env>-events`; receive/delete/
change visibility/get attributes na fila de comandos; `rds-db:connect` como o usuário `orders` no banco (autenticação IAM, token gerado pela app; a role
não lê o secret master).

## Registry lido (SSM, conta do ambiente)

- `/platform/<env>/network/vpc_id`
- `/platform/<env>/network/data_subnet_ids`
- `/platform/<env>/eks/cluster_name`
- `/platform/<env>/eks/node_security_group_id` (SG liberado no banco e no cache; shortcut: trocar por
  Security Groups for Pods quando precisar isolar por app)

## Contrato que este stack expõe

- **Tópico `orders-<env>-events`** na conta/região do ambiente. `payments` e `notifications` montam o ARN
  por esse nome (Resource Matching). O nome é API pública: renomear ou remover exige expand/contract
  (criar o novo, migrar os consumidores, só então remover o antigo).
- Outputs para os manifests K8s da app: `commands_queue_url`, `events_topic_arn`, `database_address`,
  `database_port`, `database_name`, `database_secret_arn` (só o ARN; uso exclusivo de operadores/jobs de migração, o pod não tem acesso), `cache_primary_endpoint`,
  `cache_reader_endpoint`, `cache_port`, `role_arn`. Nenhum segredo é exposto.

## Usuário do banco (passo único, fora do Terraform)

A app conecta como o usuário `orders` com token IAM (`rds-db:connect`), não com o secret master. Depois do
primeiro apply em cada ambiente, um operador ou job de migração conecta com o secret master
(`database_secret_arn`) e cria o usuário uma vez:

```sql
CREATE USER orders;
GRANT rds_iam TO orders;
GRANT ALL ON DATABASE orders TO orders;  -- ajuste aos privilégios que a app precisa
```

Sem esse passo a app recebe `PAM authentication failed`. O Terraform não gerencia usuários do PostgreSQL.

## Ordem de deploy

`network` → `eks-platform` → **orders** → `payments` → `notifications`/`catalog`.
Orders precisa existir antes de `payments` e `notifications`, que assinam o tópico dele.

## Como rodar

```bash
scripts/deploy.sh apps/orders staging plan
scripts/deploy.sh apps/orders staging apply
```

Tamanhos e `deletion_protection` vêm de `environments/<env>.tfvars`; o `prevent_destroy` fica nos módulos.
