-- Dummy Data for SewaSiswa App Presentation

-- 1. Insert 5 Dummy Listings
INSERT INTO public.listings (
  id, owner_id, title, description, address, city, postcode, state, 
  monthly_rent, deposit, house_rule, gender_preference, facilities, 
  status, latitude, longitude, rating, review_count, total_slots, occupied_slots
) VALUES 
(
  'a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', 
  '9c76b3ec-8da1-4b11-9e14-82578c98a704', 
  'Cozy Room Near UiTM Shah Alam', 
  'Looking for a friendly housemate. The house is fully furnished and very near to the UiTM main gate. Easy access to public transport.', 
  'Pangsapuri Baiduri, Seksyen 7', 'Shah Alam', '40000', 'Selangor', 
  400, 800, 'No smoking, keep clean, respect others', 'Male', ARRAY['WiFi', 'Washing Machine', 'Fridge', 'Bed', 'Study Table'], 
  'available', 3.0738, 101.4925, 4.5, 2, 4, 1
),
(
  'b2c3d4e5-f6a1-4b2c-9d0e-1f2a3b4c5d61', 
  '9c76b3ec-8da1-4b11-9e14-82578c98a704', 
  'Master Bedroom for Rent (Female Only)', 
  'Spacious master bedroom with private bathroom. Quiet environment suitable for students. Walking distance to shops and restaurants.', 
  'Kristal Heights, Seksyen 7', 'Shah Alam', '40000', 'Selangor', 
  600, 1200, 'No boys allowed, pay rent on time, clean after cooking', 'Female', ARRAY['Aircond', 'Private Bathroom', 'Cooking Allowed', 'WiFi', 'Water Heater'], 
  'available', 3.0745, 101.4880, 5.0, 1, 2, 0
),
(
  'c3d4e5f6-a1b2-4c3d-0e1f-2a3b4c5d6e72', 
  '9c76b3ec-8da1-4b11-9e14-82578c98a704', 
  'Fully Furnished Apartment i-City', 
  'Whole apartment for rent. Perfect for a group of students. Enjoy premium facilities like swimming pool and gym.', 
  'i-Suite, i-City', 'Shah Alam', '40000', 'Selangor', 
  1500, 3000, 'Max 4 people, no pets', 'Any', ARRAY['Swimming Pool', 'Gym', 'Aircond', 'Fully Furnished', 'Security 24/7'], 
  'available', 3.0655, 101.4831, 4.8, 5, 4, 0
),
(
  'd4e5f6a1-b2c3-4d4e-1f2a-3b4c5d6e7f83', 
  '9c76b3ec-8da1-4b11-9e14-82578c98a704', 
  'Single Room at Puncak Alam', 
  'New house in Eco Grandeur. Clean and peaceful. Only 15 mins to UiTM Puncak Alam.', 
  'Eco Grandeur', 'Puncak Alam', '42300', 'Selangor', 
  350, 700, 'Student only, keep common areas tidy', 'Female', ARRAY['Washing Machine', 'Cooking Allowed', 'Fridge', 'Parking'], 
  'available', 3.2355, 101.4580, 0, 0, 1, 0
),
(
  'e5f6a1b2-c3d4-4e5f-2a3b-4c5d6e7f8a94', 
  '9c76b3ec-8da1-4b11-9e14-82578c98a704', 
  'Budget Room for Male Student', 
  'Affordable room in a strategic location. Walking distance to UiTM, bus stop, and food stalls. Basic furnishing provided.', 
  'Flat PKNS Seksyen 7', 'Shah Alam', '40000', 'Selangor', 
  250, 500, 'Keep quiet after 11 PM, pay rent by 5th of every month', 'Male', ARRAY['Fan', 'Bed', 'Wardrobe'], 
  'available', 3.0760, 101.4950, 3.8, 3, 6, 3
) ON CONFLICT (id) DO NOTHING;

-- 2. Insert Dummy Photos for the Listings
INSERT INTO public.listing_photos (listing_id, photo_url) VALUES 
('a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&auto=format&fit=crop'),
('a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', 'https://images.unsplash.com/photo-1502672260266-1c1de2d93688?w=800&auto=format&fit=crop'),
('b2c3d4e5-f6a1-4b2c-9d0e-1f2a3b4c5d61', 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&auto=format&fit=crop'),
('c3d4e5f6-a1b2-4c3d-0e1f-2a3b4c5d6e72', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&auto=format&fit=crop'),
('c3d4e5f6-a1b2-4c3d-0e1f-2a3b4c5d6e72', 'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800&auto=format&fit=crop'),
('c3d4e5f6-a1b2-4c3d-0e1f-2a3b4c5d6e72', 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&auto=format&fit=crop'),
('d4e5f6a1-b2c3-4d4e-1f2a-3b4c5d6e7f83', 'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800&auto=format&fit=crop'),
('e5f6a1b2-c3d4-4e5f-2a3b-4c5d6e7f8a94', 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&auto=format&fit=crop')
ON CONFLICT DO NOTHING;

-- 3. Insert Dummy Reviews
INSERT INTO public.reviews (rental_id, reviewer_id, reviewee_id, rating, comment) VALUES
('a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', '6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 5, 'Great location! Very close to my faculty. Landlord is friendly.'),
('a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', '6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 4, 'House is clean and comfortable.'),
('b2c3d4e5-f6a1-4b2c-9d0e-1f2a3b4c5d61', '6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 5, 'Love the private bathroom and the peaceful environment.'),
('c3d4e5f6-a1b2-4c3d-0e1f-2a3b4c5d6e72', '6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 4.5, 'Nice facilities, swimming pool is a plus!'),
('c3d4e5f6-a1b2-4c3d-0e1f-2a3b4c5d6e72', '6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 5, 'Beautifully furnished. Worth the price if sharing with friends.'),
('e5f6a1b2-c3d4-4e5f-2a3b-4c5d6e7f8a94', '6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 4, 'Good for budget students. Nothing to complain about.')
ON CONFLICT DO NOTHING;

-- 4. Insert Dummy Messages
INSERT INTO public.messages (sender_id, receiver_id, listing_id, content, is_read) VALUES
('6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 'a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', 'Hi sir, is this room still available?', true),
('9c76b3ec-8da1-4b11-9e14-82578c98a704', '6d47eab0-74e8-487a-afd4-ee60f724f069', 'a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', 'Yes, it is. Would you like to come for a viewing?', true),
('6d47eab0-74e8-487a-afd4-ee60f724f069', '9c76b3ec-8da1-4b11-9e14-82578c98a704', 'a1b2c3d4-e5f6-4a1b-8c9d-0e1f2a3b4c50', 'Sure, how about tomorrow evening?', false)
ON CONFLICT DO NOTHING;

-- 5. Insert Dummy Notifications
INSERT INTO public.notifications (user_id, title, body, type, is_read) VALUES
('9c76b3ec-8da1-4b11-9e14-82578c98a704', 'New Message', 'You have a new message from zulhelmi', 'message', false),
('6d47eab0-74e8-487a-afd4-ee60f724f069', 'Listing Liked', 'Your saved listing has been updated', 'update', false)
ON CONFLICT DO NOTHING;
