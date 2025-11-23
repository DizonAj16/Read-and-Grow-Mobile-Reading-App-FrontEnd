# How to Unlock New Lessons After Quiz Completion

## Overview
The system **automatically unlocks** the next lesson/material when a student **passes a quiz**. This happens through a database trigger - no manual intervention needed!

## How It Works (Automatic)

### 1. **Student Flow** (Happens Automatically)
```
Read Lesson → Take Quiz → Pass Quiz → Next Lesson Unlocked ✅
```

When a student:
1. Reads a lesson/material
2. Takes the quiz
3. **Passes the quiz** (score >= passing_threshold, default 70%)
4. The system **automatically unlocks** the next lesson/material in sequence

### 2. **Database Trigger** (Already Set Up)
The trigger `trigger_unlock_next_lesson_on_quiz_completion` automatically:
- Checks if quiz was passed
- Calls `unlock_next_lesson()` function
- Finds the next material in the same class (ordered by `created_at`)
- Stores unlocked material ID in `quiz_completions.next_material_unlocked`

## What Teachers Need to Do in Supabase

### ✅ **Step 1: Set Task to Unlock Next Level**

When creating a quiz task, make sure the associated **task** has `unlocks_next_level = true`:

```sql
-- Update existing task
UPDATE public.tasks
SET unlocks_next_level = true
WHERE id = 'your-task-uuid';

-- Or when creating a new task
INSERT INTO public.tasks (
  id,
  task_name,
  task_type,
  class_room_id,
  unlocks_next_level,  -- ⭐ Set this to TRUE
  created_at
)
VALUES (
  gen_random_uuid(),
  'Lesson 1 Quiz',
  'quiz',
  'class-room-uuid',
  true,  -- ⭐ This enables unlocking!
  now()
);
```

### ✅ **Step 2: Create Materials in Order**

Materials are unlocked in the order they were created (`created_at`). Make sure to create lessons/materials in the correct sequence:

```sql
-- Lesson 1 (created first)
INSERT INTO public.materials (
  id,
  material_name,
  class_room_id,
  created_at
)
VALUES (
  1001,
  'Introduction to Reading',
  'class-room-uuid',
  now() - interval '3 days'  -- Created first
);

-- Lesson 2 (created second - will unlock after Lesson 1 quiz)
INSERT INTO public.materials (
  id,
  material_name,
  class_room_id,
  created_at
)
VALUES (
  1002,
  'Advanced Reading Techniques',
  'class-room-uuid',
  now() - interval '2 days'  -- Created second
);

-- Lesson 3 (created third - will unlock after Lesson 2 quiz)
INSERT INTO public.materials (
  id,
  material_name,
  class_room_id,
  created_at
)
VALUES (
  1003,
  'Reading Comprehension',
  'class-room-uuid',
  now() - interval '1 day'  -- Created third
);
```

**Important**: Materials must be in the **same `class_room_id`** to unlock sequentially.

### ✅ **Step 3: Link Quiz to Material**

When creating a quiz, link it to the material:

```sql
INSERT INTO public.quizzes (
  id,
  task_id,
  class_room_id,  -- ⭐ Must match material's class_room_id
  quiz_name,
  created_at
)
VALUES (
  gen_random_uuid(),
  'task-uuid',  -- Task with unlocks_next_level = true
  'class-room-uuid',  -- Same as material
  'Lesson 1 Quiz',
  now()
);
```

## Verification: Check What Was Unlocked

### In Supabase SQL Editor:

```sql
-- Check all unlocked lessons for a student
SELECT 
  qc.student_id,
  s.student_name,
  qc.quiz_id,
  qc.lesson_material_id as current_lesson,
  qc.next_material_unlocked as unlocked_lesson,
  qc.score,
  qc.max_score,
  qc.passed,
  m.material_name as unlocked_lesson_name
FROM public.quiz_completions qc
JOIN public.students s ON s.id = qc.student_id
LEFT JOIN public.materials m ON m.id = qc.next_material_unlocked
WHERE qc.student_id = 'student-uuid'
  AND qc.lesson_material_id IS NOT NULL  -- Only lesson quizzes
ORDER BY qc.completed_at DESC;
```

