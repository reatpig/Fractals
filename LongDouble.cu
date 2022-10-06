#pragma once

#include "LongDouble.cuh"



using namespace std;

void LongDoubleCPU::initFromString(const string& s) {
	size_t index;

	if (s[0] == '-') {
		sign = -1;
		index = 1;
	}
	else {
		sign = 1;
		index = 0;
	}

	exponent = s.length() - index;

	while (index < s.length()) {
		if (s[index] == '.')
			exponent = sign == 1 ? index : index - 1;
		else
			digits.push_back(s[index] - '0');

		index++;
	}
}

void LongDoubleCPU::removeZeroes() {
	size_t n = max((long)1, exponent);

	while (digits.size() > n && digits[digits.size() - 1] == 0)
		digits.erase(digits.end() - 1);

	while (digits.size() > 1 && digits[0] == 0) {
		digits.erase(digits.begin());
		exponent--;
	}

	while (digits.size() > 1 && digits[digits.size() - 1] == 0)
		digits.erase(digits.end() - 1);

	if (isZero()) {
		exponent = 1;
		sign = 1;
	}

	normalize();
}

void LongDoubleCPU::normalize() {
	size_t start = max(exponent, (long)0);
	size_t realDigits = digits.size() - start;

	if (realDigits >= divDigits) {
		size_t count = 0;
		size_t maxCount = 0;

		size_t i = start;

		while (i < digits.size()) {
			count = 0;

			while (i < digits.size() && digits[i] == 9) {
				count++;
				i++;
			}

			if (count > maxCount)
				maxCount = count;

			i++;
		}

		if (maxCount > divDigits * 4 / 5) {
			i = digits.size() - 1;

			do {
				count = 0;

				while (i > 0 && digits[i] != 9)
					i--;

				while (i > 0 && digits[i] == 9) {
					count++;
					i--;
				}
			} while (count != maxCount);

			digits.erase(digits.begin() + i + 1, digits.end());
			digits[i]++;
		}
	}
}

LongDoubleCPU::LongDoubleCPU() {
	sign = 1;
	digits = vector<int>(1, 0);
	exponent = 1;
}

LongDoubleCPU::LongDoubleCPU(const LongDoubleCPU& x) {
	sign = x.sign;
	exponent = x.exponent;
	digits = vector<int>(x.digits.size());

	for (size_t i = 0; i < x.digits.size(); i++)
		digits[i] = x.digits[i];
}

LongDoubleCPU::LongDoubleCPU(long double value) {
	stringstream ss;
	ss << setprecision(15) << value;

	initFromString(ss.str());
	removeZeroes();
}

LongDoubleCPU::LongDoubleCPU(const string& s) {
	initFromString(s);
	removeZeroes();
}

LongDoubleCPU& LongDoubleCPU::operator=(const LongDoubleCPU& x) {
	if (this == &x)
		return *this;

	sign = x.sign;
	exponent = x.exponent;
	digits = vector<int>(x.digits.size());

	for (size_t i = 0; i < x.digits.size(); i++)
		digits[i] = x.digits[i];

	return *this;
}

bool LongDoubleCPU::operator>(const LongDoubleCPU& x) const {
	if (sign != x.sign)
		return sign > x.sign;

	if (exponent != x.exponent)
		return (exponent > x.exponent) ^ (sign == -1);

	thrust::host_vector<int> d1(digits);
	thrust::host_vector<int> d2(x.digits);
	size_t size = max(d1.size(), d2.size());

	while (d1.size() != size)
		d1.push_back(0);

	while (d2.size() != size)
		d2.push_back(0);

	for (size_t i = 0; i < size; i++)
		if (d1[i] != d2[i])
			return (d1[i] > d2[i]) ^ (sign == -1);

	return false;
}

bool LongDoubleCPU::operator<(const LongDoubleCPU& x) const {
	return !(*this > x || *this == x);
}

bool LongDoubleCPU::operator>=(const LongDoubleCPU& x) const {
	return *this > x || *this == x;
}

bool LongDoubleCPU::operator<=(const LongDoubleCPU& x) const {
	return *this < x || *this == x;
}

