-- Run this in the Supabase SQL Editor to fix the login error

-- 1. Fix NULL values in auth.users (Supabase requires empty strings instead of NULL)
UPDATE auth.users
SET 
  confirmation_token = '',
  recovery_token = '',
  email_change_token_new = '',
  email_change = ''
WHERE confirmation_token IS NULL 
   OR recovery_token IS NULL 
   OR email_change_token_new IS NULL 
   OR email_change IS NULL;

-- 2. Create the missing "identities" for these users
-- Supabase requires an entry in auth.identities to allow email/password login
INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
SELECT 
  gen_random_uuid(), 
  id, 
  id::text, 
  jsonb_build_object('sub', id::text, 'email', email), 
  'email', 
  now(), 
  now(), 
  now()
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM auth.identities)
ON CONFLICT DO NOTHING;
