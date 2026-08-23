# HousePlants.ai — App Store Connect submission packet

This is the local handoff for the App Store Connect record. It contains the release
notes and the current Apple read-back; anything marked `OWNER ACTION` still needs the
Apple account holder, the live website owner, or legal rights evidence.

## App record

- **App name:** HousePlants.ai
- **Bundle ID:** `Rocket-Games.HousePlants`
- **Version:** `1.0`
- **Rejection history:** build `2` was rejected under `2.1.0 Performance: App Completeness` on 2026-08-15. Build `3` was rejected on 2026-08-20 under `5.2.5 Legal: Intellectual Property - Apple Products` because the WeatherKit flow did not clearly display the Apple Weather trademark and required legal attribution.
- **Last verified App Store Connect submission state:** version `1.0`, build `4` is `Waiting for Review`. Apple shows the submission date as 2026-08-21 at 6:04 PM IST under submission ID `c8d4f3c8-fe87-453f-8916-d5eccdc1469d`. Build `3` remains the rejected 2026-08-20 submission under Guideline `5.2.5`.
- **Latest Apple notice:** an App Store Connect email received on 2026-08-20 at 23:58 IST says “There's an issue with your HousePlants.ai (iOS) submission.” It points to the same submission and does not include the guideline text; the detailed Review page still requires an authenticated App Store Connect session.
- **Submission ID:** `c8d4f3c8-fe87-453f-8916-d5eccdc1469d`.
- **Physical-device evidence:** `ScreenRecording_08-21-2026_17-28-29_build4.mp4` is attached to the current version package for build `4`. It shows the physical-device WeatherKit attribution flow and opens the linked WeatherKit data-source page. The prior build-3 recording was removed from the current package.
- **SKU draft:** `houseplants-ai-ios`
- **Primary category draft:** Lifestyle
- **Secondary category draft:** Reference
- **Copyright:** `© 2026 indiehouse.io` — user-provided rights-holder instruction applied in App Store Connect.
- **Content Rights:** App Store Connect set to “Yes, this app has the necessary rights to its third-party content,” based on the user-provided indiehouse.io ownership statement.

## Store listing draft

### Subtitle

Care for plants with confidence

### Promotional text

Build a thriving indoor jungle with smarter care schedules, plant insights, and a calm daily journal.

### Description

HousePlants.ai helps you turn plant care into a simple, satisfying routine.

Discover a catalog of houseplants, learn what each one needs, and keep every plant on track with personalized watering and care schedules. Log watering, growth, health observations, and journal photos in one calm workspace.

**Everything you need to grow well**

- Personalized watering schedules and optional reminders
- Plant journal with photos, notes, growth tracking, and health scores
- Practical tools for watering, light, fertilizer, soil, propagation, and plant placement
- Seasonal and climate-aware care adjustments using your approximate location when you opt in
- Optional HomeKit sensor monitoring, Calendar export, and notifications
- Plant identification powered by Pl@ntNet when you provide your own free API key

HousePlants.ai includes its complete care toolkit with no account, subscription, or in-app purchase.

Plant-care information is for education only and is not a substitute for professional botanical, veterinary, medical, or other safety advice.

### Keywords

plants,care,watering,garden,journal,houseplant,botanical

### URLs

- **Support URL:** `https://indiehouse.vercel.app/apps/houseplants` — current live App Store Connect value and publicly reachable. This is the original Indie House site hosted on Vercel; `indiehouse.io` is the intended custom-domain address for the same site, although its DNS does not currently resolve.
- **Privacy Policy URL:** `https://indiehouse.vercel.app/apps/houseplants/privacy` — dedicated HousePlants page on the Indie House site; publicly reachable and reverified on 2026-08-20.
- **Marketing URL:** leave blank unless a verified public marketing page is available.

## App Review notes draft

HousePlants.ai does not require an account or login. The main catalog and local plant-care
features can be used without granting optional permissions.

Plant Identifier is optional. To use it, the reviewer can open Plant Identifier, choose
“API Key Needed,” create a free key at `https://my.plantnet.org`, paste the key, choose a
photo, and run identification. The selected photo is sent to Pl@ntNet for the requested
result. The app does not bundle a Pl@ntNet credential.

Climate-aware watering is optional and requests approximate location only after the user
uses that feature. HomeKit sensor monitoring, Calendar export, camera tools, photo access,
and notifications are also optional. If a reviewer does not have the corresponding
hardware or wants to skip a permission, the rest of the app remains usable.

Weather-aware watering uses WeatherKit only from the Plant Insights screen. The corrected
flow displays the official Apple Weather mark when WeatherKit attribution is available,
always provides a visible ` Weather` fallback, shows the returned legal attribution text,
and links to `https://weatherkit.apple.com/legal-attribution.html`. The attached physical-device
recording opens My Jungle, long-presses a plant, chooses Insights, shows this attribution in
the Weather-aware watering section, and opens the linked WeatherKit data-source page.

There are no in-app purchases to configure or submit for review.

