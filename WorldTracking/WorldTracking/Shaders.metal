//
//  Sampler.metal
//  WorldTracking
//
//  Created by Roman on 5/5/21.
//

#include <metal_stdlib>
#include <simd/simd.h>

#import "ShaderTypes.h"

using namespace metal;



int sampleFunc(depth2d<float, access::sample> arDepthTexture [[ texture(0)]]){
    
    float total = 0;
    int num = 0;
    float depth;
    
    // Create an object to sample textures.
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    for(size_t i = 0; i < arDepthTexture.get_height(); ++i){
        for(size_t j = 0; j < arDepthTexture.get_width(); ++i){
            depth = arDepthTexture.sample(s, float2(i,j));
            total += depth;
            num++;
        }
    }
    
    float average = total/num;
    
    return average;
}
