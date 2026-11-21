# Acme Platform: arquitetura de IaC (contrato)

Estate Terraform de uma empresa grande na AWS, desenhado com as skills do plugin `iac-patterns`
(`skills/*/SKILL.md` na raiz do repositório). Este arquivo é o **contrato** entre as partes:
quem implementa um diretório segue exatamente as interfaces abaixo.

## Ambientes e contas (skill `environment-design`)

| Ambiente | Conta AWS | Papel |
|---|---|---|
| `shared`  | acme-shared  | serviços compartilhados: ECR, OIDC do CI e roles de deploy do pipeline |
| `staging` | acme-staging | delivery environment, upstream de prod, mesmo código de prod |
| `prod`    | acme-prod    | produção |

- Uma conta por ambiente; contas criadas como código em `stacks/organization` (conta management).
- Fluxo de entrega: staging → prod (build once, deploy many). `shared` não está no caminho de entrega das apps.
- Variação entre ambientes **só** em `environments/<env>.tfvars`. Nenhum `var.environment == "prod" ? ...`.
- Região: `var.region` (padrão nos tfvars: `us-east-1`).

## Layout

```
tmp/
  ARCHITECTURE.md            este contrato
  README.md                  visão geral, decisões (com a skill de origem de cada uma), como rodar
  .gitignore  .tflint.hcl  .pre-commit-config.yaml
  scripts/deploy.sh          wrapper: init com backend do ambiente + plan/apply com tfvars
  ci/github-actions.yml      pipeline de exemplo (offline checks → staging → prod)
  modules/                   módulos de domínio da casa (reutilizáveis, sem provider/backend)
    event-topic/ messaging-queue/ app-database/ app-cache/ app-bucket/ workload-identity/
  stacks/
    bootstrap/               bucket de state por conta (1ª execução com state local, depois migra para o próprio bucket)
    organization/            OUs + contas (conta management)
    account-baseline/        role acme-<env>-deploy + guardrails da conta (shared, staging, prod)
    shared-services/         ECR + OIDC GitHub + roles de deploy (só env shared)
    network/                 VPC por ambiente (staging, prod)
    eks-platform/            cluster EKS por ambiente (staging, prod)
  apps/                      um stack por app; cada time é dono do seu (federation)
    orders/ payments/ notifications/ catalog/
```

Cada stack (root module) tem: `terraform.tf`, `providers.tf`, `backend.tf`, `main.tf` (ou arquivos por
conceito de domínio), `variables.tf`, `outputs.tf`, `locals.tf` se precisar, `README.md` curto e
`environments/<env>.tfvars` + `environments/<env>.s3.tfbackend` para cada ambiente onde é implantado.

## Convenções (skill `terraform-conventions`)

- `required_version = ">= 1.10"` (por causa de `use_lockfile`); provider `hashicorp/aws ~> 6.0`.
- Módulos da comunidade fixados por versão: `terraform-aws-modules/vpc/aws` e `terraform-aws-modules/eks/aws`
  (confira a major atual compatível com AWS provider 6 via Context7/registry).
- `backend "s3" {}` parcial. O `.s3.tfbackend` tem `bucket`, `key = "<stack-path>/terraform.tfstate"`,
  `region`, `encrypt = true`, `use_lockfile = true`. Bucket: `acme-tfstate-<env>` (um por conta).
- Credenciais vêm do ambiente (OIDC no CI / `AWS_PROFILE` local). Nenhum `assume_role` ou account ID fixo em stack.
- Provider com `default_tags`: `owner`, `environment`, `service`, `cost_center`, `managed_by = "terraform"`.
- Nomes na nuvem: `"${var.service}-${var.environment}"` / `"acme-${var.environment}-..."`.
- Segurança: KMS, privado por padrão, IAM com menor privilégio, `deletion_protection`/`prevent_destroy` em dados.
- Módulos: sem `provider`/`backend`, sem data sources de descoberta (recebem tudo por variável), `README.md`,
  `tests/*.tftest.hcl` com `mock_provider "aws"` (precisa rodar offline).

## Integração entre stacks (skill `stack-integration`): Integration Registry no SSM

Stacks de plataforma **publicam** valores em SSM Parameter Store (na conta do ambiente). Apps **leem** no root
module e injetam nos módulos por variável. Nenhum `terraform_remote_state`, nenhum ID fixo.
Esses nomes são API pública: mudar exige expand/contract.

| Parâmetro (tipo) | Publicado por |
|---|---|
| `/platform/<env>/network/vpc_id` (String) | network |
| `/platform/<env>/network/vpc_cidr` (String) | network |
| `/platform/<env>/network/private_subnet_ids` (StringList) | network |
| `/platform/<env>/network/data_subnet_ids` (StringList) | network |
| `/platform/<env>/eks/cluster_name` (String) | eks-platform |
| `/platform/<env>/eks/node_security_group_id` (String) | eks-platform |

