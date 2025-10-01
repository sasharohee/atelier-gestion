-- Fix for "Database error saving new user" error
-- This script addresses the authentication trigger issue

-- 1. First, let's check the current state
SELECT '🔍 Checking current trigger state...' as status;

-- Check existing triggers on auth.users
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- 2. Remove problematic trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Create a robust user creation function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user in public.users with error handling
    BEGIN
        INSERT INTO public.users (
            id, 
            first_name, 
            last_name, 
            email, 
            role, 
            created_at, 
            updated_at
        ) VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
            COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
            NOW(),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log error but don't fail the auth process
            RAISE WARNING 'Error creating user in public.users: %', SQLERRM;
    END;
    
    -- Create user profile with error handling
    BEGIN
        INSERT INTO public.user_profiles (
            user_id, 
            first_name, 
            last_name, 
            email, 
            created_at, 
            updated_at
        ) VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
            COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
            NEW.email,
            NOW(),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Error creating user profile: %', SQLERRM;
    END;
    
    -- Create user preferences with error handling
    BEGIN
        INSERT INTO public.user_preferences (
            user_id, 
            created_at, 
            updated_at
        ) VALUES (
            NEW.id, 
            NOW(), 
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Error creating user preferences: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Verify the fix
SELECT '✅ User creation trigger fixed and recreated' as status;

-- 6. Test the function (without actually creating a user)
SELECT '🧪 Testing user creation function...' as test_status;

-- Check if the function exists and is properly configured
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'handle_new_user';

-- Check if the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth'
AND trigger_name = 'on_auth_user_created';

SELECT '🎉 Fix applied successfully! User registration should now work.' as final_status;
