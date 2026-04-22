---
name: messaging
section: Messaging & Events
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - Kafka / RabbitMQ / SQS / NATS client in deps
  - producer call sites (send / publish / emit)
  - schema registry configuration
token-budget: 900
---

# Profile: Messaging & Events

## Scope

Covers **outbound** event publishing and **messaging infrastructure overview**:

- Which message systems are in use
- Topics / queues this system produces to
- Schema registry / contract governance (if any)
- Ordering / partitioning strategy

Inbound consumption is covered in `entry-points/event-consumers`. Load both profiles
when the system is event-driven.

## Scan Patterns

**Producer call sites:**

- Kafka: `producer\.send\(` / `kafkaTemplate\.send\(`
- RabbitMQ: `channel\.publish\(` / `rabbitTemplate\.convertAndSend\(`
- SQS: `sqs\.sendMessage\(` / `sqsClient\.send\(new SendMessageCommand`
- NATS: `nc\.publish\(` / `js\.publish\(`
- Redis streams: `XADD`

**Schema / contract signals:**

- `avro/*.avsc` / `proto/*.proto` / `schemas/*.json`
- confluent schema registry URL in config (redact specifics)
- `@SchemaMapping` / `@KafkaProtobufSerializer`

**Outbox / reliability patterns:**

- `outbox` / `event_outbox` table
- Debezium CDC config
- transactional-outbox library (`@nestjs-cloud/outbox`, etc.)

## Extraction Rules

1. **Transport summary** — one line: "Kafka for business events, SQS for async jobs,
   internal NATS for pub-sub".
2. **Produced topics** — inventory grouped by transport, with producer location.
3. **Schema governance** — state how contracts are managed (registry / repo schemas /
   ad-hoc JSON).
4. **Reliability** — at-least-once / exactly-once / outbox / fire-and-forget.
5. **Redact** broker URLs, schema registry hosts, auth credentials per C8.

## Section Template

```markdown
## Messaging & Events

**Transports in use:** Kafka (primary domain events), SQS (async job dispatch)

### Produced Topics

| Transport | Topic | Producer | Semantics |
|-----------|-------|----------|-----------|
| Kafka | `orders.events` | `src/services/order.ts:44` | at-least-once, partitioned by orderId [high] |
| Kafka | `payment.settled` | `src/services/payment.ts:89` | at-least-once, partitioned by orderId [high] |
| SQS | `orders-async-jobs` | `src/services/order.ts:118` | FIFO, MessageGroupId = customerId [high] |

### Schema Governance

- Kafka topics: JSON Schema files in `schemas/kafka/*.json`, version-bumped manually [high]
- Schema registry: hosted (host redacted per C8); enforced in staging + prod [medium]
- SQS payloads: Zod schema validation at producer boundary [high]

### Reliability

- Transactional outbox via `event_outbox` table; CDC to Kafka by Debezium [high]
- SQS producer has no outbox — fire-and-forget with 3-retry wrapper [medium]
- DLQ per topic: `<topic>.dlq` convention [medium]
```

## Confidence Tags

- `[high]` — producer call + topic name verified in source
- `[medium]` — producer inferred from library presence
- `[low]` — mentioned in docs only
- `[inferred]` — avoid