bool LongDoubleCPU::operator==(const LongDoubleCPU& x) const {
	if (sign != x.sign)
		return false;

	if (exponent != x.exponent)
		return false;

	if (digits.size() != x.digits.size())
		return false;

	for (size_t i = 0; i < digits.size(); i++)
		if (digits[i] != x.digits[i])
			return false;

	return true;
}

bool LongDoubleCPU::operator!=(const LongDoubleCPU& x) const {
	return !(*this == x);
}

LongDoubleCPU LongDoubleCPU::operator-() const {
	LongDoubleCPU res(*this);
	res.sign = -sign;

	return res;
}

LongDoubleCPU LongDoubleCPU::operator+(const LongDoubleCPU& x) const {
	if (sign == x.sign) {
		long exp1 = exponent;
		long exp2 = x.exponent;
		long exp = max(exp1, exp2);

		thrust::host_vector<int> d1(digits);
		thrust::host_vector<int> d2(x.digits);

		while (exp1 != exp) {
			d1.insert(d1.begin(), 0);
			exp1++;
		}

		while (exp2 != exp) {
			d2.insert(d2.begin(), 0);
			exp2++;
		}

		size_t size = max(d1.size(), d2.size());

		while (d1.size() != size)
			d1.push_back(0);

		while (d2.size() != size)
			d2.push_back(0);

		size_t len = 1 + size;

		LongDoubleCPU res;

		res.sign = sign;
		res.digits = vector<int>(len, 0);

		for (size_t i = 0; i < size; i++)
			res.digits[i + 1] = d1[i] + d2[i];

		for (size_t i = len - 1; i > 0; i--) {
			res.digits[i - 1] += res.digits[i] / 10;
			res.digits[i] %= 10;
		}

		res.exponent = exp + 1;
		res.removeZeroes();

		return res;
	}

	if (sign == -1)
		return x - (-(*this));

	return *this - (-x);
}

LongDoubleCPU LongDoubleCPU::operator-(const LongDoubleCPU& x) const {
	if (sign == 1 && x.sign == 1) {
		bool cmp = *this > x;

		long exp1 = cmp ? exponent : x.exponent;
		long exp2 = cmp ? x.exponent : exponent;
		long exp = max(exp1, exp2);

		thrust::host_vector<int> d1(cmp ? digits : x.digits);
		thrust::host_vector<int> d2(cmp ? x.digits : digits);

		while (exp1 != exp) {
			d1.insert(d1.begin(), 0);
			exp1++;
		}

		while (exp2 != exp) {
			d2.insert(d2.begin(), 0);
			exp2++;
		}

		size_t size = max(d1.size(), d2.size());

		while (d1.size() != size)
			d1.push_back(0);

		while (d2.size() != size)
			d2.push_back(0);

		size_t len = 1 + size;

		LongDoubleCPU res;

		res.sign = cmp ? 1 : -1;
		res.digits = vector<int>(len, 0);

		for (size_t i = 0; i < size; i++)
			res.digits[i + 1] = d1[i] - d2[i];

		for (size_t i = len - 1; i > 0; i--) {
			if (res.digits[i] < 0) {
				res.digits[i] += 10;
				res.digits[i - 1]--;
			}
		}

		res.exponent = exp + 1;
		res.removeZeroes();

		return res;
	}

	if (sign == -1 && x.sign == -1)
		return (-x) - (-(*this));

	return *this + (-x);
}

LongDoubleCPU LongDoubleCPU::operator*(const LongDoubleCPU& x) const {
	size_t len = digits.size() + x.digits.size();

	LongDoubleCPU res;

	res.sign = sign * x.sign;
	res.digits = vector<int>(len, 0);
	res.exponent = exponent + x.exponent;

	for (size_t i = 0; i < digits.size(); i++)
		for (size_t j = 0; j < x.digits.size(); j++)
			res.digits[i + j + 1] += digits[i] * x.digits[j];

	for (size_t i = len - 1; i > 0; i--) {
		res.digits[i - 1] += res.digits[i] / 10;
		res.digits[i] %= 10;
	}

	res.removeZeroes();

	return res;
}

