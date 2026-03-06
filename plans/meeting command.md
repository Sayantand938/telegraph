This document outlines the implementation for the **Meeting Module**, following the "Plug-and-Play" architecture of your Telegraph app. It mirrors the grammar and logic of your Time and Finance modules.

---

### 1. Database Schema
Consistent with your other modules, we use a main table and a tag-junction system.

**Table: `meeting_sessions`**
*   `id`: INTEGER (PK)
*   `title`: TEXT (Required)
*   `start_time`: TEXT (ISO8601)
*   `end_time`: TEXT (ISO8601, Nullable)
*   `participants`: TEXT (Stores `@names` as a string)
*   `notes`: TEXT (Nullable)
*   `location`: TEXT (Default: 'Remote')

**Tagging (Mirrored):**
*   `meeting_tags`: `id`, `name`
*   `meeting_session_tags`: `meeting_id`, `tag_id`

---

### 2. Command Structure
The module supports both "Live Tracking" and "Manual Logging."

| Command | Usage | Description |
| :--- | :--- | :--- |
| **Start** | `meeting start; [Title]; [Participants] #tags` | Starts a live meeting session. |
| **Stop** | `meeting stop` | Ends the current active meeting. |
| **Log** | `meeting log; [Date]; [Time to Time]; [Title]; [Participants] #tags` | Manually records a past meeting. |
| **Status** | `meeting status` | Shows if a meeting is currently running. |
| **List** | `meeting list [Date]` | Lists all meetings for a specific date. |

**Example Input:**
> `meeting log; yesterday; 14:00 to 15:00; Sprint Review; @Alice @Bob #scrum #work`

---

### 3. File Structure
To keep the module isolated, all files go into a new feature folder:

```text
lib/features/meetings/
├── models/
│   └── meeting_model.dart          (Data class with fromMap/toMap)
├── services/
│   ├── meeting_database_service.dart (SQL logic: create, insert, query)
│   └── meeting_command_handler.dart  (Regex parsing & logic routing)
└── utils/
    └── meeting_formatter.dart       (JSON response formatting)
```

---

### 4. Integration Plan
Since your app is modular, adding this takes exactly **3 steps**:

1.  **Define Model & Service:** Create the logic to save `@participants` and `title`.
2.  **Logic Parsing:** Use `CommandService.getArgument` and Semicolon splitting (like Finance) to extract data.
3.  **Plug-in:** Add the handler to the registry in `chat_screen.dart`:

```dart
// lib/features/chat/screens/chat_screen.dart

_commandService = CommandService([
  TimeCommandHandler(TimeDatabaseService.instance),
  FinanceCommandHandler(FinanceDatabaseService.instance),
  MeetingCommandHandler(MeetingDatabaseService.instance), // <-- Plugged in
]);
```

---

### 5. Shared Utility Strategy
To make the Meeting module truly "Plug-and-Play" and clean up your code:
*   **Move** `DateParser` from `features/time/utils/` to `core/utils/`.
*   **Move** `TimeFormatter.formatDate` to `core/utils/`.

This allows the Meeting module to use date parsing without "borrowing" from the Time module.

**Would you like me to generate the full code for the `MeetingCommandHandler` and `DatabaseService` now?**