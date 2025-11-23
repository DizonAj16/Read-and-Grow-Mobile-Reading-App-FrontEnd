-- ============================================================================
-- Supabase helper to delete a full class and all dependent records safely.
-- Run this script in the Supabase SQL editor once, then call the RPC
-- function `admin_delete_class(p_class_id uuid)` whenever a teacher removes
-- a class from the app.
-- ============================================================================

create or replace function public.admin_delete_class(
  p_class_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_assignment_ids uuid[];
  v_task_ids uuid[];
  v_quiz_ids uuid[];
  v_question_ids uuid[];
begin
  if p_class_id is null then
    raise exception 'Class id cannot be null';
  end if;

  -- Gather identifiers we will need downstream
  select array_agg(id) into v_assignment_ids
  from public.assignments
  where class_room_id = p_class_id;

  select array_agg(id) into v_task_ids
  from public.tasks
  where class_room_id = p_class_id;

  select array_agg(id) into v_quiz_ids
  from public.quizzes
  where class_room_id = p_class_id
     or (v_task_ids is not null and task_id = any(v_task_ids));

  if v_quiz_ids is not null then
    select array_agg(id) into v_question_ids
    from public.quiz_questions
    where quiz_id = any(v_quiz_ids);
  end if;

  -- Clean up dependent records (order matters to avoid FK violations)
  if v_assignment_ids is not null then
    delete from public.student_submissions
    where assignment_id = any(v_assignment_ids);
  end if;

  if v_task_ids is not null then
    delete from public.student_task_progress
    where task_id = any(v_task_ids);

    delete from public.task_materials
    where task_id = any(v_task_ids);
  end if;

  delete from public.lesson_readings
  where class_room_id = p_class_id;

  if v_question_ids is not null then
    delete from public.student_recordings
    where quiz_question_id = any(v_question_ids);

    delete from public.matching_pairs
    where question_id = any(v_question_ids);

    delete from public.question_options
    where question_id = any(v_question_ids);

    delete from public.quiz_questions
    where id = any(v_question_ids);
  end if;

  if v_quiz_ids is not null then
    delete from public.quizzes
    where id = any(v_quiz_ids);
  end if;

  delete from public.materials
  where class_room_id = p_class_id;

  if v_assignment_ids is not null then
    delete from public.assignments
    where id = any(v_assignment_ids);
  end if;

  if v_task_ids is not null then
    delete from public.tasks
    where id = any(v_task_ids);
  end if;

  delete from public.student_enrollments
  where class_room_id = p_class_id;

  -- Finally remove the class itself
  delete from public.class_rooms
  where id = p_class_id;
end;
$$;

comment on function public.admin_delete_class is
'Deletes a class and all dependent records (assignments, quizzes, submissions, readings, etc.).';

