// https://www.shadertoy.com/view/ldX3Ds

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

vec3 hueShift(vec3 color, float hueAdjust) {
    const vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
    const vec3 kRGBToI = vec3(0.596, -0.275, -0.321);
    const vec3 kRGBToQ = vec3(0.212, -0.523, 0.311);
    const vec3 kYIQToR = vec3(1.0, 0.956, 0.621);
    const vec3 kYIQToG = vec3(1.0, -0.272, -0.647);
    const vec3 kYIQToB = vec3(1.0, -1.107, 1.704);

    float YPrime = dot(color, kRGBToYPrime);
    float I = dot(color, kRGBToI);
    float Q = dot(color, kRGBToQ);
    float hue = atan(Q, I);
    float chroma = sqrt(I * I + Q * Q);

    hue += hueAdjust;

    Q = chroma * sin(hue);
    I = chroma * cos(hue);

    vec3 yIQ = vec3(YPrime, I, Q);

    return vec3(dot(yIQ, kYIQToR), dot(yIQ, kYIQToG), dot(yIQ, kYIQToB));
}

vec3 toMonochrome(vec3 color) {
    float val = (color.r + color.b + color.g) / 3.0;
    float high = smoothstep(0.0, 0.5, val);
    float low = smoothstep(0.5, 1.0, val);
    return vec3(high, low, low);
}

mat2 rotate2d(float _angle) {
    return mat2(cos(_angle), -sin(_angle),
                sin(_angle), cos(_angle));
}

vec3 mixCol(vec3 a, vec3 b, float t) {
    return ((b - a) * t) + a;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - u_resolution.xy) / max(u_resolution.y, u_resolution.x);
    uv = gl_FragCoord.xy / u_resolution.xy;
    uv = abs(uv - 0.5) + 0.25;
    uv = uv * rotate2d(cos(u_time / 4.0) / 2.0);

    vec4 col = texture2D(u_texture, uv);
    col.rgb = mixCol(hueShift(col.rgb, u_time / 2.0), toMonochrome(col.rgb), 0.3);

    col.rgb = hueShift(col.rgb, u_time / 4.0);

    gl_FragColor = col;
}
`;

const MacysShader = {
  uniforms,
  fragmentShader,
};

export { MacysShader };
