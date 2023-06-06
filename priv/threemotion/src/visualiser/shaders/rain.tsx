// https://www.shadertoy.com/view/4sGBz3

import { Vector2 } from "three";

const uniforms = {
  u_texture: { value: null },
  u_time: { value: 0.0 },
  u_resolution: { value: new Vector2() },
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform float u_time;

float T;

#define pi 3.1415926

vec2 hash(vec2 p) { p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))); return fract(sin(p) * 18.5453); }

float simplegridnoise(vec2 v) {
    float s = 1. / 256.;
    vec2 fl = floor(v), fr = fract(v);
    float mindist = 1e9;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(x, y);
            vec2 pos = 0.5 + 0.5 * cos(2. * pi * (T * 0.1 + hash(fl + offset)) + vec2(0, 1.6));
            mindist = min(mindist, length(pos + offset - fr));
        }
    }
    return mindist;
}

float blobnoise(vec2 v, float s) {
    return pow(0.5 + 0.5 * cos(pi * clamp(simplegridnoise(v) * 2., 0., 1.)), s);
}

vec3 blobnoisenrm(vec2 v, float s) {
    vec2 e = vec2(0.01, 0);
    return normalize(
        vec3(blobnoise(v + e.xy, s) - blobnoise(v - e.xy, s),
        blobnoise(v + e.yx, s) - blobnoise(v - e.yx, s),
        1.0)
    );
}

float blobnoises(vec2 uv, float s) {
    float h = 0.0;
    const float n = 3.0;
    for (float i = 0.0; i < n; i++) {
        vec2 p = vec2(0.0, 1.0 * u_time * (i + 1.0) / n) + 1.0 * uv;
        h += pow(0.5 + 0.5 * cos(pi * clamp(simplegridnoise(p * (i + 1.0)) * 2.0, 0.0, 1.0)), s);
    }
    return h / n;
}

vec3 blobnoisenrms(vec2 uv, float s) {
    float d = 0.01;
    return normalize(
        vec3(blobnoises(uv + vec2(d, 0.0), s) - blobnoises(uv + vec2(-d, 0.0), s),
        blobnoises(uv + vec2(0.0, d), s) - blobnoises(uv + vec2(0.0, -d), s),
        d)
    );
}

void main() {
    T = u_time;

    vec2 r = vec2(1.0, u_resolution.y / u_resolution.x);
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 n = blobnoisenrms(25.0 * uv * r, 1.0);
    vec4 color = texture2D(u_texture, uv + 0.05 * n.xy);

    gl_FragColor = color;
}
`;

const RainShader = {
  uniforms,
  fragmentShader,
};

export { RainShader };
