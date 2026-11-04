# ANDROID PERMISSIONS AUDIT — PROJECT RHYTHM (Agent 07)

**Project:** HexaRhythm  
**Owner:** Agent 07 — Android & Release Engineer  
**Date:** 2026-11-04  
**Engine:** Godot 4.3  
**Target:** Android API Level 34 (Android 14) / Min SDK 24 (Android 7.0)

---

## 1. Permission Philosophy

HexaRhythm is an **offline-first** rhythm game. It does not require internet
access, location, camera, contacts, or storage beyond app-private storage.
Only the minimum permissions necessary for core gameplay are requested.

---

## 2. Declared Permissions

| Permission | Purpose | Required? | Justification |
|------------|---------|-----------|---------------|
| VIBRATE | Haptic feedback on note hits | Optional | Enhances gameplay feel; user can disable in settings |
| WAKE_LOCK | Keep screen on during gameplay | Optional | Prevents screen dimming during songs |
| INTERNET | None — offline-first game | **No** | All content is local; no network features |

## 3. Permission Status in `project.godot`

Current `export_presets.cfg` configuration:

```
permissions/custom_permissions=PackedStringArray()
permissions/internet=false
permissions/vibrate=false
permissions/wake_lock=false
```

All permissions are currently **disabled** (false). This is the correct
minimal configuration for an offline-first game with no network features.

## 4. Permission Audit Findings

| Category | Status | Notes |
|----------|--------|-------|
| Internet/Network | ✅ Not requested | Game is fully offline |
| Location | ✅ Not requested | No location features |
| Camera | ✅ Not requested | No camera features |
| Microphone | ✅ Not requested | No voice/audio input features |
| Contacts | ✅ Not requested | No social features |
| Storage (external) | ✅ Not requested | Uses app-private `user://` storage only |
| SMS/Phone | ✅ Not requested | No telephony features |
| Bluetooth | ✅ Not requested | No Bluetooth features |
| VIBRATE | ⚪ Optional | Haptic feedback; disabled by default |
| WAKE_LOCK | ⚪ Optional | Screen-on during gameplay; disabled by default |

## 5. Runtime Permission Handling

Android 6.0+ (API 23+) requires runtime permission requests for dangerous
permissions. Since HexaRhythm requests no dangerous permissions, no runtime
permission dialogs are required.

VIBRATE and WAKE_LOCK are normal permissions (granted at install time) and do
not require runtime requests.

## 6. Audit Conclusion

**PASS** — HexaRhythm requests minimal permissions appropriate for an
offline-first rhythm game. No dangerous permissions are required. No runtime
permission dialogs are needed. The game respects user privacy by not
accessing network, location, contacts, or other sensitive data.

## 7. Future Considerations

If future features require additional permissions (e.g., INTERNET for online
leaderboards, EXTERNAL_STORAGE for custom song imports), each permission must
be:
1. Justified in this audit document
2. Added to `export_presets.cfg`
3. Handled with runtime permission requests (Android 6.0+)
4. Documented in the privacy policy
