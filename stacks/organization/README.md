# organization

AWS Organizations como código (account vending simples, skill `environment-design`): a organização,
as OUs `Infrastructure`, `Security`, `Workloads`, as contas `acme-shared` (Infrastructure),
`acme-staging` e `acme-prod` (Workloads), e uma SCP de baseline (`acme-baseline`) anexada a **todas** as OUs
(controle de plataforma, skill `infra-governance`):

- nega `organizations:LeaveOrganization`;
- nega desligar, apagar ou alterar CloudTrail e GuardDuty;
- nega chamadas fora de `allowed_regions` (exceto serviços globais: IAM, STS, Organizations, Route 53, CloudFront...).

- **Dono:** platform-team
- **Ambientes:** só `management` (instância única, roda na conta management)
- **Lê:** nada (e-mails das contas e regiões permitidas vêm de `environments/management.tfvars`)
- **Publica:** outputs `organization_id` (vai para `organization_id` do `shared-services`),
  `account_ids` (para configurar as credenciais do CI por ambiente), `organizational_unit_ids`

Notas:
- `aws_service_access_principals` e `enabled_policy_types` são **autoritativos** (vêm de
  `environments/management.tfvars`): o que estiver habilitado na AWS e faltar na lista é desligado no apply.
  `prevent_destroy` protege a organização contra destroy, não contra essa remoção.
- A SCP vai para cada OU (`for_each` sobre as OUs), nunca para a raiz: SCP não afeta a conta management
  (regra da AWS), e anexar por OU deixa explícita qualquer exceção futura. A OU `Security` também recebe a
  SCP; se uma conta dela virar administradora delegada do GuardDuty, a negação de `guardduty:*Members`/
  `UpdateDetector` precisa de exceção por role (`aws:PrincipalArn`) antes disso.
- Contas e organização têm `prevent_destroy`; `close_on_deletion = false`. Remover uma conta exige
  tirar o recurso com um bloco `removed {}` e fechar a conta por processo próprio.
- Teste a SCP depois de aplicar: tente a ação proibida numa conta membro e espere `AccessDenied`.
- A SCP foi renomeada de `acme-workloads-baseline` para `acme-baseline`; os blocos `moved` em `scp.tf`
  evitam recriar a policy e a anexação existente em `Workloads`.

## Organização já existente (import)

Skill `import-existing-infra`: use um bloco `import`, revisado em PR, nunca `terraform import` na CLI.

1. Reconcilie os tfvars com a realidade **antes** do primeiro plan:
   `aws organizations list-aws-service-access-for-organization` (principals) e
   `aws organizations list-roots` (`PolicyTypes` com status `ENABLED`). Tudo que estiver habilitado e
   for para ficar entra em `aws_service_access_principals` / `enabled_policy_types`.
2. Crie um `import.tf` temporário:
   ```hcl
   import {
     to = aws_organizations_organization.main
     id = "o-xxxxxxxxxx" # aws organizations describe-organization --query Organization.Id
   }
   ```
3. `terraform plan -var-file=environments/management.tfvars` e **revise o primeiro plan**: ele deve mostrar
   só o import, sem remover nenhum principal de `aws_service_access_principals` nem tipo de
   `enabled_policy_types`. Qualquer remoção: corrija os tfvars, não aplique. Adições (ex.: habilitar
   `TAG_POLICY`) são mudanças deliberadas; prefira aplicá-las num passo separado, depois do import limpo.
   As OUs e contas existentes seguem o mesmo caminho (blocos `import` com as chaves do `for_each`).
4. Depois do apply, apague o `import.tf`.

## Como rodar

```bash
terraform init -backend-config=environments/management.s3.tfbackend
terraform apply -var-file=environments/management.tfvars
```

## Ordem

`bootstrap` (management) → **organization** → `bootstrap` em cada conta nova → `shared-services`, `network`.
