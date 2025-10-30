-- =====================================================
-- Migration: Add subcategory column to services table
-- =====================================================
-- Date: 2025-01-27
-- Description: Add subcategory field to allow organizing services by subcategory
-- =====================================================

-- Add subcategory column to services table
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS subcategory TEXT;

-- Add comment to describe the column
COMMENT ON COLUMN public.services.subcategory IS 'Optional subcategory for organizing services within a category';

-- Verify the column was added
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'services' 
AND column_name = 'subcategory';

SELECT '✅ Column subcategory added successfully to services table' as status;

