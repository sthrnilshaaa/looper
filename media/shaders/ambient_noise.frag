// Ambient noise-blur background shader.
//
// Renders a slow, organic flow field of color (built from the current song's
// artwork palette) with a very fine animated film-grain layer on top — the
// same visual language as Apple Music's lyrics background: soft blurred
// color blobs that breathe and drift, dusted with subtle moving grain
// instead of a flat gradient.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uGrain;

uniform vec3 uColor0;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform vec3 uColor4;
uniform vec3 uColor5;

out vec4 fragColor;

float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float valueNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
  float value = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 4; i++) {
    value += amp * valueNoise(p);
    p *= 2.02;
    amp *= 0.55;
  }
  return value;
}

// Gaussian-weighted blend across all 6 stops at once, rather than a
// sequential "mix into the next stop" chain. The old chain only ever
// blended two neighboring colors together, and smoothstep flattens out
// near each end of its range — so most of the field sat at a nearly-flat,
// nearly-pure color (a plateau), joined by a comparatively narrow
// transition band wherever the underlying noise field's gradient was
// steep. That narrow band is what reads as a visible seam/"joint" once
// it's animating. Here every point blends *all* the nearby colors with
// smoothly-varying weights (no flat plateaus, no hard 2-color cutover), so
// the field reads as continuously drifting/brushed color rather than
// discrete tinted regions stitched together. Explicit per-stop weights
// (no array, no dynamic indexing) to stay compatible with GPUs that
// handle those poorly, same constraint the old chain was written under.
vec3 ramp(float t) {
  float s = clamp(t, 0.0, 1.0) * 5.0;

  // How far (in stop-spacing units) a color's influence reaches. Wide
  // enough that every point blends at least two, usually three, stops.
  const float sigma = 0.85;
  const float invTwoSigmaSq = 1.0 / (2.0 * sigma * sigma);

  float d0 = s - 0.0;
  float d1 = s - 1.0;
  float d2 = s - 2.0;
  float d3 = s - 3.0;
  float d4 = s - 4.0;
  float d5 = s - 5.0;

  float w0 = exp(-d0 * d0 * invTwoSigmaSq);
  float w1 = exp(-d1 * d1 * invTwoSigmaSq);
  float w2 = exp(-d2 * d2 * invTwoSigmaSq);
  float w3 = exp(-d3 * d3 * invTwoSigmaSq);
  float w4 = exp(-d4 * d4 * invTwoSigmaSq);
  float w5 = exp(-d5 * d5 * invTwoSigmaSq);

  float wSum = w0 + w1 + w2 + w3 + w4 + w5;
  vec3 blended = uColor0 * w0 + uColor1 * w1 + uColor2 * w2 +
      uColor3 * w3 + uColor4 * w4 + uColor5 * w5;
  vec3 c = blended / max(wSum, 0.0001);

  // Blending several stops at once softens the result toward grey
  // (averaging pulls saturated colors toward their shared luma) exactly
  // where the old chain looked muddiest mid-transition. Push it back out
  // from its own luma a little to keep transitions looking vivid/painted
  // rather than washed out.
  float luma = dot(c, vec3(0.299, 0.587, 0.114));
  c = mix(vec3(luma), c, 1.18);

  return c;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  float aspect = uSize.x / max(uSize.y, 1.0);
  vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.5) * 1.7;

  // Very slow drift — a full cycle takes minutes, so motion reads as a
  // gentle breathing tide rather than a loop.
  float t = uTime * 0.028;

  // Rotate and move both domains diagonally. Axis-aligned translation made
  // coherent noise boundaries look like a vertical band sweeping the screen.
  mat2 domainRotation = mat2(0.866, -0.5, 0.5, 0.866);
  vec2 q = domainRotation * p;
  vec2 flow = vec2(
    fbm(q * 0.85 + vec2(t * 0.73, -t * 0.61)),
    fbm(q.yx * 0.85 + vec2(-t * 0.47, t * 0.83))
  );

  float n1 = fbm(q * 1.05 + flow * 1.35 + vec2(t * 0.31, t * 0.23));
  float n2 = fbm(domainRotation * (p * 0.5 + flow.yx * 0.2) -
      vec2(t * 0.17, t * 0.11) + 47.0);

  float mixT = clamp(n1 * 0.65 + n2 * 0.35, 0.0, 1.0);
  vec3 color = ramp(mixT);

  // Fine animated grain, stepped to ~14fps so it reads as soft filmic
  // texture rather than a shimmering per-frame flicker.
  float grainStep = floor(uTime * 14.0);
  float g = hash(fragCoord * 0.6 + grainStep * 91.37) - 0.5;
  color += g * uGrain;

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
