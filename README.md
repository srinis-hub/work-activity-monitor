# Work Activity Monitor

# Developer
>Srinivasa Perumal J
>Flutter Dev

>  **Project Status: PHASE 1 — Foundation Complete**
>
> Phase 1 focuses on establishing the core Windows monitoring, authentication,
> session tracking, and Firebase data persistence foundation.
>
> This project is actively under development. Additional features and
> improvements will be introduced in upcoming phases.


#  IMPORTANT RULES — PLEASE FOLLOW

> **These rules are mandatory for everyone working on this project.**
> Please follow the Git workflow carefully to avoid conflicts, accidental
> changes, or issues with stable code.

###  Always use a separate branch

Always create and use a separate branch for:

- R&D
- New implementations
- Feature development
- Bug fixes
- Experiments
- Refactoring

**Never directly implement or experiment on the `development` or `production` branch.**


##  Overview

**Work Activity Monitor** is a Flutter-based Windows desktop application
designed to monitor application activity during manually started work
sessions.

The application tracks the active application and window currently being
used and organizes the collected activity into work sessions. Session data
is securely associated with the authenticated user and stored in Firebase
for future reporting and analytics.

The long-term goal is to build a scalable work activity monitoring and
analytics platform with automated reporting and insights.

---

##  Phase 1 — Foundation

### Completed

- [x] Flutter Windows desktop application setup
- [x] Modern Login UI
- [x] Firebase initialization
- [x] Firebase Authentication
- [x] Email/password authentication
- [x] User logout
- [x] Windows active application detection
- [x] Active window title detection
- [x] Application activity tracking
- [x] Activity session creation
- [x] Work session start/stop functionality
- [x] Activity duration calculation
- [x] Application-wise activity summary
- [x] Firestore integration
- [x] Daily work-day data structure
- [x] User-specific Firestore data
- [x] Session persistence
- [x] Daily session counters
- [x] Daily total duration tracking
- [x] Clean project structure
- [x] Separation of presentation, data, services, and models

---

##  Architecture

The current architecture follows a layered approach:

```text
Flutter Windows Application
          │
          ├── Presentation
          │     ├── Authentication
          │     └── Activity Monitor
          │
          ├── Core
          │     ├── Models
          │     ├── Services
          │     └── Utilities
          │
          └── Data
                └── Repositories
                       │
                       ▼
                 Firebase
                ┌──────┴──────┐
                ▼             ▼
          Authentication   Firestore