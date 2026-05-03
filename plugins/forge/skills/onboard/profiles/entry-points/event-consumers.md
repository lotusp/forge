---
name: event-consumers
section: Event Consumers
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - Kafka / RabbitMQ / SQS / NATS / Azure Service Bus client deps
  - consumer registration files (src/consumers/ / src/listeners/)
  - @KafkaListener / @RabbitListener / @MessageListener / @ServiceBusListener annotations
  - cron expressions in application.yml without @Scheduled in code (external scheduler signal)
must-grep:
  - '@(KafkaListener|RabbitListener|JmsListener|SqsListener|StreamListener|MessageListener|ServiceBusListener|EventHubConsumer|Consumer)\b'
  - 'implements ApplicationListener\b'
  - '@EventListener\b'
  - '@TransactionalEventListener\b'
must-cross-check:
  - if-zero: '@Scheduled\b'
    and-config-has: '*_cron|cron:'
    then-emit: 'No @Scheduled in code but cron configs exist — service likely triggered by an external scheduler via messaging queue (cross-reference Notes)'
detectors:
  - detector-id: ms_listeners
    detector-script: ms_listeners.sh
    rendered-as: count
  - detector-id: application_listeners
    detector-script: application_listeners.sh
    rendered-as: count
token-budget: 1100
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

**Azure Service Bus (Microsoft + custom starters):**
- `@ServiceBusListener("queue-name")` (`com.microsoft.azure.servicebus`)
- `@MessageListener("queue.name")` / `@MessageListener(QUEUE_NAME)`
  (custom in-house Service Bus starters; also bare `@Consumer`
  annotation marking handler methods)
- `@EventHubConsumer` (Azure Event Hubs)

**Generic Spring messaging:**
- `@JmsListener(destination = "...")` (Spring JMS)
- `@StreamListener("input-channel")` (Spring Cloud Stream — deprecated
  but still in many older services)
- `@SqsListener(value = "...")` (`spring-cloud-aws`)

**Webhook receivers (inbound HTTP as events):**
- `/webhooks/*` route group — cross-reference `http-api`

**Internal Spring application events (THREE tracks — all three MUST be greped):**
- `class Foo implements ApplicationListener<FooEvent>` (interface form)
- `@EventListener` on a method (annotation form)
- `@TransactionalEventListener` on a method (transaction-bound variant)

> A prior real-world review found a doc claiming 7
> `ApplicationListener<T>` implementations while the actual code had
> 0 of those and 7 `@EventListener` methods. Three-track grep prevents
> this misclassification.

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
6. **Internal application events — three-track classification.** When listing
   internal listeners, the `Mechanism` column MUST report the actual
   form found by grep (not "Spring ApplicationEvent" by default):
   - "implements `ApplicationListener<T>`"
   - "`@EventListener` method"
   - "`@TransactionalEventListener` method"
   Counting these via `application_listeners` detector is preferred over
   eyeballing the code base.
7. **Skip transports with zero consumers** — producing-only falls under
   `integration/messaging`.
8. **External-scheduler inference (cross-check).** If `@Scheduled` grep
   returns 0 but `application*.yml` contains cron-like keys
   (`*_cron`, `cron:`), mention "no in-process scheduler; the cron
   keys imply an external scheduler triggers this service via a
   messaging queue" in Notes. Do NOT silently drop the cron config.
9. **Skip if no event consumption exists** — but only after the
   must-grep patterns above have all returned 0. Do not skip on
   intuition; record the grep evidence in JOURNAL when the profile
   is skipped (Step 1.3 Skip Tier 2).

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

### Azure Service Bus Inbound (NEW)

| Queue / Topic | Handler | Mechanism |
|---------------|---------|-----------|
| `queue.example.scheduler_to_service` | `SchedulerMessageListener` | `@MessageListener` + `@Consumer` (custom starter) [high] |

### Internal Application Events (three-track)

| Event / Signal | Listener | Mechanism |
|----------------|----------|-----------|
| `ProductCreatedEvent` | `ProductCreatedListener` | `implements ApplicationListener<ProductCreatedEvent>` [high] |
| `OrderInvoicedEvent` | `OrderInvoicedHandler.onInvoiced(...)` | `@EventListener` method [high] |
| `PaymentCommittedEvent` | `PaymentEventBridge.onCommit(...)` | `@TransactionalEventListener` method [high] |

### Idempotency

- Order event handlers dedupe via `processed_events` table with unique `event_id` [high]
- SQS handlers rely on FIFO + MessageGroupId; no app-level dedup [medium]
```

## Confidence Tags

- `[high]` — listener annotation / subscribe call / registration verified in code
- `[medium]` — consumer found but retry, group, or visibility partially verified
- `[low]` — topic mentioned in docs only
- `[inferred]` — avoid
