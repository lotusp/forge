# Conflict Adjudication Examples

This file provides example adjudication dialogues for common convention
conflicts. Referenced by `/forge:calibrate` Step 5 to guide consistent
formatting and reasoning.

All examples use fictional service names. Replace with actual module names
found in the project under calibration.

---

## Example 1 — URL Versioning

```
[FORGE:CALIBRATE] Convention conflict 1 of 3

Dimension: URL versioning

Pattern A — used in app-core-service, app-order-service (24 controllers):
  All routes prefixed with /api/v2/
  Examples: /api/v2/users, /api/v2/orders/{id}
  (src/main/java/com/example/core/controller/UserController.java:18,
   src/main/java/com/example/order/controller/OrderController.java:22)

Pattern B — used in app-report-service (3 controllers):
  Routes prefixed with /api/ (no version segment)
  Examples: /api/reports, /api/reports/{id}/export
  (src/main/java/com/example/report/controller/ReportController.java:14)

Recommendation: Pattern A
Reason: Pattern A is used in 24 of 27 controllers. Versioned URLs allow
future API evolution without breaking existing clients. app-report-service
appears to be newer code that missed the convention.

Options:
  1. Adopt Pattern A for all new code: new routes use /api/v2/ (recommended)
  2. Adopt Pattern B for all new code: new routes use /api/
  3. Allow both — context-dependent
  4. Neither — describe what you want instead

Your choice:
```

**Typical resolution:** User chooses 1. Record in Decision Log:
> URL versioning: adopt /api/v2/ prefix for all new routes.
> app-report-service to migrate in a future cleanup task.
> Source: user decision 2024-01-15.

---

## Example 2 — Transaction Boundaries

```
[FORGE:CALIBRATE] Convention conflict 2 of 3

Dimension: Transaction boundaries

Pattern A — used in 18 Service classes:
  @Transactional on Service method only; Repository has no @Transactional
  (src/main/java/com/example/core/service/UserService.java:45,
   src/main/java/com/example/order/service/OrderService.java:62)

Pattern B — used in ItemRepository and 2 other Repository classes:
  @Transactional also on Repository save methods (redundant with Pattern A)
  (src/main/java/com/example/inventory/repository/ItemRepository.java:28)

Recommendation: Pattern A
Reason: @Transactional belongs on the Service layer where the business unit
of work is defined. Repository-level @Transactional is redundant and creates
ambiguity about which boundary is authoritative.

Options:
  1. @Transactional on Service methods only — Repositories are non-transactional (recommended)
  2. @Transactional on both Service and Repository methods
  3. Allow both — context-dependent
  4. Neither — describe what you want instead

Your choice:
```

---

## Example 3 — Test Isolation Strategy

```
[FORGE:CALIBRATE] Convention conflict 3 of 3

Dimension: Test isolation strategy

Pattern A — used in 35 integration test classes:
  @Transactional on test class → Spring rolls back after each test
  (src/test/java/com/example/core/UserServiceIntegrationTest.java:12,
   src/test/java/com/example/order/OrderIntegrationTest.java:8)

Pattern B — used in 4 integration test classes:
  No @Transactional; manual DELETE in @AfterEach
  (src/test/java/com/example/notification/NotificationIntegrationTest.java:15)

Recommendation: Pattern A
Reason: @Transactional rollback is simpler, faster, and more reliable.
Manual DELETE is error-prone if test fails before @AfterEach runs.
Pattern B tests may have been written before Pattern A was established.

Options:
  1. Use @Transactional rollback for all integration tests (recommended)
  2. Use manual teardown in @AfterEach for all integration tests
  3. Allow both — @Transactional for simple tests, manual teardown when
     test needs to verify committed data (e.g. async event processing)
  4. Neither — describe what you want instead

Your choice:
```

---

## Example 4 — Logger Declaration (no conflict)

Not all dimensions produce conflicts. For single-pattern dimensions, use
the confirmation format:

```
[FORGE:CALIBRATE] Confirming established patterns

The following patterns were observed consistently. Correct any that are
wrong or should not apply to new code.

Logging: @Slf4j annotation on all classes; `log` as the field name
  → Correct? (yes / correct it)
  (src/main/java/com/example/core/service/UserService.java:14)

Error handling: Typed domain exceptions extend AppException; caught by
  GlobalExceptionHandler; error codes are string constants in ErrorCode.java
  → Correct? (yes / correct it)
  (src/main/java/com/example/common/exception/AppException.java:1,
   src/main/java/com/example/common/GlobalExceptionHandler.java:20)
```

---

## Decision Log Format

Every adjudicated decision is appended to `.forge/_session/calibrate-scan.md` under:

```markdown
## Adjudication Log

| # | Dimension | Decision | Reason | Date |
|---|-----------|----------|--------|------|
| 1 | URL versioning | Adopt /api/v2/ for all new routes | Dominant pattern (24/27 controllers); enables future versioning | 2024-01-15 |
| 2 | Transaction boundaries | @Transactional on Service only | Clearer ownership; Repository-level is redundant | 2024-01-15 |
| 3 | Test isolation | @Transactional rollback; allow manual teardown only for async tests | User-specified exception for async scenarios | 2024-01-15 |
```
