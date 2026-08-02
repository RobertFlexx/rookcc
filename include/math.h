#ifndef RCC_MATH_H
#define RCC_MATH_H

#include <rcc/features.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MATH_ERRNO 1
#define MATH_ERREXCEPT 2
#define math_errhandling (MATH_ERRNO | MATH_ERREXCEPT)

#define HUGE_VAL (1.0 / 0.0)
#define HUGE_VALF (1.0f / 0.0f)
#define INFINITY HUGE_VALF
#define NAN (0.0f / 0.0f)

#define FP_NAN 0
#define FP_INFINITE 1
#define FP_ZERO 2
#define FP_SUBNORMAL 3
#define FP_NORMAL 4

#if defined(_GNU_SOURCE) || defined(_DEFAULT_SOURCE) || defined(_RCC_SOURCE)
#define M_E 2.71828182845904523536
#define M_LOG2E 1.44269504088896340736
#define M_LOG10E 0.43429448190325182765
#define M_LN2 0.69314718055994530942
#define M_LN10 2.30258509299404568402
#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.78539816339744830962
#define M_1_PI 0.31830988618379067154
#define M_2_PI 0.63661977236758134308
#define M_2_SQRTPI 1.12837916709551257390
#define M_SQRT2 1.41421356237309504880
#define M_SQRT1_2 0.70710678118654752440
#endif




int __fpclassify(double value);
int __fpclassifyf(float value);
int __isinf(double value);
int __isinff(float value);
int __isnan(double value);
int __isnanf(float value);
int __finite(double value);
int __finitef(float value);
int __signbit(double value);
int __signbitf(float value);

#define fpclassify(value) \
  (sizeof(value) == sizeof(float) ? __fpclassifyf((float)(value)) : \
   __fpclassify((double)(value)))
#define isinf(value) \
  (sizeof(value) == sizeof(float) ? __isinff((float)(value)) : \
   __isinf((double)(value)))
#define isnan(value) \
  (sizeof(value) == sizeof(float) ? __isnanf((float)(value)) : \
   __isnan((double)(value)))
#define isfinite(value) \
  (sizeof(value) == sizeof(float) ? __finitef((float)(value)) : \
   __finite((double)(value)))
#define signbit(value) \
  (sizeof(value) == sizeof(float) ? __signbitf((float)(value)) : \
   __signbit((double)(value)))
#define isnormal(value) (fpclassify(value) == FP_NORMAL)
#define isunordered(left, right) (isnan(left) || isnan(right))
#define isgreater(left, right) \
  (!isunordered((left), (right)) && ((left) > (right)))
#define isgreaterequal(left, right) \
  (!isunordered((left), (right)) && ((left) >= (right)))
#define isless(left, right) \
  (!isunordered((left), (right)) && ((left) < (right)))
#define islessequal(left, right) \
  (!isunordered((left), (right)) && ((left) <= (right)))
#define islessgreater(left, right) \
  (!isunordered((left), (right)) && ((left) != (right)))

double acos(double value);
float acosf(float value);
double asin(double value);
float asinf(float value);
double atan(double value);
float atanf(float value);
double cos(double value);
float cosf(float value);
double sin(double value);
float sinf(float value);
double tan(double value);
float tanf(float value);
double acosh(double value);
float acoshf(float value);
double asinh(double value);
float asinhf(float value);
double atanh(double value);
float atanhf(float value);
double cosh(double value);
float coshf(float value);
double sinh(double value);
float sinhf(float value);
double tanh(double value);
float tanhf(float value);
double exp(double value);
float expf(float value);
double exp2(double value);
float exp2f(float value);
double expm1(double value);
float expm1f(float value);
double log(double value);
float logf(float value);
double log10(double value);
float log10f(float value);
double log1p(double value);
float log1pf(float value);
double log2(double value);
float log2f(float value);
double logb(double value);
float logbf(float value);
double cbrt(double value);
float cbrtf(float value);
double fabs(double value);
float fabsf(float value);
double sqrt(double value);
float sqrtf(float value);
double erf(double value);
float erff(float value);
double erfc(double value);
float erfcf(float value);
double lgamma(double value);
float lgammaf(float value);
double tgamma(double value);
float tgammaf(float value);
double ceil(double value);
float ceilf(float value);
double floor(double value);
float floorf(float value);
double nearbyint(double value);
float nearbyintf(float value);
double rint(double value);
float rintf(float value);
double round(double value);
float roundf(float value);
double trunc(double value);
float truncf(float value);
double atan2(double left, double right);
float atan2f(float left, float right);
double hypot(double left, double right);
float hypotf(float left, float right);
double pow(double left, double right);
float powf(float left, float right);
double fmod(double left, double right);
float fmodf(float left, float right);
double remainder(double left, double right);
float remainderf(float left, float right);
double copysign(double left, double right);
float copysignf(float left, float right);
double nextafter(double left, double right);
float nextafterf(float left, float right);
double fdim(double left, double right);
float fdimf(float left, float right);
double fmax(double left, double right);
float fmaxf(float left, float right);
double fmin(double left, double right);
float fminf(float left, float right);
double fma(double first, double second, double third);
float fmaf(float first, float second, float third);

double frexp(double value, int *exponent);
float frexpf(float value, int *exponent);
double ldexp(double value, int exponent);
float ldexpf(float value, int exponent);
int ilogb(double value);
int ilogbf(float value);
double modf(double value, double *integer_part);
float modff(float value, float *integer_part);
double scalbn(double value, int exponent);
float scalbnf(float value, int exponent);
double scalbln(double value, long exponent);
float scalblnf(float value, long exponent);
long lrint(double value);
long lrintf(float value);
long long llrint(double value);
long long llrintf(float value);
long lround(double value);
long lroundf(float value);
long long llround(double value);
long long llroundf(float value);
double remquo(double left, double right, int *quotient);
float remquof(float left, float right, int *quotient);
double nan(const char *tag);
float nanf(const char *tag);


#ifdef __cplusplus
}
#endif

#endif
