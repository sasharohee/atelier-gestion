-- =====================================================
-- Migration: Add subcategory column to parts table
-- =====================================================
-- Date: 2025-01-27
-- Description: Add subcategory field to allow organizing parts by subcategory
-- =====================================================

-- Add subcategory column to parts table
ALTER TABLE public.parts ADD COLUMN IF NOT EXISTS subcategory TEXT;

-- Add comment to describe the column
COMMENT ON COLUMN public.parts.subcategory IS 'Optional subcategory for organizing parts within a brand';

-- Verify the column was added
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'parts' 
AND column_name = 'subcategory';

SELECT '✅ Column subcategory added successfully to parts table' as status;

