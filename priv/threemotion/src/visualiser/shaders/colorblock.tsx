// https://www.shadertoy.com/view/MdSGRW

import { Vector2 } from "three";

const uniforms = {
  u_texture: { value: null },
  u_resolution: { value: new Vector2() },
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec2 u_resolution;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    vec2 muv = gl_FragCoord.xy / u_resolution.xy;
    int id = int(floor(uv.x * 3.0)) + int(floor(uv.y * 3.0)) * 3;

    vec2 texuv = fract(uv * 3.0);
    vec4 col = texture2D(u_texture, vec2(texuv.x, texuv.y));

    vec3 c_r = vec3(100, 0, 0);
    vec3 c_g = vec3(0, 100, 0);
    vec3 c_b = vec3(0, 0, 100);

    if (id == 0) {
        c_r = vec3(80, 20, 0);
        c_g = vec3(25.833, 74.167, 0);
        c_b = vec3(0, 14.167, 85.833);
    } else if (id == 1) {
        c_r = vec3(56.667, 43.333, 0);
        c_g = vec3(55.833, 44.167, 0);
        c_b = vec3(0, 24.167, 75.833);
    } else if (id == 2) {
        c_r = vec3(81.667, 18.333, 0);
        c_g = vec3(33.333, 66.667, 0);
        c_b = vec3(0, 12.5, 87.5);
    } else if (id == 3) {
        c_r = vec3(62.5, 37.5, 0);
        c_g = vec3(70, 30, 0);
        c_b = vec3(0, 30, 70);
    } else if (id == 4) {
        // NO ADJUSTMENT
    } else if (id == 5) {
        c_r = vec3(96.667, 3.333, 0);
        c_g = vec3(0, 73.333, 26.667);
        c_b = vec3(0, 18.333, 81.667);
    } else if (id == 6) {
        c_r = vec3(29.9, 58.7, 11.4);
        c_g = vec3(29.9, 58.7, 11.4);
        c_b = vec3(29.9, 58.7, 11.4);
    } else if (id == 7) {
        c_r = vec3(61.8, 32, 6.2);
        c_g = vec3(16.3, 77.5, 6.2);
        c_b = vec3(16.3, 32.0, 51.6);
    } else if (id == 8) {
        c_r = vec3(95, 5, 0);
        c_g = vec3(0, 43.333, 56.667);
        c_b = vec3(0, 47.5, 52.5);
    } else {
        c_r = vec3(0, 0, 0);
        c_g = vec3(0, 0, 0);
        c_b = vec3(0, 0, 0);
    }

    c_r /= 100.0;
    c_g /= 100.0;
    c_b /= 100.0;

    vec3 rgb = vec3(dot(col.rgb, c_r), dot(col.rgb, c_g), dot(col.rgb, c_b));

    gl_FragColor = vec4(rgb, 1.0);
}
`;

const ColorBlockShader = {
  uniforms,
  fragmentShader,
};

export { ColorBlockShader };