LongDoubleCPU LongDoubleCPU::operator/(const LongDoubleCPU& x) const {
	LongDoubleCPU res = *this * x.inverse();

	size_t intPart = max((long)0, exponent);

	if (intPart > res.digits.size() - 1)
		return res;

	size_t i = res.digits.size() - 1 - intPart;
	size_t n = max((long)0, res.exponent);

	if (i > n && res.digits[i] == 9) {
		while (i > n && res.digits[i] == 9)
			i--;

		if (res.digits[i] == 9) {
			res.digits.erase(res.digits.begin() + n, res.digits.end());
			res = res + res.sign;
		}
		else {
			res.digits.erase(res.digits.begin() + i + 1, res.digits.end());
			res.digits[i]++;
		}
	}

	return res;
}

LongDoubleCPU& LongDoubleCPU::operator+=(const LongDoubleCPU& x) {
	return (*this = *this + x);
}

LongDoubleCPU& LongDoubleCPU::operator-=(const LongDoubleCPU& x) {
	return (*this = *this - x);
}

LongDoubleCPU& LongDoubleCPU::operator*=(const LongDoubleCPU& x) {
	return (*this = *this * x);
}

LongDoubleCPU& LongDoubleCPU::operator/=(const LongDoubleCPU& x) {
	return (*this = *this / x);
}

LongDoubleCPU LongDoubleCPU::operator++(int) {
	LongDoubleCPU res(*this);
	*this = *this + 1;

	return res;
}

LongDoubleCPU LongDoubleCPU::operator--(int) {
	LongDoubleCPU res(*this);
	*this = *this - 1;

	return res;
}

LongDoubleCPU& LongDoubleCPU::operator++() {
	return (*this = *this + 1);
}

LongDoubleCPU& LongDoubleCPU::operator--() {
	return (*this = *this - 1);
}

LongDoubleCPU LongDoubleCPU::inverse() const {
	if (isZero())
		throw string("LongDoubleCPU LongDoubleCPU::inverse() - division by zero!");

	LongDoubleCPU x(*this);
	x.sign = 1;

	LongDoubleCPU d("1");

	LongDoubleCPU res;
	res.sign = sign;
	res.exponent = 1;
	res.digits = vector<int>();

	while (x < 1) {
		x.exponent++;
		res.exponent++;
	}

	while (d < x)
		d.exponent++;

	res.exponent -= d.exponent - 1;

	size_t numbers = 0;
	size_t intPart = max((long)0, res.exponent);
	size_t maxNumbers = divDigits + intPart;

	do {
		int div = 0;

		while (d >= x) {
			div++;
			d -= x;
		}

		d.exponent++;
		d.removeZeroes();

		res.digits.push_back(div);
		numbers++;
	} while (!d.isZero() && numbers < maxNumbers);

	return res;
}

LongDoubleCPU LongDoubleCPU::sqrt() const {
	if (sign == -1)
		throw string("LongDoubleCPU LongDoubleCPU::sqrt() - number is negative");

	if (isZero())
		return 0;

	LongDoubleCPU x0;
	LongDoubleCPU p("0.5");
	LongDoubleCPU xk("0.5");
	LongDoubleCPU eps;
	eps.digits = vector<int>(1, 1);
	eps.exponent = 1 - sqrtDigits;

	do {
		x0 = xk;
		xk = p * (x0 + *this / x0);
	} while ((x0 - xk).abs() > eps);

	xk.digits.erase(xk.digits.begin() + max((long)0, xk.exponent) + sqrtDigits, xk.digits.end());
	xk.removeZeroes();

	return xk;
}

LongDoubleCPU LongDoubleCPU::pow(const LongDoubleCPU& n) const {
	if (!n.isInteger())
		throw string("LongDoubleCPU LongDoubleCPU::power(const LongDoubleCPU& n) - n is not integer!");

	LongDoubleCPU res("1");
	LongDoubleCPU a = n.sign == 1 ? *this : this->inverse();
	LongDoubleCPU power = n.abs();

	while (power > 0) {
		if (power.isOdd())
			res *= a;

		a *= a;
		power /= 2;

		if (!power.isInteger())
			power.digits.erase(power.digits.end() - 1);
	}

	return res;
}

LongDoubleCPU LongDoubleCPU::abs() const {
	LongDoubleCPU res(*this);
	res.sign = 1;

	return res;
}

