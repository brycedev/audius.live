// https://www.shadertoy.com/view/Xd2yWz

import {Vector2} from 'three';

const uniforms = {
	u_texture: {value: null},
	u_time: {value: 0.0},
	u_resolution: {value: new Vector2()},
};

const fragmentShader = `
uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform float u_time;

float timeRandom() {
    float f = fract(u_time);
    return texture2D(u_texture, vec2(f, 0.0)).r;
}

float slash(float x, float y, float maxInterval, float offset) {
    float c = x - y + offset;
    float interval = mod(c, maxInterval);
    return 1.0 - step((maxInterval - 2.0), interval);
}

float backslash(float x, float y, float maxInterval, float offset) {
    float c = x + y;
    float interval = mod(c, maxInterval);
    return 1.0 - step((maxInterval - 2.0), interval);
}

vec4 image(sampler2D img, float x, float y) {
    vec4 color = texture2D(img, vec2(x / u_resolution.x, y / u_resolution.y));
    return color;
}

vec4 outline(sampler2D img, float x, float y) {
    vec4 result =
        32.0 * image(img, x, y) -
        8.0 * image(img, x + 1.0, y) -
        8.0 * image(img, x - 1.0, y) -
        8.0 * image(img, x, y + 1.0) -
        8.0 * image(img, x, y - 1.0);
    return 1.0 - result;
}

float grey(vec4 color) {
    return (color.r + color.g + color.b) * 0.33333;
}

float posterize(float component, float colors) {
    float temp = floor(pow(component, 0.6) * colors) / colors;
    return pow(temp, 1.666667);
}

float contrast(float color, float factor) {
    return (color - 0.5) * factor + 0.5;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    float x = fragCoord.x;
    float y = fragCoord.y;

    vec4 pixel = image(u_texture, x, y);

    float component = grey(pixel);
    component = posterize(component, 16.0);
    component = contrast(component, 1.2);

    float maxInterval = 4.0 + floor(component * 2.0);

    float offset = timeRandom() * 2.0;
    float slashShade = slash(x, y, maxInterval, offset);
    float backslashShade = backslash(x, y, maxInterval, offset);

    float useBoth = 1.0 - step(0.5, component);
    float useSlash = 1.0 - step(0.65, component) - useBoth;
    float useBackslash = step(0.65, component);

    float shade = useBoth * (slashShade * backslashShade) + useSlash * slashShade + useBackslash * backslashShade;

    float color = mix(shade, 1.0, component);
    color = contrast(color, 1.5);

    gl_FragColor = vec4(color, color, color, 1.0);
}
`;

const CrossHatchShader = {
	uniforms,
	fragmentShader,
};

export {CrossHatchShader};
