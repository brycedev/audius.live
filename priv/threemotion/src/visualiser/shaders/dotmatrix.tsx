// https://www.shadertoy.com/view/4sySDd

import { Vector2 } from "three";

const uniforms = {
  u_texture: { value: null },
  u_resolution: { value: new Vector2() },
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec2 u_resolution;



void main() {
    vec2 fragCoord = gl_FragCoord.xy;

    float dotSpace = 8.0;
    float dotSize = 3.0;

    float sinPer = 3.141592 / dotSpace;
    float frac = dotSize / dotSpace;

    float varyX = (abs(sin(sinPer * fragCoord.x)) - frac);
    float varyY = (abs(sin(sinPer * fragCoord.y)) - frac);

    float pointX = floor(fragCoord.x / dotSpace) * dotSpace + (0.5 * dotSpace);
    float pointY = floor(fragCoord.y / dotSpace) * dotSpace + (0.5 * dotSpace);
    vec2 pointCoord = vec2(pointX, pointY) / u_resolution.xy;
    vec4 texColor = texture2D(u_texture, pointCoord);
    gl_FragColor = texColor * varyX * varyY * (2.0 / frac);
}
`;

const DotMatrixShader = {
  uniforms,
  fragmentShader,
};

export { DotMatrixShader };
