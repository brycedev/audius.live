// https://www.shadertoy.com/view/ldX3Ds

import { Vector2 } from "three";

const uniforms = {
  u_texture: { value: null },
  u_resolution: { value: new Vector2() },
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec2 u_resolution;

void main() {
    float scaleX = 60.0;
    vec2 scale = vec2(scaleX, scaleX / u_resolution.x * u_resolution.y);
    float width = 0.3;
    float scaleY = scaleX / u_resolution.x * u_resolution.y;
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 pos = fract(uv * scale);
    vec2 coord = floor(uv * scale) / scale;
    float xb = dot(texture2D(u_texture, vec2(coord.x, uv.y)).xyz, vec3(1.0 / 3.0));
    float yb = dot(texture2D(u_texture, vec2(uv.x, coord.y)).xyz, vec3(1.0 / 3.0));
    float lit = float(abs(pos.y - width / 2.0 - (1.0 - width) * yb) < width / 2.0 || abs(pos.x - width / 2.0 - (1.0 - width) * xb) < width / 2.0);
    float b = (yb + xb) / 2.0;
    vec4 textureColor = texture2D(u_texture, uv);
    gl_FragColor = vec4(textureColor.rgb * (1.0 - lit), textureColor.a);
}
`;

const GridShader = {
  uniforms,
  fragmentShader,
};

export { GridShader };
