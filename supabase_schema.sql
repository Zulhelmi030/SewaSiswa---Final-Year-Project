-- SQL DDL Schema for SewaSiswa project
-- Run this in your Supabase SQL Editor

-- 1. Users Table (Maps to UserModel & ERD User)
-- (Table already exists, adding missing columns to preserve existing data)
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS global_role TEXT, -- e.g., 'student', 'owner'
  ADD COLUMN IF NOT EXISTS matric_number TEXT,
  ADD COLUMN IF NOT EXISTS faculty TEXT,
  ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- 2. Listings Table (Maps to ListingModel & ERD Listing)
CREATE TABLE public.listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT,
  postcode TEXT,
  state TEXT,
  monthly_rent NUMERIC(10, 2) NOT NULL, -- ERD: PricePerMonth
  deposit NUMERIC(10, 2) NOT NULL,
  house_rule TEXT,
  gender_preference TEXT,
  facility TEXT,
  status TEXT DEFAULT 'available', 
  post_type TEXT NOT NULL DEFAULT 'property',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Listing Photos Table (From ERD ListingPhoto)
CREATE TABLE public.listing_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL
);

-- 4. Rental Tenants Table (Merged Dart RentalTenantModel + ERD Rental)
CREATE TABLE public.rental_tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  tenant_role TEXT NOT NULL, -- 'house_leader' or 'house_member'
  start_date DATE,
  end_date DATE,
  due_day INTEGER,
  status TEXT DEFAULT 'active',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(listing_id, user_id) -- Ensures a user isn't assigned to the same rental multiple times
);

-- 5. Payments Table (Maps to PaymentModel & ERD Payment)
CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL,
  status TEXT NOT NULL, -- 'pending', 'completed', 'failed'
  method TEXT, -- From ERD (e.g., 'fpx', 'card')
  transaction_ref TEXT, -- From ERD
  payment_date TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Reviews Table (Maps to ReviewModel & ERD Review)
CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reviewee_id UUID REFERENCES public.users(id) ON DELETE CASCADE, -- From ERD
  rating NUMERIC(3, 2) NOT NULL CHECK (rating >= 0 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Messages Table (From ERD Message)
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  listing_id UUID REFERENCES public.listings(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Notifications Table (Maps to NotificationModel & ERD Notification)
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL, -- e.g., 'payment', 'housemate_request', 'system'
  is_read BOOLEAN DEFAULT FALSE,
  related_id UUID, 
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. WishLists Table (From ERD WishList)
CREATE TABLE public.wishlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, listing_id)
);

-- -----------------------------------------------------------------------------
-- Enable Row Level Security (RLS)
-- -----------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.housemate_posts ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- RLS Policies
-- -----------------------------------------------------------------------------

-- 1. Users Table
CREATE POLICY "Anyone can view user profiles" ON public.users FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- 2. Listings & Listing Photos
CREATE POLICY "Anyone can view listings" ON public.listings FOR SELECT USING (true);
CREATE POLICY "Owners can manage their own listings" ON public.listings 
  FOR ALL USING (auth.uid() = owner_id);

CREATE POLICY "Anyone can view listing photos" ON public.listing_photos FOR SELECT USING (true);
CREATE POLICY "Owners can manage their listing photos" ON public.listing_photos 
  FOR ALL USING (
    auth.uid() IN (SELECT owner_id FROM public.listings WHERE id = listing_id)
  );

-- 3. Rental Tenants
CREATE POLICY "Users and owners can view tenancy records" ON public.rental_tenants 
  FOR SELECT USING (
    auth.uid() = user_id OR 
    auth.uid() IN (SELECT owner_id FROM public.listings WHERE id = listing_id)
  );
CREATE POLICY "Owners manage tenants" ON public.rental_tenants 
  FOR ALL USING (
    auth.uid() IN (SELECT owner_id FROM public.listings WHERE id = listing_id)
  );

-- 4. Payments
CREATE POLICY "Sender or receiver can view payment" ON public.payments 
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
  
CREATE POLICY "Sender can create payment" ON public.payments 
  FOR INSERT WITH CHECK (auth.uid() = sender_id);
  
CREATE POLICY "Receiver can update payment status" ON public.payments 
  FOR UPDATE USING (auth.uid() = receiver_id);

-- 5. Reviews & Housemate Posts
CREATE POLICY "Anyone can read reviews and posts" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Author can manage own reviews" ON public.reviews 
  FOR ALL USING (auth.uid() = reviewer_id);

CREATE POLICY "Anyone can read housemate posts" ON public.housemate_posts FOR SELECT USING (true);
CREATE POLICY "Author can manage own housemate posts" ON public.housemate_posts 
  FOR ALL USING (auth.uid() = author_id);

-- 6. Messages
CREATE POLICY "Sender and receiver can view messages" ON public.messages 
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
  
CREATE POLICY "Sender can send messages" ON public.messages 
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Receiver can mark as read" ON public.messages 
  FOR UPDATE USING (auth.uid() = receiver_id);

-- 7. Notifications & Wishlists
CREATE POLICY "Users manage own notifications" ON public.notifications 
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users manage own wishlists" ON public.wishlists 
  FOR ALL USING (auth.uid() = user_id);
