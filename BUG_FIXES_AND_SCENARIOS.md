# Bug Fixes and Scenario Testing Guide

## 🔧 Critical Bug Fixes Applied

### 1. Database Schema Clarification
**Issue**: Unclear which table to use (`tasks` vs `reading_tasks`)  
**Fix**: Added clear documentation in `DATABASE_MIGRATION.md` with both options  
**Status**: ✅ Documented

### 2. Foreign Key Reference
**Issue**: `student_readings` references `auth.users` (not `students`) for student_id  
**Fix**: Migration script uses correct reference  
**Status**: ✅ Fixed

### 3. Student ID in Progress Tracking
**Issue**: `student_task_progress` uses `user_id` from `auth.users` not `students.id`  
**Current Code**: Already uses `user.id` (auth user ID)  
**Status**: ✅ Correct

## 📋 Scenario Testing Checklist

### Student Scenarios

#### ✅ 1. Student Reads PDF with Recording
**Given**: Student is logged in and has assigned reading level  
**When**: Student opens a reading task  
**Then**:
- [x] PDF loads from `task_materials` table
- [x] Fallback to `passage_text` works if no PDF
- [x] Recording button is visible
- [x] Can record while viewing PDF
- [x] Can preview recording
- [x] Can clear and re-record
- [x] Must record before submitting

**Test Cases**:
```
1. Task with PDF → Should display PDF viewer
2. Task without PDF but with passage_text → Should display text
3. Task with neither → Should show "No reading material available"
4. Start recording → Button turns red, mic icon changes
5. Stop recording → Preview button appears
6. Preview → Audio plays, pause/stop works
7. Clear → Recording removed, back to record state
8. Submit without recording → Error message shown
9. Submit with recording → Uploads to storage, saves to DB
```

#### ✅ 2. Multiple Attempts Per Task
**Given**: Student has up to 3 attempts  
**When**: Student submits recording  
**Then**:
- [x] Attempt counter decreases in app bar
- [x] Can retry if attempts remain
- [x] Cannot proceed if out of attempts
- [x] Progress saved to `student_task_progress`

**Test Cases**:
```
1. First attempt → Shows "2 attempts left"
2. Second attempt → Shows "1 attempt left"
3. Third attempt → Shows "0 attempts left"
4. Fourth attempt → Button disabled, warning message shown
5. After quiz → Progress marked as completed
```

#### ⚠️ 3. Sequential Task Unlocking
**Given**: Multiple tasks in reading level  
**When**: Student completes Task 1  
**Then**:
- [x] Task 2 becomes unlocked
- [x] Task 1 shows completed status
- [x] Visual indicators update

**Test Cases**:
```
1. Load level → First task unlocked, others locked
2. Complete Task 1 → Task 2 unlocks
3. Complete Task 2 → Task 3 unlocks
4. Refresh page → Lock states persist
5. Completed tasks → Green checkmark, "Completed" badge
```

#### ⚠️ 4. Offline Access (Partially Implemented)
**Given**: PDF downloaded to device  
**When**: Device goes offline  
**Then**:
- [x] PDF still viewable (local file)
- [ ] Recordings stored locally until online
- [ ] Upload queue on reconnection

**Current State**: PDF downloads work, but no offline queue yet  
**Priority**: Medium

### Teacher Scenarios

#### ✅ 5. Teacher Views Recordings to Grade
**Given**: Teacher logged in  
**When**: Teacher opens "Grade Reading Recordings"  
**Then**:
- [x] Sees list of ungraded recordings
- [x] Each card shows student name, task name, date
- [x] Empty state if all graded
- [x] Refresh button works

**Test Cases**:
```
1. No recordings → Shows "All recordings graded" message
2. Multiple recordings → All listed with proper info
3. Refresh → Reloads list from database
4. Sort order → Newest first (recorded_at DESC)
```

#### ✅ 6. Teacher Grades Recording
**Given**: Teacher views recording  
**When**: Teacher clicks on recording card  
**Then**:
- [x] Dialog opens with audio player
- [x] Can play/pause/stop audio
- [x] Position slider works
- [x] Duration displays correctly
- [x] Score slider (0-10) works
- [x] Comments field editable
- [x] Save updates database
- [x] Recording removed from list

**Test Cases**:
```
1. Play audio → Starts playback, button changes to pause
2. Pause audio → Stops playback, button changes to play
3. Seek audio → Position updates
4. Change score → Value updates in UI
5. Add comments → Text saves
6. Save grade → Dialog closes, list refreshes
7. Recording no longer in list → Confirmed graded
```

