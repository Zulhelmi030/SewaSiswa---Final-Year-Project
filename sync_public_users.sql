-- Run this in the Supabase SQL Editor to ensure EVERY user in authentication 
-- has a corresponding profile in your public.users table.

INSERT INTO public.users (id, email, full_name, global_role)
SELECT 
  id, 
  email, 
  -- If they don't have a full_name set, use the first part of their email
  COALESCE(raw_user_meta_data->>'full_name', split_part(email, '@', 1)), 
  'guest' -- Defaulting to guest
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users)
ON CONFLICT (id) DO NOTHING;

-- Also update any existing users so everyone becomes a guest
UPDATE public.users
SET global_role = 'guest';
