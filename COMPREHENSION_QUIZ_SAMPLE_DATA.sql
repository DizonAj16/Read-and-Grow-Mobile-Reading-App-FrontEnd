-- ============================================================================
-- COMPREHENSION QUIZ SYSTEM - SAMPLE DATA FOR LESSONS/MATERIALS
-- Creates test data for: Materials → Tasks → Quizzes
-- Flow: Read Lesson → Take Quiz → Unlock Next Lesson
-- ============================================================================

-- ============================================================================
-- 1. SAMPLE MATERIALS/LESSONS (if not exists)
-- ============================================================================

-- Note: Replace teacher_id and class_room_id with actual IDs from your database

-- Lesson 1: Introduction to Reading
INSERT INTO public.materials (
  id,
  class_room_id,
  uploaded_by,
  material_title,
  material_type,
  description,
  material_file_url,
  file_extension,
  created_at
)
SELECT 
  1001,
  (SELECT id FROM public.class_rooms LIMIT 1),
  (SELECT id FROM public.teachers LIMIT 1),
  'Lesson 1: Introduction to Reading',
  'pdf',
  'Learn the basics of reading comprehension',
  'materials/lessons/lesson1_intro.pdf',
  'pdf',
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM public.materials 
  WHERE id = 1001
);

-- Lesson 2: Reading Comprehension
INSERT INTO public.materials (
  id,
  class_room_id,
  uploaded_by,
  material_title,
  material_type,
  description,
  material_file_url,
  file_extension,
  created_at
)
SELECT 
  1002,
  (SELECT id FROM public.class_rooms LIMIT 1),
  (SELECT id FROM public.teachers LIMIT 1),
  'Lesson 2: Reading Comprehension',
  'pdf',
  'Practice understanding what you read',
  'materials/lessons/lesson2_comprehension.pdf',
  'pdf',
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM public.materials 
  WHERE id = 1002
);

-- Lesson 3: Advanced Reading Skills
INSERT INTO public.materials (
  id,
  class_room_id,
  uploaded_by,
  material_title,
  material_type,
  description,
  material_file_url,
  file_extension,
  created_at
)
SELECT 
  1003,
  (SELECT id FROM public.class_rooms LIMIT 1),
  (SELECT id FROM public.teachers LIMIT 1),
  'Lesson 3: Advanced Reading Skills',
  'pdf',
  'Master advanced reading techniques',
  'materials/lessons/lesson3_advanced.pdf',
  'pdf',
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM public.materials 
  WHERE id = 1003
);

-- ============================================================================
-- 2. TASKS (Sample tasks linked to materials)
-- ============================================================================

-- Task 1: Lesson 1 Quiz - Unlocks Lesson 2
INSERT INTO public.tasks (
  id,
  title,
  description,
  class_room_id,
  unlocks_next_level,
  order,
  created_at
)
SELECT 
  '20000000-0000-0000-0000-000000000001',
  'Quiz: Introduction to Reading',
  'Test your understanding of Lesson 1',
  (SELECT id FROM public.class_rooms LIMIT 1),
  true, -- This task unlocks the next lesson
  1,
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM public.tasks 
  WHERE id = '20000000-0000-0000-0000-000000000001'
);

-- Task 2: Lesson 2 Quiz - Unlocks Lesson 3
INSERT INTO public.tasks (
  id,
  title,
  description,
  class_room_id,
  unlocks_next_level,
  order,
  created_at
)
SELECT 
  '20000000-0000-0000-0000-000000000002',
  'Quiz: Reading Comprehension',
  'Test your understanding of Lesson 2',
  (SELECT id FROM public.class_rooms LIMIT 1),
  true, -- This task unlocks Lesson 3
  2,
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM public.tasks 
  WHERE id = '20000000-0000-0000-0000-000000000002'
);

-- Task 3: Lesson 3 Quiz - Does not unlock (last lesson)
INSERT INTO public.tasks (
  id,
  title,
  description,
  class_room_id,
  unlocks_next_level,
  order,
  created_at
)
SELECT 
  '20000000-0000-0000-0000-000000000003',
  'Quiz: Advanced Reading Skills',
  'Test your understanding of Lesson 3',
  (SELECT id FROM public.class_rooms LIMIT 1),
  false, -- This task does NOT unlock next lesson (last lesson)
  3,
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM public.tasks 
  WHERE id = '20000000-0000-0000-0000-000000000003'
);

