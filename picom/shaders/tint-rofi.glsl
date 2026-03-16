#version 330

in vec2 texcoord;
uniform sampler2D tex;
uniform float opacity;
uniform float corner_radius;

vec4 default_post_processing(vec4 c);

const vec3 mauve    = vec3(0.796, 0.651, 0.969);
const vec3 lavender = vec3(0.702, 0.718, 0.969);

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

vec4 window_shader() {
    vec2 texsize = textureSize(tex, 0);
    vec2 uv = texcoord / texsize;
    vec4 color = texture2D(tex, uv, 0);

    // Brighter contrast + less darkening for Rofi
    vec3 proc = clamp((color.rgb - 0.5) * 1.25 + 0.5, 0.0, 1.0);
    proc *= 0.96;

    // Desaturation
    float luma = dot(proc, vec3(0.2126, 0.7152, 0.0722));
    proc = mix(proc, vec3(luma), 0.25);

    // Purple tint
    vec3 tinted = mix(proc, proc * mauve, 0.15);

    // Frost crystal texture
    tinted += voronoi(texcoord * 0.008) * 0.015;

    // Static film grain
    float grain = hash(texcoord * 0.8);
    tinted += (grain - 0.5) * 0.06;

    // Fresnel edge brightening
    vec2 norm = uv * 2.0 - 1.0;
    float fresnelEdge = max(abs(norm.x), abs(norm.y));
    tinted += pow(fresnelEdge, 4.0) * 0.06 * mauve;

    // Gradient
    float grad = mix(1.0, 0.4, uv.y);
    tinted = mix(proc, tinted, grad);

    return default_post_processing(vec4(tinted, color.a));
}