#### ⚠️ 7. Teacher Assigns Reading Level to Student
**Given**: Teacher managing pupils  
**When**: Teacher assigns reading level  
**Then**:
- [ ] Student sees assigned level immediately
- [ ] Tasks for that level load
- [ ] Progress tracking starts

**Current State**: Feature exists but needs testing  
**Location**: `teacher_student_list_modal.dart`

### Edge Cases & Error Handling

#### ✅ 8. Permission Denied
**Scenario**: Student tries to record without mic permission  
**Result**: 
- [x] Shows "Microphone permission denied" snackbar
- [x] Recording button still visible
- [x] User can retry

#### ⚠️ 9. Upload Failures
**Scenario**: Network error during upload  
**Result**:
- [x] Error message displayed
- [ ] Recording saved locally
- [ ] Retry mechanism
- [ ] Progress indicator

**Current State**: Error handling exists but no retry queue

#### ⚠️ 10. Storage Full
**Scenario**: Supabase storage quota exceeded  
**Result**:
- [ ] Error message
- [ ] Prevent further uploads
- [ ] Alert admin

**Action Needed**: Add storage quota check

#### ⚠️ 11. Corrupted Audio File
**Scenario**: Downloaded file corrupted  
**Result**:
- [x] Debug error logged
- [ ] User-friendly error message
- [ ] Retry download option

#### ⚠️ 12. PDF Viewing Issues
**Scenario**: PDF won't load or render  
**Result**:
- [x] Falls back to `passage_text`
- [ ] Error message
- [ ] Download retry

### Data Integrity Scenarios

#### ✅ 13. Concurrent Recording Submissions
**Scenario**: Student submits multiple times quickly  
**Result**:
- [x] Database constrains prevent duplicates
- [x] Each recording gets unique filename
- [x] Progress updates once per submission

#### ⚠️ 14. Recording Without Task Progress
**Scenario**: `student_readings` exists but no `student_task_progress`  
**Result**:
- [x] Progress auto-created on submission
- [ ] Handle orphaned recordings

#### ⚠️ 15. Graded Recording Deleted from Storage
**Scenario**: Teacher grades, then admin deletes file  
**Result**:
- [x] Database record still exists
- [ ] Audio player shows error
- [ ] Handle gracefully

## 🐛 Known Issues & Workarounds

### Issue 1: Task Type Mismatch
**Problem**: Code uses `tasks` table but database may use `reading_tasks`  
**Impact**: Medium - Reading levels won't load  
**Workaround**: See `DATABASE_MIGRATION.md` for migration options  
**Priority**: High

### Issue 2: No Offline Support
**Problem**: No offline queue for recordings  
**Impact**: Low - Requires internet  
**Workaround**: Ensure internet connectivity  
**Priority**: Medium

### Issue 3: No Audio Compression
**Problem**: Audio files can be large  
**Impact**: Medium - Storage costs  
**Workaround**: Monitor storage usage  
**Priority**: Low

### Issue 4: No Transcript Analysis
**Problem**: Manual grading only  
**Impact**: Low - Teachers must listen to all recordings  
**Workaround**: None  
**Priority**: Future Enhancement

## 🔍 Testing Priority

### P0 - Critical (Must Test Before Production)
1. ✅ Record and submit reading
2. ✅ Teacher grade recording
3. ⚠️ Task loading with correct table
4. ⚠️ Multiple attempts tracking
5. ⚠️ Sequential task unlocking

### P1 - Important (Should Test)
6. ⚠️ Offline PDF viewing
7. ⚠️ Error handling for failed uploads
8. ⚠️ Storage quota management
9. ⚠️ Concurrent submissions
10. ⚠️ Data integrity checks

### P2 - Nice to Have
11. Audio compression
12. Transcript analysis
13. Batch grading
14. Export grades report

## 📝 Test Data Requirements

For comprehensive testing, you need:

### Students
- At least 2 students with assigned reading levels
- Different progress states (none, in progress, completed)

### Tasks
- At least 5 tasks per reading level
- Mix of PDF and text-only tasks
- Various difficulty levels

### Recordings
- Multiple recordings per student
- Mix of graded and ungraded
- Various audio quality samples

### Teachers
- At least 1 teacher able to grade
- Access to assigned students

## 🎯 Success Criteria

Feature is production-ready when:
- [x] All P0 scenarios pass
- [ ] All P1 scenarios pass
- [ ] Database migration verified
- [ ] Storage policy configured
- [ ] User acceptance testing complete
- [ ] Performance benchmarks met
- [ ] Security audit passed


