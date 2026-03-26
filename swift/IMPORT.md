# Anna Expenses — Data Import Guide

This document describes how to import data into the Anna Expenses Mac app.
An AI agent (e.g. Claude Code) can read a messy Excel/CSV file and convert it into the structured JSON format below.

## Where data lives

The app reads/writes JSON files in:
```
~/Library/Application Support/AnnaExpenses/
```

Files:
- `students.json`
- `teachers.json`
- `packages.json`
- `sessions.json` (class attendance records)
- `transactions.json` (income/payments received)
- `expenses.json` (outgoing costs)

**Important**: Close the app before writing these files. Reopen to load the new data.

## JSON Schemas

All dates use ISO 8601 format: `"2025-03-15T00:00:00Z"`
All IDs are UUID v4 strings: `"a1b2c3d4-e5f6-7890-abcd-ef1234567890"`

### students.json
```json
[
  {
    "id": "uuid",
    "name": "Student Name",
    "email": "optional@email.com",
    "phone": "+optional phone",
    "notes": "optional notes"
  }
]
```

### teachers.json
```json
[
  {
    "id": "uuid",
    "name": "Teacher Name",
    "email": "optional@email.com",
    "paymentDetails": "optional bank account info"
  }
]
```

### packages.json
A package is a bundle of classes a student purchased.
```json
[
  {
    "id": "uuid",
    "studentID": "uuid (references a student)",
    "name": "8-class bundle",
    "totalClasses": 8,
    "pricePaid": 500.0,
    "currency": "AED",
    "purchaseDate": "2025-01-15T00:00:00Z",
    "notes": "optional"
  }
]
```

### sessions.json
Each record = one class a student attended with a teacher, drawn from a package.
```json
[
  {
    "id": "uuid",
    "packageID": "uuid (references a package)",
    "studentID": "uuid (references a student)",
    "teacherID": "uuid (references a teacher)",
    "date": "2025-02-10T00:00:00Z",
    "notes": "optional"
  }
]
```

### transactions.json
Income — money received from students.
```json
[
  {
    "id": "uuid",
    "date": "2025-01-20T00:00:00Z",
    "amount": 500.0,
    "currency": "AED",
    "description": "Payment for 8-class package",
    "studentID": "uuid or null",
    "packageID": "uuid or null",
    "source": "manual"
  }
]
```
`source` is either `"manual"` or `"csvImport"`.

### expenses.json
Outgoing costs — rent, marketing, admin, teacher payments, etc.
```json
[
  {
    "id": "uuid",
    "date": "2025-02-01T00:00:00Z",
    "amount": 1000.0,
    "currency": "AED",
    "category": "rent",
    "description": "Office rent February",
    "notes": "optional"
  }
]
```
`category` must be one of: `"Marketing"`, `"Rent"`, `"Admin"`, `"Teacher Payment"`, `"Other"`.

## How to import

1. Read the source Excel/CSV file
2. Identify students, teachers, packages, class sessions, transactions, and expenses
3. Generate UUIDs for each record
4. Maintain referential integrity — e.g. a session's `studentID` must match an entry in students.json
5. Write the 6 JSON files to `~/Library/Application Support/AnnaExpenses/`
6. Open (or reopen) the app — data will load automatically

## Business logic notes

- A **package** belongs to one student and has a fixed number of classes
- Each **session** (class attended) draws from a package — track which teacher taught it
- **Teacher payments** are calculated automatically by the app based on session ratios:
  - If a student's 8-class package had 5 sessions with Teacher A and 3 with Teacher B,
    Teacher A gets 5/8 of the package price, Teacher B gets 3/8
- **Transactions** are payments received (income). Link to student/package when possible.
- **Expenses** are outgoing costs not tied to specific students.
