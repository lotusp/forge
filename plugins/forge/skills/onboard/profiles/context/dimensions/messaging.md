---
name: messaging
output-file: conventions.md
applies-to:
  - web-backend
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py}"
  - grep: "(kafka|rabbitmq|amqp|sqs|sns|nats|pulsar|@KafkaListener|@RabbitListener)"
  - glob: "**/consumers/**"
  - glob: "**/producers/**"
  - glob: "**/events/**"
confidence-signals:
  - messaging client dep present
  - consumer / producer modules identifiable
  - schema registry / event catalog visible
token-budget: 900
---

# Dimension: Messaging & Events

## Scan Patterns

**Transport detection:**

| Evidence | Transport |
|----------|-----------|
| `kafkajs` / `@kafkajs/*` / `sarama` | Kafka |
| `amqplib` / `spring-rabbit` / `go-amqp` | RabbitMQ |
| `@aws-sdk/client-sqs` / `aws-sdk sqs` | SQS |
| `@aws-sdk/client-sns` | SNS |
| `nats` / `nats.go` | NATS |
| `pulsar-client` | Pulsar |
| `redis XADD` / `XREADGROUP` | Redis Streams |

**Consumer identification:**
```
Glob "**/consumers/**" / "**/listeners/**"
Grep "@KafkaListener" / "@RabbitListener" / "consumer.subscribe"
```

**Producer identification:**
```
Grep "producer.send" / "kafkaTemplate.send" / "rabbitTemplate.convertAndSend" /
     "channel.publish" / "sqsClient.send"
```

**Schema governance:**
- `schemas/**/*.avsc` → Avro with registry
- `proto/**/*.proto` → Protobuf
- `schemas/**/*.json` → JSON Schema, often with Zod / AJV validation
- No schemas → ad-hoc payloads

**Reliability patterns:**
- Outbox table: `event_outbox` / `outbox_events`
- Debezium CDC config
- DLQ conventions: `<topic>.dlq` / `<queue>-dlq`
- Idempotency keys: `processed_events` dedup table

## Extraction Rules

1. Identify **transports in use** (there may be multiple)
2. Separate **consumer inventory** (topics / queues subscribed) from
   **producer inventory** (topics / queues published to)
3. Document **schema governance** approach
4. Document **delivery guarantees** (at-least-once, exactly-once via
   outbox, fire-and-forget)
5. Document **retry / DLQ** conventions
6. Document **partitioning strategy** (by entity ID, by tenant, etc.)

## Output Template

```markdown
## Messaging & Events

**Transports:** <Kafka (business events), SQS (async jobs), ...> [high] [build]

### Consumers

Consumer files live in `<src/consumers/ | src/listeners/>`. [high] [code]

**Conventions:**
- One consumer = one topic/queue; no multi-subject consumers [high] [code]
- Consumer handler signature: `(message) => Promise<void>`; thrown
  errors cause retry [high] [code]
- Idempotency enforced via `<processed_events table | message dedup
  library>` [medium] [code]

### Producers

Producer calls centralized in service layer. Handlers do NOT publish
events directly. [high] [code]

**Conventions:**
- Outbox pattern for at-least-once business events (write DB + outbox row
  in same tx; Debezium CDC to Kafka) [high] [code]
- Fire-and-forget for low-value async jobs (SQS with 3-retry + DLQ)
  [medium] [code]
- Partitioning key: `<entity ID such as orderId / customerId>` for
  ordering guarantees [high] [code]

### Schema governance

- Format: <Avro | Protobuf | JSON Schema> [high] [build]
- Registry: <Confluent Schema Registry | Buf Schema Registry | None>
  [medium] [build]
- Version policy: <backward-compatible changes only | breaking changes
  require new topic> [medium] [readme]

### Retry / DLQ

- Default: <N retries with exponential backoff> [high] [code]
- DLQ naming: `<topic>.dlq` / `<queue>-dlq` [high] [code]
- DLQ monitoring: <metric / alert> [medium] [build]

### What to avoid

- Publishing events inside controllers (use services)
- At-least-once consumer without idempotency protection (double-processing
  risk)
- Silent message drops in catch blocks
- Schema changes that break older consumers without coordination
```

## Confidence Tags

- `[high]` — transport client in deps AND ≥ 3 consumers OR producers observed
- `[medium]` — transport in use but patterns inconsistent
- `[low]` — single consumer/producer; patterns not codified
- `[inferred]` — transport in docker-compose but no code consumes it yet
