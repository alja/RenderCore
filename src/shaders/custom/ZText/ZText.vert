#version 300 es
precision mediump float;

//DEF
//**********************************************************************************************************************
#define TEXT2D_SPACE_WORLD 0.0
#define TEXT2D_SPACE_SCREEN 1.0

#if (TEXTURE)
struct Material {
    vec3 diffuse;
    sampler2D texture0; //FONT TEXTURE
};

uniform Material material;
in vec2 uv;  // Texture coordinate
#fi

// UIO
//**********************************************************************************************************************
uniform mat4 MVPMat;
uniform float aspect;
uniform vec2 viewport;
uniform float MODE;
uniform vec2 offset;
uniform vec2 FinalOffset;

// SDF Uniforms
uniform float sdf_border_size;

in vec2 VPos; // Vertex position (screenspace)
in float scale;

// Output quad texture coordinates
out vec2 fragUV;

//out SDF
out float doffset;
flat out vec2 sdf_texel;

void main() {
    if(MODE == TEXT2D_SPACE_SCREEN) {

        vec2 VPosNew = VPos + FinalOffset;
        if(offset.x != 0.0 && offset.y != 0.0)
        {
            VPosNew = VPosNew + offset;
        }
        //map [0, 1][0, 1] to [-1, 1][-1, 1]
        vec2 VPos_clipspace = (VPosNew * vec2(2.0))-vec2(1.0);

        // Vertex position in clip space
        gl_Position = vec4(VPos_clipspace, 0.0, 1.0);

    } else if (MODE == TEXT2D_SPACE_WORLD) {

        vec4 VPos_clipspace = MVPMat * vec4(VPos.xy, 0.0, 1.0);
        vec3 VPos_NDC = VPos_clipspace.xyz / VPos_clipspace.w;
        gl_Position = vec4(VPos_NDC * VPos_clipspace.w, VPos_clipspace.w);

    }

    #if (TEXTURE)
    // Pass-through texture coordinate
    fragUV = uv;
    float sdf_size = 2.0 * scale * sdf_border_size;
    // Distance field delta in screen pixels
    doffset = 1.0 / sdf_size;
    ivec2 ts = textureSize(material.texture0, 0);
    sdf_texel = vec2(1.0 / float(ts.x), 1.0 / float(ts.y));
    #fi
}
