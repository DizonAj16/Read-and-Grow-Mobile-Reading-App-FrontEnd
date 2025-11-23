-- Sample Data Insert Statements for Reading with Recording Feature
-- This file contains example data for testing the complete feature

-- ============================================================================
-- STEP 1: Create a Reading Level
-- ============================================================================
INSERT INTO public.reading_levels (level_number, title, description) VALUES
(1, 'Beginner Level', 'Introduction to basic reading skills for young learners');

-- Note: Get the UUID of the level you just created for use below
-- Let's assume we got: 11111111-1111-1111-1111-111111111111

-- ============================================================================
-- STEP 2: Create Tasks for this Reading Level
-- ============================================================================
-- Option A: If your schema has tasks table with reading_level_id
INSERT INTO public.tasks (title, description, reading_level_id, "order", unlocks_next_level) VALUES
('The Cat and The Bird', 'A simple story about friendship between a cat and a bird', 
 '11111111-1111-1111-1111-111111111111', 1, false);

-- Option B: If your schema uses reading_tasks table with level_id
INSERT INTO public.reading_tasks (level_id, title, description, "order") VALUES
('11111111-1111-1111-1111-111111111111', 'The Cat and The Bird', 
 'A simple story about friendship between a cat and a bird', 1);

-- Note: Get the task UUID for use below
-- Let's assume we got: 22222222-2222-2222-2222-222222222222

-- ============================================================================
-- STEP 3: Add PDF Material to the Task
-- ============================================================================
INSERT INTO public.task_materials (task_id, material_title, description, material_file_path, material_type) VALUES
('22222222-2222-2222-2222-222222222222', 
 'The Cat and The Bird Story', 
 'PDF version of the reading story',
 'reading-materials/cat-and-bird-story.pdf',
 'pdf');

-- ============================================================================
-- STEP 4: Create a Student Assignment
-- ============================================================================
-- First, ensure you have a student in the students table linked to auth.users
-- Note: The student_id here references auth.users(id), not students(id)

-- Get a student's user_id from auth.users (assume: 33333333-3333-3333-3333-333333333333)
-- Update the student's reading level
UPDATE public.students 
SET current_reading_level_id = '11111111-1111-1111-1111-111111111111'
WHERE user_id = '33333333-3333-3333-3333-333333333333';

-- ============================================================================
-- STEP 5: Create Initial Progress Record
-- ============================================================================
-- Create progress for the student-task combination
INSERT INTO public.student_task_progress (
    student_id, 
    task_id, 
    attempts_left, 
    completed, 
    score, 
    max_score, 
    correct_answers, 
    wrong_answers
) VALUES (
    '33333333-3333-3333-3333-333333333333',  -- student_id (from auth.users)
    '22222222-2222-2222-2222-222222222222',  -- task_id
    3,                                       -- attempts_left
    false,                                   -- completed
    0,                                       -- score
    0,                                       -- max_score
    0,                                       -- correct_answers
    0                                        -- wrong_answers
);

-- ============================================================================
-- STEP 6: Simulate a Student Recording Submission
-- ============================================================================
-- When a student records their reading, insert into student_readings
INSERT INTO public.student_readings (
    student_id,
    task_id,
    recording_url,
    recorded_at,
    needs_grading
) VALUES (
    '33333333-3333-3333-3333-333333333333',  -- student_id (from auth.users)
    '22222222-2222-2222-2222-222222222222',  -- task_id
    'https://your-supabase-project.supabase.co/storage/v1/object/public/student_voice/recording-12345.m4a',
    NOW(),
    true
);

-- ============================================================================
-- STEP 7: Simulate Teacher Grading
-- ============================================================================
-- When a teacher grades the recording, update the student_readings record
UPDATE public.student_readings 
SET 
    score = 8.5,
    teacher_comments = 'Great pronunciation! Keep practicing the difficult words.',
    needs_grading = false,
    graded_at = NOW()
WHERE 
    student_id = '33333333-3333-3333-3333-333333333333'
    AND task_id = '22222222-2222-2222-2222-222222222222'
    AND needs_grading = true;

-- ============================================================================
-- STEP 8: Update Student Progress After Grading
-- ============================================================================
-- Update the student's task progress based on quiz results
UPDATE public.student_task_progress 
SET 
    attempts_left = 2,
    completed = true,
    score = 85,
    max_score = 100,
    correct_answers = 8,
    wrong_answers = 2,
    updated_at = NOW()
WHERE 
    student_id = '33333333-3333-3333-3333-333333333333'
    AND task_id = '22222222-2222-2222-2222-222222222222';

-- ============================================================================
-- EXTRA: Create a Quiz for the Task (if needed)
-- ============================================================================
-- If you want to add a quiz linked to the task
INSERT INTO public.quizzes (task_id, title, class_id) VALUES
('22222222-2222-2222-2222-222222222222', 'The Cat and The Bird Quiz', NULL);

-- Note: Get the quiz UUID
-- Let's assume we got: 44444444-4444-4444-4444-444444444444

