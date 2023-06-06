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

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    uv.x += cos(uv.y * 5.2 + u_time * 1.4) / 100.0;
    uv.y += sin(uv.x * 5.1 + u_time * 1.4) / 100.0;
    uv.x -= cos(uv.y * 5.2 + u_time * 1.4) / 100.0;
    uv.x -= cos(uv.x * 5.2 + u_time * 1.4) / 100.0;

    vec4 color = texture2D(u_texture, uv);

    gl_FragColor = color;
}
`;

const AcidShader = {
  uniforms,
  fragmentShader,
};

export { AcidShader };
