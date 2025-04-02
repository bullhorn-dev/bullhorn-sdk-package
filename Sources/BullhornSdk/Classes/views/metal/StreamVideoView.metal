#include <metal_stdlib>

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texPos;
};

vertex VertexOut i420_vertex
(
    const device packed_float3* vertex_array [[ buffer(0) ]],
    unsigned int vid [[ vertex_id ]]
)
{
    const float4x2 TextureCoordinates = float4x2
    (
        float2( 0.0, 0.0 ),
        float2( 1.0, 0.0 ),
        float2( 0.0, 1.0 ),
        float2( 1.0, 1.0 )
    );

    VertexOut out;
    out.position = float4(vertex_array[vid], 1.0);
    out.texPos   = TextureCoordinates[vid];
    return out;
}

fragment half4 i420_fragment
(
    VertexOut in [[ stage_in ]],
    texture2d<float, access::sample> yTex [[ texture(0) ]],
    texture2d<float, access::sample> uvTex [[ texture(1) ]]
)
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 uv = uvTex.sample(s, in.texPos).rg;
    float   y = yTex.sample(s, in.texPos).r;
    float   u = uv.x - 0.5;
    float   v = uv.y - 0.5;

    half4 ret;
    ret.r = y +               1.402   * v;
    ret.g = y - 0.34414 * u - 0.71414 * v;
    ret.b = y + 1.772   * u;
    ret.a = 1.0;
    
    return ret;

//    return half4(in.texPos.x, in.texPos.y, 0.0, 1.0);
}

/*
vertex float4 i420_vertex
(
    const device packed_float3* vertex_array [[ buffer(0) ]],
    unsigned int vid [[ vertex_id ]]
) {
    return float4(vertex_array[vid], 1.0);
}

fragment half4 i420_fragment()
{
    return half4(1.0, 0.0, 0.0, 1.0);
}
*/
