# bootstrap

Cria o bucket de state do Terraform de **uma conta**: `acme-tfstate-<env>` com versionamento, SSE-KMS
(chave própria com rotação), block public access, ownership enforced, policy que nega acesso sem TLS,
expiração de versões antigas e `prevent_destroy` no bucket e na chave.

- **Dono:** platform-team
- **Ambientes:** `management`, `shared`, `staging`, `prod` (um por conta)
- **Lê:** nada (só tfvars)
- **Publica:** o bucket `acme-tfstate-<env>` usado por todo `environments/<env>.s3.tfbackend`; outputs `state_bucket_name`, `state_kms_key_arn`

## Ovo e galinha

Este stack cria o bucket onde os outros guardam state, inclusive ele mesmo: em regime o state fica em
`acme-tfstate-<env>`, chave `stacks/bootstrap/terraform.tfstate` (`environments/<env>.s3.tfbackend`, igual aos
outros stacks). Na primeira vez em cada conta o bucket ainda não existe, então o primeiro apply roda com state
local e depois o state é migrado para o bucket. Roda por uma pessoa com credencial de admin da conta, e
raramente muda.

## Primeira vez numa conta

```bash
export AWS_PROFILE=acme-staging-admin
cd stacks/bootstrap

# 1. backend local temporário (arquivos *_override.tf estão no .gitignore; nunca commitar)
cat > backend_override.tf <<'HCL'
terraform {
  backend "local" {}
}
HCL
terraform init -reconfigure
terraform apply -var-file=environments/staging.tfvars

# 2. volta para o backend s3 e migra o state local para o bucket recém-criado
rm backend_override.tf
terraform init -migrate-state -backend-config=environments/staging.s3.tfbackend

# 3. confere e apaga a cópia local
terraform plan -var-file=environments/staging.tfvars   # esperado: No changes
rm -f terraform.tfstate terraform.tfstate.backup
```

Uma conta por vez: o state local fica em `stacks/bootstrap/terraform.tfstate`, então migre antes de passar
para a próxima conta. Se o state se perder, todos os nomes são determinísticos (`acme-tfstate-<env>`,
`alias/acme-<env>-tfstate`) e dá para recuperar com `terraform import`.

## Como rodar (depois da primeira vez)

```bash
export AWS_PROFILE=acme-staging-admin
terraform init -reconfigure -backend-config=environments/staging.s3.tfbackend
terraform apply -var-file=environments/staging.tfvars
```

## Ordem

1. `bootstrap` com `management` → `organization` (cria as contas)
2. `bootstrap` com `shared`, `staging`, `prod` em cada conta nova → demais stacks
