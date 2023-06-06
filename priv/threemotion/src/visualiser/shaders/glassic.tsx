// https://www.shadertoy.com/view/WltSWM

import { Vector2 } from "three";

const uniforms = {
  u_texture: { value: null },
  u_time: { value: 0.0 },
  u_resolution: { value: new Vector2() },
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform float u_time;
uniform vec2 u_resolution;

void main() {
  vec2 mouse = mix(
    vec2(u_time * 100.0),
    gl_FragCoord.xy,
    step(0.0, 0.0)) * 0.01;

vec2 glass_offset = sin(gl_FragCoord.xy * 0.1 - mouse) * 10.0;
vec2 glass_coord = gl_FragCoord.xy + glass_offset;

vec2 ps = vec2(1.0) / u_resolution.xy;
vec2 uv = gl_FragCoord.xy * ps;

vec2 glass_uv = glass_coord * ps;

vec4 textureColor = texture2D(u_texture, glass_uv);
gl_FragColor = textureColor;
}
`;

const GlassicShader = {
  uniforms,
  fragmentShader,
};

export { GlassicShader };
