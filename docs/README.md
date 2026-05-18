# EduConnect Documentation

Dokumentasi ini menjelaskan proses pengerjaan, arsitektur, cara menjalankan aplikasi, skema database, serta panduan pengujian untuk aplikasi EduConnect (Flutter + Supabase).

## Daftar Dokumen

- `docs/PROJECT_OVERVIEW.md` - Ringkasan aplikasi, role, dan fitur utama
- `docs/ARCHITECTURE.md` - Arsitektur Flutter (layering, routing, state management)
- `docs/ENV_SETUP.md` - Cara setup environment, Supabase URL/Anon key, dan perintah run
- `docs/DATABASE_SCHEMA.md` - Skema tabel penting + relasi + catatan RLS/validasi
- `docs/MILESTONES_LOG.md` - Kronologi milestone & perubahan besar (termasuk migrations)
- `docs/TESTING.md` - Panduan E2E smoke test + checklist regression
- `docs/DEPLOYMENT.md` - Deploy/migrasi Supabase + catatan operasional
- `docs/TROUBLESHOOTING.md` - Solusi masalah umum (config, auth, realtime, web vs mobile)

Dokumen pendukung (checklist):
- `docs/phase1-post-push-checklist.md`
- `docs/e2e-phase1-manual-test.md`
- `docs/milestone5-e2e-checklist.md`
- `docs/milestone6-e2e-checklist.md`
- `docs/milestone7-e2e-checklist.md`
- `docs/milestone8-e2e-checklist.md`

Bundle final:
- `docs/FINAL_DOCUMENTATION.md`
- `docs/SCREENSHOT_FEATURE_CHECKLIST.md`
- `docs/FINAL_TEST_SCENARIOS.md`
- `docs/DEMO_ACCOUNTS_AND_SEED.md`
- `docs/THESIS_ARCHITECTURE_AND_TESTING_NARRATIVE.md`

## Quick Start

1. Pastikan dependency Flutter sudah ter-install.
2. Jalankan app dengan environment Supabase (contoh):

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY `
  --dart-define=ENABLE_GOOGLE_AUTH=false
```

3. Untuk migrasi database Supabase:

```powershell
cmd /c npx supabase db push
```
