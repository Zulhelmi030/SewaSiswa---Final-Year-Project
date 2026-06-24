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
  payment_date TIMESTAMPTZ DEFAULT NOW(),
  for_month INTEGER NOT NULL,
  for_year INTEGER NOT NULL
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
  FOR SELECT USING (auth.role() = 'authenticated');
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

-- -----------------------------------------------------------------------------
-- Scheduled Jobs & Cron
-- -----------------------------------------------------------------------------

-- Enable pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create the notification function
CREATE OR REPLACE FUNCTION public.check_and_notify_due_rent()
RETURNS void AS $$
DECLARE
  rec RECORD;
  current_due_date DATE;
  target_month INTEGER;
  target_year INTEGER;
BEGIN
  -- Loop through all active tenants
  FOR rec IN 
    SELECT rt.user_id, rt.listing_id, rt.due_day 
    FROM public.rental_tenants rt 
    WHERE rt.status = 'active' AND rt.due_day IS NOT NULL
  LOOP
    
    -- Determine current due date
    current_due_date := make_date(
      EXTRACT(YEAR FROM CURRENT_DATE)::int, 
      EXTRACT(MONTH FROM CURRENT_DATE)::int, 
      rec.due_day
    );
    
    -- If current_date is past this month's due date, the next cycle is next month
    IF CURRENT_DATE > current_due_date THEN
      current_due_date := current_due_date + interval '1 month';
    END IF;
    
    target_month := EXTRACT(MONTH FROM current_due_date);
    target_year := EXTRACT(YEAR FROM current_due_date);
    
    -- Check if a payment has already been made for this specific cycle
    IF NOT EXISTS (
      SELECT 1 FROM public.payments p 
      WHERE p.rental_id = rec.listing_id 
      AND p.sender_id = rec.user_id 
      AND p.for_month = target_month 
      AND p.for_year = target_year 
      AND p.status IN ('paid', 'succeeded', 'pending')
    ) THEN
      
      -- Check if due_date is exactly 3 days or less away (and not passed)
      IF (current_due_date - CURRENT_DATE) <= 3 AND (current_due_date - CURRENT_DATE) >= 0 THEN
        
        -- Check if we already notified them for this cycle (e.g. in the last 4 days)
        IF NOT EXISTS (
          SELECT 1 FROM public.notifications n
          WHERE n.user_id = rec.user_id
          AND n.type = 'payment'
          AND n.created_at >= (CURRENT_DATE - interval '4 days')
        ) THEN
          
          -- Insert notification
          INSERT INTO public.notifications (user_id, title, body, type)
          VALUES (
            rec.user_id, 
            'Rent Due Soon!', 
            'Your rent payment is due in ' || (current_due_date - CURRENT_DATE) || ' days.', 
            'payment'
          );
        END IF;
      END IF;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule the job to run every day at 8:00 AM UTC
-- SELECT cron.schedule('daily-rent-reminder', '0 8 * * *', $$ SELECT public.check_and_notify_due_rent(); $$);
