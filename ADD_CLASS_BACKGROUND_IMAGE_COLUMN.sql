-- ============================================================================
-- ADD BACKGROUND_IMAGE COLUMN TO CLASS_ROOMS TABLE
-- ============================================================================
-- This migration adds the background_image column to the class_rooms table
-- to support uploading and storing class background images.
--
-- Run this in your Supabase SQL Editor.
-- ============================================================================

DO $$
BEGIN
    -- Add background_image column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'class_rooms' AND column_name = 'background_image'
    ) THEN
        ALTER TABLE public.class_rooms 
        ADD COLUMN background_image text;
        
        -- Add comment for documentation
        COMMENT ON COLUMN public.class_rooms.background_image IS 
        'URL or path to the background image for this classroom. Stored in Supabase storage.';
        
        RAISE NOTICE '✅ Successfully added background_image column to class_rooms table';
    ELSE
        RAISE NOTICE 'ℹ️ background_image column already exists in class_rooms table';
    END IF;
END $$;

-- Verify the column was added
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'class_rooms' 
    AND column_name = 'background_image';

