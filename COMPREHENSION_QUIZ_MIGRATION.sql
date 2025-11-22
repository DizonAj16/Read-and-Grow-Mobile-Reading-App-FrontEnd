-- ============================================================================
-- COMPREHENSION QUIZ SYSTEM MIGRATION - PRODUCTION READY
-- Flow: Read Lesson/Material → Take Quiz → Unlock Next Lesson/Material
-- ============================================================================

-- ============================================================================
-- 1. CREATE LESSON READINGS TABLE
-- Tracks when students read lessons/materials (prerequisite for taking quiz)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.lesson_readings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  material_id bigint NOT NULL, -- References materials.id (bigint)
  task_id uuid, -- Optional: link to task if material is part of a task
  class_room_id uuid NOT NULL, -- The class this material belongs to
  started_at timestamp with time zone DEFAULT now() NOT NULL,
  completed_at timestamp with time zone,
  reading_duration_seconds integer DEFAULT 0 NOT NULL CHECK (reading_duration_seconds >= 0),
  pages_viewed integer DEFAULT 0 NOT NULL CHECK (pages_viewed >= 0),
  is_completed boolean DEFAULT false NOT NULL,
  last_page_viewed integer DEFAULT 0 CHECK (last_page_viewed >= 0),
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT lesson_readings_pkey PRIMARY KEY (id),
  CONSTRAINT lesson_readings_student_id_fkey 
    FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE,
  CONSTRAINT lesson_readings_material_id_fkey 
    FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE,
  CONSTRAINT lesson_readings_task_id_fkey 
    FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE SET NULL,
  CONSTRAINT lesson_readings_class_room_id_fkey 
    FOREIGN KEY (class_room_id) REFERENCES public.class_rooms(id) ON DELETE CASCADE,
  -- Prevent duplicate readings (one reading per student per material)
  CONSTRAINT lesson_readings_unique UNIQUE (student_id, material_id),
  -- Ensure completed_at is set when is_completed is true
  CONSTRAINT lesson_readings_completed_check 
    CHECK ((is_completed = false) OR (is_completed = true AND completed_at IS NOT NULL))
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_lesson_readings_student_id 
  ON public.lesson_readings(student_id);
CREATE INDEX IF NOT EXISTS idx_lesson_readings_material_id 
  ON public.lesson_readings(material_id);
CREATE INDEX IF NOT EXISTS idx_lesson_readings_task_id 
  ON public.lesson_readings(task_id);
CREATE INDEX IF NOT EXISTS idx_lesson_readings_class_room_id 
  ON public.lesson_readings(class_room_id);
CREATE INDEX IF NOT EXISTS idx_lesson_readings_completed 
  ON public.lesson_readings(is_completed) WHERE is_completed = true;
CREATE INDEX IF NOT EXISTS idx_lesson_readings_student_task 
  ON public.lesson_readings(student_id, task_id) WHERE task_id IS NOT NULL;

-- Trigger to update updated_at timestamp
DROP FUNCTION IF EXISTS public.update_lesson_readings_updated_at() CASCADE;

CREATE OR REPLACE FUNCTION public.update_lesson_readings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_lesson_readings_updated_at ON public.lesson_readings;

CREATE TRIGGER trigger_update_lesson_readings_updated_at
  BEFORE UPDATE ON public.lesson_readings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_lesson_readings_updated_at();

-- ============================================================================
-- 2. ALTER EXISTING QUIZ COMPLETIONS TABLE FOR LESSON/MATERIAL SUPPORT
-- The quiz_completions table already exists for reading_levels
-- We're adding columns to support lessons/materials as well
-- ============================================================================

-- Drop dependent views FIRST to avoid conflicts when altering table
-- These views will be recreated later in the migration
DROP VIEW IF EXISTS public.v_student_quiz_performance CASCADE;
DROP VIEW IF EXISTS public.v_student_lesson_progress CASCADE;
DROP VIEW IF EXISTS public.v_lesson_completion_rate CASCADE;

