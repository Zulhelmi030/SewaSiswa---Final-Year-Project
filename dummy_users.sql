-- Run this script in the Supabase SQL Editor to create 8 realistic dummy users directly.
-- Password for ALL users is: password123
-- Ages are included in their bios.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  user1_id uuid := gen_random_uuid();
  user2_id uuid := gen_random_uuid();
  user3_id uuid := gen_random_uuid();
  user4_id uuid := gen_random_uuid();
  user5_id uuid := gen_random_uuid();
  user6_id uuid := gen_random_uuid();
  user7_id uuid := gen_random_uuid();
  user8_id uuid := gen_random_uuid();
BEGIN
  -- 1. Insert into auth.users so they can log in
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, 
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) VALUES 
  (user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ahmad.faris@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Ahmad Faris"}', now(), now()),
  (user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'daniel.hakim@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Daniel Hakim"}', now(), now()),
  (user3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'irfan.zikri@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Irfan Zikri"}', now(), now()),
  (user4_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'syed.ammar@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Syed Ammar"}', now(), now()),
  (user5_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'nurul.aisyah@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Nurul Aisyah"}', now(), now()),
  (user6_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'siti.aminah@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Siti Aminah"}', now(), now()),
  (user7_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'farah.nadia@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Farah Nadia"}', now(), now()),
  (user8_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'alya.batrisyia@student.uitm.edu.my', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Alya Batrisyia"}', now(), now());

  -- 2. Insert into public.users to populate their profiles in your app
  -- We use ON CONFLICT DO UPDATE in case your Supabase project has an automated trigger that already created them.
  INSERT INTO public.users (id, full_name, email, global_role, bio, avatar_url) VALUES 
  (user1_id, 'Ahmad Faris', 'ahmad.faris@student.uitm.edu.my', 'tenant', 'Hi! I am a 19 year old IT student. Looking for a friendly housemate!', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Faris'),
  (user2_id, 'Daniel Hakim', 'daniel.hakim@student.uitm.edu.my', 'tenant', '21 y/o. Easy going and clean. Currently in my 3rd year.', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Daniel'),
  (user3_id, 'Irfan Zikri', 'irfan.zikri@student.uitm.edu.my', 'tenant', 'Final year student (23). Mostly studying, very quiet.', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Irfan'),
  (user4_id, 'Syed Ammar', 'syed.ammar@student.uitm.edu.my', 'tenant', '20 years old, from Johor. I love playing football.', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Syed'),
  (user5_id, 'Nurul Aisyah', 'nurul.aisyah@student.uitm.edu.my', 'tenant', '20 year old Accounting student. Looking for an all-female house.', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Aisyah'),
  (user6_id, 'Siti Aminah', 'siti.aminah@student.uitm.edu.my', 'tenant', '19 years old, new to Shah Alam! Let''s be friends!', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Aminah'),
  (user7_id, 'Farah Nadia', 'farah.nadia@student.uitm.edu.my', 'tenant', '22 y/o. Very particular about cleanliness.', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Farah'),
  (user8_id, 'Alya Batrisyia', 'alya.batrisyia@student.uitm.edu.my', 'tenant', '21 year old Business student. Friendly and approachable.', 'https://api.dicebear.com/7.x/avataaars/svg?seed=Alya')
  ON CONFLICT (id) DO UPDATE SET 
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    bio = EXCLUDED.bio,
    avatar_url = EXCLUDED.avatar_url;

END $$;
