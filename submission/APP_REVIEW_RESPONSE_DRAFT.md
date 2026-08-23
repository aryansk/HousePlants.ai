# HousePlants.ai — App Review Response Draft

Prepared for the rejected iOS version 1.0 build 3 submission under Guideline 5.2.5 (Legal:
Intellectual Property - Apple Products). Apple requested WeatherKit attribution: the Apple
Weather trademark and the required legal attribution link, plus a physical-device recording
showing where WeatherKit is used.

## Compact App Store Connect Notes block

This is the compact block currently represented in App Store Connect’s Notes field. Keep the
physical-device evidence truthful if a future submission requires the notes to be repasted.

```text
Thank you for reviewing HousePlants.ai. It is an iPhone-only, local-first plant-care companion for indoor-plant owners and gardeners. It helps users discover plants, learn care requirements, track their collection, and complete routine care tasks.

No account, login, registration, password, or demo credentials are required. Launch the app, tap “Enter your jungle,” browse Discover, open a plant detail page, review the care guide, and add a plant to My Jungle. My Jungle supports watering, fertilising, repotting, journaling, health updates, and reminders. Tools contains search, care calculators, seasonal care, toxicity information, and optional Plant Identifier. Profile contains the privacy information and “Delete All My Data,” which irreversibly removes app data. The app has no public user-generated content, content reporting/blocking flow, paid content, payments, subscriptions, or in-app purchases.

Optional permissions are requested only when their related feature is used: Photos/camera for plant identification or a profile photo; approximate Location for climate-aware recommendations; Notifications for care reminders; Calendar for optional reminder export; and HomeKit for optional temperature/humidity sensor monitoring. The main catalog and local care features remain usable if permissions or hardware are unavailable. Plant Identifier uses a free Pl@ntNet API key supplied by the user; the selected photo is sent over HTTPS to Pl@ntNet and the app does not bundle a credential.

Weather-aware watering uses WeatherKit from Plant Insights. The corrected build displays the
official Apple Weather mark when the WeatherKit attribution asset is available, always provides
a visible ` Weather` fallback, shows the returned legal attribution text, and links to
`https://weatherkit.apple.com/legal-attribution.html`. The physical-device recording shows
My Jungle → long-press a plant → Insights → Weather-aware watering.

External services/platforms: Apple WeatherKit, iCloud private key-value storage, HomeKit, Calendar/EventKit, UserNotifications, Photos/AVFoundation, and the optional Pl@ntNet API. There is no account/authentication, advertising, analytics, tracking, payment processor, or AI service.

The bundled catalog, care guides, collection tracking, calculators, journaling, and local reminders work consistently across regions. WeatherKit, HomeKit, Calendar, Notifications, and Pl@ntNet vary only with regional availability, compatible hardware, user permissions, device settings, or the user’s API key. This is educational plant-care software, not a regulated-industry service.

The rights holder/owner is indiehouse.io. The account holder states that all plant/catalog images used in this version were generated with AI for this project by or for the owner and are owned/authorized for use by indiehouse.io. No third-party catalog photos are intentionally used in this release.

