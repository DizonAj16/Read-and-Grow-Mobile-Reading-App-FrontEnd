-- ============================================================================
-- DATABASE SCHEMA FIXES AND IMPROVEMENTS
-- ============================================================================
-- This script contains all necessary database-level fixes to ensure
-- proper registration flows, data integrity, and relationship consistency.
-- Run this in your Supabase SQL Editor.
-- ============================================================================

-- ============================================================================
-- 1. ENSURE PARENTS TABLE HAS ALL REQUIRED FIELDS
-- ============================================================================
-- Verify that parents table has: first_name, last_name, email as NOT NULL
-- If missing, add them:

-- Check if columns exist and add if missing
DO $$
BEGIN
    -- Add first_name if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parents' AND column_name = 'first_name'
    ) THEN
        ALTER TABLE public.parents ADD COLUMN first_name text NOT NULL DEFAULT '';
    END IF;

    -- Add last_name if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parents' AND column_name = 'last_name'
    ) THEN
        ALTER TABLE public.parents ADD COLUMN last_name text NOT NULL DEFAULT '';
    END IF;

    -- Ensure email can be NULL (unique but nullable)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parents' AND column_name = 'email'
    ) THEN
        -- Remove NOT NULL constraint if exists
        ALTER TABLE public.parents ALTER COLUMN email DROP NOT NULL;
    ELSE
        ALTER TABLE public.parents ADD COLUMN email text UNIQUE;
    END IF;
END $$;

-- ============================================================================
-- 2. ENFORCE ONE-TO-ONE ROLE MAPPING
-- ============================================================================
-- Add check constraints to ensure a user can only be in one role table

-- Function to check if user exists in other role tables
CREATE OR REPLACE FUNCTION check_single_role()
RETURNS TRIGGER AS $$
BEGIN
    -- Check for students
    IF EXISTS (SELECT 1 FROM public.students WHERE id = NEW.id) THEN
        RAISE EXCEPTION 'User already exists as student';
    END IF;
    
    -- Check for teachers
    IF EXISTS (SELECT 1 FROM public.teachers WHERE id = NEW.id) THEN
        RAISE EXCEPTION 'User already exists as teacher';
    END IF;
    
    -- Check for parents
    IF EXISTS (SELECT 1 FROM public.parents WHERE id = NEW.id) THEN
        RAISE EXCEPTION 'User already exists as parent';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS ensure_single_role_student ON public.students;
DROP TRIGGER IF EXISTS ensure_single_role_teacher ON public.teachers;
DROP TRIGGER IF EXISTS ensure_single_role_parent ON public.parents;

-- Create triggers for each role table
CREATE TRIGGER ensure_single_role_student
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION check_single_role();

CREATE TRIGGER ensure_single_role_teacher
    BEFORE INSERT ON public.teachers
    FOR EACH ROW
    EXECUTE FUNCTION check_single_role();

CREATE TRIGGER ensure_single_role_parent
    BEFORE INSERT ON public.parents
    FOR EACH ROW
    EXECUTE FUNCTION check_single_role();

-- ============================================================================
-- 3. ENFORCE ONE ACTIVE ENROLLMENT PER STUDENT
-- ============================================================================
-- Add unique constraint to prevent multiple enrollments per student

-- Option 1: Partial unique index (allows only one active enrollment)
CREATE UNIQUE INDEX IF NOT EXISTS unique_student_enrollment 
ON public.student_enrollments (student_id);

-- Alternative: If you want to allow historical enrollments but only one active,
-- you could add an 'active' boolean column and create a partial unique index:
-- ALTER TABLE public.student_enrollments ADD COLUMN IF NOT EXISTS active boolean DEFAULT true;
-- CREATE UNIQUE INDEX IF NOT EXISTS unique_active_student_enrollment 
-- ON public.student_enrollments (student_id) WHERE active = true;

-- ============================================================================
-- 4. ADD CASCADE DELETE FOR RELATIONSHIPS
-- ============================================================================
-- Ensure foreign keys have proper ON DELETE CASCADE

