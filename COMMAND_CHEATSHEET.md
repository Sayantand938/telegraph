This cheat sheet covers all the active modules in **Alison CLI**. 

### 💡 Global Syntax Rules
*   **Notes:** Must be enclosed in double quotes: `"My Note"`.
*   **Tags:** Start with `#` (e.g., `#work`, `#urgent`).
*   **Participants:** Start with `@` (e.g., `@boss`, `@team`).
*   **Dates:** Supports `today`, `yesterday`, `last monday`, or `YYYY-MM-DD`.
*   **Duration:** Supports `2h`, `1.5h`, `45m`, `1h 30m`.
*   **Time Range:** Format as `HH:mm-HH:mm` (e.g., `09:00-11:30`).

---

### 🕒 Time Tracking (`time`)
| Command | Syntax |
| :--- | :--- |
| **Start** | `time start ["Note"] #tags` |
| **Stop** | `time stop` |
| **Log (Manual)** | `time log [date] [range/duration] ["Note"] #tags` |
| **Status** | `time status` |
| **List** | `time list [date]` |
| **Summary** | `time summary [date]` |
| **Stats** | `time stats [date]` |
| **Delete** | `time delete [id]` |

---

### 🤝 Meetings (`meeting`)
| Command | Syntax |
| :--- | :--- |
| **Start** | `meeting start ["Topic"] @people #tags` |
| **Stop** | `meeting stop` |
| **Log (Manual)** | `meeting log [date] [range/duration] ["Topic"] @people #tags` |
| **Status** | `meeting status` |
| **List** | `meeting list [date]` |
| **Summary** | `meeting summary [date]` |
| **Delete** | `meeting delete [id]` |

---

### 💰 Finance (`finance`)
| Command | Syntax |
| :--- | :--- |
| **Log Expense** | `finance log expense [amount] [date] ["Note"] #tags @people` |
| **Log Income** | `finance log income [amount] [date] ["Note"] #tags` |
| **List** | `finance list [date]` |
| **Summary** | `finance summary [date]` |
| **Stats** | `finance stats [date]` |
| **Delete** | `finance delete [id]` |

---

### ✅ Tasks (`task`)
| Command | Syntax |
| :--- | :--- |
| **Add** | `task add ["The Task"] #tags @people` |
| **Mark Done** | `task done [id]` |
| **Log (Backdated)** | `task log [date] ["The Task"] #tags` |
| **List** | `task list [today/all/completed]` |
| **Delete** | `task delete [id]` |

---

### 😴 Sleep Tracking (`sleep`)
| Command | Syntax |
| :--- | :--- |
| **Start** | `sleep start ["Note"] #tags` |
| **Stop** | `sleep stop` |
| **Log (Manual)** | `sleep log [date] [range/duration] ["Note"] #tags` |
| **Status** | `sleep status` |
| **List** | `sleep list [date]` |
| **Summary** | `sleep summary [date]` |
| **Stats** | `sleep stats [date]` |
| **Delete** | `sleep delete [id]` |

---

### 🛠 System Commands
| Command | Syntax |
| :--- | :--- |
| **Help** | Just type `help` or send an empty message to see all commands. |

### 📝 Example Usage:
*   *Track current work:* `time start "Refactoring DB" #dev`
*   *Log yesterday's sleep:* `sleep log yesterday 23:00-07:00 "Deep sleep" #recovery`
*   *Record lunch expense:* `finance log expense 450 today "Team Lunch" @alice #food`
*   *Set a task:* `task add "Fix memory leak" #urgent`