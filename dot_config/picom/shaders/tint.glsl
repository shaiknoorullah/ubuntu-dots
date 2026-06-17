#version 330

in vec2 texcoord;
uniform sampler2D tex;
uniform float opacity;
uniform float corner_radius;
uniform float time;

vec4 default_post_processing(vec4 c);

// ── Wallpaper-derived palette (wallust) ──
const vec3 accent  = vec3(132.0/255.0, 165.0/255.0, 109.0/255.0);
const vec3 accent2 = vec3(116.0/255.0, 138.0/255.0, 178.0/255.0);

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

float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// ═══════════════════════════════════════════════════
// MAIN SHADER
// ═══════════════════════════════════════════════════

vec4 window_shader() {
    vec2 texsize = textureSize(tex, 0);
    vec2 uv = texcoord / texsize;
    vec2 center = texcoord - texsize * 0.5;

    // ─── Sample window content ───
    vec4 color = texture2D(tex, uv, 0);

    // ─── Brightness-based content detection ───
    float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    float effectStrength = smoothstep(0.05, 0.15, brightness);

    // ─── Contrast boost (readability) ───
    vec3 proc = clamp((color.rgb - 0.5) * 1.15 + 0.5, 0.0, 1.0);
    proc *= 0.925;

    // ─── Desaturation + tint (background only) ───
    float luma = dot(proc, vec3(0.2126, 0.7152, 0.0722));
    vec3 desaturated = mix(proc, vec3(luma), 0.25);
    vec3 tintedBg = mix(desaturated, desaturated * accent, 0.15);

    // Content keeps original colors, background gets desat + tint
    vec3 tinted = mix(tintedBg, proc, effectStrength);

    // ─── Frost crystal texture ───
    tinted += voronoi(texcoord * 0.008) * 0.015;

    // ─── Static film grain ───
    float grain = hash(texcoord * 0.8);
    tinted += (grain - 0.5) * 0.06;

    // ─── Fresnel edge brightening ───
    vec2 norm = uv * 2.0 - 1.0;
    float fresnelEdge = max(abs(norm.x), abs(norm.y));
    tinted += pow(fresnelEdge, 4.0) * 0.06 * accent;

    // ─── Gradient ───
    float grad = mix(1.0, 0.4, uv.y);
    tinted = mix(proc, tinted, grad);

    // ═══════════════════════════════════════════
    // ACTIVE WINDOW BORDER
    // ═══════════════════════════════════════════

    float rad = max(corner_radius, 0.0);
    float sdf = sdRoundedBox(center, texsize * 0.5, rad);
    float border = 1.0 - smoothstep(0.0, 1.0, -sdf);
    float focused = smoothstep(0.82, 0.88, opacity);
    border *= focused;

    vec3 borderGlow = accent2 * 0.15;
    tinted += border * borderGlow;

    // Dark pixels: darken. Bright pixels: preserve.
    vec3 darkenedBg = color.rgb * 0.7;
    tinted = mix(darkenedBg, tinted, effectStrength);

    return default_post_processing(vec4(tinted, color.a));
}
