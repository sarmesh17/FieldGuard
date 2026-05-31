# Bug: `GET /api/v1/dashboard/summary` returns wrong task counts

## Summary
The task-bucket `pagination.total` values in the dashboard summary are **capped by
the query `limit` instead of being the real total count**. Because each bucket is
queried with `limit: 1`, every `total` comes back as `0` or `1`, so the app's
dashboard shows wrong **Pending / In Progress / Completed** numbers and a wrong
**Daily Progress** bar.

## Evidence (live response, ADMIN token)
`GET /api/v1/dashboard/summary`

```jsonc
"pendingTasks":    { "tasks": [ /* 1 */ ], "pagination": { "limit": 1, "total": 1 } },
"inProgressTasks": { "tasks": [],          "pagination": { "limit": 1, "total": 0 } },
"completedTasks":  { "tasks": [ /* 1 */ ], "pagination": { "limit": 1, "total": 1 } }
```

Every `total` is `<= limit (1)`. But there are clearly many completed tasks — the
audit log (`GET /api/v1/tasks/history`) shows dozens of `COMPLETED` /
`TASK_AUTO_COMPLETED` entries, total 115 history rows.

### Cross-check with the tasks endpoint (same token, same moment)
`GET /api/v1/tasks?status=COMPLETED&limit=1`  → `pagination.total` is the **real**
count (e.g. 6+), while the summary says `1`.

So: the tasks list endpoint computes `total` correctly; the dashboard summary does
not.

## Root cause (most likely)
The summary is computing `total` from the **length of the limited result set**
(`rows.length` after `LIMIT 1`) instead of a real `COUNT(*)`.

- ❌ `total = rows.length`           // capped by LIMIT
- ✅ `total = COUNT(*) WHERE status = …`  // independent of LIMIT

If using Sequelize: use `findAndCountAll().count` (the separate count), **not**
`rows.length`. With raw SQL, run a separate `SELECT COUNT(*)` per status.

## Expected behaviour
For each bucket (`pendingTasks`, `inProgressTasks`, `completedTasks`):

- `pagination.total` = full count of tasks matching that **status** for the
  requesting user, **independent of `limit`**.
- Role scoping must match `/api/v1/tasks` exactly:
  - ADMIN → company-wide
  - MANAGER → their team
  - EMPLOYEE → their own tasks

The `tasks` array can stay limited (1 preview item is fine); only `total` must be
the true count.

## App impact
- Dashboard stat cards (Pending / Done / In Progress) — wrong, capped at 1.
- "Daily Progress" = completed / (pending + inProgress + completed) — wrong because
  every input is capped.

---

## Optional (nice-to-have, not required for the fix)

1. **Return plain counts.** The dashboard only needs numbers, not the sample task
   arrays. A lighter shape would help:
   ```jsonc
   "taskCounts": { "pending": 12, "inProgress": 3, "completed": 48 }
   ```

2. **Add team total to `liveEmployees`.** Today it returns `{ count, employees }`
   (online only), so the app makes a **separate `GET /api/v1/employees`** call just
   to compute "offline = total − online". If the summary included the team total:
   ```jsonc
   "liveEmployees": { "online": 0, "total": 4, "employees": [] }
   ```
   the app could drop that extra request.

— Reported from the Flutter app dashboard (`lib/features/dashboard/`).
