# Milestone 7 E2E Checklist (Chat & Realtime)

## 1) Apply migrations

```bash
npx supabase db push
```

Migrations:
- `supabase/migrations/202604190004_milestone6_payment_flow.sql`
- `supabase/migrations/202604190005_milestone7_chat_realtime.sql`

## 2) Inbox list + unread badge

- Login student/tutor.
- Verify chat badge appears on home appbar.
- Open `Inbox Chat` and verify each booking appears as one thread.
- Send a message from one account and verify unread count increments on other account.

## 3) Chat per booking realtime

- Open same booking chat on two sessions (student+tutor).
- Send message from student and verify appears in tutor view without refresh.
- Send reply from tutor and verify appears in student view without refresh.

## 4) Booking status notification

- Tutor accept booking -> status `Menunggu Pembayaran` appears in student chat/inbox.
- Student pay dummy -> status `Lunas` appears in tutor inbox.
- Tutor complete class -> status `Selesai` appears in student inbox.

## 5) Read state behavior

- Open chat thread from receiver side.
- Verify unread badge for that thread decreases to 0.
