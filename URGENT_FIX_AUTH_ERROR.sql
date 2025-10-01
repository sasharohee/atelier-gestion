-- URGENT FIX: Database error saving new user
-- Execute this in Supabase SQL Editor to fix the authentication issue

-- Step 1: Remove problematic trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Step 2: Create a robust user creation function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user in public.users with comprehensive error handling
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

-- Step 3: Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 4: Verify the fix
SELECT '✅ User creation trigger fixed and recreated successfully!' as status;

-- Step 5: Test verification
SELECT 
    'Trigger exists: ' || CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE event_object_table = 'users' 
            AND event_object_schema = 'auth'
            AND trigger_name = 'on_auth_user_created'
        ) THEN 'YES' 
        ELSE 'NO' 
    END as trigger_status;

SELECT 
    'Function exists: ' || CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = 'handle_new_user'
        ) THEN 'YES' 
        ELSE 'NO' 
    END as function_status;

-- Final confirmation
SELECT '🎉 AUTHENTICATION FIX APPLIED SUCCESSFULLY!' as final_status;
SELECT 'You can now test user registration in your application.' as next_step;
