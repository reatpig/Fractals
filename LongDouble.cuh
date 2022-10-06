#pragma once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <string>
#include <vector>
#include "thrust/device_vector.h"
#include "thrust/host_vector.h"
class LongDoubleCPU {
	const size_t divDigits = 1000;
	const size_t sqrtDigits = 100;

	int sign;
	
	thrust::host_vector<int> digits;
	long exponent;

	void initFromString(const std::string& s);
	void removeZeroes();
	void normalize();

public:
	LongDoubleCPU();
	LongDoubleCPU(const LongDoubleCPU& x);
	LongDoubleCPU(long double value);
	LongDoubleCPU(const std::string& s);

	LongDoubleCPU& operator=(const LongDoubleCPU& x);

	bool operator>(const LongDoubleCPU& x) const;
	bool operator<(const LongDoubleCPU& x) const;
	bool operator>=(const LongDoubleCPU& x) const;
	bool operator<=(const LongDoubleCPU& x) const;
	bool operator==(const LongDoubleCPU& x) const;
	bool operator!=(const LongDoubleCPU& x) const;

	LongDoubleCPU operator-() const;

	LongDoubleCPU operator+(const LongDoubleCPU& x) const;
	LongDoubleCPU operator-(const LongDoubleCPU& x) const;
	LongDoubleCPU operator*(const LongDoubleCPU& x) const;
	LongDoubleCPU operator/(const LongDoubleCPU& x) const;

	LongDoubleCPU& operator+=(const LongDoubleCPU& x);
	LongDoubleCPU& operator-=(const LongDoubleCPU& x);
	LongDoubleCPU& operator*=(const LongDoubleCPU& x);
	LongDoubleCPU& operator/=(const LongDoubleCPU& x);

	LongDoubleCPU operator++(int);
	LongDoubleCPU operator--(int);

	LongDoubleCPU& operator++();
	LongDoubleCPU& operator--();

	LongDoubleCPU inverse() const;
	LongDoubleCPU sqrt() const;
	LongDoubleCPU pow(const LongDoubleCPU& n) const;
	LongDoubleCPU abs() const;

	bool isInteger() const;
	bool isEven() const;
	bool isOdd() const;
	bool isZero() const;

	friend std::ostream& operator<<(std::ostream& os, const LongDoubleCPU& value);

	int getSign() const;
	thrust::device_vector<int> getDigits() const;
	long getExponent() const;
};

class LongDoubleGPU {
	const size_t divDigits = 1000;
	const size_t sqrtDigits = 100;

	int sign;
	
	//thrust::device_vector<int> digits;
	int* digits;
	size_t digitsSize;
	long exponent;

	__device__ void removeZeroes();
	__device__ void normalize();

public:
	__device__ void initFromString(const char* s, size_t length);
	__device__ LongDoubleGPU();
	__device__ LongDoubleGPU(const LongDoubleGPU& x);
	__device__ LongDoubleGPU(const char* s, size_t length);
	__device__ LongDoubleGPU(long double value);
	LongDoubleGPU(const LongDoubleCPU& x);

	__device__ LongDoubleGPU& operator=(const LongDoubleGPU& x);

	__device__ bool operator>(const LongDoubleGPU& x) const;
	__device__ bool operator<(const LongDoubleGPU& x) const;


	__device__ LongDoubleGPU operator-() const;

	__device__ LongDoubleGPU operator+(const LongDoubleGPU& x) const;
	__device__ LongDoubleGPU operator-(const LongDoubleGPU& x) const;
	__device__ LongDoubleGPU operator*(const LongDoubleGPU& x) const;
	__device__ LongDoubleGPU operator/(const LongDoubleGPU& x) const;

	__device__ bool operator==(const LongDoubleGPU& x) const;
	__device__ bool operator!=(const LongDoubleGPU& x) const;

	__device__ LongDoubleGPU abs() const;

	__device__ LongDoubleGPU inverse() const;
	__device__ 	bool isInteger() const;
	__device__ 	bool isEven() const;
	__device__ 	bool isOdd() const;
	__device__ bool isZero() const;

	
};