-- Update student_enrollments to cascade delete
ALTER TABLE public.student_enrollments
DROP CONSTRAINT IF EXISTS student_enrollments_student_id_fkey,
ADD CONSTRAINT student_enrollments_student_id_fkey 
    FOREIGN KEY (student_id) 
    REFERENCES public.students(id) 
    ON DELETE CASCADE;

ALTER TABLE public.student_enrollments
DROP CONSTRAINT IF EXISTS student_enrollments_class_room_id_fkey,
ADD CONSTRAINT student_enrollments_class_room_id_fkey 
    FOREIGN KEY (class_room_id) 
    REFERENCES public.class_rooms(id) 
    ON DELETE CASCADE;

-- Update parent_student_relationships
ALTER TABLE public.parent_student_relationships
DROP CONSTRAINT IF EXISTS parent_student_relationships_parent_id_fkey,
ADD CONSTRAINT parent_student_relationships_parent_id_fkey 
    FOREIGN KEY (parent_id) 
    REFERENCES public.parents(id) 
    ON DELETE CASCADE;

ALTER TABLE public.parent_student_relationships
DROP CONSTRAINT IF EXISTS parent_student_relationships_student_id_fkey,
ADD CONSTRAINT parent_student_relationships_student_id_fkey 
    FOREIGN KEY (student_id) 
    REFERENCES public.students(id) 
    ON DELETE CASCADE;

-- Update role tables to cascade from users
ALTER TABLE public.students
DROP CONSTRAINT IF EXISTS students_id_fkey,
ADD CONSTRAINT students_id_fkey 
    FOREIGN KEY (id) 
    REFERENCES public.users(id) 
    ON DELETE CASCADE;

ALTER TABLE public.teachers
DROP CONSTRAINT IF EXISTS teachers_id_fkey,
ADD CONSTRAINT teachers_id_fkey 
    FOREIGN KEY (id) 
    REFERENCES public.users(id) 
    ON DELETE CASCADE;

ALTER TABLE public.parents
DROP CONSTRAINT IF EXISTS parents_id_fkey,
ADD CONSTRAINT parents_id_fkey 
    FOREIGN KEY (id) 
    REFERENCES public.users(id) 
    ON DELETE CASCADE;

-- ============================================================================
-- 5. NORMALIZE COLUMN NAMING
-- ============================================================================
-- Ensure consistent use of class_room_id (not class_id)

-- Fix tasks table if it uses class_id instead of class_room_id
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' AND column_name = 'class_id'
    ) THEN
        -- Rename class_id to class_room_id if it exists
        ALTER TABLE public.tasks RENAME COLUMN class_id TO class_room_id;
        
        -- Recreate foreign key with correct name
        ALTER TABLE public.tasks
        DROP CONSTRAINT IF EXISTS tasks_class_id_fkey,
        ADD CONSTRAINT tasks_class_room_id_fkey 
            FOREIGN KEY (class_room_id) 
            REFERENCES public.class_rooms(id);
    END IF;
END $$;

-- Fix quizzes table if it uses class_id instead of class_room_id
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'quizzes' AND column_name = 'class_id'
    ) THEN
        -- Rename class_id to class_room_id
        ALTER TABLE public.quizzes RENAME COLUMN class_id TO class_room_id;
        
        -- Recreate foreign key with correct name
        ALTER TABLE public.quizzes
        DROP CONSTRAINT IF EXISTS quizzes_class_id_fkey,
        ADD CONSTRAINT quizzes_class_room_id_fkey 
            FOREIGN KEY (class_room_id) 
            REFERENCES public.class_rooms(id);
    END IF;
END $$;

-- ============================================================================
-- 6. CREATE TRIGGER FOR AUTO-GENERATING PARENT_NAME
-- ============================================================================
-- Auto-generate parent_name from first_name and last_name if not provided

CREATE OR REPLACE FUNCTION generate_parent_name()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-generate parent_name from first_name and last_name if not provided
    IF NEW.parent_name IS NULL OR NEW.parent_name = '' THEN
        NEW.parent_name := TRIM(CONCAT(NEW.first_name, ' ', NEW.last_name));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_generate_parent_name ON public.parents;