Replacement physical-device recording for build 4: `ScreenRecording_08-21-2026_17-28-29_build4.mp4` is attached to the current version package. It begins on the physical iPhone, shows the corrected WeatherKit attribution flow, and opens the linked WeatherKit data-source page. The prior `ScreenRecording_08-15-2026_13-47-58_1.mp4` belonged to rejected build 3 and was replaced. Device/OS: iPhone 14 Plus, iOS 27.0 (`24A5408d`). Additional physical devices/OS: none claimed.
```

## Paste-ready App Review Information notes

Thank you for reviewing HousePlants.ai. This is an iPhone-only, local-first plant-care companion for indoor-plant owners and gardeners. It helps users discover plants, understand care requirements, track their own collection, and complete routine care tasks in one place.

### Account access

The app does not require an account, login, registration, or password. No demo credentials are needed. The app can be used after launch by tapping “Enter your jungle.”

### Main flow

1. Launch the app.
2. Tap “Enter your jungle” on the welcome screen.
3. In Discover, browse the plant catalog and open a plant detail page.
4. Review the care guide, then add a plant to My Jungle.
5. Open My Jungle to view the collection and record care actions such as watering, fertilising, repotting, journaling, and plant-health updates.
6. Open Tools to use plant search, care calculators, seasonal care, toxicity information, and the optional Plant Identifier.
7. Open Profile to review privacy information or use “Delete All My Data” to remove data stored by the app. This deletion is irreversible.

### Optional permissions and feature flows

The main catalog and local care features remain usable if optional permissions are declined. The app requests access only when the related feature is used:

- Photos/camera: choose or capture a plant photo for the optional Plant Identifier, or choose a profile photo.
- Location: optional approximate location for climate-aware care recommendations.
- Notifications: optional care reminders.
- Calendar: optional export of care reminders to Apple Calendar.
- HomeKit: optional temperature/humidity sensor monitoring and alerts.

The Plant Identifier requires a free Pl@ntNet API key supplied by the user. When the user submits a photo, the selected image is sent over HTTPS to Pl@ntNet and identification results are returned. The app does not include a bundled Pl@ntNet credential.

### WeatherKit attribution

Weather-aware watering is optional and is opened from a plant’s Insights screen. The corrected
build displays Apple’s WeatherKit-provided combined Apple Weather mark when available, with a
visible ` Weather` fallback, the returned legal attribution text, and a link to
`https://weatherkit.apple.com/legal-attribution.html`.

### External services, tools, and platforms

- Apple WeatherKit: optional climate-aware recommendations after location access is granted.
- Apple iCloud private key-value storage: optional mirroring of selected collection, favourites, preferences, and streak data when iCloud is available.
- Apple HomeKit: optional sensor monitoring.
- Apple Calendar/EventKit: optional reminder export.
- Apple UserNotifications: optional local care reminders.
- Apple Photos and AVFoundation camera access: user-selected or user-captured photos for optional features.
- Pl@ntNet API: optional plant identification using the user’s own API key.

The app has no account system, advertising, analytics, tracking, payments, subscriptions, or in-app purchases. The core catalog and care calculations are bundled and work locally.

### Regional behavior

The bundled catalog, care guides, collection tracking, calculators, journaling, and local reminders work consistently across regions. WeatherKit recommendations depend on location and Apple WeatherKit availability. HomeKit depends on the user’s compatible hardware and permissions. Calendar and notifications depend on the user’s permissions and device settings. Pl@ntNet identification depends on the user’s API key and service availability.

### Audience, purpose, and value

The target audience is people who care for indoor plants, from beginners to experienced plant owners. The app addresses the problem of scattered plant-care information and forgotten routines by combining plant discovery, care guidance, collection tracking, reminders, and optional identification tools in a single iPhone app. It is educational and informational plant-care software, not a medical, veterinary, or other regulated-industry service.

### Third-party content and authorization

The account holder states that all plant/catalog images used in this version were generated with AI for this project by or for the owner and are owned/authorized for use by indiehouse.io. No third-party catalog photos are intentionally used in this release. The project provenance record documents the generated image batches and this owner statement.

### Review evidence

The previous physical-device recording belonged to rejected build 3. The replacement recording
is attached to the current version package. It begins on the physical iPhone, shows the main
flow, then shows My Jungle → long-press a plant → Insights → Weather-aware watering with the
Apple Weather mark and legal attribution link visible, followed by the linked WeatherKit
data-source page.

- Physical device and OS: iPhone 14 Plus, iOS 27.0 (`24A5408d`)
- Additional physical devices and OS versions: None claimed
- Previous screen recording: `ScreenRecording_08-15-2026_13-47-58_1.mp4`
- Replacement screen recording: `ScreenRecording_08-21-2026_17-28-29_build4.mp4`

## Live metadata follow-up

On 2026-08-21, the current version package was updated and reloaded successfully: build 4 is
attached, the old build-3 recording was replaced with
`ScreenRecording_08-21-2026_17-28-29_build4.mp4`, and the Notes field identifies the corrected
WeatherKit flow. `Sign-in required` is off, username and password remain blank because the app
has no account, and the verified account-holder phone and email are populated. The Save control
is disabled after the server read-back. The final resubmission was completed on 2026-08-21 at
6:04 PM IST. Apple’s server-rendered detail page shows `Waiting for Review` for version 1.0
build 4 under submission ID `c8d4f3c8-fe87-453f-8916-d5eccdc1469d`.
