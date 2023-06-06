// https://www.shadertoy.com/view/Xsfyzr

import {Vector2} from 'three';

const uniforms = {
	u_texture: {value: null},
	u_time: {value: 0.0},
	u_resolution: {value: new Vector2()},
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec3 u_resolution;
uniform float u_time;

float rand(float x) {
    return fract(sin(x) * 43758.5453);
}

float triangle(float x) {
    return abs(1.0 - mod(abs(x), 2.0)) * 2.0 - 1.0;
}

void main() {
    float time = floor(u_time * 16.0) / 16.0;
    
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    // Pixel position
    vec2 p = uv;
    p += vec2(triangle(p.y * rand(time) * 4.0) * rand(time * 1.9) * 0.015,
              triangle(p.x * rand(time * 3.4) * 4.0) * rand(time * 2.1) * 0.015);
    p += vec2(rand(p.x * 3.1 + p.y * 8.7) * 0.01,
              rand(p.x * 1.1 + p.y * 6.7) * 0.01);
    
    // Apply distortion to all pixels or not
    vec4 baseColor;
    #ifdef distort_all
        vec2 blurredUV = vec2(p.x + 0.003, p.y + 0.003);
        baseColor = vec4(texture2D(u_texture, blurredUV).rgb, 1.0);
    #else
        baseColor = vec4(texture2D(u_texture, uv).rgb, 1.0);
    #endif
    
    vec4 edges = 1.0 - (baseColor / vec4(texture2D(u_texture, p).rgb, 1.0));
    
    // Apply color inversion or not
    #ifdef invert_color
        baseColor.rgb = vec3(baseColor.r);
        gl_FragColor = baseColor / vec4(length(edges));
    #else
        gl_FragColor = vec4(length(edges));
    #endif
}
`;

const SketchShader = {
	uniforms,
	fragmentShader,
};

export {SketchShader};
