# event-topic

Tópico SNS de eventos de uma app, sempre criptografado com KMS (CMK informada ou `alias/aws/sns`).

## Entradas

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `name` | string | - | Nome completo do tópico (ex.: `orders-staging-events`) |
| `kms_key_arn` | string | `null` | CMK; `null` usa `alias/aws/sns` |
| `fifo` | bool | `false` | Tópico FIFO (o sufixo `.fifo` é adicionado ao nome) |
| `tags` | map(string) | `{}` | Tags dos recursos |

## Saídas

| Nome | Descrição |
|---|---|
| `topic_arn` | ARN do tópico |
| `topic_name` | Nome do tópico |

## Uso

```hcl
module "events" {
  source = "../../modules/event-topic"
  name   = "orders-${var.environment}-events"
}
```

O nome é contrato: outras apps montam o ARN a partir de `<app>-<env>-events`.
Com CMK, a key policy precisa liberar `sns.amazonaws.com` e os publicadores.
