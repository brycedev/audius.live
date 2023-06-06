// https://www.shadertoy.com/view/ldB3Dh

import { Vector2 } from "three";

const uniforms = {
  u_texture: { value: null },
  u_resolution: { value: new Vector2() },
  u_time: { value: 0.0 },
};

const fragmentShader = `
    uniform sampler2D u_texture;
    uniform vec2 u_resolution;
    uniform float u_time;

    mat2 RotateMat(float angle)
    {
        float si = sin(angle);
        float co = cos(angle);
        return mat2(co, si, -si, co);
    }

    vec3 Colour(float h)
    {
        h = h * 4.0;
        return clamp(abs(mod(h + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    }

    void main() {
        float time = u_time;

        vec2 pixel = (gl_FragCoord.xy - u_resolution.xy * 0.5) / u_resolution.xy + vec2(0.0, 0.1 - smoothstep(9.0, 12.0, time) * 0.35 + smoothstep(18.0, 20.0, time) * 0.15);

        vec3 col;
        float n;
        float inc = (smoothstep(17.35, 18.5, time) - smoothstep(18.5, 21.0, time)) * (time - 16.0) * 0.1;

        mat2 rotMat = RotateMat(inc);
        for (int i = 1; i < 50; i++) {
            pixel = pixel * rotMat;

            float depth = 40.0 + float(i) + smoothstep(18.0, 21.0, time) * 65.0;

            vec2 uv = pixel * depth / 210.0;

            col = texture(u_texture, fract(uv + vec2(0.5 + smoothstep(20.0, 21.0, time) * 0.11 + smoothstep(23.0, 23.5, time) * 0.04, 0.7 - smoothstep(20.0, 21.0, time) * 0.2))).rgb;
            col = mix(col, col * Colour(float(i) / 50.0 + u_time), smoothstep(18.5, 21.5, time));

            if ((1.0 - (col.y * col.y)) < float(i + 1) / 50.0) {
                break;
            }
        }

        col = min(col * col * 1.5, 1.0);

        float gr = smoothstep(17.0, 16.0, time) + smoothstep(18.5, 21.0, time);
        float bl = smoothstep(17.0, 15.0, time) + smoothstep(18.5, 21.0, time);
        col = col * vec3(1.0, gr, bl);

        col *= smoothstep(29.5, 28.2, time);

        gl_FragColor = vec4(col, 1.0);
    }
`;

const ScaryShader = {
  uniforms,
  fragmentShader,
};

export { ScaryShader };
