// lib/core/utils/response_codes.dart

/// Success codes for tracking successful operations
/// Format: MODULE_XXX (e.g., TIME_001, FIN_001)
enum SuccessCode {
  // Global
  success('SUCCESS_001', 'Operation completed successfully'),
  deleted('DEL_001', 'Item deleted'),
  logged('LOG_001', 'Entry logged'),

  // Time Module
  sessionStarted('TIME_001', 'Time session started'),
  sessionStopped('TIME_002', 'Time session stopped'),
  sessionLogged('TIME_003', 'Time session logged'),

  // Meeting Module
  meetingStarted('MEET_001', 'Meeting started'),
  meetingStopped('MEET_002', 'Meeting ended'),
  meetingLogged('MEET_003', 'Meeting logged'),

  // Task Module
  taskAdded('TASK_001', 'Task added'),
  taskCompleted('TASK_002', 'Task marked as done'),
  taskLogged('TASK_003', 'Task logged'),

  // Finance Module
  transactionLogged('FIN_001', 'Transaction recorded'),
  transactionDeleted('FIN_002', 'Transaction deleted');

  final String code;
  final String message;
  const SuccessCode(this.code, this.message);
}

/// Error codes for tracking and debugging failures
/// Format: ERR_XXX or MODULE_ERR_XXX
enum ErrorCode {
  // Global Errors
  unknown('ERR_001', 'Unknown error occurred'),
  invalidFormat('ERR_002', 'Invalid command format'),
  notFound('ERR_003', 'Resource not found'),
  alreadyActive('ERR_004', 'Session already active'),
  noActiveSession('ERR_005', 'No active session'),
  validationFailed('ERR_006', 'Validation failed'),
  timeout('ERR_007', 'Operation timed out'),

  // Database Errors
  databaseError('DB_001', 'Database operation failed'),
  initializationError('DB_002', 'Database initialization failed'),

  // Time Module Errors
  timeParseError('TIME_ERR_001', 'Failed to parse time'),
  dateParseError('TIME_ERR_002', 'Failed to parse date'),

  // Meeting Module Errors
  participantError('MEET_ERR_001', 'Failed to process participants'),

  // Task Module Errors
  taskError('TASK_ERR_001', 'Task operation failed'),

  // Finance Module Errors
  amountError('FIN_ERR_001', 'Invalid amount'),
  typeError('FIN_ERR_002', 'Invalid transaction type');

  final String code;
  final String message;
  const ErrorCode(this.code, this.message);
}
