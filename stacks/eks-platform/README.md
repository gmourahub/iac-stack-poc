# eks-platform

Um cluster EKS por ambiente (topologia "cluster per environment", skill `servers-and-clusters`) com
`terraform-aws-modules/eks/aws` (`~> 21.30`):

- endpoint privado sempre; endpoint público só se `endpoint_public_access_cidrs` não for vazio
  (`0.0.0.0/0` é recusado por validação);
- `authentication_mode = "API"` com access entry de cluster-admin para `admin_role_arn`
  (o criador do cluster **não** vira admin automaticamente);
- criptografia de secrets do Kubernetes com chave KMS criada pelo módulo;
- addons `coredns`, `kube-proxy`, `vpc-cni` e `eks-pod-identity-agent` (os dois últimos antes dos nós);
- um managed node group `default` (AL2023) com tamanhos via tfvars;
- `deletion_protection = true`.

- **Dono:** platform-team
- **Ambientes:** `staging` (m7i.large, 2–4 nós, endpoint público restrito a um CIDR), `prod` (m7i.xlarge, 3–9 nós, só privado)
- **Lê (SSM, mesma conta):** `/platform/<env>/network/vpc_id`, `/platform/<env>/network/private_subnet_ids`
- **Publica (Integration Registry no SSM; API pública, mudar só com expand/contract):**

| Parâmetro | Tipo |
|---|---|
| `/platform/<env>/eks/cluster_name` | String |
| `/platform/<env>/eks/node_security_group_id` | String |

`node_desired_size` só vale na criação; depois o módulo ignora mudanças.

## Como rodar

```bash
terraform init -backend-config=environments/staging.s3.tfbackend
terraform apply -var-file=environments/staging.tfvars
```

## Ordem

`network` → **eks-platform** → apps (orders → payments → notifications/catalog).