bool LongDoubleCPU::isInteger() const {
	if (exponent < 0)
		return false;

	return digits.size() <= (size_t)exponent;
}

bool LongDoubleCPU::isEven() const {
	if (!isInteger())
		return false;

	if (digits.size() == (size_t)exponent)
		return digits[digits.size() - 1] % 2 == 0;

	return true;
}

bool LongDoubleCPU::isOdd() const {
	if (!isInteger())
		return false;

	if (digits.size() == (size_t)exponent)
		return digits[digits.size() - 1] % 2 == 1;

	return false;
}

bool LongDoubleCPU::isZero() const {
	return digits.size() == 1 && digits[0] == 0;
}

int LongDoubleCPU::getSign() const
{
	return sign;
}

thrust::device_vector<int> LongDoubleCPU::getDigits() const
{
	 thrust::device_vector<int> diviceVector;
	 for (auto value : digits)
		 diviceVector.push_back(value);
	 return diviceVector;
}

long LongDoubleCPU::getExponent()const
{
	return exponent;
}

ostream& operator<<(ostream& os, const LongDoubleCPU& value) {
	if (value.sign == -1)
		os << '-';

	if (value.exponent > 0) {
		size_t i = 0;
		size_t e = value.exponent;

		while (i < value.digits.size() && i < e)
			os << value.digits[i++];

		while (i < e) {
			os << "0";
			i++;
		}

		if (i < value.digits.size()) {
			os << ".";

			while (i < value.digits.size())
				os << value.digits[i++];
		}
	}
	else if (value.exponent == 0) {
		os << "0.";

		for (size_t i = 0; i < value.digits.size(); i++)
			os << value.digits[i];
	}
	else {
		os << "0.";

		for (long i = 0; i < -value.exponent; i++)
			os << "0";

		for (size_t i = 0; i < value.digits.size(); i++)
			os << value.digits[i];
	}

	return os;
}



//GPU

void LongDoubleGPU::initFromString(const char* s, size_t length) {
	size_t index;

	if (s[0] == '-') {
		sign = -1;
		index = 1;
	}
	else {
		sign = 1;
		index = 0;
	}

	exponent = length - index;

	while (index < length) {
		if (s[index] == '.')
			exponent = sign == 1 ? index : index - 1;
		else
			digits.push_back(s[index] - '0');

		index++;
	}
}
void LongDoubleGPU::removeZeroes() {
	size_t n = max((long)1, exponent);

	while (digitsSize > n && digits[digitsSize - 1] == 0)
		digits.erase(digits.end() - 1);

	while (digitsSize> 1 && digits[0] == 0) {
		digits.erase(digits.begin());
		exponent--;
	}

	while (digitsSize > 1 && digits[digitsSize - 1] == 0)
		digits.erase(digits.end() - 1);

	if (isZero()) {
		exponent = 1;
		sign = 1;
	}

	normalize();
}

void LongDoubleGPU::normalize() {
	size_t start = max(exponent, (long)0);
	size_t realDigits = digits.size() - start;

	if (realDigits >= divDigits) {
		size_t count = 0;
		size_t maxCount = 0;

		size_t i = start;

		while (i < digits.size()) {
			count = 0;

			while (i < digits.size() && digits[i] == 9) {
				count++;
				i++;
			}

			if (count > maxCount)
				maxCount = count;

			i++;
		}

		if (maxCount > divDigits * 4 / 5) {
			i = digits.size() - 1;

			do {
				count = 0;

				while (i > 0 && digits[i] != 9)
					i--;

				while (i > 0 && digits[i] == 9) {
					count++;
					i--;
				}
			} while (count != maxCount);

			digits.erase(digits.begin() + i + 1, digits.end());
			digits[i]++;
		}
	}
}

LongDoubleGPU::LongDoubleGPU() {
	sign = 1;
	digits = thrust::device_vector<int>(1, 0);
	exponent = 1;
}

LongDoubleGPU::LongDoubleGPU(const LongDoubleGPU& x) {
	sign = x.sign;
	exponent = x.exponent;
	digits = thrust::device_vector<int>(x.digits.size());

	for (size_t i = 0; i < x.digits.size(); i++)
		digits[i] = x.digits[i];
}

