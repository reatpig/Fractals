#pragma once
#include "cuda_runtime.h"
#include <stdint.h>

#define HEIGHT 960
#define WIDTH 960

const int iterations = 1024/16;
__host__
void render( double numberPerPixel,
	 double leftTopX,  double leftTopY, uint8_t* result, double deltaTime);

__host__ void defineColorPerIter(uint8_t* whitchColorPerIter);

