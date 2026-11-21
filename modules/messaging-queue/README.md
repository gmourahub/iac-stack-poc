# messaging-queue

Fila SQS com DLQ (`<name>-dlq`, retenção de 14 dias) e redrive. Opcionalmente assina tópicos SNS: cria uma
subscription por tópico e uma queue policy que libera `sqs:SendMessage` só para esses tópicos.
Criptografia: CMK informada ou SSE-SQS.

## Entradas

| Nome | Tipo | Padrão | Descrição |
|---|---|---|---|
| `name` | string | - | Nome completo da fila (ex.: `payments-staging-orders`) |
| `max_receive_count` | number | `5` | Recebimentos antes de ir para a DLQ |
| `visibility_timeout_seconds` | number | `30` | Visibility timeout da fila principal |
| `message_retention_seconds` | number | `345600` | Retenção da fila principal (4 dias) |
| `subscribe_topic_arns` | map(string) | `{}` | Chave estável → ARN do tópico a assinar |
| `kms_key_arn` | string | `null` | CMK; `null` usa SSE-SQS |
| `tags` | map(string) | `{}` | Tags dos recursos |

## Saídas

| Nome | Descrição |
|---|---|
| `queue_arn` / `queue_url` / `queue_name` | Fila principal |
| `dlq_arn` / `dlq_url` | Dead-letter queue |

## Uso

```hcl
module "orders_events" {
  source = "../../modules/messaging-queue"
  name   = "payments-${var.environment}-orders"
  subscribe_topic_arns = {
    orders_events = local.orders_events_topic_arn
  }
}
```

Use chaves estáveis no mapa: trocar a chave recria a subscription. Com CMK, a key policy precisa liberar
`sns.amazonaws.com` (`kms:GenerateDataKey*`, `kms:Decrypt`) para a entrega do SNS funcionar.
