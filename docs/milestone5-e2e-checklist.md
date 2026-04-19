# Milestone 5 E2E Checklist

## 1) Apply database migration

```bash
npx supabase db push
```

Migration file:
- `supabase/migrations/202604190003_milestone5_bookings.sql`

## 2) Student flow

- Login as student.
- Open tutor detail.
- Click `Ajukan Booking`.
- Choose subject, duration, and schedule.
- Submit.
- Open `Kelas` menu from student home and verify booking appears as `Menunggu`.

## 3) Tutor flow

- Login as tutor.
- Open `Kelola Booking Murid` from tutor home.
- Accept or reject a pending booking.
- Verify status updates.

## 4) Student history check

- Login back as student.
- Open booking history page (`Kelas`).
- Verify latest status matches tutor action.