-- Add columns for lesson/material support (if they don't exist)
DO $$
BEGIN
  -- Add lesson_material_id (bigint) for materials table
  -- Keep existing material_id (UUID) for reading_materials
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quiz_completions' AND column_name = 'lesson_material_id'
  ) THEN
    ALTER TABLE public.quiz_completions 
    ADD COLUMN lesson_material_id bigint;
    
    ALTER TABLE public.quiz_completions
    ADD CONSTRAINT quiz_completions_lesson_material_id_fkey 
      FOREIGN KEY (lesson_material_id) REFERENCES public.materials(id) ON DELETE SET NULL;
  END IF;
  
  -- Add class_room_id for lessons (nullable - only needed for lessons, not reading levels)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quiz_completions' AND column_name = 'class_room_id'
  ) THEN
    ALTER TABLE public.quiz_completions 
    ADD COLUMN class_room_id uuid;
    
    ALTER TABLE public.quiz_completions
    ADD CONSTRAINT quiz_completions_class_room_id_fkey 
      FOREIGN KEY (class_room_id) REFERENCES public.class_rooms(id) ON DELETE CASCADE;
  END IF;
  
  -- Add next_material_unlocked (bigint) for unlocking next lesson/material
  -- Keep existing next_level_unlocked (UUID) for reading levels
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'quiz_completions' AND column_name = 'next_material_unlocked'
  ) THEN
    ALTER TABLE public.quiz_completions 
    ADD COLUMN next_material_unlocked bigint;
    
    ALTER TABLE public.quiz_completions
    ADD CONSTRAINT quiz_completions_next_material_unlocked_fkey 
      FOREIGN KEY (next_material_unlocked) REFERENCES public.materials(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Note: The existing quiz_completions table structure is preserved
-- Existing columns (for reading levels):
--   - material_id (UUID) → reading_materials
--   - reading_level_id (UUID) → reading_levels  
--   - next_level_unlocked (UUID) → reading_levels
-- New columns (for lessons/materials):
--   - lesson_material_id (bigint) → materials
--   - class_room_id (UUID) → class_rooms (nullable - only for lessons)
--   - next_material_unlocked (bigint) → materials

-- Indexes for faster queries (add if they don't exist)
CREATE INDEX IF NOT EXISTS idx_quiz_completions_student_id 
  ON public.quiz_completions(student_id);
CREATE INDEX IF NOT EXISTS idx_quiz_completions_quiz_id 
  ON public.quiz_completions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_completions_task_id 
  ON public.quiz_completions(task_id);
CREATE INDEX IF NOT EXISTS idx_quiz_completions_lesson_material_id 
  ON public.quiz_completions(lesson_material_id) WHERE lesson_material_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_quiz_completions_class_room_id 
  ON public.quiz_completions(class_room_id) WHERE class_room_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_quiz_completions_passed 
  ON public.quiz_completions(passed) WHERE passed = true;
CREATE INDEX IF NOT EXISTS idx_quiz_completions_student_task 
  ON public.quiz_completions(student_id, task_id);
CREATE INDEX IF NOT EXISTS idx_quiz_completions_completed_at 
  ON public.quiz_completions(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_quiz_completions_next_material_unlocked 
  ON public.quiz_completions(next_material_unlocked) WHERE next_material_unlocked IS NOT NULL;

-- Trigger to update updated_at timestamp
DROP FUNCTION IF EXISTS public.update_quiz_completions_updated_at() CASCADE;

CREATE OR REPLACE FUNCTION public.update_quiz_completions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_quiz_completions_updated_at ON public.quiz_completions;

CREATE TRIGGER trigger_update_quiz_completions_updated_at
  BEFORE UPDATE ON public.quiz_completions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_quiz_completions_updated_at();

-- ============================================================================
-- 3. CREATE FUNCTION TO UNLOCK NEXT LESSON/MATERIAL
-- Automatically unlocks next lesson/material when quiz is passed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.unlock_next_lesson(
  p_student_id uuid,
  p_current_material_id bigint,
  p_task_id uuid,
  p_class_room_id uuid
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_material_id bigint;
  v_task_unlocks_next boolean;
  v_current_material_order bigint;
  v_student_exists boolean;
  v_task_exists boolean;
BEGIN
  -- Validate inputs
  IF p_student_id IS NULL OR p_current_material_id IS NULL OR p_task_id IS NULL OR p_class_room_id IS NULL THEN
    RAISE EXCEPTION 'All parameters are required: student_id, current_material_id, task_id, class_room_id';
  END IF;
  
  -- Check if student exists
  SELECT EXISTS(SELECT 1 FROM public.students WHERE id = p_student_id) INTO v_student_exists;
  IF NOT v_student_exists THEN
    RAISE EXCEPTION 'Student with id % does not exist', p_student_id;
  END IF;
  
  -- Check if task exists
  SELECT EXISTS(SELECT 1 FROM public.tasks WHERE id = p_task_id) INTO v_task_exists;
  IF NOT v_task_exists THEN
    RAISE EXCEPTION 'Task with id % does not exist', p_task_id;
  END IF;
  
  -- Check if task unlocks next lesson
  SELECT unlocks_next_level INTO v_task_unlocks_next
  FROM public.tasks
  WHERE id = p_task_id;
  
  -- If task doesn't unlock next lesson, return NULL
  IF v_task_unlocks_next IS NOT TRUE THEN
    RETURN NULL;
  END IF;
  
  -- Get current material's order (using created_at as order if no order field exists)
  -- Assuming materials are ordered by created_at or id
  SELECT id INTO v_current_material_order
  FROM public.materials
  WHERE id = p_current_material_id;
  
  IF v_current_material_order IS NULL THEN
    RAISE EXCEPTION 'Material with id % does not exist', p_current_material_id;
  END IF;
  
  -- Get next material in the same class (next by created_at/id)
  SELECT id INTO v_next_material_id
  FROM public.materials
  WHERE class_room_id = p_class_room_id
    AND created_at > (SELECT created_at FROM public.materials WHERE id = p_current_material_id)
    AND id != p_current_material_id
  ORDER BY created_at ASC, id ASC
  LIMIT 1;
  
  -- If next material exists, it's automatically "unlocked" (no need to update student table)
  -- The unlock is tracked in quiz_completions.next_material_unlocked
  IF v_next_material_id IS NOT NULL THEN
    RAISE NOTICE 'Next lesson unlocked: Material % for student %', v_next_material_id, p_student_id;
    RETURN v_next_material_id;
  END IF;
  
  -- No next material exists (student completed all lessons)
  RETURN NULL;
END;
$$;

-- ============================================================================
-- 4. CREATE FUNCTION TO CHECK IF LESSON WAS READ
-- Validates that student read lesson/material before taking quiz
-- ============================================================================

-- Drop existing function if it exists with different signature
DROP FUNCTION IF EXISTS public.has_read_lesson(uuid, bigint);
DROP FUNCTION IF EXISTS public.has_read_lesson(uuid, uuid); -- In case old version used UUID

CREATE OR REPLACE FUNCTION public.has_read_lesson(
  p_student_id uuid,
  p_material_id bigint
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_completed boolean;
  v_student_exists boolean;
  v_material_exists boolean;
BEGIN
  -- Validate inputs
  IF p_student_id IS NULL OR p_material_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- Check if student exists
  SELECT EXISTS(SELECT 1 FROM public.students WHERE id = p_student_id) INTO v_student_exists;
  IF NOT v_student_exists THEN
    RETURN false;
  END IF;
  
  -- Check if material exists
  SELECT EXISTS(SELECT 1 FROM public.materials WHERE id = p_material_id) INTO v_material_exists;
  IF NOT v_material_exists THEN
    RETURN false;
  END IF;
  
  -- Check if lesson was completed
  SELECT is_completed INTO v_completed
  FROM public.lesson_readings
  WHERE student_id = p_student_id
    AND material_id = p_material_id
    AND is_completed = true;
  
  RETURN COALESCE(v_completed, false);
END;
$$;

-- ============================================================================
-- 5. CREATE FUNCTION TO GET NEXT ATTEMPT NUMBER
-- Gets the next attempt number for a student's quiz
-- ============================================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.get_next_quiz_attempt(uuid, uuid);

CREATE OR REPLACE FUNCTION public.get_next_quiz_attempt(
  p_student_id uuid,
  p_quiz_id uuid
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_max_attempt integer;
BEGIN
  -- Validate inputs
  IF p_student_id IS NULL OR p_quiz_id IS NULL THEN
    RETURN 1;
  END IF;
  
  -- Get the maximum attempt number for this student and quiz
  SELECT COALESCE(MAX(attempt_number), 0) INTO v_max_attempt
  FROM public.quiz_completions
  WHERE student_id = p_student_id
    AND quiz_id = p_quiz_id;
  
  -- Return next attempt number
  RETURN v_max_attempt + 1;
END;
$$;

-- ============================================================================
-- 6. CREATE FUNCTION TO VALIDATE QUIZ PREREQUISITES
-- Checks if student can take quiz (lesson read, etc.)
-- ============================================================================

-- Drop existing function(s) with same name but potentially different signatures
DROP FUNCTION IF EXISTS public.can_take_quiz(uuid, uuid);
DROP FUNCTION IF EXISTS public.can_take_quiz(uuid, uuid, bigint);
DROP FUNCTION IF EXISTS public.can_take_quiz(uuid, uuid, uuid);

CREATE OR REPLACE FUNCTION public.can_take_quiz(
  p_student_id uuid,
  p_quiz_id uuid,
  p_material_id bigint DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
  v_lesson_read boolean;
  v_student_exists boolean;
  v_quiz_exists boolean;
  v_task_id uuid;
  v_class_room_id uuid;
BEGIN
  -- Initialize result
  v_result := jsonb_build_object(
    'can_take', false,
    'reason', '',
    'task_id', NULL,
    'class_room_id', NULL
  );
  
  -- Validate inputs
  IF p_student_id IS NULL OR p_quiz_id IS NULL THEN
    v_result := jsonb_set(v_result, '{reason}', '"Invalid parameters"');
    RETURN v_result;
  END IF;
  
  -- Check if student exists
  SELECT EXISTS(SELECT 1 FROM public.students WHERE id = p_student_id) INTO v_student_exists;
  IF NOT v_student_exists THEN
    v_result := jsonb_set(v_result, '{reason}', '"Student does not exist"');
    RETURN v_result;
  END IF;
  
  -- Check if quiz exists and get task_id
  SELECT q.task_id INTO v_task_id
  FROM public.quizzes q
  WHERE q.id = p_quiz_id;
  
  IF v_task_id IS NULL THEN
    v_result := jsonb_set(v_result, '{reason}', '"Quiz does not exist"');
    RETURN v_result;
  END IF;
  
  -- Get class_room_id from quizzes table first (most reliable)
  SELECT class_room_id INTO v_class_room_id
  FROM public.quizzes
  WHERE id = p_quiz_id;
  
  -- If NULL, try to get from materials table (if material_id provided)
  IF v_class_room_id IS NULL AND p_material_id IS NOT NULL THEN
    SELECT class_room_id INTO v_class_room_id
    FROM public.materials
    WHERE id = p_material_id;
  END IF;
  
  -- If still NULL, try to get from assignments table (via task_id)
  IF v_class_room_id IS NULL THEN
    SELECT class_room_id INTO v_class_room_id
    FROM public.assignments
    WHERE task_id = v_task_id
    LIMIT 1;
  END IF;
  
  v_result := jsonb_set(v_result, '{task_id}', to_jsonb(v_task_id));
  v_result := jsonb_set(v_result, '{class_room_id}', to_jsonb(v_class_room_id));
  
  -- Check if lesson was read (if material_id provided - bigint for materials table)
  IF p_material_id IS NOT NULL THEN
    v_lesson_read := public.has_read_lesson(p_student_id, p_material_id);
    IF NOT v_lesson_read THEN
      v_result := jsonb_set(v_result, '{reason}', '"Lesson not read yet"');
      RETURN v_result;
    END IF;
  END IF;
  
  -- Validate that class_room_id was found
  IF v_class_room_id IS NULL THEN
    v_result := jsonb_set(v_result, '{reason}', '"Could not determine class room. Please ensure quiz is linked to a class."');
    RETURN v_result;
  END IF;
  
  -- All checks passed
  v_result := jsonb_set(v_result, '{can_take}', 'true');
  v_result := jsonb_set(v_result, '{reason}', '"All prerequisites met"');
  
  RETURN v_result;
END;
$$;

-- ============================================================================
-- 7. CREATE TRIGGER TO AUTO-UNLOCK NEXT LESSON ON QUIZ COMPLETION
-- Automatically unlocks next lesson/material when quiz_completions record is inserted
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_unlock_next_lesson_on_quiz_completion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_material_id bigint;
  v_score_percentage double precision;
BEGIN
  -- Calculate score percentage
  IF NEW.max_score > 0 THEN
    v_score_percentage := (NEW.score::double precision / NEW.max_score);
  ELSE
    v_score_percentage := 0;
  END IF;
  
  -- Determine if passed based on threshold
  IF v_score_percentage >= NEW.passing_threshold THEN
    NEW.passed := true;
  ELSE
    NEW.passed := false;
  END IF;
  
  -- Only unlock if quiz was passed AND this is a lesson quiz (has lesson_material_id)
  IF NEW.passed = true AND NEW.lesson_material_id IS NOT NULL AND NEW.class_room_id IS NOT NULL THEN
    BEGIN
      -- Call unlock function for lessons/materials
      v_next_material_id := public.unlock_next_lesson(
        NEW.student_id,
        NEW.lesson_material_id,
        NEW.task_id,
        NEW.class_room_id
      );
      
      -- Update the completion record with unlocked material
      IF v_next_material_id IS NOT NULL THEN
        NEW.next_material_unlocked := v_next_material_id;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error but don't fail the insert
        RAISE WARNING 'Error unlocking next lesson for student %: %', NEW.student_id, SQLERRM;
    END;
  END IF;
  
  -- Note: Reading level unlocking (next_level_unlocked) is handled elsewhere
  -- This trigger only handles lesson/material unlocking
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_unlock_next_lesson_on_quiz_completion
  BEFORE INSERT ON public.quiz_completions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_unlock_next_lesson_on_quiz_completion();

-- ============================================================================
-- 8. CREATE VIEWS FOR ANALYTICS
-- Views were dropped earlier before ALTER TABLE to avoid conflicts
-- Now we recreate them with the updated table structure
-- ============================================================================

-- View: Student lesson reading progress
CREATE VIEW public.v_student_lesson_progress AS
SELECT 
  lr.student_id,
  s.student_name,
  lr.class_room_id,
  cr.class_name,
  COUNT(DISTINCT lr.material_id) as lessons_started_count,
  COUNT(DISTINCT CASE WHEN lr.is_completed THEN lr.material_id END) as lessons_completed_count,
  SUM(lr.reading_duration_seconds) as total_reading_time_seconds,
  AVG(lr.reading_duration_seconds) as avg_reading_time_seconds
FROM public.lesson_readings lr
JOIN public.students s ON s.id = lr.student_id
JOIN public.class_rooms cr ON cr.id = lr.class_room_id
GROUP BY lr.student_id, s.student_name, lr.class_room_id, cr.class_name;

-- View: Student quiz performance (for lessons/materials)
CREATE OR REPLACE VIEW public.v_student_quiz_performance AS
SELECT 
  qc.student_id,
  s.student_name,
  qc.class_room_id,
  cr.class_name,
  COUNT(*) as quizzes_taken,
  COUNT(CASE WHEN qc.passed THEN 1 END) as quizzes_passed,
  AVG(qc.score::double precision / NULLIF(qc.max_score, 0)) as avg_score_percentage,
  MAX(qc.completed_at) as last_quiz_date,
  COUNT(DISTINCT qc.next_material_unlocked) as lessons_unlocked_count
FROM public.quiz_completions qc
JOIN public.students s ON s.id = qc.student_id
LEFT JOIN public.class_rooms cr ON cr.id = qc.class_room_id
WHERE qc.lesson_material_id IS NOT NULL -- Only lesson quizzes
GROUP BY qc.student_id, s.student_name, qc.class_room_id, cr.class_name;

-- View: Lesson completion rate
CREATE VIEW public.v_lesson_completion_rate AS
SELECT 
  m.id as material_id,
  m.material_title,
  m.class_room_id,
  cr.class_name,
  COUNT(DISTINCT lr.student_id) as students_started,
  COUNT(DISTINCT CASE WHEN lr.is_completed THEN lr.student_id END) as students_completed,
  CASE 
    WHEN COUNT(DISTINCT lr.student_id) > 0 
    THEN (COUNT(DISTINCT CASE WHEN lr.is_completed THEN lr.student_id END)::double precision / 
          COUNT(DISTINCT lr.student_id)) * 100
    ELSE 0 
  END as completion_rate_percentage
FROM public.materials m
LEFT JOIN public.lesson_readings lr ON lr.material_id = m.id
LEFT JOIN public.class_rooms cr ON cr.id = m.class_room_id
GROUP BY m.id, m.material_title, m.class_room_id, cr.class_name;

-- ============================================================================
-- 9. ROW LEVEL SECURITY POLICIES (if using RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE public.lesson_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_completions ENABLE ROW LEVEL SECURITY;

-- Policy: Students can only see their own lesson readings
CREATE POLICY "Students can view own lesson readings"
  ON public.lesson_readings
  FOR SELECT
  USING (
    student_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.teachers 
      WHERE id = auth.uid()
    )
  );

-- Policy: Students can insert their own lesson readings
CREATE POLICY "Students can insert own lesson readings"
  ON public.lesson_readings
  FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- Policy: Students can update their own lesson readings
CREATE POLICY "Students can update own lesson readings"
  ON public.lesson_readings
  FOR UPDATE
  USING (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

-- Policy: Students can only see their own quiz completions
CREATE POLICY "Students can view own quiz completions"
  ON public.quiz_completions
  FOR SELECT
  USING (
    student_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.teachers 
      WHERE id = auth.uid()
    )
  );

-- Policy: Students can insert their own quiz completions
CREATE POLICY "Students can insert own quiz completions"
  ON public.quiz_completions
  FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- Drop existing policies if they conflict (optional - only if needed)
-- DROP POLICY IF EXISTS "Students can view own quiz completions" ON public.quiz_completions;
-- DROP POLICY IF EXISTS "Students can insert own quiz completions" ON public.quiz_completions;

-- ============================================================================
-- 10. COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE public.lesson_readings IS 'Tracks when students read lessons/materials. Required prerequisite for taking quizzes.';
COMMENT ON TABLE public.quiz_completions IS 'Tracks quiz completion and automatically unlocks next lesson/material when quiz is passed.';
COMMENT ON FUNCTION public.unlock_next_lesson IS 'Unlocks the next lesson/material for a student when quiz is passed.';
COMMENT ON FUNCTION public.has_read_lesson IS 'Checks if a student has completed reading a lesson/material.';
COMMENT ON FUNCTION public.can_take_quiz IS 'Validates if a student can take a quiz (checks lesson reading, etc.).';
COMMENT ON FUNCTION public.get_next_quiz_attempt IS 'Gets the next attempt number for a student quiz.';

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
