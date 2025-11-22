-- ============================================================================
-- SUPABASE CONFIGURATION FOR QUIZ COMPLETION TRACKING
-- ============================================================================
-- This script ensures proper Row Level Security (RLS) policies and indexes
-- for student_submissions table to fix quiz completion tracking issues.
-- Run this in your Supabase SQL Editor.
-- ============================================================================

-- ============================================================================
-- 1. ENABLE ROW LEVEL SECURITY ON student_submissions
-- ============================================================================
ALTER TABLE public.student_submissions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 2. RLS POLICIES FOR student_submissions
-- ============================================================================

-- 2.1 Students can view their own submissions
DROP POLICY IF EXISTS "Students can view own submissions" ON public.student_submissions;
CREATE POLICY "Students can view own submissions"
ON public.student_submissions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.students 
    WHERE students.id = auth.uid() 
    AND students.id = student_submissions.student_id
  )
);

-- 2.2 Students can insert their own submissions
DROP POLICY IF EXISTS "Students can insert own submissions" ON public.student_submissions;
CREATE POLICY "Students can insert own submissions"
ON public.student_submissions FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.students 
    WHERE students.id = auth.uid() 
    AND students.id = student_submissions.student_id
  )
);

-- 2.3 Students can update their own submissions (for score corrections)
DROP POLICY IF EXISTS "Students can update own submissions" ON public.student_submissions;
CREATE POLICY "Students can update own submissions"
ON public.student_submissions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.students 
    WHERE students.id = auth.uid() 
    AND students.id = student_submissions.student_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.students 
    WHERE students.id = auth.uid() 
    AND students.id = student_submissions.student_id
  )
);

-- 2.4 Teachers can view all submissions from their classes
DROP POLICY IF EXISTS "Teachers can view class submissions" ON public.student_submissions;
CREATE POLICY "Teachers can view class submissions"
ON public.student_submissions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.teachers 
    WHERE teachers.id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.assignments
    INNER JOIN public.class_rooms ON assignments.class_room_id = class_rooms.id
    WHERE assignments.id = student_submissions.assignment_id
    AND class_rooms.teacher_id = auth.uid()
  )
);

-- 2.5 Teachers can update submissions (for grading)
DROP POLICY IF EXISTS "Teachers can update class submissions" ON public.student_submissions;
CREATE POLICY "Teachers can update class submissions"
ON public.student_submissions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.assignments
    INNER JOIN public.class_rooms ON assignments.class_room_id = class_rooms.id
    WHERE assignments.id = student_submissions.assignment_id
    AND class_rooms.teacher_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.assignments
    INNER JOIN public.class_rooms ON assignments.class_room_id = class_rooms.id
    WHERE assignments.id = student_submissions.assignment_id
    AND class_rooms.teacher_id = auth.uid()
  )
);

-- 2.6 Admins can view all submissions
DROP POLICY IF EXISTS "Admins can view all submissions" ON public.student_submissions;
CREATE POLICY "Admins can view all submissions"
ON public.student_submissions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- ============================================================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================================================

-- 3.1 Index for querying submissions by student_id and assignment_id
CREATE INDEX IF NOT EXISTS idx_student_submissions_student_assignment
ON public.student_submissions (student_id, assignment_id);

-- 3.2 Index for querying submissions by assignment_id (for teachers)
CREATE INDEX IF NOT EXISTS idx_student_submissions_assignment_id
ON public.student_submissions (assignment_id);

-- 3.3 Index for querying by submitted_at (for sorting)
CREATE INDEX IF NOT EXISTS idx_student_submissions_submitted_at
ON public.student_submissions (submitted_at DESC);

-- 3.4 Index for querying by student_id (for dashboard)
CREATE INDEX IF NOT EXISTS idx_student_submissions_student_id
ON public.student_submissions (student_id);

-- ============================================================================
-- 4. VERIFY FOREIGN KEY RELATIONSHIPS
-- ============================================================================

-- Ensure student_submissions has proper foreign key to assignments
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'student_submissions_assignment_id_fkey'
        AND table_name = 'student_submissions'
    ) THEN
        ALTER TABLE public.student_submissions
        ADD CONSTRAINT student_submissions_assignment_id_fkey
        FOREIGN KEY (assignment_id)
        REFERENCES public.assignments(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- Ensure student_submissions has proper foreign key to students
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'student_submissions_student_id_fkey'
        AND table_name = 'student_submissions'
    ) THEN
        ALTER TABLE public.student_submissions
        ADD CONSTRAINT student_submissions_student_id_fkey
        FOREIGN KEY (student_id)
        REFERENCES public.students(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- ============================================================================
-- 5. VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify the configuration:

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename = 'student_submissions';

-- Check RLS policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies 
-- WHERE tablename = 'student_submissions';

-- Check indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'student_submissions';

-- Check foreign keys
-- SELECT
--     tc.constraint_name, 
--     tc.table_name, 
--     kcu.column_name, 
--     ccu.table_name AS foreign_table_name,
--     ccu.column_name AS foreign_column_name 
-- FROM information_schema.table_constraints AS tc 
-- JOIN information_schema.key_column_usage AS kcu
--   ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage AS ccu
--   ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY' 
-- AND tc.table_name = 'student_submissions';

