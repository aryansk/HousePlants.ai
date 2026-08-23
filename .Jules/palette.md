# Palette's Journal - Critical UX & Accessibility Learnings

## 2026-02-20 - Icon-Only Buttons and Unlabeled Form Controls in Custom Card Components
**Learning:** In SwiftUI custom card rows and management sheets (like `EnhancedJungleListRow` and `PlantCareSheet`), icon-only buttons (such as quick action drop buttons) and standard form inputs (`Slider`, `TextEditor`) lack explicit `.accessibilityLabel` and `.accessibilityValue` modifiers. VoiceOver reads icon-only buttons by their system image name ("drop fill button") or generic state ("Slider") without providing plant context or unit feedback to screen reader users.
**Action:** Always attach explicit `.accessibilityLabel(...)`, `.accessibilityValue(...)`, and `.accessibilityHint(...)` to icon-only action buttons and input controls in plant card components and care sheets, ensuring the plant name or input unit is clearly conveyed.