LongDoubleGPU::LongDoubleGPU(const char* s, size_t length)
{
	initFromString(s, length);
	removeZeroes();
}

LongDoubleGPU::LongDoubleGPU(long double value) {
	stringstream ss; 
	ss << setprecision(15) << value;
	initFromString(ss.str().c_str(),ss.str().size());
	removeZeroes();
}

LongDoubleGPU::LongDoubleGPU(const LongDoubleCPU& x)
{
	sign = x.getSign();
	exponent = x.getExponent();
	
	digits = x.getDigits();
}


LongDoubleGPU& LongDoubleGPU::operator=(const LongDoubleGPU& x) {
	if (this == &x)
		return *this;

	sign = x.sign;
	exponent = x.exponent;
	digits = thrust::device_vector<int>(x.digits.size());

	for (size_t i = 0; i < x.digits.size(); i++)
		digits[i] = x.digits[i];

	return *this;
}

bool LongDoubleGPU::operator>(const LongDoubleGPU& x) const {
	if (sign != x.sign)
		return sign > x.sign;

	if (exponent != x.exponent)
		return (exponent > x.exponent) ^ (sign == -1);

	thrust::device_vector<int> d1(digits);
	thrust::device_vector<int> d2(x.digits);
	size_t size = max(d1.size(), d2.size());

	while (d1.size() != size)
		d1.push_back(0);

	while (d2.size() != size)
		d2.push_back(0);

	for (size_t i = 0; i < size; i++)
		if (d1[i] != d2[i])
			return (d1[i] > d2[i]) ^ (sign == -1);

	return false;
}

bool LongDoubleGPU::operator<(const LongDoubleGPU& x) const {
	return !(*this > x || *this == x);
}


bool LongDoubleGPU::operator==(const LongDoubleGPU& x) const {
	if (sign != x.sign)
		return false;

	if (exponent != x.exponent)
		return false;

	if (digits.size() != x.digits.size())
		return false;

	for (size_t i = 0; i < digits.size(); i++)
		if (digits[i] != x.digits[i])
			return false;

	return true;
}

bool LongDoubleGPU::operator!=(const LongDoubleGPU& x) const {
	return !(*this == x);
}

LongDoubleGPU LongDoubleGPU::operator-() const {
	LongDoubleGPU res(*this);
	res.sign = -sign;

	return res;
}

LongDoubleGPU LongDoubleGPU::operator+(const LongDoubleGPU& x) const {
	if (sign == x.sign) {
		long exp1 = exponent;
		long exp2 = x.exponent;
		long exp = max(exp1, exp2);

		thrust::device_vector<int> d1(digits);
		thrust::device_vector<int> d2(x.digits);

		while (exp1 != exp) {
			d1.insert(d1.begin(), 0);
			exp1++;
		}

		while (exp2 != exp) {
			d2.insert(d2.begin(), 0);
			exp2++;
		}

		size_t size = max(d1.size(), d2.size());

		while (d1.size() != size)
			d1.push_back(0);

		while (d2.size() != size)
			d2.push_back(0);

		size_t len = 1 + size;

		LongDoubleGPU res;

		res.sign = sign;
		res.digits = thrust::device_vector<int>(len, 0);

		for (size_t i = 0; i < size; i++)
			res.digits[i + 1] = d1[i] + d2[i];

		for (size_t i = len - 1; i > 0; i--) {
			res.digits[i - 1] += res.digits[i] / 10;
			res.digits[i] %= 10;
		}

		res.exponent = exp + 1;
		res.removeZeroes();

		return res;
	}

	if (sign == -1)
		return x - (-(*this));

	return *this - (-x);
}

