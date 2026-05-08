-- EduConnect push pipeline smoke test
-- Jalankan potongan query ini di Supabase SQL Editor saat ingin memverifikasi:
-- Android token -> user_push_tokens -> app_notifications -> push_delivery_queue -> dispatch-push

-- 1) Cek apakah token perangkat user sudah masuk
select
  id,
  user_uid,
  platform,
  push_provider,
  is_active,
  left(device_token, 24) || '...' as token_preview,
  last_seen_at,
  created_at,
  updated_at
from public.user_push_tokens
order by updated_at desc
limit 20;

-- 2) Cek notifikasi terbaru user
select
  id,
  user_uid,
  actor_uid,
  category,
  title,
  body,
  target_type,
  target_id,
  is_read,
  created_at
from public.app_notifications
order by created_at desc
limit 20;

-- 3) Cek item queue push yang terbentuk otomatis dari app_notifications
select
  q.id,
  q.notification_id,
  q.user_uid,
  q.status,
  q.attempt_count,
  q.scheduled_for,
  q.sent_at,
  q.provider_message_id,
  q.last_error,
  q.created_at,
  q.updated_at,
  left(t.device_token, 24) || '...' as token_preview
from public.push_delivery_queue q
left join public.user_push_tokens t on t.id = q.token_id
order by q.created_at desc
limit 20;

-- 4) Insert notifikasi test manual untuk user tertentu
-- Ganti UUID di bawah dengan user_uid target yang memang punya token aktif.
insert into public.app_notifications (
  user_uid,
  actor_uid,
  category,
  title,
  body,
  target_type,
  target_id,
  is_read
) values (
  'PASTE_USER_UID_DI_SINI',
  'PASTE_USER_UID_DI_SINI',
  'general',
  'Test Push EduConnect',
  'Jika pipeline benar, item ini akan masuk ke push_delivery_queue.',
  'booking',
  'manual-test',
  false
);

-- 5) Cek queue terbaru setelah insert test notification
select
  q.id,
  q.notification_id,
  q.user_uid,
  q.status,
  q.attempt_count,
  q.scheduled_for,
  q.sent_at,
  q.provider_message_id,
  q.last_error,
  q.created_at
from public.push_delivery_queue q
order by q.created_at desc
limit 10;

-- 6) Setelah dispatch-push dijalankan, cek hasil delivery
select
  q.id,
  q.status,
  q.attempt_count,
  q.sent_at,
  q.provider_message_id,
  q.last_error,
  q.payload
from public.push_delivery_queue q
order by q.updated_at desc
limit 10;
