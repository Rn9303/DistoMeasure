//
//  Sampler.h
//  WorldTracking
//
//  Created by Roman on 5/5/21.
//

#ifndef Sampler_h
#define Sampler_h

#include <simd/simd.h>


// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum BufferIndices {
    kBufferIndexMeshPositions    = 0,
    kBufferIndexMeshGenerics     = 1,
    kBufferIndexInstanceUniforms = 2,
    kBufferIndexSharedUniforms   = 3
} BufferIndices;


#endif /* Sampler_h */
