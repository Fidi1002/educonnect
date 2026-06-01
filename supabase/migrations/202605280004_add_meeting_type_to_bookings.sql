-- Supabase Migration: Add meeting type and location to bookings

-- Add meeting_type (online/offline) and meeting_location
ALTER TABLE public.bookings ADD COLUMN meeting_type text NOT NULL DEFAULT 'online' CONSTRAINT check_booking_meeting_type CHECK (meeting_type IN ('online', 'offline'));
ALTER TABLE public.bookings ADD COLUMN meeting_location text NOT NULL DEFAULT 'Online Classroom';
