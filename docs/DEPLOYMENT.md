# Deployment / Operasional (Supabase)

Dokumen ini berfokus pada proses migrasi schema dan sanity check backend di Supabase.

## 1) Link Project Supabase (sekali saja per mesin)
Jika menggunakan Supabase CLI dan sudah punya project ref:
```powershell
cmd /c npx supabase link --project-ref <PROJECT_REF>
```

Catatan:
- `<PROJECT_REF>` adalah identifier project Supabase, misalnya `tbgyiqepezafouekmzii`.
- Jika environment Windows PowerShell mengalami kendala eksekusi `npx`, gunakan `cmd /c ...` seperti contoh.

## 2) Push Migrasi Database
```powershell
cmd /c npx supabase db push
```

Jika terjadi error, jalankan dengan debug:
```powershell
cmd /c npx supabase db push --debug
```

## 3) Sanity Check SQL (disarankan setelah push)
Script sanity check tersedia di:
- `supabase/checks/phase1_sanity.sql`

Cara menjalankan:
1. Supabase Dashboard -> SQL Editor.
2. Copy-paste isi file `supabase/checks/phase1_sanity.sql`.
3. Run dan pastikan tidak ada error.

## 4) Auth Provider (Google)
Jika akan mengaktifkan Google provider:
1. Supabase Dashboard -> Authentication -> Providers -> Google -> Enable.
2. Set redirect URL sesuai aplikasi (custom scheme), contoh:
   - `io.supabase.educonnect://login-callback/`
3. Jalankan aplikasi dengan `ENABLE_GOOGLE_AUTH=true`.

## 5) Storage (Foto Tutor)
Bucket yang digunakan:
- `tutor-photos`

Kebijakan (policy) memastikan:
- Read: public read untuk objek pada bucket ini (agar foto mudah ditampilkan).
- Write/Update/Delete: hanya owner folder `/<uid>/...` yang dapat mengubah file miliknya.

Catatan operasional:
- Pastikan struktur path upload konsisten: `tutor-photos/<uid>/<filename>`.

## 6) Catatan Production (ringkas)
Untuk production-ready, disarankan:
- Review RLS policies sebelum go-live.
- Aktifkan email confirmation kembali (jika sempat dimatikan saat dev).
- Tambahkan rate limit dan observability (logs) sesuai kebutuhan.

