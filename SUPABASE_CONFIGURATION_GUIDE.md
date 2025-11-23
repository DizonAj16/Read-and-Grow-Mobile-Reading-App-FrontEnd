# Supabase Configuration Guide for Quiz Completion Tracking

## Overview
This guide explains the Supabase configurations needed to fix the quiz completion tracking issue where completed quizzes don't move from pending to completed.

## Problem
After a student completes a quiz:
- The quiz doesn't disappear from pending
- The quiz doesn't appear in completed
- This happens even after refresh

## Root Cause
The issue is likely due to missing or incorrect Row Level Security (RLS) policies on the `student_submissions` table, which prevents the app from properly querying submission data.

## Solution

### Step 1: Run the SQL Script
1. Open your Supabase Dashboard
2. Go to **SQL Editor**
3. Create a new query
4. Copy and paste the contents of `SUPABASE_QUIZ_COMPLETION_FIXES.sql`
5. Click **Run** to execute the script

### Step 2: What the Script Does

#### 1. Enables Row Level Security (RLS)
- Enables RLS on `student_submissions` table to ensure proper access control

#### 2. Creates RLS Policies
- **Students can view their own submissions** - Allows students to see their quiz submissions
- **Students can insert their own submissions** - Allows students to submit quizzes
- **Students can update their own submissions** - Allows score corrections
- **Teachers can view class submissions** - Allows teachers to see all submissions from their classes
- **Teachers can update class submissions** - Allows teachers to grade submissions
- **Admins can view all submissions** - Allows admins full access

#### 3. Creates Performance Indexes
- Index on `(student_id, assignment_id)` - For fast lookup of student submissions
- Index on `assignment_id` - For teacher queries
- Index on `submitted_at` - For sorting submissions by date
- Index on `student_id` - For dashboard queries

#### 4. Verifies Foreign Key Relationships
- Ensures proper relationships between `student_submissions`, `assignments`, and `students` tables

## Verification

After running the script, verify the configuration:

### Check RLS is Enabled
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'student_submissions';
```
Should return `rowsecurity = true`

### Check Policies Exist
```sql
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'student_submissions';
```
Should show all 6 policies listed above

### Check Indexes Exist
```sql
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'student_submissions';
```
Should show at least 4 indexes

## Testing

After configuration:

1. **Student Side:**
   - Complete a quiz
   - Check if it appears in completed quizzes
   - Check if it disappears from pending quizzes
   - Refresh the page and verify the status persists

2. **Teacher/Admin Side:**
   - View student submissions
   - Verify completed quizzes are visible
   - Verify pending quizzes are correctly filtered

## Troubleshooting

### If students still can't see their submissions:
1. Check if RLS is enabled: `SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'student_submissions';`
2. Check if policies exist: `SELECT policyname FROM pg_policies WHERE tablename = 'student_submissions';`
3. Verify student ID matches: Check if `auth.uid()` matches `student_submissions.student_id`

### If queries are slow:
1. Check if indexes exist: `SELECT indexname FROM pg_indexes WHERE tablename = 'student_submissions';`
2. Run `ANALYZE student_submissions;` to update query statistics

### If foreign key errors occur:
1. Verify assignments exist: `SELECT COUNT(*) FROM assignments;`
2. Verify students exist: `SELECT COUNT(*) FROM students;`
3. Check foreign key constraints: See verification queries in the SQL file

## Additional Notes

- The script uses `IF EXISTS` and `IF NOT EXISTS` clauses, so it's safe to run multiple times
- All policies use `TO authenticated` to ensure only logged-in users can access data
- The unique index on `(student_id, assignment_id, attempt_number)` from `DATABASE_SCHEMA_FIXES.sql` is preserved

## Related Files

- `SUPABASE_QUIZ_COMPLETION_FIXES.sql` - The SQL script to run
- `DATABASE_SCHEMA_FIXES.sql` - General database schema fixes (run this first if not already done)
- `lib/pages/student pages/student_dashboard_page.dart` - Updated to query quizzes correctly
- `lib/pages/student pages/list_of_quiz_and_lessons.dart` - Updated refresh mechanism

