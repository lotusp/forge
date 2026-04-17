# Convention Dimensions Reference

This file provides detailed guidance for each convention dimension scanned
by `/forge:calibrate`. Referenced by SKILL.md Step 2.

---

## 1. Architecture & Layering

**Goal:** Determine which layer owns which concern, and which import directions
are permitted.

**What to look for:**
- Does application logic live in Services, or does it leak into Controllers or
  Repositories?
- Do Repositories get injected into Controllers directly (anti-pattern in
  layered architectures)?
- Are domain objects used in API responses directly, or are there separate DTOs?
- Service-to-service calls: direct injection vs Feign client vs event bus?

**Red flags:**
- `@Repository` injected into `@RestController`
- Business logic in `@EventListener` or consumer methods
- Domain entities returned directly from REST controllers (exposes internals)

**Output for conventions.md:**
```
### Architecture & Layering
- Controller → Service → Repository is the only permitted call direction
- Service-to-service communication uses Feign clients (not direct injection)
- DTOs are separate from domain entities; mapping happens in the Service layer
  Source: src/main/java/com/example/order/controller/OrderController.java:34,
          src/main/java/com/example/user/service/UserService.java:88
```

---

## 2. Naming

**Goal:** Codify the exact naming schemes in use so new code blends in.

**What to look for:**
- File and class names: `PascalCase`? `camelCase`? Suffix patterns (`Service`, `Impl`, `Manager`, `Helper`)?
- Method names: verb-first (`findById`, `createOrder`) or noun phrases?
- Variable names: full words vs abbreviations? Hungarian notation?
- Constants: `SCREAMING_SNAKE_CASE`? Enum names?
- DB table names: `snake_case`? `PascalCase`? Prefix conventions (`t_`, `tbl_`)?
- DB column names: `snake_case` vs `camelCase` in ORM mappings?
- Test class naming: `FooTest` vs `FooTests` vs `TestFoo`? Method naming pattern?

**Common inconsistencies to flag:**
- Mix of `findById` and `getById` for the same kind of operation
- Some tests use `FooTest`, others use `FooServiceTest`
- Plural vs singular table names

---

## 3. Logging

**Goal:** Establish what to log, how to declare loggers, and what fields are always present.

**What to look for:**
- Logger library: `@Slf4j`, `LoggerFactory`, `java.util.logging`, Winston, etc.
- Declaration style: annotation vs `private static final Logger log = ...`
- Log levels used: is `DEBUG` used locally only? Is `INFO` the production baseline?
- Structured fields: are there always-present fields (`userId`, `requestId`, `traceId`)?
- Are exceptions always logged with stack trace, or swallowed?
- MDC / correlation ID patterns

**Red flags:**
- Both `@Slf4j` annotation and manual `LoggerFactory` in the same file
- `catch (Exception e) { log.error("error"); }` — swallowed stack traces
- Logging PII (email, phone, ID number) at INFO or higher

---

## 4. Error Handling

**Goal:** Establish what exception types to throw and where errors are caught.

**What to look for:**
- Custom exception hierarchy: is there a base `AppException`? Domain-specific exceptions?
- Where are exceptions caught and translated to HTTP responses? `@ControllerAdvice`? Per-controller?
- Are checked vs unchecked exceptions used consistently?
- Service layer: throw exception or return `Result<T>` / `Optional<T>`?
- Are error codes numeric, string codes, or enum-based?

**Output pattern:**
```
### Error Handling
- Throw typed domain exceptions (extend AppException) from Service layer
- GlobalExceptionHandler (@ControllerAdvice) translates all exceptions to API responses
- Never catch and re-wrap exceptions in the Controller layer
  Source: src/common/exception/AppException.java:1,
          src/common/GlobalExceptionHandler.java:20
```

---

## 5. Validation

**Goal:** Determine when, where, and how inputs are validated.

**What to look for:**
- Validation library: Bean Validation (`@Valid`, `@NotNull`), custom validators, manual checks?
- Where is validation invoked: Controller boundary only, or also in Service?
- Error response format for validation failures: field-level errors? single message?
- Are DTOs validated on the way in, or domain objects?
- How are complex cross-field validations handled?

---

## 6. Testing

**Goal:** Establish test structure, isolation strategy, and naming conventions.

**What to look for:**
- Test file location: same package as production, or separate test package?
- Test class naming: `FooTest` / `FooTests` / `FooServiceTest`?
- Test method naming: `testMethod_condition_expectedResult`? `should_do_X_when_Y`? Free-form?
- Mock library: Mockito? MockK? Sinon? Manual stubs?
- Integration test isolation: `@Transactional` (rollback) vs manual DB teardown?
- Test data strategy: factories? builders? fixtures loaded from files?
- Are unit tests and integration tests in separate source sets or mixed?

**Mandatory check — test isolation strategy:**
If both `@Transactional` (rollback) and manual truncation exist, this is a
contradiction that must be adjudicated.

---

## 7. API Design

**Goal:** Document the URL structure, response envelope, and HTTP conventions.

**What to look for:**
- URL patterns: `/api/{resource}` vs `/api/v2/{resource}` vs `/v1/{resource}`?
- HTTP verbs: are `POST` for creation and `PUT`/`PATCH` for update used correctly?
- Response envelope: `{ code, message, data }` wrapper vs naked response body?
- Pagination: `page`/`size` query params? `cursor`? Response includes `total`?
- Error response structure: consistent JSON shape?
- Authentication: JWT in header? API key? How is the caller identified?

**Mandatory check — URL versioning:**
Scan all `@RequestMapping`/`@GetMapping`/router definitions. List all URL prefixes
found. If `/api/` and `/api/v2/` both exist, this is a mandatory contradiction.

---

## 8. Database Access

**Goal:** Establish how the application reads and writes to the DB.

**What to look for:**
- ORM vs raw SQL: JPA/Hibernate? MyBatis? JDBC template? QueryDSL?
- Repository pattern: Spring Data `JpaRepository`? Custom base repository?
- Are complex queries in JPQL, QueryDSL `Q` objects, or native SQL?
- Soft delete: is there a common `deleted_at` / `is_deleted` pattern?
- Transaction boundaries: `@Transactional` on Service, Repository, or both?
- N+1 query handling: `@EntityGraph`? `JOIN FETCH`? Explicit batching?

**Mandatory check — transaction boundaries:**
If `@Transactional` appears on both Repository and Service methods for the same
flow, this is a contradiction: who owns the transaction boundary?

---

## 9. Messaging & Events

**Goal:** Understand when internal events vs external queues are used.

**What to look for:**
- Internal event bus: Spring `ApplicationEventPublisher`? Guava EventBus?
- External MQ: Kafka? RabbitMQ? Azure Service Bus? AWS SQS?
- Which scenarios use internal events vs external MQ? (Common pattern: internal
  for same-service side effects, external for cross-service communication)
- Consumer/listener class structure: dedicated class per topic, or shared dispatcher?
- Error handling in consumers: dead letter queue? retry policy?
- Are events typed (strongly-typed event objects) or generic maps?
