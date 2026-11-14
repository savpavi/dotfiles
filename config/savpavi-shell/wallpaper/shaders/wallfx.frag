#version 440

// Wallpaper transition for Wallpaper.qml. `t` runs 0 -> 1 and the map made by
// bin/dot-wallfx says, per pixel, when the new wallpaper arrives.
//
//   mode 0  fade     plain cross-fade (no map available)
//   mode 1  spread   ink bleeding in from a few points
//   mode 2  sketch   a pen draws the subject's outline, hatching fills it in,
//                    then the rest bleeds outwards from the subject
//
// Map channels (8 bit, no alpha):
//   R  signed distance to the subject's outline, 0.5 = on it, +-SD_RANGE map px
//   G  how far along the stroke the nearest outline point is (0 = pen starts)
//   B  arrival order: outside the subject, outwards from it; inside, the
//      direction the hatching sweeps
//
// Rebuild after editing (the .qsb is what Qt loads):
//   /usr/lib/qt6/bin/qsb --glsl "100 es,120,150" -o wallfx.frag.qsb wallfx.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    float mode;
    float pxPerTexel;   // screen px covered by one map texel
    float lineWidth;    // outline half-width, screen px
    vec2 size;          // screen size, px
    vec4 cropOld;       // uv window (x, y, w, h) that covers the screen
    vec4 cropNew;
    vec4 ink;           // pen colour
    vec4 edge;          // colour of the bleeding front
};

layout(binding = 1) uniform sampler2D oldTex;
layout(binding = 2) uniform sampler2D newTex;
layout(binding = 3) uniform sampler2D mapTex;

const float SD_RANGE = 16.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 1 where `order` has been reached by a front at `p`, soft over +-w
float reached(float order, float p, float w) {
    return 1.0 - smoothstep(p - w, p + w, order);
}

float span(float a, float b, float x) {
    return clamp((x - a) / (b - a), 0.0, 1.0);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 o = texture(oldTex, cropOld.xy + uv * cropOld.zw).rgb;
    vec3 n = texture(newTex, cropNew.xy + uv * cropNew.zw).rgb;
    vec3 col;

    if (mode < 0.5) {
        col = mix(o, n, smoothstep(0.0, 1.0, t));
    } else {
        vec3 m = texture(mapTex, cropNew.xy + uv * cropNew.zw).rgb;
        vec2 px = uv * size;
        // paper grain: keeps the fronts from looking like a clean gradient
        float grain = (hash(floor(px / 3.0)) - 0.5) * 0.03;
        const float w = 0.035;

        if (mode < 1.5) {
            float p = smoothstep(0.0, 1.0, t) * (1.0 + 2.0 * w) - w;
            float order = m.b + grain;
            float r = reached(order, p, w);
            float front = exp(-pow((order - p) / (w * 0.8), 2.0))
                        * smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.9, 1.0, t));
            col = mix(o, n, r);
            col = mix(col, edge.rgb, front * 0.55);
        } else {
            float sd = (m.r - 128.0 / 255.0) * (255.0 / 127.0) * SD_RANGE * pxPerTexel;
            float inside = smoothstep(-0.75, 0.75, sd);
            float near = 1.0 - smoothstep(SD_RANGE * pxPerTexel * 0.75, SD_RANGE * pxPerTexel * 0.95, abs(sd));

            // 1. the pen: steady, with a slight ease at both ends
            float tl = span(0.0, 0.44, t);
            tl = mix(tl, smoothstep(0.0, 1.0, tl), 0.5);
            float drawn = 1.0 - smoothstep(tl - 0.006, tl, m.g);
            float body = 1.0 - smoothstep(lineWidth - 0.7, lineWidth + 0.7, abs(sd));
            float line = body * drawn * near;
            // the nib: a small bright dot where the pen is right now
            float nib = exp(-pow((m.g - tl) / 0.006, 2.0))
                      * (1.0 - smoothstep(lineWidth, lineWidth * 3.5, abs(sd)))
                      * near * step(0.001, tl) * step(tl, 0.999);

            // 2. hatching fills the subject: diagonal strokes that sweep across
            //    it and thicken until nothing of the old wallpaper is left
            float tf = span(0.36, 0.66, t);
            float stripe = abs(fract((px.x + px.y) / 11.0) - 0.5) * 2.0;
            float fillOrder = m.b * 0.62 + stripe * 0.38 + grain;
            float rin = inside * reached(fillOrder, tf * 1.1 - 0.05, 0.05);

            // 3. the rest bleeds outwards from the subject
            float ts = span(0.56, 1.0, t);
            float p = smoothstep(0.0, 1.0, ts) * (1.0 + 2.0 * w) - w;
            float order = m.b + grain;
            float rout = (1.0 - inside) * reached(order, p, w);
            float front = (1.0 - inside) * exp(-pow((order - p) / (w * 0.8), 2.0))
                        * smoothstep(0.0, 0.1, ts) * (1.0 - smoothstep(0.85, 1.0, ts));

            col = mix(o, n, max(rin, rout));
            col = mix(col, edge.rgb, front * 0.5);
            float lineFade = 1.0 - smoothstep(0.62, 0.86, t);
            col = mix(col, ink.rgb, clamp(line + nib, 0.0, 1.0) * lineFade);
        }
    }

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