`eks-platform` lê os parâmetros de network do mesmo jeito.

## Interfaces dos módulos (`modules/`)

Todas as variáveis com `type` + `description`; `name` já vem completo (ex.: `orders-staging-events`).
Todo módulo aceita `tags` (map(string), default `{}`).

**event-topic**: tópico SNS criptografado com KMS.
- in: `name` (string), `kms_key_arn` (string, null → `alias/aws/sns`), `fifo` (bool, false)
- out: `topic_arn`, `topic_name`

**messaging-queue**: fila SQS + DLQ + redrive; opcionalmente assina tópicos SNS (subscription + queue policy
que libera `sqs:SendMessage` só para esses tópicos).
- in: `name`, `max_receive_count` (number, 5), `visibility_timeout_seconds` (number, 30),
  `message_retention_seconds` (number, 345600), `subscribe_topic_arns` (map(string) chave estável → ARN, default `{}`),
  `kms_key_arn` (string, null → SSE-SQS)
- out: `queue_arn`, `queue_url`, `queue_name`, `dlq_arn`, `dlq_url`

**app-database**: RDS PostgreSQL privado, senha master gerenciada pelo RDS no Secrets Manager
(`manage_master_user_password`), subnet group, SG com ingresso 5432 só dos SGs informados, criptografado,
backups, `deletion_protection` por variável, Performance Insights, autenticação IAM sempre ligada (apps usam
`rds-db:connect` com o próprio usuário; o secret master é só para operadores/migração).
- in: `name`, `vpc_id`, `subnet_ids` (list), `allowed_security_group_ids` (map(string), chave estável),
  `engine_version` (string), `instance_class`, `allocated_storage` (number), `max_allocated_storage` (number),
  `multi_az` (bool), `backup_retention_days` (number), `deletion_protection` (bool, true), `database_name`
- out: `endpoint`, `address`, `port`, `master_user_secret_arn`, `db_resource_id`, `security_group_id`,
  `db_instance_identifier`

**app-cache**: ElastiCache (engine `valkey` ou `redis`) replication group, criptografia at-rest e in-transit,
privado, SG 6379 só dos SGs informados, failover automático quando `num_cache_clusters > 1`.
- in: `name`, `vpc_id`, `subnet_ids`, `allowed_security_group_ids` (map(string)), `engine` (string,
  validation valkey|redis, default "valkey"), `engine_version`, `node_type`, `num_cache_clusters` (number)
- out: `primary_endpoint`, `reader_endpoint`, `port`, `security_group_id`

**app-bucket**: S3 privado, block public access, versionamento, SSE-KMS (ou SSE-S3 se `kms_key_arn` null),
TLS-only bucket policy, ownership enforced, lifecycle para versões antigas.
- in: `name`, `kms_key_arn` (string, null), `noncurrent_version_expiration_days` (number, 90),
  `force_destroy` (bool, false)
- out: `bucket_name`, `bucket_arn`

**workload-identity**: IAM role para EKS Pod Identity (`pods.eks.amazonaws.com`, `sts:AssumeRole` +
`sts:TagSession`) + `aws_eks_pod_identity_association` + policy inline montada a partir de statements.
- in: `name`, `cluster_name`, `namespace`, `service_account`,
  `policy_statements` (map(object({ actions = list(string), resources = list(string) })), chave = sid)
- out: `role_arn`, `role_name`

## Apps (`apps/`)

Cada app roda como Deployment no EKS do ambiente, namespace = nome da app, service account = nome da app.
O stack da app cria só os recursos AWS da app + a workload identity (o manifest K8s fica fora daqui).
O SG que acessa RDS/Redis é o `node_security_group_id` do registry (shortcut documentado: trocar por
Security Groups for Pods quando precisar isolar por app).

| App | Time | Recursos |
|---|---|---|
| orders | team-orders | RDS Postgres, Redis, SNS `orders-events` (publica), SQS `orders-commands` |
| payments | team-payments | RDS Postgres, SQS que assina `orders-events`, SNS `payments-events` (publica) |
| notifications | team-engagement | SQS que assina `orders-events` e `payments-events`, S3 de templates |
| catalog | team-catalog | RDS Postgres, Redis, S3 de imagens |

Tópicos de outra app são descobertos por **nome convencionado** (`<app>-<env>-events`) e montados como ARN
com a conta/região do próprio provider (`data "aws_caller_identity"`/`aws_region` no root module).
Isso é Resource Matching, e o nome é contrato. Documente no README de cada app.
Ordem de deploy por ambiente: network → eks-platform → orders → payments → notifications/catalog.

Tamanhos (via tfvars): staging pequeno (db.t4g.medium, cache.t4g.small, 1 nó de cache, sem multi-AZ);
prod robusto (db.r7g.large multi-AZ, cache.r7g.large com 2 nós, backups 14 dias).