-- Add quiz questions
INSERT INTO public.quiz_questions (quiz_id, question_text, question_type, sort_order) VALUES
('44444444-4444-4444-4444-444444444444', 'What were the main characters in the story?', 'multiple_choice', 1),
('44444444-4444-4444-4444-444444444444', 'Where did the cat and bird meet?', 'multiple_choice', 2);

-- Add question options
INSERT INTO public.question_options (question_id, option_text, is_correct) VALUES
-- For question 1
((SELECT id FROM public.quiz_questions WHERE question_text = 'What were the main characters in the story?' LIMIT 1), 'Cat and Bird', true),
((SELECT id FROM public.quiz_questions WHERE question_text = 'What were the main characters in the story?' LIMIT 1), 'Dog and Cat', false),
((SELECT id FROM public.quiz_questions WHERE question_text = 'What were the main characters in the story?' LIMIT 1), 'Bird and Fish', false),
((SELECT id FROM public.quiz_questions WHERE question_text = 'What were the main characters in the story?' LIMIT 1), 'Rabbit and Bird', false),
-- For question 2
((SELECT id FROM public.quiz_questions WHERE question_text = 'Where did the cat and bird meet?' LIMIT 1), 'In the garden', true),
((SELECT id FROM public.quiz_questions WHERE question_text = 'Where did the cat and bird meet?' LIMIT 1), 'At the park', false),
((SELECT id FROM public.quiz_questions WHERE question_text = 'Where did the cat and bird meet?' LIMIT 1), 'In the house', false);

-- ============================================================================
-- EXTRA: Create an Assignment (if task is assigned to a class)
-- ============================================================================
-- If you have a class_room_id (assume: 55555555-5555-5555-5555-555555555555)
-- If you have a teacher_id (assume: 66666666-6666-6666-6666-666666666666)
INSERT INTO public.assignments (
    task_id,
    class_room_id,
    teacher_id,
    assigned_date,
    due_date,
    max_attempts
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    '55555555-5555-5555-5555-555555555555',
    '66666666-6666-6666-6666-666666666666',
    NOW(),
    NOW() + INTERVAL '7 days',
    3
);

-- ============================================================================
-- QUERY: View Complete Data for Verification
-- ============================================================================
-- Run this to see all the connected data

SELECT 
    rl.title as level_title,
    rt.title as task_title,
    tm.material_title as pdf_title,
    sp.attempts_left,
    sp.completed,
    sp.score,
    sr.recording_url,
    sr.score as teacher_score,
    sr.teacher_comments,
    sr.needs_grading
FROM 
    reading_levels rl
JOIN reading_tasks rt ON rt.level_id = rl.id
LEFT JOIN task_materials tm ON tm.task_id = rt.id
LEFT JOIN student_task_progress sp ON sp.task_id = rt.id
LEFT JOIN student_readings sr ON sr.task_id = rt.id
WHERE 
    rl.level_number = 1;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
IMPORTANT: Replace all UUID placeholders with actual UUIDs from your database!

To get real UUIDs:
1. After inserting reading_levels, run:
   SELECT id FROM reading_levels WHERE level_number = 1;

2. After inserting tasks/reading_tasks, run:
   SELECT id FROM tasks WHERE title = 'The Cat and The Bird';
   -- OR
   SELECT id FROM reading_tasks WHERE title = 'The Cat and The Bird';

3. To find a student's user_id:
   SELECT s.user_id, s.student_name 
   FROM students s 
   LIMIT 1;

4. To find a teacher's ID:
   SELECT t.id, t.teacher_name 
   FROM teachers t 
   LIMIT 1;

5. To find a classroom ID:
   SELECT c.id, c.class_name 
   FROM class_rooms c 
   LIMIT 1;
*/

-- ============================================================================
-- CLEANUP (Use for testing)
-- ============================================================================
-- Uncomment to delete the test data (run in reverse order)

-- DELETE FROM student_readings WHERE recording_url LIKE '%recording-12345.m4a%';
-- DELETE FROM question_options WHERE question_id IN (SELECT id FROM quiz_questions WHERE quiz_id = '44444444-4444-4444-4444-444444444444');
-- DELETE FROM quiz_questions WHERE quiz_id = '44444444-4444-4444-4444-444444444444';
-- DELETE FROM quizzes WHERE id = '44444444-4444-4444-4444-444444444444';
-- DELETE FROM assignments WHERE task_id = '22222222-2222-2222-2222-222222222222';
-- DELETE FROM student_task_progress WHERE task_id = '22222222-2222-2222-2222-222222222222';
-- DELETE FROM task_materials WHERE task_id = '22222222-2222-2222-2222-222222222222';
-- DELETE FROM tasks WHERE id = '22222222-2222-2222-2222-222222222222';
-- DELETE FROM reading_tasks WHERE id = '22222222-2222-2222-2222-222222222222';
-- DELETE FROM reading_levels WHERE id = '11111111-1111-1111-1111-111111111111';


