# MVP Recording Report

## 1. What was implemented
- Added MVP v0.1 architecture with models, services, screens, and widgets for daily plan-driven speech practice.
- Implemented Firestore daily plan loading from `users/mohsin/plans/YYYY-MM-DD`.
- Implemented per-repetition audio recording using `record`, saving local `.m4a` first in app documents storage.
- Implemented Firebase Storage upload to `audio/mohsin/YYYY-MM-DD/{session_id}/{task_id}_rep_{XX}.m4a`.
- Implemented attempt metadata persistence in Firestore with required linkage fields:
  - `date`
  - `session_id`
  - `task_id`
  - `task_text`
  - `repetition_number`
  - `target_sound`
  - `language`
- Implemented simple UI flow:
  - `HomeScreen`: load today plan and show sessions.
  - `PracticeScreen`: record/stop one repetition at a time, save+upload+persist metadata.
  - `DoneScreen`: show total attempts and upload status summary.
  - `ParentReviewScreen`: list today attempts.
- Implemented error handling for:
  - no plan found
  - microphone permission denied
  - recording failures
  - upload failures
  - Firestore metadata save failures
- Added pending-upload fallback: if upload fails, metadata still saved with `upload_status = pending` and local audio retained.

## 2. Files created/changed
- Created:
  - `lib/models/task_item.dart`
  - `lib/models/session_plan.dart`
  - `lib/models/daily_plan.dart`
  - `lib/models/attempt.dart`
  - `lib/services/auth_service.dart`
  - `lib/services/plan_service.dart`
  - `lib/services/attempt_service.dart`
  - `lib/services/storage_service.dart`
  - `lib/services/recording_service.dart`
  - `lib/screens/home_screen.dart`
  - `lib/screens/practice_screen.dart`
  - `lib/screens/done_screen.dart`
  - `lib/screens/parent_review_screen.dart`
  - `lib/widgets/session_card.dart`
  - `MVP_RECORDING_REPORT.md`
- Updated:
  - `lib/main.dart`
  - `test/widget_test.dart`

## 3. Firestore paths used
- Daily plan read:
  - `users/mohsin/plans/YYYY-MM-DD`
- Attempt metadata write/read:
  - `users/mohsin/attempts/{attempt_id}`

## 4. Firebase Storage paths used
- Audio upload:
  - `audio/mohsin/YYYY-MM-DD/{session_id}/{task_id}_rep_{XX}.m4a`

## 5. Sample Firestore daily plan document
Create this document at:
- `users/mohsin/plans/2026-04-30`

Sample document body:

```json
{
  "date": "2026-04-30",
  "user_id": "mohsin",
  "plan_version": "v0.1",
  "schedule_type": "daily",
  "sessions": [
    {
      "session_id": "morning",
      "title": "Morning Practice",
      "preferred_time": "08:00",
      "follow_up_time": "17:00",
      "estimated_minutes": 20,
      "tasks": [
        {
          "task_id": "t1",
          "type": "word",
          "text": "Practice the word: school",
          "language": "en",
          "target_sound": "sk",
          "repetitions": 3,
          "instruction": "Say clearly and slowly."
        },
        {
          "task_id": "t2",
          "type": "sentence",
          "text": "I study after school.",
          "language": "en",
          "target_sound": "s",
          "repetitions": 2,
          "instruction": "Keep a steady pace."
        }
      ]
    }
  ]
}
```

## 6. Build result
- `flutter clean`: success
- `flutter pub get`: success
- `flutter analyze`: success (`No issues found!`)
- `flutter build apk --debug`: success
  - Output: `build/app/outputs/flutter-apk/app-debug.apk`

## 7. Remaining next steps
- Add retry worker for pending uploads when connectivity returns.
- Add local attempt cache and sync queue for stronger offline support.
- Add playback preview for recorded attempts.
- Add reminders in next milestone (explicitly deferred for v0.1).
