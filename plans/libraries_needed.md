## Recommended Libraries for Standardization

### **Dependency Injection**
- **`get_it`** - Service locator for dependency injection
- **`injectable`** - Code generation for type-safe DI (works with get_it)

### **State Management** (if UI grows)
- **`riverpod`** - Modern, compile-safe state management
- **`flutter_bloc`** - BLoC pattern for predictable state

### **Testing & Mocking**
- **`mocktail`** - Null-safe mocking (preferred over mockito)
- **`bloc_test`** - If using BLoC pattern
- **`integration_test`** - For E2E tests

### **Code Quality**
- **`dart_code_metrics`** - Static analysis with rules
- **`custom_lint`** - Custom lint rules
- **`very_good_analysis`** - Comprehensive analysis set

### **Data Layer**
- **`drift`** (formerly Moor) - Type-safe SQLite abstraction
- **`json_serializable`** - Code gen for JSON parsing
- **`freezed`** - Union types, immutability, copyWith

### **Error Handling**
- **`faulty`** - Functional error handling (Either/Result types)
- **`dartz`** - Functional programming utilities

### **Logging**
- **`logger`** - Pretty, configurable logging

### **Validation**
- **`formz`** - Form validation with BLoC integration
- **`validators`** - Simple validation functions

### **Architecture**
- **`clean_architecture`** - Package for clean architecture layers
- **`domain-driven-design`** - DDD value objects, entities

## Current Project Priority
Given your current architecture, start with:
1. **`get_it` + `injectable`** - To break singleton dependencies
2. **`mocktail`** - For unit testing databases and tools
3. **`dart_code_metrics`** - To enforce coding standards
4. **`logger`** - Replace `dart:developer` with structured logging