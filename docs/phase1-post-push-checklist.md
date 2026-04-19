# Phase 1 Post-Push Checklist (Supabase)

## A. Backend Sanity Check

1. Open Supabase SQL Editor.
2. Run `supabase/checks/phase1_sanity.sql`.
3. Confirm:
   - tables `public.users` and `public.tutors` exist
   - function `public.get_nearby_tutors` exists
   - RLS is enabled on both tables
   - storage bucket `tutor-photos` exists
   - policies are listed for `public.users`, `public.tutors`, and `storage.objects`

## B. Auth Provider Final Setup

1. Go to **Authentication > Providers > Email**.
   - Enable Email provider.
   - Keep email confirmation as desired for MVP (usually OFF for faster testing).
2. Go to **Authentication > Providers > Google**.
   - Enable Google provider.
   - Fill Google OAuth Client ID + Secret.
3. Go to **Authentication > URL Configuration**.
   - Add redirect URL: `io.supabase.educonnect://login-callback/`

## C. Android Deep Link Match

Ensure Android intent filter already includes:
- scheme: `io.supabase.educonnect`
- host: `login-callback`

(Implemented in `android/app/src/main/AndroidManifest.xml`.)

## D. Runtime Env for App

Run app with:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY `
  --dart-define=ENABLE_GOOGLE_AUTH=false `
  --dart-define=SUPABASE_GOOGLE_REDIRECT_URL=io.supabase.educonnect://login-callback/
```

## E. E2E Smoke Test Matrix

1. Email register -> role onboarding -> correct home route.
2. Google login -> role onboarding -> correct home route.
3. Tutor edit profile + upload photo -> row updated in `tutors`.
4. Student nearby search with radius 1/5/10/20 km -> list populated and sorted by distance.
5. Manual location fallback works when GPS denied.
