# MVP v0.3 — Local practice reminders

## 1. What was implemented

- **`ReminderService`** ([`lib/services/reminder_service.dart`](lib/services/reminder_service.dart)): initializes `flutter_local_notifications`, creates a high-importance Android channel with sound and vibration, requests notification permission on Android 13+ (and iOS), and schedules or cancels local notifications from the daily plan.
- **App startup** ([`lib/main.dart`](lib/main.dart)): `ReminderService.instance.initialize()` runs after Firebase initialization and before `runApp`.
- **Home** ([`lib/screens/home_screen.dart`](lib/screens/home_screen.dart)): after today’s plan loads successfully, the app calls `cancelAllReminders()` then `scheduleSessionReminders(plan)` so reminders are not duplicated across rebuilds. Shows **“Reminders are active”** when at least one session reminder was scheduled. In debug mode, **“Test reminder in 10 seconds”** schedules a one-shot notification.
- **Practice completion** ([`lib/screens/practice_screen.dart`](lib/screens/practice_screen.dart)): when the last task finishes, the session’s **follow-up** notification is cancelled (if it was registered) before navigating to `DoneScreen`.
- **Dependencies**: direct [`timezone`](https://pub.dev/packages/timezone) and [`flutter_timezone`](https://pub.dev/packages/flutter_timezone) for correct `TZDateTime` / local IANA zone handling with `zonedSchedule`.

## 2. How reminders are scheduled

1. When the home load pipeline resolves a non-null `DailyPlan`, it always runs **`cancelAllReminders()`** first, clearing all pending notifications and the in-memory follow-up id map.
2. If `plan.sessions` is non-empty, it calls **`scheduleSessionReminders(plan)`**:
   - For each session index `i`, parses `preferred_time` and `follow_up_time` as `HH:mm` (24-hour).
   - Builds a `TZDateTime` on **`plan.date`** (`yyyy-MM-dd`) in the device’s local timezone.
   - If that instant is **already in the past**, that notification is **skipped** (avoids firing immediately on every open).
   - Schedules two one-shot notifications per session (when times are valid and in the future) using **`AndroidScheduleMode.inexactAllowWhileIdle`** (no exact alarm permission).
3. **Stable notification ids** use `Object.hash(plan.date, sessionId, index, slot) & 0x7fffffff` with a slot for primary vs follow-up.
4. **Follow-up cancellation** after practice uses a map **`sessionId → notification id`** populated when follow-ups are scheduled. **`cancelSessionFollowUp`** only works for non-empty `sessionId` keys present in that map.

## 3. Notification channel details (Android)

| Property | Value |
|----------|--------|
| Channel id | `speech_practice_reminders` |
| Channel name | `Speech Practice Reminders` |
| Importance | `Importance.high` |
| Notification priority (details) | `Priority.high` |
| Sound | `playSound: true` (default sound) |
| Vibration | `enableVibration: true` |

**Primary notification:** title `Speech practice ready`, body `Your practice session is ready.`  
**Follow-up notification:** title `Gentle reminder`, body `Your speech practice is still pending.`

Manifest already includes **`POST_NOTIFICATIONS`** ([`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml)).

## 4. How to test the 10-second reminder

1. Run the app in **debug** on a device or emulator (**Android 13+**: accept the notification permission prompt).
2. On the home screen, tap **“Test reminder in 10 seconds”** (debug-only control).
3. Background the app or leave it open; after ~10 seconds you should see/hear the notification with vibration (device settings permitting).

## 5. Known limitations

- **Inexact scheduling** on Android may drift from the exact minute; no `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` in this MVP.
- Times **in the past** for today are not scheduled; opening the app late in the day may result in **no** reminders until the next day’s plan load.
- **`cancelSessionFollowUp`** depends on the in-memory map and a **non-empty `session_id`** in Firestore; empty or duplicate `session_id` values are not fully supported.
- **Session scheduling** runs only on **Android and iOS** (Linux `zonedSchedule` is not used here).
- Reminders are **cleared on `cancelAll`**; refreshing the home screen reschedules from the current plan.

## 6. Next steps

- Add **exact alarms** only if product requires minute-precise firing and Play policy allows it.
- Persist “last scheduled plan version / date” if you need to avoid redundant work without `cancelAll`.
- **iOS**: tune categories, badges, and permission UX if you ship primarily on iOS.
- Optional: cancel the **primary** (“practice ready”) notification when the user starts a session, not only the follow-up.
