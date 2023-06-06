// https://www.shadertoy.com/view/4lXGzS

import {Vector2} from 'three';

const uniforms = {
	u_texture: {value: null},
	u_resolution: {value: new Vector2()},
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec2 u_resolution;

float yVar;
vec2 s, g, m;

// Source to transform
vec3 bg(vec2 uv) {
    return texture2D(u_texture, uv).rgg;
}

// Transform effect
vec3 effect(vec2 uv, vec3 col) {
    float granularity = yVar * 10.0 + 10.0;
    if (granularity > 0.0) {
        float dx = granularity / s.x;
        float dy = granularity / s.y;
        uv = vec2(dx * (floor(uv.x / dx) + 0.5), dy * (floor(uv.y / dy) + 0.5));
        return bg(uv);
    }
    return col;
}

void main() {
    s = u_resolution.xy;
    g = gl_FragCoord.xy;
    m = u_resolution.xy;
    yVar = m.y / s.y;
    vec2 uv = g / s;
    vec3 tex = bg(uv);
    vec3 col = effect(uv, tex);
    col = mix(col, vec3(0.0), vec3(0.0));
    gl_FragColor = vec4(col, 1.0);
}
`;

const PixelateShader = {
	uniforms,
	fragmentShader,
};

export {PixelateShader};
