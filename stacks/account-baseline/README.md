# account-baseline

Baseline de cada conta de workload (e da `acme-shared`), aplicado uma vez por conta:

- **Role `acme-<env>-deploy`**: a role que o Terraform usa no CI. Confia só na conta `acme-shared`
  (`shared_account_id`), restrita por `aws:PrincipalArn` à role `acme-shared-deploy-<env>` criada pelo
  `shared-services` (o CI chega nela por role chaining; veja `ci/github-actions.yml`). Permite
  `sts:AssumeRole` + `sts:TagSession` (o `configure-aws-credentials` marca a sessão encadeada).
- **Permissões amplas, com justificativa**: o deploy cria VPC, EKS, RDS, ElastiCache, SNS/SQS, S3, KMS e
  roles IAM de workload; uma lista de ações escrita à mão quebra a cada recurso novo. Por isso a role tem
  `AdministratorAccess`, limitada pelo **permissions boundary** `acme-<env>-deploy-boundary`, que nega:
  criar usuário IAM, access key e login profile; `organizations:*` e `account:*`; desligar a criptografia
  EBS padrão e alterar o public access block da conta; mexer na própria role ou no próprio boundary.
  Os controles de verdade ficam antes: só um job no GitHub environment certo, do repo certo, chega
  aqui, e toda mudança é um commit revisado.
- **Guardrails da conta**: S3 Block Public Access no nível da conta e criptografia EBS por padrão
  (chave gerenciada `alias/aws/ebs`).

- **Dono:** platform-team
- **Ambientes:** `shared`, `staging`, `prod` (um por conta). Na `shared`, a role só fica utilizável se
  o `shared-services` ganhar um alvo `shared` em `deploy_targets`.
- **Lê:** `shared_account_id` (output `account_ids` do `organization`, copiado para o tfvars)
- **Publica:** output `deploy_role_arn` → variável `AWS_TARGET_ROLE_ARN` do GitHub environment

## Como rodar

Ovo e galinha: o stack cria a role que o pipeline usa, então roda com credencial de admin da conta,
fora do CI (como o `bootstrap`). O boundary impede que o pipeline desfaça estes guardrails.

```bash
export AWS_PROFILE=acme-staging-admin
terraform init -backend-config=environments/staging.s3.tfbackend
terraform apply -var-file=environments/staging.tfvars
```

## Ordem

`bootstrap` (conta) → **account-baseline** → `shared-services` (shared) / `network` (staging, prod).
