# Offline script checks

Run `python3 -m unittest discover -s tests -v`. The verifier tests execute the
real shell script with a fake ADB executable. No connected device is used.

The accessibility examples are synthetic and follow AOSP's
[Android 9 dump format](https://android.googlesource.com/platform/frameworks/base/+/android-9.0.0_r1/services/accessibility/java/com/android/server/accessibility/AccessibilityManagerService.java)
and [Android 14 dump format](https://android.googlesource.com/platform/frameworks/base/+/android-14.0.0_r1/services/accessibility/java/com/android/server/accessibility/AccessibilityUserState.java).
They cover bound, enabled-but-unbound, other-user, unknown-format, failed-read
and opt-out cases. They are not a substitute for running the changed verifier
on Fire OS hardware.
