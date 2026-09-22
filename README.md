# Reminder

Reminder is an iOS 17+ SwiftUI app for scheduling one-time alarms at any future
date and time. It stores alarms locally with SwiftData and delivers them through
iOS local notifications.

The repository also includes the same GitHub Pages PWA installation approach as
Today Priority.

## Install from GitHub Pages

After GitHub Pages is configured to use **GitHub Actions**, open:

<https://yogurt100869.github.io/reminder/>

On iPhone, use Safari's Share menu and select **Add to Home Screen**.

The PWA checks alarms while it is open or resident. iOS does not allow a static
GitHub Pages PWA to guarantee scheduled execution after it has been fully
closed. Use the native app below when reliable background alarms are required.

## Open and run

1. Open `Reminder.xcodeproj` in Xcode 15 or newer.
2. Select the `Reminder` scheme and an iOS 17+ simulator or device.
3. Build and run.
4. Allow notifications when creating the first alarm.

For a device build, select your development team and replace the example bundle
identifier if necessary.

## Included MVP features

- Schedule an alarm for any future date and time
- Optional alarm label
- Upcoming and elapsed alarm states
- Local persistence with no account required
- Notification permission status and actionable error messages
- Swipe to delete an alarm and cancel its pending notification
- Foreground banner and sound presentation

## Platform note

This app uses standard local notifications, matching the reference app's
notification architecture. iOS controls final notification delivery and sound
duration, so this is not a replacement for Apple's Clock alarms and cannot
guarantee continuous ringing or bypass Silent/Focus modes.

## Tests

Run the `ReminderTests` target in Xcode. The tests cover future-date validation
and notification date component generation.

For the PWA:

```sh
npm install
npm test
npm run build
```