The rejected build-3 submission contains the previous notes and physical-device attachment.
The latest authenticated read-back shows `Rejected` under Guideline 5.2.5. On 2026-08-21, the
current version package was updated with build-4 notes and the replacement recording; the
reloaded page retained both. On 2026-08-20, App Review Information was corrected so
`Sign-in required` is off for this no-account app, username and password remain blank, and the
verified account-holder contact fields are populated. The page was reloaded successfully with
the Save control disabled, confirming no pending metadata changes.

## App Privacy questionnaire draft

Use the actual final binary and the live service terms to confirm this questionnaire before
submitting it. The current local implementation has no analytics or advertising tracking.

Apple published these responses on 2026-08-14: Photos or Videos and Coarse Location, both used
for App Functionality; photos are marked linked to the user and coarse location is marked not
linked. The dedicated privacy-policy route is reachable; re-read the live App Store Connect
privacy-policy field before resubmission.

- **Data used to track you:** None
- **Photos or videos:** Photos or videos, used for App Functionality, when the user submits a photo to Plant Identifier. Mark as linked only if the final Pl@ntNet data relationship is confirmed as linked to the user's identity.
- **Location:** Coarse Location, used for App Functionality, when climate-aware care is enabled.
- **Data stored only on device:** profile, plant collection, journal, care settings, and local photos are not represented as developer-collected cloud data.
- **Apple services:** confirm how Apple presents iCloud key-value storage, WeatherKit, HomeKit, Calendar, and Notifications in the final privacy questionnaire.

## Age rating and export compliance

- **Age rating:** Apple saved the feature-based questionnaire at a calculated global rating of `4+`.
- **Pricing:** App Store Connect shows a current `$0.00` price schedule, including the base United States price and the displayed 175-region schedule.
- **Export compliance:** the account holder confirmed that build 4 uses none of Apple’s listed non-exempt encryption algorithms. App Store Connect accepted that answer and the build is now `Ready to Submit`.

## Screenshot plan

The app targets iPhone only (`TARGETED_DEVICE_FAMILY = 1`). Capture the final build on:

- iPhone 6.9-inch display class: onboarding/home, plant detail/care schedule, and plant journal.

Use the same polished data state across the set, remove simulator/debug artifacts, and export
opaque RGB JPEGs at Apple's accepted dimensions. Keep the raw simulator PNGs only as local
references.

Current local status: four polished, upload-ready iPhone scrapbook marketing JPEGs are included
at 1320×2868 in `submission/screenshots/scrapbook/`:

- `iphone-catalog-scrapbook.jpg` — Discover catalog and plant matching
- `iphone-my-jungle-scrapbook.jpg` — My Jungle care overview and reminders
- `iphone-plant-detail-scrapbook.jpg` — Monstera Deliciosa detail and care information
- `iphone-tools-scrapbook.jpg` — Tools catalog and plant-care utilities

Each scrapbook file is an opaque RGB JPEG. The earlier clean marketing set is retained under
`submission/screenshots/marketing/`. The authentic simulator captures remain in
`submission/screenshots/` and the corresponding raw PNGs remain under
`submission/screenshots/raw/` for local reference. No iPad screenshot set is needed for this
iPhone-only release.

The corrected replacement build is build `4`. The signed archive is at
`/tmp/houseplants-weatherkit-build4-20260821.xcarchive` and the exported App Store Connect IPA
is at `/tmp/houseplants-weatherkit-build4-20260821-export/HousePlants.ipa`. The archive was
validated with `codesign --verify --deep --strict`; its `CFBundleShortVersionString` is `1.0`,
its `CFBundleVersion` is `4`, it is iPhone-only (`UIDeviceFamily` `1`), and it retains the
WeatherKit entitlement. Xcode reported the upload complete at 16:13 IST on 2026-08-21;
the authenticated TestFlight read-back at 17:07 IST showed the upload as `Complete`, and the reloaded version page showed build `4` attached with `Ready to Submit`.
The previous live build `3` remains the rejected binary and must not be reused.

## Submission actions remaining

1. Wait for Apple’s review decision. The final submission is complete and server-rendered as
   `Waiting for Review` for build `4`.
2. Reverify the support and privacy URLs if Apple requests another submission; both returned
   HTTP 200 on 2026-08-20.

## Release blockers found in this checkout

- The account holder states that all catalog images used in this release were generated with AI for the project by or for the owner and are owned/authorized for use by `indiehouse.io`; no third-party catalog photos are intentionally used.
- Apple enrollment and capability/product configuration cannot be verified from this local checkout.
- App Store Connect build 2 remains rejection history; build 3 is rejected under Guideline
  5.2.5. A new build is required because the correction changes the binary.
- The app has no in-app purchase; the old `RocketGames.HousePlants.pro.lifetime` StoreKit path was removed from the source before the replacement build.
- App Store Connect currently lists no in-app purchase products for this app.
- App Store Connect App Review metadata was corrected on 2026-08-20: `Sign-in required` is off,
  the credential fields are blank as appropriate for a no-account app, and verified contact
  details are populated.
- The canonical Indie House deployment is on Vercel and its support/privacy routes are verified; the custom `indiehouse.io` domain for the same site does not currently resolve.
- App Store Connect currently identifies the developer as a DSA trader for this app.
