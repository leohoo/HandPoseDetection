//
//  circle_fit.hpp
//  Hand Detection
//
//  Created by Wei Liu on 2021/02/18.
//

#ifndef circle_fit_hpp
#define circle_fit_hpp

#include <stdio.h>

#if defined(__cplusplus)
extern "C" {
#endif

int CircleFit(int n, const float data[], float *x, float *y, float * r);

#if defined(__cplusplus)
}
#endif

#endif /* circle_fit_hpp */
