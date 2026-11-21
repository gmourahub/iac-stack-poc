# shared-services

Serviços compartilhados da conta `acme-shared`, fora do caminho de entrega das apps:

- **ECR** por app (`acme-shared/<app>` para orders, payments, notifications, catalog): tags imutáveis,
  scan on push, criptografia KMS (chave própria), lifecycle (expira untagged e mantém as N imagens mais
  recentes) e repository policy que libera pull para qualquer principal da organização
  (`aws:PrincipalOrgID = var.organization_id`) e para ninguém de fora.
- **OIDC do GitHub Actions** + uma **role de deploy por ambiente alvo** (`acme-shared-deploy-<alvo>`).
  A trust policy exige `aud = sts.amazonaws.com` e `sub = repo:<owner>/<repo>:environment:<github env>`:
  só um job rodando no GitHub environment certo (com as proteções dele) consegue a role.
  A role só pode fazer `sts:AssumeRole` em `acme-<alvo>-deploy` em contas da organização
  (`aws:ResourceOrgID`), sem account ID no código.

- **Dono:** platform-team
- **Ambientes:** só `shared`
- **Lê:** `organization_id` (output do stack `organization`, copiado para o tfvars), repo GitHub e mapa de alvos
- **Publica:** outputs `ecr_repository_urls`, `deploy_role_arns` (vão para a config do pipeline)

Contrato com as contas alvo: cada uma precisa de uma role `acme-<alvo>-deploy` que confie em
`acme-shared-deploy-<alvo>`. Essa role não é criada aqui (fica na conta alvo).

## Como rodar

```bash
terraform init -backend-config=environments/shared.s3.tfbackend
terraform apply -var-file=environments/shared.tfvars
```

## Ordem

`organization` → `bootstrap` (shared) → **shared-services**. Independente de `network`/`eks-platform`.