LongDoubleGPU LongDoubleGPU::operator-(const LongDoubleGPU& x) const {
	if (sign == 1 && x.sign == 1) {
		bool cmp = *this > x;

		long exp1 = cmp ? exponent : x.exponent;
		long exp2 = cmp ? x.exponent : exponent;
		long exp = max(exp1, exp2);

		thrust::device_vector<int> d1(cmp ? digits : x.digits);
		thrust::device_vector<int> d2(cmp ? x.digits : digits);

		while (exp1 != exp) {
			d1.insert(d1.begin(), 0);
			exp1++;
		}

		while (exp2 != exp) {
			d2.insert(d2.begin(), 0);
			exp2++;
		}

		size_t size = max(d1.size(), d2.size());

		while (d1.size() != size)
			d1.push_back(0);

		while (d2.size() != size)
			d2.push_back(0);

		size_t len = 1 + size;

		LongDoubleGPU res;

		res.sign = cmp ? 1 : -1;
		res.digits = thrust::device_vector<int>(len, 0);

		for (size_t i = 0; i < size; i++)
			res.digits[i + 1] = d1[i] - d2[i];

		for (size_t i = len - 1; i > 0; i--) {
			if (res.digits[i] < 0) {
				res.digits[i] += 10;
				res.digits[i - 1]--;
			}
		}

		res.exponent = exp + 1;
		res.removeZeroes();

		return res;
	}

	if (sign == -1 && x.sign == -1)
		return (-x) - (-(*this));

	return *this + (-x);
}

LongDoubleGPU LongDoubleGPU::operator*(const LongDoubleGPU& x) const {
	size_t len = digits.size() + x.digits.size();

	LongDoubleGPU res;

	res.sign = sign * x.sign;
	res.digits = thrust::device_vector<int>(len, 0);
	res.exponent = exponent + x.exponent;

	for (size_t i = 0; i < digits.size(); i++)
		for (size_t j = 0; j < x.digits.size(); j++)
			res.digits[i + j + 1] += digits[i] * x.digits[j];

	for (size_t i = len - 1; i > 0; i--) {
		res.digits[i - 1] += res.digits[i] / 10;
		res.digits[i] %= 10;
	}

	res.removeZeroes();

	return res;
}

LongDoubleGPU LongDoubleGPU::operator/(const LongDoubleGPU& x) const {
	LongDoubleGPU res = *this * x.inverse();

	size_t intPart = max((long)0, exponent);

	if (intPart > res.digits.size() - 1)
		return res;

	size_t i = res.digits.size() - 1 - intPart;
	size_t n = max((long)0, res.exponent);

	if (i > n && res.digits[i] == 9) {
		while (i > n && res.digits[i] == 9)
			i--;

		if (res.digits[i] == 9) {
			res.digits.erase(res.digits.begin() + n, res.digits.end());
			res = res + res.sign;
		}
		else {
			res.digits.erase(res.digits.begin() + i + 1, res.digits.end());
			res.digits[i]++;
		}
	}

	return res;
}

LongDoubleGPU LongDoubleGPU::abs() const {
	LongDoubleGPU res(*this);
	res.sign = 1;

	return res;
}

__device__ LongDoubleGPU LongDoubleGPU::inverse() const
{
	
	LongDoubleGPU x(*this);
	x.sign = 1;

	LongDoubleGPU d("1",1);

	LongDoubleGPU res;
	res.sign = sign;
	res.exponent = 1;
	

	while (x < 1) {
		x.exponent++;
		res.exponent++;
	}

	while (d < x)
		d.exponent++;

	res.exponent -= d.exponent - 1;

	size_t numbers = 0;
	size_t intPart = max((long)0, res.exponent);
	size_t maxNumbers = divDigits + intPart;

	do {
		int div = 0;

		while (d > x||d==x) {
			div++;
			d =d- x;
		}

		d.exponent++;
		d.removeZeroes();

		res.digits.push_back(div);
		numbers++;
	} while (!d.isZero() && numbers < maxNumbers);

	return res;
}

bool LongDoubleGPU::isInteger() const {
	if (exponent < 0)
		return false;

	return digits.size() <= (size_t)exponent;
}

bool LongDoubleGPU::isEven() const {
	if (!isInteger())
		return false;

	if (digits.size() == (size_t)exponent)
		return digits[digits.size() - 1] % 2 == 0;

	return true;
}

bool LongDoubleGPU::isOdd() const {
	if (!isInteger())
		return false;

	if (digits.size() == (size_t)exponent)
		return digits[digits.size() - 1] % 2 == 1;

	return false;
}

bool LongDoubleGPU::isZero() const {
	return digits.size() == 1 && digits[0] == 0;
}