-- ============================================================================
-- 3. LINK MATERIALS TO TASKS (task_materials)
-- ============================================================================

-- Link Lesson 1 material to Task 1
INSERT INTO public.task_materials (
  id,
  task_id,
  material_title,
  description,
  material_file_path,
  material_type
)
SELECT 
  '30000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  'Lesson 1: Introduction to Reading',
  'Reading material for comprehension quiz',
  'materials/lessons/lesson1_intro.pdf',
  'pdf'
WHERE NOT EXISTS (
  SELECT 1 FROM public.task_materials 
  WHERE id = '30000000-0000-0000-0000-000000000001'
);

-- Link Lesson 2 material to Task 2
INSERT INTO public.task_materials (
  id,
  task_id,
  material_title,
  description,
  material_file_path,
  material_type
)
SELECT 
  '30000000-0000-0000-0000-000000000002',
  '20000000-0000-0000-0000-000000000002',
  'Lesson 2: Reading Comprehension',
  'Reading material for comprehension quiz',
  'materials/lessons/lesson2_comprehension.pdf',
  'pdf'
WHERE NOT EXISTS (
  SELECT 1 FROM public.task_materials 
  WHERE id = '30000000-0000-0000-0000-000000000002'
);

-- Link Lesson 3 material to Task 3
INSERT INTO public.task_materials (
  id,
  task_id,
  material_title,
  description,
  material_file_path,
  material_type
)
SELECT 
  '30000000-0000-0000-0000-000000000003',
  '20000000-0000-0000-0000-000000000003',
  'Lesson 3: Advanced Reading Skills',
  'Reading material for comprehension quiz',
  'materials/lessons/lesson3_advanced.pdf',
  'pdf'
WHERE NOT EXISTS (
  SELECT 1 FROM public.task_materials 
  WHERE id = '30000000-0000-0000-0000-000000000003'
);

-- ============================================================================
-- 4. QUIZZES (Sample quizzes linked to tasks)
-- ============================================================================

-- Quiz 1: For Task 1 (Lesson 1)
INSERT INTO public.quizzes (
  id,
  task_id,
  title,
  class_room_id
)
SELECT 
  '40000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  'Quiz: Introduction to Reading',
  (SELECT id FROM public.class_rooms LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM public.quizzes 
  WHERE id = '40000000-0000-0000-0000-000000000001'
);

-- Quiz 2: For Task 2 (Lesson 2)
INSERT INTO public.quizzes (
  id,
  task_id,
  title,
  class_room_id
)
SELECT 
  '40000000-0000-0000-0000-000000000002',
  '20000000-0000-0000-0000-000000000002',
  'Quiz: Reading Comprehension',
  (SELECT id FROM public.class_rooms LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM public.quizzes 
  WHERE id = '40000000-0000-0000-0000-000000000002'
);

-- Quiz 3: For Task 3 (Lesson 3)
INSERT INTO public.quizzes (
  id,
  task_id,
  title,
  class_room_id
)
SELECT 
  '40000000-0000-0000-0000-000000000003',
  '20000000-0000-0000-0000-000000000003',
  'Quiz: Advanced Reading Skills',
  (SELECT id FROM public.class_rooms LIMIT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM public.quizzes 
  WHERE id = '40000000-0000-0000-0000-000000000003'
);

-- ============================================================================
-- 5. QUIZ QUESTIONS (Sample questions for Quiz 1)
-- ============================================================================

-- Question 1 for Quiz 1
INSERT INTO public.quiz_questions (
  id,
  quiz_id,
  question_text,
  question_type,
  sort_order
)
SELECT 
  '50000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  'What is the main purpose of reading?',
  'multiple_choice',
  1
WHERE NOT EXISTS (
  SELECT 1 FROM public.quiz_questions 
  WHERE id = '50000000-0000-0000-0000-000000000001'
);

