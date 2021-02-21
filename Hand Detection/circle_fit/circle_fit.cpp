//
//  circle_fit.cpp
//  Hand Detection
//
//  Created by Wei Liu on 2021/02/18.
//

#include "circle_fit.hpp"

#include <iostream>
#include <math.h>
#include <vector>
#include "Eigen/Dense"
#include "Eigen/StdVector"

using namespace std;

/**
 * Fit a circle in a set of points. You need a minimum of 1 point to fit a circle.
 *
 * @param points Is the set of points.
 * @param midpoint Is the fitted midpoint of the circle.
 * @param Returns true, if no error occur. An error occurs, if the points vector is empty.
 */
bool solveLeastSquaresCircleKasa(const  std::vector<Eigen::Vector2d, Eigen::aligned_allocator<Eigen::Vector2d> > &points, Eigen::Vector2d &midpoint, double &radius)
{
    int length = points.size();
    double x1;
    double x2;
    double x3;
    Eigen::MatrixXd AFill(3, length);
    Eigen::MatrixXd A(length, 3);
    Eigen::VectorXd AFirst(length);
    Eigen::VectorXd ASec(length);
    Eigen::VectorXd AFirstSquared(length);
    Eigen::VectorXd ASecSquared(length);
    Eigen::VectorXd ASquaredRes(length);
    Eigen::VectorXd b(length);
    Eigen::VectorXd c(3);
    bool ok = true;

    if (length > 1)
    {
        for (int i = 0; i < length; i++)
        {
            AFill(0, i) = points[i](0);
            AFill(1, i) = points[i](1);
            AFill(2, i) = 1;
        }

        A = AFill.transpose();

        for (int i = 0; i < length; i++)
        {
            AFirst(i) = A(i, 0);
            ASec(i) = A(i, 1);
        }

        for (int i = 0; i < length; i++)
        {
            AFirstSquared(i) = AFirst(i) * AFirst(i);
            ASecSquared(i) = ASec(i) * ASec(i);
        }

        b = AFirstSquared + ASecSquared;

        c = A.jacobiSvd(Eigen::ComputeThinU | Eigen::ComputeThinV).solve(b);

        x1 = c(0);
        midpoint(0) = x1 * 0.5;
        x2 = c(1);
        midpoint(1) = x2 * 0.5;
        x3 = c(2);
        radius = sqrt((x1 * x1 + x2 * x2) / 4 + x3);
    }
    else
    {
        ok = false;
    }

    return ok;
}

int CircleFit(int n, const float data[], float *x, float *y, float * r)
{
    vector<Eigen::Vector2d, Eigen::aligned_allocator<Eigen::Vector2d> > points;
    for(int i=0; i<n; i++) {
        points.push_back(Eigen::Vector2d(data[i*2], data[i*2+1]));
        printf("CircleFit: %f, %f\n", data[i*2], data[i*2+1]);
    }

    double radius;
    Eigen::Vector2d center;

    auto ok = solveLeastSquaresCircleKasa(points, center, radius);
    if (ok) {
        *x = center[0];
        *y = center[1];
        *r = radius;
        printf("CircleFit: (%g, %g), r = %g\n", *x, *y, *r);
    }

    return ok? 1 : 0;
}
