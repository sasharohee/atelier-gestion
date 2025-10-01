-- URGENT FIX: Disable problematic auth trigger
-- Copy and paste this entire script into your Supabase SQL Editor

-- Step 1: Remove the problematic trigger
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- Step 2: Remove the problematic function
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Step 3: Verify removal
SELECT 'Trigger removed successfully' as status;

-- Step 4: Check remaining triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- Step 5: Confirmation
SELECT 'Auth should now work without 500 error' as status;