-- Options for Question 1
INSERT INTO public.question_options (id, question_id, option_text, is_correct)
VALUES 
  ('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'To understand information', true),
  ('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', 'To waste time', false),
  ('60000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000001', 'To skip pages', false),
  ('60000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000001', 'To look at pictures', false)
ON CONFLICT (id) DO NOTHING;

-- Question 2 for Quiz 1
INSERT INTO public.quiz_questions (
  id,
  quiz_id,
  question_text,
  question_type,
  sort_order
)
SELECT 
  '50000000-0000-0000-0000-000000000002',
  '40000000-0000-0000-0000-000000000001',
  'What should you do when you encounter a word you don''t know?',
  'multiple_choice',
  2
WHERE NOT EXISTS (
  SELECT 1 FROM public.quiz_questions 
  WHERE id = '50000000-0000-0000-0000-000000000002'
);

-- Options for Question 2
INSERT INTO public.question_options (id, question_id, option_text, is_correct)
VALUES 
  ('60000000-0000-0000-0000-000000000005', '50000000-0000-0000-0000-000000000002', 'Try to understand from context', true),
  ('60000000-0000-0000-0000-000000000006', '50000000-0000-0000-0000-000000000002', 'Skip it', false),
  ('60000000-0000-0000-0000-000000000007', '50000000-0000-0000-0000-000000000002', 'Stop reading', false),
  ('60000000-0000-0000-0000-000000000008', '50000000-0000-0000-0000-000000000002', 'Guess randomly', false)
ON CONFLICT (id) DO NOTHING;

-- Question 3 for Quiz 1
INSERT INTO public.quiz_questions (
  id,
  quiz_id,
  question_text,
  question_type,
  sort_order
)
SELECT 
  '50000000-0000-0000-0000-000000000003',
  '40000000-0000-0000-0000-000000000001',
  'Reading comprehension means:',
  'multiple_choice',
  3
WHERE NOT EXISTS (
  SELECT 1 FROM public.quiz_questions 
  WHERE id = '50000000-0000-0000-0000-000000000003'
);

-- Options for Question 3
INSERT INTO public.question_options (id, question_id, option_text, is_correct)
VALUES 
  ('60000000-0000-0000-0000-000000000009', '50000000-0000-0000-0000-000000000003', 'Understanding what you read', true),
  ('60000000-0000-0000-0000-000000000010', '50000000-0000-0000-0000-000000000003', 'Reading fast', false),
  ('60000000-0000-0000-0000-000000000011', '50000000-0000-0000-0000-000000000003', 'Reading loud', false),
  ('60000000-0000-0000-0000-000000000012', '50000000-0000-0000-0000-000000000003', 'Reading many books', false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 6. TEST SCENARIO DATA
-- ============================================================================

-- To test the flow:
-- 1. Student reads lesson (insert into lesson_readings)
-- 2. Student takes quiz (insert into quiz_completions)
-- 3. System automatically unlocks next lesson if quiz passed

-- Example: Mark lesson as read (replace student_id and material_id)
-- INSERT INTO public.lesson_readings (
--   student_id,
--   material_id,
--   task_id,
--   class_room_id,
--   is_completed,
--   completed_at,
--   reading_duration_seconds
-- )
-- VALUES (
--   'YOUR_STUDENT_ID_HERE',
--   1001, -- Lesson 1
--   '20000000-0000-0000-0000-000000000001', -- Task 1
--   (SELECT id FROM public.class_rooms LIMIT 1),
--   true,
--   now(),
--   300 -- 5 minutes reading time
-- );

-- Example: Complete quiz (this will trigger lesson unlock if passed)
-- INSERT INTO public.quiz_completions (
--   student_id,
--   quiz_id,
--   task_id,
--   material_id,
--   class_room_id,
--   score,
--   max_score,
--   passed,
--   passing_threshold
-- )
-- VALUES (
--   'YOUR_STUDENT_ID_HERE',
--   '40000000-0000-0000-0000-000000000001', -- Quiz 1
--   '20000000-0000-0000-0000-000000000001', -- Task 1
--   1001, -- Lesson 1 material
--   (SELECT id FROM public.class_rooms LIMIT 1),
--   3, -- Score: 3 out of 3
--   3, -- Max score: 3
--   true, -- Passed (100% >= 70%)
--   0.7 -- 70% passing threshold
-- );
-- This will automatically unlock Lesson 2 (material_id: 1002) for the student!

-- ============================================================================
-- END OF SAMPLE DATA
-- ============================================================================
