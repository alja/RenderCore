#version 300 es
precision mediump float;


//DEF
//**********************************************************************************************************************

#if (INSTANCED)
struct Material {
    vec3 emissive;
    vec3 diffuse;
    float alpha;
    sampler2D instanceData;
    // The following one could actually be instanced in int (or it has to be float?)
    // #if (OUTLINE)
    //    sampler2D instance_indices;
    // #fi
    #if (TEXTURE)
        #for I_TEX in 0 to NUM_TEX
            sampler2D texture##I_TEX;
        #end
    #fi
};
#fi


//STRUCT
//**********************************************************************************************************************
#if (DLIGHTS)
struct DLight {
    vec3 direction;
    vec3 color;
};
#fi
#if (PLIGHTS)
struct PLight {
    vec3 position;
    vec3 color;
    float distance;
    float decay;
};
#fi
#if (SLIGHTS)
struct SLight {
    vec3 position;
    vec3 color;
    float distance;
    float decay;
    float cutoff;
    float outerCutoff;
    vec3 direction;
};
#fi

//UIO
//**********************************************************************************************************************
uniform mat4 MVMat; // Model View Matrix
uniform mat4 PMat;  // Projection Matrix
uniform vec2 viewport;
uniform vec2 SpriteSize;

in vec3 VPos;       // Vertex position
in vec3 VNorm;      // Vertex normal
uniform mat3 NMat;  // Normal Matrix

#if (COLORS)
    in vec4 VColor;
    out vec4 fragVColor;
#fi

#if (TEXTURE)
    in vec2 uv;
    out vec2 fragUV;
#fi

#if (PLIGHTS)
    out vec3 fragVPos;
#fi

#if (POINTS)
    uniform float pointSize;
#fi

#if (CLIPPING_PLANES)
    out vec3 vViewPosition;
#fi

#if (INSTANCED)
    uniform Material material;
#fi

#if (OUTLINE)
out vec3 v_normal_viewspace;
out vec3 v_ViewDirection_viewspace;
#fi

// AMT


