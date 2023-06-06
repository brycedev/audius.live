// https://www.shadertoy.com/view/dssGzH

import { Vector2 } from "three";

const uniforms = {
  u_texture: { value: null },
  u_resolution: { value: new Vector2() },
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec2 u_resolution;

float sdPlane(vec3 p){
    float width = 0.4; // Width of the tile
    float tiling = 12.0; // Grid precision

    vec2 idx = floor(p.xy * tiling);
    vec2 str = vec2(u_resolution.y / u_resolution.x, 1.0); 
    float h = length(texture2D(u_texture, str * idx / (2.0 * tiling) + vec2(0.5)).rgb) / 7.0;
    
    // Shapable tile
    vec2 f = fract(p.xy * tiling) - vec2(0.5); // Centering
    float N = 4.0; // 1. for losange, 2. for circle, +inf for square (L-N distances)
    float l = pow(pow(abs(f.x), N) + pow(abs(f.y), N), 1.0 / N);

    return h * smoothstep(0.0, 0.05, width - l);
}

float castray(vec3 ro, vec3 rd) {
    vec3 p;
    float dt, depth;
  
    float t = 0.05 * fract(sin(dot(rd, vec3(125.45, 213.345, 156.2001)))); // Dithering
    for (float d = 0.5; d < 2.4; d += 0.004) { // Lower value for d induces better results but is more costly
        p = ro + rd * (d + t);
        float depth = sdPlane(p);
        if (p.z < depth) {
            break;
        }
    }
    return p.z;
}

void main() {
    vec2 st = (2.0 * gl_FragCoord.xy - u_resolution) / u_resolution.y;

    vec3 ro = vec3(0.0, 0.0, 1.0); // Ray origin 
    vec3 rd = normalize(vec3(st, -1.0)); // Ray direction

    float d = castray(ro, rd);
    gl_FragColor = vec4(vec3(d) * 5.0, 0.2);
}
`;

const ExtrudedShader = {
  uniforms,
  fragmentShader,
};

export { ExtrudedShader };