CREATE TRIGGER auto_generate_parent_name
    BEFORE INSERT OR UPDATE ON public.parents
    FOR EACH ROW
    EXECUTE FUNCTION generate_parent_name();

-- ============================================================================
-- 7. ENSURE ROLE ENUM IS PROPERLY DEFINED
-- ============================================================================
-- Create role enum type if it doesn't exist

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE public.user_role AS ENUM ('student', 'teacher', 'parent', 'admin');
    END IF;
END $$;

-- Update users.role column to use enum if it's not already
-- Note: This might require data migration if role is currently text
-- ALTER TABLE public.users 
-- ALTER COLUMN role TYPE public.user_role USING role::public.user_role;

-- ============================================================================
-- 8. ADD VALIDATION TRIGGER FOR STUDENT ENROLLMENT
-- ============================================================================
-- Prevent duplicate enrollments (already handled by unique index, but add trigger for better error messages)

CREATE OR REPLACE FUNCTION validate_student_enrollment()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if student is already enrolled in another class
    IF EXISTS (
        SELECT 1 FROM public.student_enrollments 
        WHERE student_id = NEW.student_id 
        AND class_room_id != NEW.class_room_id
    ) THEN
        RAISE EXCEPTION 'Student is already enrolled in another class. Please unassign them first.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS validate_student_enrollment_trigger ON public.student_enrollments;
CREATE TRIGGER validate_student_enrollment_trigger
    BEFORE INSERT ON public.student_enrollments
    FOR EACH ROW
    EXECUTE FUNCTION validate_student_enrollment();

-- ============================================================================
-- 9. ADD MISSING TIMESTAMPS
-- ============================================================================
-- Ensure all tables have created_at and updated_at where appropriate

ALTER TABLE public.parents 
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

ALTER TABLE public.teachers 
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- ============================================================================
-- 10. ADD UPDATED_AT TRIGGER FUNCTION
-- ============================================================================
-- Auto-update updated_at timestamp on row updates

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
DROP TRIGGER IF EXISTS update_parents_updated_at ON public.parents;
CREATE TRIGGER update_parents_updated_at
    BEFORE UPDATE ON public.parents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_students_updated_at ON public.students;
CREATE TRIGGER update_students_updated_at
    BEFORE UPDATE ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_teachers_updated_at ON public.teachers;
CREATE TRIGGER update_teachers_updated_at
    BEFORE UPDATE ON public.teachers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 11. RLS POLICIES FOR STORAGE BUCKETS (SUPABASE DASHBOARD)
-- ============================================================================
-- These policies should be configured in Supabase Dashboard > Storage
-- But here's the SQL if you want to apply via SQL Editor:

-- For materials bucket:
-- CREATE POLICY "Teachers can upload materials"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (
--     bucket_id = 'materials' AND
--     (storage.foldername(name))[1] = (SELECT id::text FROM auth.users WHERE id = auth.uid())
-- );

-- CREATE POLICY "Authenticated users can read materials"
-- ON storage.objects FOR SELECT
-- TO authenticated
-- USING (bucket_id = 'materials');

-- For profile picture buckets (teacher-avatars, student-avatars):
-- CREATE POLICY "Users can upload own profile picture"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK (
--     (bucket_id = 'teacher-avatars' OR bucket_id = 'student-avatars') AND
--     (storage.foldername(name))[1] = (SELECT id::text FROM auth.users WHERE id = auth.uid())
-- );

-- CREATE POLICY "Public can read profile pictures"
-- ON storage.objects FOR SELECT
-- TO public
-- USING (bucket_id = 'teacher-avatars' OR bucket_id = 'student-avatars');

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify the schema is correct:

-- Check parent table structure
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'parents' 
-- ORDER BY ordinal_position;

-- Check unique constraints
-- SELECT conname, contype, conrelid::regclass 
-- FROM pg_constraint 
-- WHERE conrelid = 'public.student_enrollments'::regclass;

-- Check triggers
-- SELECT trigger_name, event_manipulation, event_object_table 
-- FROM information_schema.triggers 
-- WHERE trigger_schema = 'public';

