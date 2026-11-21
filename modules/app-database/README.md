# app-database

RDS PostgreSQL privado de uma app: subnet group, security group com ingresso 5432 só dos SGs informados,
storage gp3 criptografado, senha master gerada e guardada pelo RDS no Secrets Manager
(`manage_master_user_password`, nunca passa pelo state), backups, snapshot final, Performance Insights e
`deletion_protection` (ligado por padrão). Usuário master: `app_admin`.

Autenticação IAM no banco (`iam_database_authentication_enabled`) sempre ligada, sem toggle (padrão da
casa): a app conecta com o próprio usuário e um token IAM (`rds-db:connect` em
`arn:<partição>:rds-db:<região>:<conta>:dbuser:<db_resource_id>/<usuário>`). O secret master é só para
operadores e jobs de migração (ex.: criar o usuário da app com `GRANT rds_iam TO <app>`).

## Entradas

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `name` | string | - | Identificador da instância (ex.: `orders-staging`) |
| `vpc_id` | string | - | VPC do security group |
| `subnet_ids` | list(string) | - | Subnets de dados (privadas) |
| `allowed_security_group_ids` | map(string) | - | Chave estável → SG com acesso à 5432 |
| `engine_version` | string | - | Versão do PostgreSQL (ex.: `17.4`) |
| `instance_class` | string | - | Classe (ex.: `db.t4g.medium`) |
| `allocated_storage` | number | - | Storage inicial (GiB) |
| `max_allocated_storage` | number | - | Teto do autoscaling de storage (GiB) |
| `multi_az` | bool | - | Standby em outra AZ |
| `backup_retention_days` | number | - | Dias de backup (1 a 35) |
| `deletion_protection` | bool | `true` | Bloqueia a exclusão |
| `database_name` | string | - | Banco inicial |
| `tags` | map(string) | `{}` | Tags dos recursos |

## Saídas

| Nome | Descrição |
|---|---|
| `endpoint` | `address:port` |
| `address` / `port` | Host e porta |
| `master_user_secret_arn` | ARN do secret com as credenciais master (só operador/migração, nunca o pod) |
| `db_resource_id` | Resource ID da instância (`db-...`), para o ARN de `rds-db:connect` |
| `security_group_id` | SG da instância |
| `db_instance_identifier` | Identificador RDS |

## Uso

```hcl
module "database" {
  source                     = "../../modules/app-database"
  name                       = "orders-${var.environment}"
  vpc_id                     = local.vpc_id
  subnet_ids                 = local.data_subnet_ids
  allowed_security_group_ids = { eks_nodes = local.node_security_group_id }
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  max_allocated_storage      = 100
  multi_az                   = var.db_multi_az
  backup_retention_days      = var.db_backup_retention_days
  database_name              = "orders"
}
```

Para destruir: primeiro aplique `deletion_protection = false`, depois remova. O snapshot final
`<name>-final` é criado na exclusão.
