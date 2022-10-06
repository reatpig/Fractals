#include "cuda.h"
#include "Calculations.cuh"
#include "device_launch_parameters.h"
#include <cstdio>
#define _USE_MATH_DEFINES
#include <math.h>
#include <iostream>

__device__ __constant__ uint8_t devColorPerIter[4*1549];

__global__ void MandelbrotSet( double numberPerPixel,
	 double leftTopX,  double leftTopY, uint8_t* result) {
	int startx = blockIdx.x * blockDim.x + threadIdx.x;
	int starty = blockIdx.y * blockDim.y + threadIdx.y;

	double x0 = (startx -WIDTH / 2 - leftTopX) * numberPerPixel;
	double y0 = (starty - HEIGHT / 2 - leftTopY) * numberPerPixel;
	 
	//Optimization,fast calculating big circle 
	double p = (x0 - 0.25) * (x0 - 0.25) + y0 * y0;
	double angle = atan2(y0, x0 - 0.25);
	double pc = 0.5 - (cos(angle) / 2);
	if (p <= pc * pc) {
		for (int r = 0; r <= 3; ++r) {	
			result[4 * (starty * WIDTH + startx) + r] = devColorPerIter[4 * iterations + r];
		}
		return;
	}

	double xPast = x0, yPast = y0;
	double R = 10;
	for (int i = 0; i < iterations; ++i) {
		 //Z^2
		 double	x = xPast * xPast - yPast * yPast + x0;
		 double	y =  2 * xPast * yPast + y0;
		if (x * x + y * y > R * R) {
			for (int r = 0; r <= 3; ++r)
				result[4 * (starty * WIDTH + startx) + r] = devColorPerIter[4 * i + r];
			return;
		}
		xPast = x;
		yPast = y;
	}

	for (int r = 0; r <= 3; ++r)
		result[4 * (starty * WIDTH + startx) + r] = devColorPerIter[4 * iterations + r]; 	
}

__global__ void JuliaSet(double numberPerPixel,
	double leftTopX, double leftTopY, uint8_t* result,double cx, double cy) {
	int startx = blockIdx.x * blockDim.x + threadIdx.x;
	int starty = blockIdx.y * blockDim.y + threadIdx.y;

	double x = (startx - WIDTH / 2 - leftTopX) * numberPerPixel;
	double y = (starty - HEIGHT / 2 - leftTopY) * numberPerPixel;
	double R = 36.;

	int pos = 4 * (starty * WIDTH + startx);
	for (int i = 0; i < iterations; ++i) {
		//Z^2
		double xCopy = x;
			x = xCopy * xCopy - y * y ;
			y = 2 * xCopy * y ;	
		//sin 
			xCopy = x;
			x = sin(xCopy) * cosh(y) + cx;
			y = cos(xCopy) * sinh(y) + cy;
		if(x*x+y*y>R){
			for(int r=0;r<=3;++r)
			result[pos + r] = devColorPerIter[4 * i + r];
			return;
		}
	}
	for (int r = 0; r <= 3; ++r)
		result[pos + r] = devColorPerIter[4 * iterations + r];
}

__global__ void parallelTransfer(int* pixelIteration,
	float deltaX, float deltaY) {
	int startx = blockIdx.x * blockDim.x + threadIdx.x;
	int starty = blockIdx.y * blockDim.y + threadIdx.y;

	int oldPosX = startx -deltaX;
	int oldPosY = startx - deltaY;
	if (oldPosX < 0 || oldPosY < 0 || oldPosX >= WIDTH || oldPosY >= HEIGHT)
		pixelIteration[starty*WIDTH+startx]=0;
	pixelIteration[starty * WIDTH + startx] = pixelIteration[oldPosY * WIDTH + oldPosX];

}

__host__
void render( double numberPerPixel,
	 double leftTopX,  double leftTopY, uint8_t* result,double deltaTime) {
	
	uint8_t* devResult = 0;
	
	if (cudaMalloc((void**)&devResult, 4 * WIDTH * HEIGHT * sizeof(uint8_t)) != cudaSuccess) {
		std::cerr << "Cuda malloc failed!";
		exit(EXIT_FAILURE);
	}
	dim3 threadsPerBlock(32, 16);
	dim3 numBlocks((WIDTH) / threadsPerBlock.x, (HEIGHT) / threadsPerBlock.y);

	//Calculating change x, y for Jukia Set 
	static double cx =0;
	static double cy=0;
	static double time=0;
	time += deltaTime;
	if (time > 5000) {
		cx += 0.01;
		cy += 0.01;
		time = 0;
		if (cx >= 2 || cy >= 2) {
			cx = 0;
			cy = 0;
		}
	}

	//MandelbrotSet << <numBlocks, threadsPerBlock >> > (numberPerPixel, leftTopX, leftTopY, 
		//devResult);
	JuliaSet << <numBlocks, threadsPerBlock >> > (numberPerPixel, leftTopX, leftTopY,
		devResult,cx,cy);

	cudaError_t  error = cudaGetLastError();
	if (error != cudaSuccess)
	{
		std::cerr << "Error in set: "<<error;
		exit(EXIT_FAILURE);
	}
	if (cudaMemcpy(result, devResult, 4 * WIDTH * HEIGHT * sizeof(uint8_t), cudaMemcpyDeviceToHost) != cudaSuccess)
	{
		std::cerr << "CudaMemcp Device to host failed!";
		exit(EXIT_FAILURE);
	}
	if (cudaFree(devResult) != cudaSuccess)
	{
		std::cerr << "CudaFree failed!";
		exit(EXIT_FAILURE);
	}
}

__host__ void defineColorPerIter(uint8_t* whitchColorPerIter)
{
	if (cudaMemcpyToSymbol(devColorPerIter, whitchColorPerIter, 4 * 1549 * sizeof(uint8_t)) != cudaSuccess)
	{
		std::cerr << "CudaMemcpy failed!";
	}

}