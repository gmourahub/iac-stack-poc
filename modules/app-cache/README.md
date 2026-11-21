# app-cache

ElastiCache replication group (`valkey` por padrão, ou `redis`) privado, com criptografia at-rest e
in-transit (clientes precisam de TLS), SG com ingresso 6379 só dos SGs informados. Com
`num_cache_clusters > 1` liga failover automático e Multi-AZ.

## Entradas

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `name` | string | - | ID do replication group (minúsculas, até 40 caracteres) |
| `vpc_id` | string | - | VPC do security group |
| `subnet_ids` | list(string) | - | Subnets de dados (privadas) |
| `allowed_security_group_ids` | map(string) | - | Chave estável → SG com acesso à 6379 |
| `engine` | string | `"valkey"` | `valkey` ou `redis` |
| `engine_version` | string | - | Versão (ex.: `8.0`) |
| `node_type` | string | - | Tipo de nó (ex.: `cache.t4g.small`) |
| `num_cache_clusters` | number | - | Nós (primário + réplicas), 1 a 6 |
| `tags` | map(string) | `{}` | Tags dos recursos |

## Saídas

| Nome | Descrição |
|---|---|
| `primary_endpoint` | Endpoint de escrita |
| `reader_endpoint` | Endpoint de leitura |
| `port` | Porta (6379) |
| `security_group_id` | SG do cache |

## Uso

```hcl
module "cache" {
  source                     = "../../modules/app-cache"
  name                       = "orders-${var.environment}"
  vpc_id                     = local.vpc_id
  subnet_ids                 = local.data_subnet_ids
  allowed_security_group_ids = { eks_nodes = local.node_security_group_id }
  engine_version             = "8.0"
  node_type                  = var.cache_node_type
  num_cache_clusters         = var.cache_nodes
}
```
