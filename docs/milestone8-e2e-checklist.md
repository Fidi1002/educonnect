# Milestone 8 E2E Checklist (Availability & Smart Scheduling)

## 1) Apply migration

```bash
npx supabase db push
```

Migration:
- `supabase/migrations/202604190006_milestone8_availability_scheduling.sql`

## 2) Tutor setup availability

- Login tutor.
- Open `Atur Jadwal Ketersediaan`.
- Add at least 2 slots (example: Senin 16:00-18:00, Rabu 19:00-21:00).
- Verify slots appear in list.

## 3) Student booking guard

- Login student.
- Open tutor detail -> `Ajukan Booking`.
- Pick date where tutor has slot.
- Verify only available times shown as chips.
- Pick time and submit booking.

## 4) Conflict prevention

- Create one booking on same tutor/date/time.
- Try creating another booking that overlaps.
- Verify app shows conflict error.

## 5) Availability editing

- Tutor remove one slot.
- Student repeat booking on removed slot date.
- Verify no available times for removed range.
