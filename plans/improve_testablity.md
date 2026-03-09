# Testability Improvement Roadmap

## Phase 1: Foundation (Week 1-2)
**Goal:** Establish testing infrastructure and patterns

- [x] Set up test dependencies (mockito/mocktail, test, flutter_test)
- [ ] Create test directory structure:
  - `test/unit/` for pure unit tests
  - `test/integration/` for database tests
  - `test/fixtures/` for test data
- [ ] Define testing conventions and documentation
- [ ] Add CI/CD pipeline configuration for running tests

## Phase 2: Refactor Core Services (Week 3-4)
**Goal:** Enable dependency injection and mocking

- [x] Create abstract interfaces for all database classes:
  - `ISessionDatabase`
  - `IFinanceDatabase`
  - `IBaseDatabase<T>`
- [x] Refactor `ToolService` to accept dependencies via constructor
- [x] Update singleton implementations to support instance injection
- [ ] Add factory pattern for test vs production instances

## Phase 3: Database Layer Testing (Week 5-6)
**Goal:** Comprehensive database test coverage

- Implement in-memory SQLite database for tests
- Write unit tests for `BaseDatabase` CRUD operations
- Test `SessionDatabase` specific methods:
  - `endSession()` (including midnight splitting logic)
  - `hasOverlap()` detection
- Test `FinanceDatabase` query methods:
  - `getTransactionsByDateRange()`
  - `getTotalByType()`
- Create test fixtures for common scenarios

## Phase 4: Tool Layer Testing (Week 7-8)
**Goal:** Isolated tool function tests

- Create mock implementations of database interfaces
- Write unit tests for all session tools:
  - `start_session`, `end_session`, `list_sessions`, etc.
- Write unit tests for all finance tools:
  - `add_transaction`, `list_transactions`, `get_financial_summary`, etc.
- Test error handling and edge cases
- Achieve >80% code coverage for tool layer

## Phase 5: Model & Serialization Tests (Week 9)
**Goal:** Ensure data integrity

- Write tests for `Session` model:
  - `toMap()`, `fromMap()`, `copyWith()`
- Write tests for `FinanceTransaction` model
- Test enum serialization (TransactionType)
- Validate database schema migrations (if any)

## Phase 6: Integration & E2E (Week 10)
**Goal:** Full-stack validation

- Write integration tests combining tools + real database
- Test complete workflows (e.g., start session → add transactions → get summary)
- Add flutter_test widget tests for UI components
- Performance testing for database operations

## Phase 7: Quality Gates (Ongoing)
**Goal:** Maintain testability standards

- Enforce minimum 80% code coverage
- Add pre-commit hooks to run tests
- Document testing patterns and best practices
- Regular test review in code reviews
- Add mutation testing to verify test effectiveness

## Success Metrics
- Unit test coverage: >80%
- All critical paths covered
- Tests run in <5 minutes
- Zero singleton dependencies in production code
- All external dependencies injectable