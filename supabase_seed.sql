-- ==========================================
-- SAMPLE SEED DATA FOR SEWASISWA PROJECT
-- Run this script in your Supabase SQL Editor
-- ==========================================

-- 1. Insert Sample Users
-- Note: Replace these UUIDs if you want to link them to specific Auth users
INSERT INTO public.users (id, first_name, last_name, email, global_role, phone_number, faculty)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'Ahmad', 'Owner', 'ahmad.owner@example.com', 'owner', '012-3456789', NULL),
  ('00000000-0000-0000-0000-000000000002', 'Siti', 'Owner', 'siti.owner@example.com', 'owner', '013-4567890', NULL),
  ('00000000-0000-0000-0000-000000000003', 'Ali', 'Student', 'ali.student@siswa.edu.my', 'student', '014-5678901', 'FTSM')
ON CONFLICT (id) DO NOTHING;

-- 2. Insert Sample Listings
-- We use the owner IDs from above
INSERT INTO public.listings (id, owner_id, title, description, address, city, postcode, state, monthly_rent, deposit, house_rule, gender_preference, facility, status)
VALUES 
  (
    '10000000-0000-0000-0000-000000000001', 
    '00000000-0000-0000-0000-000000000001', 
    'Bilik Sewa Mewah dekat UKM', 
    'Bilik fully furnished dengan aircond. Berdekatan dengan pintu masuk utama universiti. Boleh jalan kaki sahaja.', 
    'No 12, Jalan Universiti 3, Taman Anggerik', 
    'Bangi', 
    '43600', 
    'Selangor', 
    450.00, 
    900.00, 
    'No pets allowed. Keep the house clean.', 
    'Male Only', 
    'WiFi, Washing Machine, Fridge, Aircond', 
    'available'
  ),
  (
    '10000000-0000-0000-0000-000000000002', 
    '00000000-0000-0000-0000-000000000002', 
    'Rumah Sewa Teres 2 Tingkat', 
    'Sesuai untuk kumpulan pelajar seramai 6-8 orang. Ruang tamu yang luas dan selesa.', 
    'No 45, Jalan Mewah 5, Seksyen 7', 
    'Shah Alam', 
    '40000', 
    'Selangor', 
    1800.00, 
    3600.00, 
    'Strictly no smoking inside the house.', 
    'Any', 
    'Cooking allowed, Parking space, TV', 
    'available'
  ),
  (
    '10000000-0000-0000-0000-000000000003', 
    '00000000-0000-0000-0000-000000000001', 
    'Bilik Master - Seksyen 2', 
    'Bilik master sharing 2 orang. Toilet di dalam bilik.', 
    'Apartment Mutiara, Jalan Cempaka 2', 
    'Bangi', 
    '43650', 
    'Selangor', 
    300.00, 
    600.00, 
    'Curfew at 12 AM.', 
    'Female Only', 
    'Washing Machine, Security Guard', 
    'available'
  )
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Sample Listing Photos
-- Adding multiple photos for the listings above
INSERT INTO public.listing_photos (listing_id, photo_url)
VALUES 
  ('10000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=800'),
  ('10000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1502672260266-1c1de2d9d000?auto=format&fit=crop&q=80&w=800'),
  ('10000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&q=80&w=800'),
  ('10000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&q=80&w=800'),
  ('10000000-0000-0000-0000-000000000003', 'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?auto=format&fit=crop&q=80&w=800')
ON CONFLICT DO NOTHING;

-- 4. Insert Sample Housemate Posts
INSERT INTO public.housemate_posts (rental_id, author_id, title, description, preferences)
VALUES 
  (
    '10000000-0000-0000-0000-000000000002', 
    '00000000-0000-0000-0000-000000000003', 
    'Mencari 2 orang housemate lelaki', 
    'Kami memerlukan lagi 2 orang housemate untuk memenuhi bilik tengah. Rumah fully furnished.', 
    ARRAY['Pembersih', 'Tidak merokok', 'Boleh bayar sewa on time']
  );
