# Plant Image Provenance

The active catalog is `plants.json`; its main images are stored in
`Assets.xcassets/<asset-name>.imageset`.

## Project-generated catalog photography

The following assets were generated specifically for this project with OpenAI's
built-in image-generation tool on 2026-07-28 and reviewed as square catalog
photography:

- First correction batch: `p_015`, `p_016`, `p_018`, `p_019`, `p_020`, `p_051`,
  `p_052`, `p_055`–`p_059`, `p_072`–`p_079`, `p_088`, `p_090`, `p_091`,
  `p_121`–`p_123`, `p_138`, and `p_151`–`p_166`.
- Second correction batch: `p_013`, `p_028`, `p_042`, `p_043`, `p_047`,
  `p_053`, `p_054`, `p_060`–`p_065`, `p_070`, `p_071`, `p_081`, `p_084`,
  `p_087`, `p_089`, `p_092`–`p_095`, `p_111`, `p_113`–`p_120`, `p_125`,
  `p_126`, `p_132`, `p_135`, `p_139`–`p_143`, `p_147`, `p_149`, and `p_150`.

Shared production direction: botanically specific specimen; complete centered
plant; neutral indoor setting; soft natural light; no text, labels, watermarks,
hands, or competing plants. Each final asset was converted to a 1024×1024 JPEG.

The generation originals are development artifacts and are not runtime
dependencies. The reviewed JPEGs in `Assets.xcassets` are the shipping assets.

## Owner rights statement

On 2026-08-15, the account holder stated that all catalog images currently used
by HousePlants.ai, including assets not enumerated in the generation batches
above, were generated with AI for this project by or for the owner and are
owned/authorized for use by `indiehouse.io`. No third-party catalog photos are
intentionally used in this release. This is the owner-provided rights statement
for Apple review and should remain aligned with Content Rights and App Review
Notes.

## Validation

Run:

```sh
python3 scripts/audit_plant_images.py
```

The audit checks catalog ids, image references, `Contents.json`, file
integrity, minimum dimensions, extreme aspect ratios, and exact duplicates.