### In Flutter App:

```dart
final quizService = ComprehensionQuizService();

// Get all unlocked lessons for a student
final unlockedLessons = await quizService.getUnlockedLessons(studentId);
print('Unlocked lessons: $unlockedLessons');

// Check if a specific lesson is unlocked
final isUnlocked = await quizService.isLessonUnlocked(
  studentId: studentId,
  materialId: 1002, // material ID
);
```

## Common Issues & Solutions

### ❌ **Problem: Next lesson not unlocking**

**Check:**
1. ✅ Is `tasks.unlocks_next_level = true`? 
   ```sql
   SELECT unlocks_next_level FROM public.tasks WHERE id = 'task-uuid';
   ```

2. ✅ Did student pass the quiz? (score >= passing_threshold)
   ```sql
   SELECT passed, score, max_score, passing_threshold 
   FROM public.quiz_completions 
   WHERE quiz_id = 'quiz-uuid' AND student_id = 'student-uuid';
   ```

3. ✅ Are materials in the same `class_room_id`?
   ```sql
   SELECT id, material_name, class_room_id, created_at
   FROM public.materials
   WHERE class_room_id = 'class-room-uuid'
   ORDER BY created_at;
   ```

4. ✅ Is there a next material to unlock?
   ```sql
   -- Check if there's a next material after current one
   SELECT id, material_name, created_at
   FROM public.materials
   WHERE class_room_id = 'class-room-uuid'
     AND created_at > (
       SELECT created_at FROM public.materials WHERE id = 1001
     )
   ORDER BY created_at
   LIMIT 1;
   ```

### ❌ **Problem: Wrong lesson unlocking**

**Solution**: Check material creation order. The system unlocks the **next material by `created_at`** in the same class. If materials were created out of order, you may need to:

1. Delete and recreate materials in correct order, OR
2. Manually update `created_at` timestamps:
   ```sql
   UPDATE public.materials
   SET created_at = now() - interval '3 days'
   WHERE id = 1001;  -- First lesson
   
   UPDATE public.materials
   SET created_at = now() - interval '2 days'
   WHERE id = 1002;  -- Second lesson
   ```

## Summary Checklist for Teachers

- [ ] Create materials/lessons in the correct order (by `created_at`)
- [ ] Ensure all materials are in the same `class_room_id`
- [ ] Set `tasks.unlocks_next_level = true` for quiz tasks
- [ ] Link quizzes to materials via `quizzes.class_room_id`
- [ ] Set appropriate `passing_threshold` (default 0.7 = 70%)
- [ ] Test: Student reads lesson → takes quiz → passes → next lesson unlocks automatically!

## Example: Complete Setup

```sql
-- 1. Create materials in order
INSERT INTO public.materials (id, material_name, class_room_id, created_at)
VALUES 
  (1001, 'Lesson 1', 'class-uuid', now() - interval '3 days'),
  (1002, 'Lesson 2', 'class-uuid', now() - interval '2 days'),
  (1003, 'Lesson 3', 'class-uuid', now() - interval '1 day');

-- 2. Create task with unlocking enabled
INSERT INTO public.tasks (id, task_name, task_type, class_room_id, unlocks_next_level)
VALUES (gen_random_uuid(), 'Lesson 1 Quiz', 'quiz', 'class-uuid', true);

-- 3. Create quiz linked to task
INSERT INTO public.quizzes (id, task_id, class_room_id, quiz_name)
VALUES (gen_random_uuid(), 'task-uuid', 'class-uuid', 'Lesson 1 Quiz');

-- 4. When student passes quiz, Lesson 2 (1002) will unlock automatically! 🎉
```

That's it! The system handles everything else automatically. 🚀


