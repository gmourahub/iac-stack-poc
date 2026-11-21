# network

VPC por ambiente com `terraform-aws-modules/vpc/aws` (`~> 6.8`): 3 AZs, subnets public (/24),
private (/20) e data (/24) recortadas de um /16 (`vpc_cidr`), NAT gateway único ou um por AZ
(`single_nat_gateway`), flow logs no CloudWatch Logs criptografados com KMS (submódulo `flow-log`;
o flow log dentro do módulo raiz está deprecado na v6) e tags de subnet para o AWS Load Balancer
Controller do EKS (`kubernetes.io/role/elb` nas públicas, `kubernetes.io/role/internal-elb` nas privadas).

- **Dono:** platform-team
- **Ambientes:** `staging` (1 NAT, 30 dias de flow log), `prod` (NAT por AZ, 365 dias)
- **Lê:** nada (só tfvars)
- **Publica (Integration Registry no SSM; API pública, mudar só com expand/contract):**

| Parâmetro | Tipo |
|---|---|
| `/platform/<env>/network/vpc_id` | String |
| `/platform/<env>/network/vpc_cidr` | String |
| `/platform/<env>/network/private_subnet_ids` | StringList |
| `/platform/<env>/network/data_subnet_ids` | StringList |

As subnets "data" são as `database_subnets` do módulo. O stack não cria DB subnet group: cada app cria o
seu (`modules/app-database`).

## Como rodar

```bash
terraform init -backend-config=environments/staging.s3.tfbackend
terraform apply -var-file=environments/staging.tfvars
```

## Ordem

`bootstrap` (conta do ambiente) → **network** → `eks-platform` → apps.
