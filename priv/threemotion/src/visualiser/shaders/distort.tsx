// https://www.shadertoy.com/view/4dScWc

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
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec4 img2 = texture2D(u_texture, uv * 0.2);
    vec2 fu = vec2(uv.x, uv.y);
    vec4 displace = texture2D(u_texture, fu * 0.137);
    float t = u_time * 0.5;
    float yo = sin(t) * 0.3;
    float a = (sin(123.0 + t * 2.0) + 1.0) * 1.5;
    float one = cos(t) * (displace.x - 0.5) * a;
    float two = sin(t) * (displace.x - 0.5) * 0.3;
    vec2 tc = vec2(uv.x + one + img2.r * yo, uv.y - two);
    vec4 img = texture2D(u_texture, tc);
    vec4 img3 = texture2D(u_texture, uv);
    img.r = mod(uv.y * u_resolution.y, 2.0);
    float g = (img.r + img.g + img.b) / 3.0;
    gl_FragColor = vec4((img3.r + g) * 0.5, g, g, 1.0);
}
`;

const DistortShader = {
  uniforms,
  fragmentShader,
};

export { DistortShader };
