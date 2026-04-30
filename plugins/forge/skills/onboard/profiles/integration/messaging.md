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

- Which message systems are in use, as evidenced by dependencies/config/code
- Topics / queues this system produces to, if producer call sites are found
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

1. **Direction first.** Keep produced topics/queues separate from consumed
   topics/queues. If direction is unclear, mark it as unclear instead of
   choosing.
2. **Transport summary** — one line per transport actually evidenced.
3. **Produced topics** — inventory grouped by transport, with producer location.
   Do not list a topic as produced unless a producer call/config is found.
4. **Schema governance** — state how contracts are managed (registry / repo
   schemas / ad-hoc JSON) only when evidenced.
5. **Reliability** — at-least-once / exactly-once / outbox / fire-and-forget
   only when code/config/docs support the claim.
5. **Redact** broker URLs, schema registry hosts, auth credentials per C8.

## Section Template

```markdown
## Messaging & Events

**Transports in use:** Kafka, SQS [medium] [build]

### Produced Topics

| Transport | Topic | Producer | Semantics |
|-----------|-------|----------|-----------|
| Kafka | `orders.events` | `src/services/order.ts:44` | semantics observed in producer/config [high] |
| SQS | `orders-async-jobs` | `src/services/order.ts:118` | semantics observed in producer/config [medium] |

### Schema Governance

- Kafka topics: JSON Schema files in `schemas/kafka/*.json` [high]
- Schema registry: <observed registry integration, host redacted per C8> [medium]
- SQS payloads: validation observed at producer boundary [medium]

### Reliability

- Transactional outbox via `event_outbox` table; CDC to Kafka by Debezium [high]
- SQS producer uses retry wrapper observed in code [medium]
- DLQ convention: `<topic>.dlq` only if documented/configured [medium]

### Direction Gaps

- <topic/queue name found in config but direction not verified> [medium] [config]
```

## Confidence Tags

- `[high]` — producer call + topic name verified in source with no conflict
- `[medium]` — transport/topic found but semantics or direction partially verified
- `[low]` — mentioned in docs only
- `[inferred]` — avoid
