// https://www.shadertoy.com/view/ldX3Ds

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

vec2 RotateUVsByVector(vec2 RotationCenter, vec2 UV, vec2 Direction) {
    vec2 OffsetUV = UV - RotationCenter;
    float NewU = dot(OffsetUV, vec2(Direction.y, -Direction.x));
    float NewV = dot(OffsetUV, vec2(Direction.x, Direction.y));
    return vec2(NewU, NewV) + RotationCenter;
}

vec2 AngleToVector(float Angle) {
    return vec2(sin(Angle), cos(Angle));
}

vec2 RotateUVs(vec2 RotationCenter, vec2 UV, float Angle) {
    Angle *= 6.28318548;
    return RotateUVsByVector(RotationCenter, UV, AngleToVector(Angle));
}

vec2 MirrorAlongAxis(vec2 UV, vec2 Axis) {
    UV -= 0.5;
    UV = UV - (dot(UV, Axis) * Axis * 2.0);
    UV += 0.5;
    return UV;
}

void main() {
    vec3 result = vec3(0.0);
    vec2 UV = gl_FragCoord.xy / u_resolution.xy;
    float col = 0.0;
    vec2 ImageScale = vec2(1.0, 1.2);
    float Scale = 5.0;
    vec2 ScaledUV = UV * Scale / ImageScale;
    float TriangleDirection = ceil(fract(ScaledUV).y - fract(ScaledUV.x + ScaledUV.y * 0.5));
    float Rows = ((1.0 - floor(fract((ScaledUV.y * 0.5)) * 2.0)) * 0.5);
    float RowIndex = floor(ScaledUV.y);
    float TriangleIndex1 = (floor((ScaledUV.x - Rows * 3.0)) + 0.5) * 2.0;
    float TriangleIndex2 = floor((ScaledUV.x - Rows * 3.0) + 0.5) * 2.0;
    float IndexX = mix(TriangleIndex2, TriangleIndex1, TriangleDirection);
    float IndexY = RowIndex;
    vec2 UpDownOffset = vec2(0.0, ((TriangleDirection - 0.5) * -0.32));
    vec2 UV1 = vec2(ScaledUV.x + Rows + 0.5, ScaledUV.y);
    vec2 UV2 = vec2(ScaledUV.x + Rows, ScaledUV.y);
    vec2 BlendedUV = fract(mix(UV1, UV2, TriangleDirection)) + UpDownOffset;
    if (TriangleDirection > 0.5) {
        BlendedUV = MirrorAlongAxis(BlendedUV, AngleToVector(-2.094333));
    }
    float wat = mod(floor(IndexX / 2.0), 3.0);
    BlendedUV = RotateUVs(vec2(0.5, 0.5), BlendedUV, (u_time * 0.1) + (wat * 3.3333));
    vec3 color = texture2D(u_texture, clamp(((BlendedUV - 0.5) * 1.0) + 0.5, 0.0, 1.0)).rgb;
    gl_FragColor = vec4(color, 1.0);
}
`;

const KaleidoscopeShader = {
  uniforms,
  fragmentShader,
};

export { KaleidoscopeShader };
