# catalog

Stack da aplicação **catalog**. Dono: **team-catalog**. Implantado em `staging` e `prod` (uma instância e
um state por ambiente).

## Recursos

| Recurso | Nome na nuvem | Módulo |
|---|---|---|
| RDS PostgreSQL (senha master gerenciada pelo RDS no Secrets Manager) | `catalog-<env>` | `app-database` |
| ElastiCache Valkey | `catalog-<env>` | `app-cache` |
| S3 de imagens (privado, versionado, TLS-only) | `acme-<env>-catalog-images-<conta>` | `app-bucket` |
| IAM role via EKS Pod Identity (namespace e service account `catalog`) | `catalog-<env>` | `workload-identity` |

Permissões da role (menor privilégio): `s3:GetObject` e `s3:PutObject` só no prefixo `images/` do bucket;
`rds-db:connect` como o usuário `catalog` no banco (autenticação IAM, token gerado pela app; a role
não lê o secret master). Sem `s3:ListBucket`: objeto inexistente devolve 403.

O nome do bucket leva o account ID porque nomes de bucket são globais.

## Registry lido (SSM, conta do ambiente)

- `/platform/<env>/network/vpc_id`
- `/platform/<env>/network/data_subnet_ids`
- `/platform/<env>/eks/cluster_name`
- `/platform/<env>/eks/node_security_group_id` (SG liberado no banco e no cache; shortcut: trocar por
  Security Groups for Pods quando precisar isolar por app)

## Contrato que este stack expõe

Não consome tópicos de outras apps e nenhum stack depende dele. Outputs para os manifests K8s:
`database_address`, `database_port`, `database_name`, `database_secret_arn` (só o ARN; uso exclusivo de operadores/jobs de migração, o pod não tem acesso),
`cache_primary_endpoint`, `cache_reader_endpoint`, `cache_port`, `images_bucket_name`, `role_arn`.
Nenhum segredo é exposto.

## Usuário do banco (passo único, fora do Terraform)

A app conecta como o usuário `catalog` com token IAM (`rds-db:connect`), não com o secret master. Depois do
primeiro apply em cada ambiente, um operador ou job de migração conecta com o secret master
(`database_secret_arn`) e cria o usuário uma vez:

```sql
CREATE USER catalog;
GRANT rds_iam TO catalog;
GRANT ALL ON DATABASE catalog TO catalog;  -- ajuste aos privilégios que a app precisa
```

Sem esse passo a app recebe `PAM authentication failed`. O Terraform não gerencia usuários do PostgreSQL.

## Ordem de deploy

`network` → `eks-platform` → **catalog** (na prática, junto com `notifications`, depois de `orders`/`payments`).
Só depende da plataforma.

## Como rodar

```bash
scripts/deploy.sh apps/catalog staging plan
scripts/deploy.sh apps/catalog staging apply
```

Tamanhos e `deletion_protection` vêm de `environments/<env>.tfvars`; o `prevent_destroy` fica nos módulos.
