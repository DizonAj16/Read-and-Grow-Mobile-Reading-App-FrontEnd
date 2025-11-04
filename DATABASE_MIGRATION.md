# Database Migration for Reading Recordings Feature

## Schema Requirements

### Important Note on Task Structure
Your Supabase database has two task-related tables:
- `reading_tasks` - Contains reading-specific tasks linked to `reading_levels` via `level_id`
- `tasks` - General tasks table that may not have `reading_level_id` field

The `enhanced_reading_level_page.dart` uses `tasks` table with `reading_level_id` field. 
You need to verify if the `tasks` table has a `reading_level_id` column or if you should be using `reading_tasks` instead.

## New Table: student_readings

This table stores student reading recordings with grading information.

```sql
CREATE TABLE public.student_readings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  task_id uuid NOT NULL,
  recording_url text NOT NULL,
  recorded_at timestamp with time zone DEFAULT now(),
  needs_grading boolean NOT NULL DEFAULT true,
  score double precision,
  teacher_comments text,
  graded_at timestamp with time zone,
  CONSTRAINT student_readings_pkey PRIMARY KEY (id),
  CONSTRAINT student_readings_student_id_fkey FOREIGN KEY (student_id) REFERENCES auth.users(id),
  CONSTRAINT student_readings_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id)
);

-- Add index for faster queries
CREATE INDEX idx_student_readings_needs_grading ON public.student_readings(needs_grading);
CREATE INDEX idx_student_readings_student_id ON public.student_readings(student_id);
CREATE INDEX idx_student_readings_task_id ON public.student_readings(task_id);
```

## If tasks table doesn't have reading_level_id

If your `tasks` table doesn't have a `reading_level_id` field, you have two options:

### Option 1: Add reading_level_id to tasks table
```sql
ALTER TABLE public.tasks ADD COLUMN reading_level_id uuid;
ALTER TABLE public.tasks ADD CONSTRAINT tasks_reading_level_id_fkey 
    FOREIGN KEY (reading_level_id) REFERENCES public.reading_levels(id);
```

### Option 2: Change code to use reading_tasks instead
Update `enhanced_reading_level_page.dart` line 52-56 to use `reading_tasks`:
```dart
final tasksRes = await supabase
    .from('reading_tasks')  // Changed from 'tasks'
    .select('*')
    .eq('level_id', levelId)  // Changed from 'reading_level_id'
    .order('order', ascending: true);
```

And update `student_readings` foreign key:
```sql
-- Drop existing constraint and recreate
ALTER TABLE public.student_readings 
  DROP CONSTRAINT student_readings_task_id_fkey;
ALTER TABLE public.student_readings 
  ADD CONSTRAINT student_readings_task_id_fkey 
  FOREIGN KEY (task_id) REFERENCES public.reading_tasks(id);
```

## Notes

1. The `student_id` references `auth.users(id)` because students are authenticated users in Supabase
2. `task_id` references either `public.tasks(id)` or `public.reading_tasks(id)` depending on your schema
3. `recording_url` stores the full URL to the audio file in storage
4. `needs_grading` defaults to true for all new recordings
5. `score` and `teacher_comments` are optional until a teacher grades the recording
6. `graded_at` is set when a teacher completes the grading
7. Ensure `student_voice` storage bucket exists with proper RLS policies

