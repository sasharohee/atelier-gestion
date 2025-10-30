-- =====================================================
-- Migration: Add subcategory column to products table
-- =====================================================
-- Date: 2025-01-27
-- Description: Add subcategory field to allow organizing products by subcategory
-- =====================================================

-- Add subcategory column to products table
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS subcategory TEXT;

-- Add comment to describe the column
COMMENT ON COLUMN public.products.subcategory IS 'Optional subcategory for organizing products within a category';

-- Verify the column was added
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'products' 
AND column_name = 'subcategory';

SELECT '✅ Column subcategory added successfully to products table' as status;

