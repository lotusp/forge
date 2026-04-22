---
name: event-consumers
section: Event Consumers
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - Kafka / RabbitMQ / SQS / NATS client dependencies
  - consumer registration files (src/consumers/ / src/listeners/)
  - @KafkaListener / @RabbitListener annotations
token-budget: 1000
---

# Profile: Event Consumers

## Scope

Covers **inbound** event consumption: topics / queues the system subscribes to,
handler locations, retry / DLQ policy at a high level.

Outbound publishing is covered under `integration/messaging` (if loaded).

## Scan Patterns

**Kafka:**
- `@KafkaListener(topics = "...")` (Spring)
- `consumer.subscribe(["..."])` (Node kafkajs / Python confluent-kafka)
- `sarama.NewConsumerGroup(...)` (Go)

**RabbitMQ / AMQP:**
- `@RabbitListener(queues = "...")` (Spring AMQP)
- `channel.consume("...", ...)` (Node amqplib)
- `queue.consume(...)` (Python pika)

**SQS / SNS:**
- `Consumer.create({ queueUrl: ... })` (Node sqs-consumer)
- `ReceiveMessage` polling loops (Go SDK)
- Lambda event source mappings (from `serverless.yml` / CDK / Terraform)

**NATS:**
- `nats.subscribe("subject", ...)`
- JetStream pull consumers

**Redis Streams:**
- `XREADGROUP` calls / consumer group setup

**Webhook receivers (inbound HTTP as events):**
- `/webhooks/*` route group — cross-reference `http-api`

## Extraction Rules

1. **Transport summary** — which event systems are in play (one line per transport).
2. **Topic / queue inventory** — grouped by transport. Extract name + handler file.
3. **Retry / DLQ policy** — if configured (max attempts, DLQ destination). Say "default"
   if using library defaults.
4. **Idempotency notes** — if handlers document idempotency keys or dedup tables.
5. **Skip transports with zero consumers** — producing-only falls under
   `integration/messaging`.
6. **Skip if no event consumption exists.**

## Section Template

```markdown
## Event Consumers

**Transports:** Kafka (primary business events), SQS (async jobs), HTTP webhooks
(partner inbound)

### Kafka Consumers

| Topic | Handler | Consumer group |
|-------|---------|----------------|
| `orders.events` | `src/consumers/order-events.ts:12` | `orders-svc` [high] |
| `payment.settled` | `src/consumers/payment-settled.ts:8` | `orders-svc` [high] |
| `inventory.low-stock` | `src/consumers/inventory-alert.ts:15` | `orders-svc` [medium] |

### SQS Consumers

| Queue | Handler | Max attempts |
|-------|---------|--------------|
| `orders-async-jobs` | `src/consumers/async-jobs.ts:5` | 3 + DLQ `orders-async-jobs-dlq` [high] |

### Webhook Receivers

See `/webhooks` route group in HTTP API Surface. All webhooks are HMAC-signed; signature
verified by `verifyWebhookSignature` middleware. [high]

### Idempotency

- Order event handlers dedupe via `processed_events` table with unique `event_id` [high]
- SQS handlers rely on FIFO + MessageGroupId; no app-level dedup [medium]
```

## Confidence Tags

- `[high]` — listener annotation / subscribe call verified in code
- `[medium]` — consumer group / retry config inferred from library defaults
- `[low]` — topic mentioned in docs only
- `[inferred]` — avoid
