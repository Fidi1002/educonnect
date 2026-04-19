# Milestone 6 E2E Checklist (Payment Dummy)

## 1) Apply migration

```bash
npx supabase db push
```

Migration:
- `supabase/migrations/202604190004_milestone6_payment_flow.sql`

## 2) Student creates booking

- Login student -> pilih tutor -> `Ajukan Booking`.
- Verify status awal booking: `Menunggu`.

## 3) Tutor accepts booking

- Login tutor -> `Kelola Booking Murid`.
- Click `Terima`.
- Verify status berubah ke `Menunggu Pembayaran`.

## 4) Student pays (dummy)

- Login student -> halaman `Kelas`.
- Click `Bayar Sekarang (Dummy)`.
- Verify status berubah `Lunas`.

## 5) Tutor completes class

- Login tutor -> booking status `Lunas`.
- Click `Tandai Selesai`.
- Verify status akhir `Selesai`.

## 6) Notifications sanity

- Student home shows banner + badge when there are booking updates.
- Tutor home stat card shows pending booking and waiting payment counts.
