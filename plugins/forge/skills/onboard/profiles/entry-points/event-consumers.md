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

Outbound publishing is covered under `integration/messaging` (if loaded). Do
not mix produced topics with consumed queues.

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

**Internal application events:**
- framework listener interfaces, decorators, observer registration, or event bus
  subscriptions
- transactional event listener annotations/hooks where present

## Extraction Rules

1. **Direction first.** Include only inbound consumers here. If a topic/queue is
   only produced by this service, route it to `integration/messaging`.
2. **Transport summary** — which event systems are in play (one line per
   transport).
3. **Consumer inventory** — grouped by transport/mechanism. Extract name,
   handler file, and annotation/registration mechanism from code.
4. **Retry / DLQ policy** — include only if configured in current repo. Do not
   write library defaults as project facts unless the default was verified.
5. **Idempotency notes** — include if handlers document idempotency keys,
   dedup tables, unique constraints, or explicit guard logic.
6. **Internal application events** — list framework/internal listeners separately
   from external messaging consumers.
7. **Skip transports with zero consumers** — producing-only falls under
   `integration/messaging`.
8. **Skip if no event consumption exists.**

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

### Internal Application Events

| Event / Signal | Listener | Mechanism |
|----------------|----------|-----------|
| `ProductCreatedEvent` | `ProductCreatedListener` | framework listener interface [high] |

### Idempotency

- Order event handlers dedupe via `processed_events` table with unique `event_id` [high]
- SQS handlers rely on FIFO + MessageGroupId; no app-level dedup [medium]
```

## Confidence Tags

- `[high]` — listener annotation / subscribe call / registration verified in code
- `[medium]` — consumer found but retry, group, or visibility partially verified
- `[low]` — topic mentioned in docs only
- `[inferred]` — avoid
