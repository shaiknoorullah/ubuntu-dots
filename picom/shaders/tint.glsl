#version 330

in vec2 texcoord;
uniform sampler2D tex;
uniform float opacity;
uniform float corner_radius;
uniform float time;

vec4 default_post_processing(vec4 c);

// ── Catppuccin Mocha palette ──
const vec3 mauve    = vec3(0.796, 0.651, 0.969); // #CBA6F7
const vec3 lavender = vec3(0.702, 0.718, 0.969); // #B4BEFE
const vec3 starCore = vec3(0.95, 0.92, 1.0);     // bright white-purple

// ═══════════════════════════════════════════════════
// NOISE FUNCTIONS
// ═══════════════════════════════════════════════════

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1, 0)), u.x),
        mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x),
        u.y
    );
}

// Fractional Brownian Motion — multi-scale frost roughness
float fbm3(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * valueNoise(p);
        p *= 2.0; a *= 0.5;
    }
    return v;
}

float fbm2(vec2 p) {
    return 0.5 * valueNoise(p) + 0.25 * valueNoise(p * 2.0);
}

// Voronoi — frost crystal cell pattern
float voronoi(vec2 p) {
    vec2 n = floor(p), f = fract(p);
    float md = 8.0;
    for (int j = -1; j <= 1; j++)
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(i, j);
            vec2 o = vec2(hash(n + g), hash(n + g + vec2(31, 17)));
            float d = dot(g + o - f, g + o - f);
            md = min(md, d);
        }
    return sqrt(md);
}

// ═══════════════════════════════════════════════════
// GEOMETRY
// ═══════════════════════════════════════════════════

// Signed distance to rounded rectangle (negative inside)
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Point on rectangle perimeter at parameter t ∈ [0,1)
vec2 perimeterPoint(float t, vec2 hs) {
    float w = hs.x * 2.0;
    float h = hs.y * 2.0;
    float perim = 2.0 * (w + h);
    float d = fract(t) * perim;
    if (d < w)
        return vec2(-hs.x + d, -hs.y);        // bottom: left → right
    d -= w;
    if (d < h)
        return vec2(hs.x, -hs.y + d);         // right: bottom → top
    d -= h;
    if (d < w)
        return vec2(hs.x - d, hs.y);          // top: right → left
    d -= w;
    return vec2(-hs.x, hs.y - d);             // left: top → bottom
}

// ═══════════════════════════════════════════════════
// MAIN SHADER
// ═══════════════════════════════════════════════════

vec4 window_shader() {
    vec2 texsize = textureSize(tex, 0);
    vec2 uv = texcoord / texsize;
    vec2 center = texcoord - texsize * 0.5;

    // ─── Sample window content (clean, no distortion) ───
    vec4 color = texture2D(tex, uv, 0);

    // ─── Skip shader on very dark pixels (fixes padding mismatch) ───
    float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    float effectStrength = smoothstep(0.05, 0.15, brightness);

    // ─── Contrast boost (readability) ───
    vec3 proc = clamp((color.rgb - 0.5) * 1.15 + 0.5, 0.0, 1.0);
    proc *= 0.925;

    // ─── Desaturation + tint (background only) ───
    // Use effectStrength to skip these on bright/colorful content
    float luma = dot(proc, vec3(0.2126, 0.7152, 0.0722));
    vec3 desaturated = mix(proc, vec3(luma), 0.32);
    vec3 tintedBg = mix(desaturated, desaturated * mauve, 0.22);

    // Content keeps original colors, background gets desat + tint
    vec3 tinted = mix(tintedBg, proc, effectStrength);

    // ─── Frost crystal texture (voronoi surface pattern) ───
    tinted += voronoi(texcoord * 0.008) * 0.025;

    // ─── Static film grain ───
    float grain = hash(texcoord * 0.8);
    tinted += (grain - 0.5) * 0.06;

    // ─── Fresnel edge brightening ───
    // Real glass reflects more light at grazing angles (Schlick approx.)
    vec2 norm = uv * 2.0 - 1.0;
    float fresnelEdge = max(abs(norm.x), abs(norm.y));
    tinted += pow(fresnelEdge, 4.0) * 0.08 * mauve;

    // ─── Gradient: full effect at top, fades toward bottom ───
    float grad = mix(1.0, 0.5, uv.y);
    tinted = mix(proc, tinted, grad);

    // ═══════════════════════════════════════════
    // ACTIVE WINDOW BORDER + SHOOTING STAR
    // ═══════════════════════════════════════════

    float rad = max(corner_radius, 0.0);
    float sdf = sdRoundedBox(center, texsize * 0.5, rad);

    // 1px inner border (sdf ≈ 0 at edge, negative inside)
    float border = 1.0 - smoothstep(0.0, 1.0, -sdf);

    // Only show on focused windows (they have higher opacity)
    float focused = smoothstep(0.72, 0.78, opacity);
    border *= focused;

    // Subtle lavender border
    vec3 borderGlow = lavender * 0.15;

    // Add border glow (additive, masked to border region)
    tinted += border * borderGlow;

    // Dark pixels (bg/padding): darken only. Bright pixels (content): full shader effect.
    vec3 darkenedBg = color.rgb * 0.7;
    tinted = mix(darkenedBg, tinted, effectStrength);

    return default_post_processing(vec4(tinted, color.a));
}