#if (DLIGHTS)
uniform DLight dLights[##NUM_DLIGHTS];
#fi
#if (PLIGHTS)
uniform PLight pLights[##NUM_PLIGHTS];
#fi
#if (SLIGHTS)
uniform SLight sLights[##NUM_SLIGHTS];
#fi

uniform vec3 ambient;
out vec4 v_VColor;


//FUNCTIONS
//**********************************************************************************************************************
#if (DLIGHTS)
vec3 calcDirectLight (DLight light, vec3 normal, vec3 viewDir) {

    vec3 lightDir = normalize(-light.direction);

    // Difuse
    float diffuseF = max(dot(normal, lightDir), 0.0f);

    // Combine results
    vec3 diffuse  = light.color * diffuseF * material.diffuse;

    return diffuse;
}
#fi

#if (PLIGHTS)
// Calculates the point light color contribution
vec3 calcPointLight (vec3 VPos_viewspace, PLight light, vec3 normal, vec3 viewDir) {

    float distance = length(light.position - VPos_viewspace);
    if(light.distance > 0.0 && distance > light.distance) return vec3(0.0, 0.0, 0.0);

    vec3 lightDir = normalize(light.position - VPos_viewspace);

    // Difuse
    float diffuseF = max(dot(lightDir, normal), 0.0f);

    // Attenuation
    //float attenuation = 1.0f / (1.0f + 0.01f * distance + 0.0001f * (distance * distance));
    float attenuation = light.decay / (light.decay + 0.01f * distance + 0.0001f * (distance * distance));

    // Combine results
    vec3 diffuse  = light.color * diffuseF  * material.diffuse  * attenuation;

    return diffuse;
}
#fi

#if (SLIGHTS)
vec3 calcSpotLight (vec3 VPos_viewspace, SLight light, vec3 normal, vec3 viewDir) {

    float distance = length(light.position - VPos_viewspace);
    if(light.distance > 0.0 && distance > light.distance) return vec3(0.0, 0.0, 0.0);

    vec3 lightDir = normalize(light.position - VPos_viewspace);


    // spot
    float theta = dot(lightDir, normalize(-light.direction));
    float epsilon = light.cutoff - light.outerCutoff;
    float intensity = clamp((theta - light.outerCutoff) / epsilon, 0.0, 1.0);
    //if(theta <= light.cutoff) return vec3(0.0, 0.0, 0.0);
    if(theta <= light.outerCutoff) return vec3(0.0, 0.0, 0.0);


    // Difuse
    float diffuseF = max(dot(lightDir, normal), 0.0f);

    // Attenuation
    //float attenuation = 1.0f / (1.0f + 0.01f * distance + 0.0001f * (distance * distance));
    float attenuation = light.decay / (light.decay + 0.01f * distance + 0.0001f * (distance * distance));

    // Combine results
    vec3 diffuse  = light.color * diffuseF  * material.diffuse  * attenuation;

    return diffuse * intensity;
}
#fi

//MAIN
//**********************************************************************************************************************
void main() {
    // Position of the origin in viewspace.
    vec3 VPos_origin;

    #if (INSTANCED)
        ivec2 tsi = textureSize(material.instanceData, 0);
        vec2 ootsf = vec2(1.0 / float(tsi.x), 1.0 / float(tsi.y));
        vec2 tc;
        tc.y = (float(gl_InstanceID / tsi.x) + 0.5) * ootsf.y;
        tc.x = (float(gl_InstanceID % tsi.x) + 0.5) * ootsf.x;
        vec4 pos = texture(material.instanceData, tc);

        VPos_origin = vec3(pos.x, pos.y, pos.z);
    #else
        VPos_origin = vec3(0.0, 0.0, 0.0);
    #fi

    vec4 VPos_viewspace = MVMat * vec4((VPos_origin + vec3(SpriteSize.x, SpriteSize.y, 1.0) * VPos), 1.0);

    // Assume vertices in x,y plane, z = 0; close to (0, 0) as SpriteSize
    // will scale them (for centered sprite there should be a quad with x, y = +-0.5).
    gl_Position = PMat * VPos_viewspace;

    #if (PLIGHTS)
        // Pass vertex position to fragment shader
        fragVPos = vec3(VPos_viewspace) / VPos_viewspace.w;
    #fi

    #if (COLORS)
        // Pass vertex color to fragment shader
        fragVColor = VColor;
    #fi

    #if (TEXTURE)
        // Pass uv coordinate to fragment shader
        fragUV = uv;
    #fi

    #if (CLIPPING_PLANES)
        vViewPosition = -VPos_viewspace.xyz;
    #fi

    #if (OUTLINE)
        v_normal_viewspace = vec3(0.0, 0.0, -1.0);

        float dToCam = length(VPos_viewspace.xyz);
        v_ViewDirection_viewspace = -VPos_viewspace.xyz / dToCam;
    #fi


    // AMT begin
    // define colors for fragment shader
    //
    vec4 combined = vec4(ambient + material.emissive, material.alpha);
    vec3 normal = normalize(NMat * VNorm);
    vec3 viewDir = normalize(-VPos_viewspace.xyz);

    #if (DLIGHTS)
        vec3 dLight;
        float dShadow = 0.0;

        #for lightIdx in 0 to NUM_DLIGHTS
            dLight = calcDirectLight(dLights[##lightIdx], normal, viewDir);
            combined.rgb += dLight;

            // if(dLights[##lightIdx].castShadows && material.receiveShadows)
            //     dShadow = calcDirectShadow(fragVPos_dlightspace[##lightIdx], dLights[##lightIdx], normal);

            // combined += dLight * (1.0 - dShadow);
        #end
    #fi
    #if (PLIGHTS)
        vec3 pLight;
        float pShadow = 0.0;


        #for lightIdx in 0 to NUM_PLIGHTS
            pLight = calcPointLight(VPos_viewspace.xyz, pLights[##lightIdx], normal, viewDir);
            combined.rgb += pLight;

            // if(pLights[##lightIdx].castShadows && material.receiveShadows)
            //     pShadow = calcPointShadow(fragVPos_plightspace[##lightIdx], pLights[##lightIdx], normal);

            // combined += pLight * (1.0 - pShadow);
        #end
    #fi
    #if (SLIGHTS)
        vec3 sLight;
        float sShadow = 0.0;

        #for lightIdx in 0 to NUM_SLIGHTS
            sLight = calcSpotLight(VPos_viewspace.xyz, sLights[##lightIdx], normal, viewDir);
            combined.rgb += sLight;

            // if(sLights[##lightIdx].castShadows && material.receiveShadows)
            //     sShadow = calcSpotShadow(fragVPos_slightspace[##lightIdx], sLights[##lightIdx], normal);

            // combined += sLight * (1.0 - sShadow);
        #end
    #fi

    v_VColor = combined;
 }
