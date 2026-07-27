#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

// MARK: - Reward shimmer
//
// A diagonal band of light that sweeps across a view, used on the moments the app wants
// to feel earned: a completed streak, a plant moving back into good health.
//
// Shaders are stateless — nothing carries between frames — so all animation comes from
// the `time` parameter, which the Swift side feeds from a TimelineView. That's the whole
// idea behind timeline-driven effects: the view doesn't interpolate from state A to state
// B, it's a pure function of the clock.
//
// `layer.sample()` reads the already-rendered view, so this composites on top of whatever
// the card actually looks like rather than replacing it.

[[ stitchable ]] half4 rewardShimmer(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float time,
    half4 tint,
    float intensity
) {
    half4 source = layer.sample(position);

    // Fully transparent pixels stay transparent — without this the band would paint
    // over the rounded corners the card was clipped to.
    if (source.a < 0.01h) {
        return source;
    }

    float2 uv = position / size;

    // Diagonal coordinate, so the band travels corner to corner rather than straight
    // down. The 1.6 span covers the extra distance the diagonal adds.
    float diagonal = (uv.x + uv.y) * 0.5;

    // Sweep runs from -0.3 to 1.3 so the band is fully off-view at both ends of the
    // cycle, which avoids a visible pop when time wraps.
    float sweep = fract(time) * 1.6 - 0.3;

    float distance = abs(diagonal - sweep);

    // Narrow, soft-edged band. smoothstep gives the falloff; the inverse makes the
    // centre brightest.
    float band = 1.0 - smoothstep(0.0, 0.14, distance);
    band = band * band; // Tighten the core so the edges stay subtle.

    half highlight = half(band * intensity);

    // Screen-style additive blend, weighted by the source alpha so edge pixels don't
    // pick up more light than the solid interior.
    half4 result = source;
    result.rgb += tint.rgb * highlight * source.a;

    return clamp(result, 0.0h, 1.0h);
}

// MARK: - Water ripple
//
// Concentric rings expanding from a point, for the instant a plant is watered. Also
// purely time-driven: `progress` is passed in from Swift as a 0→1 value.

[[ stitchable ]] half4 waterRipple(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float2 origin,
    float progress,
    float strength
) {
    // Once the ripple has run its course, sample straight through — no distortion and
    // no wasted arithmetic on every subsequent frame.
    if (progress >= 1.0 || progress <= 0.0) {
        return layer.sample(position);
    }

    float2 delta = position - origin;
    float distance = length(delta);

    // Ring radius grows to cover the view's diagonal.
    float maxRadius = length(size);
    float radius = progress * maxRadius;

    // Displacement is a narrow ring around the wavefront, and fades as the ripple
    // expands so it dissipates rather than stopping abruptly.
    float ring = 1.0 - smoothstep(0.0, 60.0, abs(distance - radius));
    float falloff = 1.0 - progress;
    float displacement = ring * falloff * strength;

    // Push pixels outward along the radius. Guard against the origin, where the
    // direction is undefined.
    float2 direction = distance > 0.001 ? (delta / distance) : float2(0.0);
    float2 sampleAt = position - direction * displacement;

    return layer.sample(sampleAt);
}
