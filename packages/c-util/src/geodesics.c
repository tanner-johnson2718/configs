//*****************************************************************************
// ECEF and Ellipsoidial cordinates. ECEF or Earth Centered, Earth Fixed is a 
// frame a measurement as it sounds expressed in cartesian coordinates. The z
// axis extends through the poles with North being pos and origin at center of 
// earth. The X-plane is zero-ed at the Greenwhich median. Y is perdicualar
// east ward. We map x,y,z to our gsl_mat indicies as such:
//
// Spherical. Since Eart is not a perfect sphere, we generally do no map
// cartesian to sperical. As a prelude to ellipsoidal cords, spherical 
// cordinates can be expressed as)
//
//    x = r * cos(theta) * cos(lamdba) 
//    y = r * cos(theta) * sin(lambda) 
//    z = r * sin(theta)
//
// Theta is the angle between the x/y plane and line from your current pos to
// the origin. R is the length of that line and lambda is angle of your pos
// projected onto the x/y plane and the x-axis. To derive this yourself, take
// a sphere, keep Z facing up and take a circular cut at an arbitrary angle
// lamda. Now you can see cos(theta) projects you onto the the X/Y plane. From
// there you have a circular projection of radius r which can be parameterized 
// in lamda the usual way i.e. (rcos(lamdba), rsin(lambda)). We can also see from
// here that Z is just the verical projection of the line shown or r*sin(thata)
//
//                                 Z
//                                 |
//                          ooo OOO|OOO ooo  *
//                      oOO        |        /
//                  oOO            |       /    OOo
//               oOO               |      /        OOo
//             oOO                 |     /           OOo
//           oOO                   |    /              OOo
//          oOO                    |   /                OOo
//         oOO                     |  /                  OOo
//        oOO                      | /                    OOo
//        oOO                      |/  theta              OOo
//   ------------------------------|--------------------------------- Lambda
//        oOO                      |                      OOo
//        oOO                      |                      OOo
//         oOO                     |                     OOo
//          oOO                    |                    OOo
//           oOO                   |                   OOo
//             oOO                 |                 OOo
//               oO                |               OOo
//                  oOO            |            OOo
//                      oOO        |        OOo
//                          ooo OOO|OOO ooo
//                                 |
//       
//
// Ellipsoidal. Now we can extend this type of reasoning to an ellipsoid which
// is an ellipse rotated about the Z-axis showb below. We denote the vertical
// axis length of thw ellipse as b (this is the smaller i.e. minor axis). We
// denote the major or horizontal axis as a. Throughout the code and our system
// we will use a and the parameter e, the eccentricty, which is defined as shown 
// below and gives a positive such that the larger the number the more "oblong"
// the ellipsoid is with e=0 being the case of sphere.
//
//    e = sqrt(a*a - b*b) / a
//
//
//
//                                               *   P(h, lambda, theta)
//                                 Z            /
//                                 |         h /  
//                          ooo OOO|OOO ooo   /  
//                      oOO        |         *
//                  oOO            |        /   OOo
//               oOO               |       /       OOo
//             oOO                 |      /          OOo
//           oOO                   |   N /            OOo
//          oOO                    |    /               OOo
//         oOO                     |   / theta           OOo
//   ------------------------------|--/------------------------------ Lambda
//         oOO                     | /                   OOo
//          oOO                    |/                   OOo
//           oOO                   *                   OOo
//             oOO                 |                 OOo
//               oO                |               OOo
//                  oOO            |            OOo
//                      oOO        |        OOo
//                          ooo OOO|OOO ooo
//                                 |
//
// As you can see we need to generalize the radial line, which in ellipsoidail
// coordinates is given by N
//
//    N - is the prime normal vertical i.e. I am sitting on the surface of an 
//        ellisoid. I draw a tangent. The normal to the tangent plane extented
//        from my location to the Z-axis. The length of this line is N.
//
// We also replace the radial distance with simply a height above the surface,
// giving an above sea level altitude. The formal coordinate transformation is 
// given by the following:
//
//    x = (N+h)         * cos(theta) * cos(lamdba) 
//    y = (N+h)         * cos(theta) * sin(lambda) 
//    z = (N(1-e^2) +h) * sin(theta)
//    N = a / sqrt(1 - (e^2)(sin^2 (theta)))
//
// Deriving x and y and is a simple extension of the logic used in the
// spherical case. To compute both N and Z one needs to do the following.
//
//    1) Take an ellipse slice at some angle lamba
//    2) Parameterize ellipse: {x = acos(theta), y = b sin(theta)}
//    3) Compute Tangent Line slope dy/dx
//    4) Compute normal line to tangent as y = (-dx/dy)x + A
//         4a) A is the y intercept
//    5) N is distance between point {acos(theta), b sin(theta)} and y intercept
//    6) Z is N - the portion of the normal verical below the y axis. 
//
// As one can see going from ECEF -> WGS is much harder and requires numerics
// or approximation. Included in the repo is a paper on the "improved Zhus"
// algorithm for doing this fast and accurately. We will not go into depth
// about it as it really isn't super important.
//
//*****************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdarg.h>
#include <time.h>
#include <time.h>
#include <pthread.h>
#include <stdint.h>
#include <unistd.h>
#include "ws.h"

static const double  a = +6.37813700000000000000e+0006; /* a */
static const double  invaa = +2.45817225764733181057e-0014; /* 1/(a^2) */
static const double  ee = +6.69437999014131705734e-0003; /* e^2 */
static const double  l = +3.34718999507065852867e-0003; /* (e^2)/2 */
static const double  ll4 = +4.48147234524044602618e-0005; /* e^4 */
static const double  ll = +1.12036808631011150655e-0005; /* (e^4)/4 */
static const double  p1mee = +9.93305620009858682943e-0001; /* 1-(e^2) */
static const double  p1meedaa = +2.44171631847341700642e-0014; /* (1-(e^2))/(a^2) */
static const double  Hmin = +2.25010182030430273673e-0014; /* (e^12)/4 */
static const double  invcbrt2 = +7.93700525984099737380e-0001; /* 1/(2^(1/3)) */
static const double  inv3 = +3.33333333333333333333e-0001; /* 1/3 */
static const double  inv6 = +1.66666666666666666667e-0001; /* 1/6 */
static const double  d2r = +1.74532925199432957691e-0002; /* pi/180 */
static const double  r2d = +5.72957795130823208766e+0001; /* 180/pi */

typedef struct
{
    double x;
    double y;
    double z;
} ECEF_t;

typedef struct
{
    double lat;
    double lon;
    double alt;
} WGS84_t;


static inline double N(double theta)
{
    return  a / sqrt(1.0 - (ee*sin(theta) * sin(theta)));
}

double rad(double deg)
{
    return deg * d2r;
}

double deg(double rad)
{
    return rad * r2d;
}

ECEF_t ECEF(WGS84_t in)
{
    ECEF_t p;
    double _N = N(in.lat);

    p.x = (_N+in.alt) * cos(in.lat) * cos(in.lon);
    p.y = (_N+in.alt) * cos(in.lat) * sin(in.lon);
    p.z = ((_N*(1.0 - (ee))) + in.alt ) * sin(in.lat);

    return p;
}

// Zhu's algorith (see docs in repo)
WGS84_t WGS84(ECEF_t in)
{
    double x, y, z;
    double lat, lon, alt;
    // The variables below correspond to symbols used in the paper
    // "Accurate Conversion of Earth-Centered, Earth-Fixed Coordinates
    // to Geodetic Coordinates"
    double beta;
    double C;
    double dFdt;
    double dt;
    double dw;
    double dz;
    double F;
    double G;
    double H;
    double i;
    double k;
    double m;
    double n;
    double p;
    double P;
    double t;
    double u;
    double v;
    double w;
    // Intermediate variables
    double j;
    double ww; // w^2
    double mpn; // m+n
    double g;
    double tt; // t^2
    double ttt; // t^3
    double tttt; // t^4
    double zu; // z * u
    double wv; // w * v
    double invuv; // 1 / (u * v)
    double da;
    double t1, t2, t3, t4, t5, t6, t7;
    x = in.x;
    y = in.y;
    z = in.z;
    ww = x * x + y * y;
    m = ww * invaa;
    n = z * z * p1meedaa;
    mpn = m + n;
    p = inv6 * (mpn - ll4);
    G = m * n * ll;
    H = 2 * p * p * p + G;
    if (H < Hmin)
    {
    return (WGS84_t) {0,0,0};
    }
    C = pow(H + G + 2 * sqrt(H * G), inv3) * invcbrt2;
    i = -ll - 0.5 * mpn;
    P = p * p;
    beta = inv3 * i - C - P / C;
    k = ll * (ll - mpn);
    // Compute left part of t
    t1 = beta * beta - k;
    t2 = sqrt(t1);
    t3 = t2 - 0.5 * (beta + i);
    t4 = sqrt(t3);
    // Compute right part of t
    t5 = 0.5 * (beta - i);
    // t5 may accidentally drop just below zero due to numeric turbulence
    // This only occurs at latitudes close to +- 45.3 degrees
    t5 = fabs(t5);
    t6 = sqrt(t5);
    t7 = (m < n) ? t6 : -t6;
    // Add left and right parts
    t = t4 + t7;
    // Use Newton-Raphson's method to compute t correction
    j = l * (m - n);
    g = 2 * j;
    tt = t * t;
    ttt = tt * t;
    tttt = tt * tt;
    F = tttt + 2 * i * tt + g * t + k;
    dFdt = 4 * ttt + 4 * i * t + g;
    dt = -F / dFdt;
    // compute latitude (range -PI/2..PI/2)
    u = t + dt + l;
    v = t + dt - l;
    w = sqrt(ww);
    zu = z * u;
    wv = w * v;
    lat = atan2(zu, wv);
    // compute altitude
    invuv = 1 / (u * v);
    dw = w - wv * invuv;
    dz = z - zu * p1mee * invuv;
    da = sqrt(dw * dw + dz * dz);
    alt = (u < 1) ? -da : da;
    // compute longitude (range -PI..PI)
    lon = atan2(y, x);
    return (WGS84_t) {lat, lon, alt};
}

static void ellipsoid_test(char* prompt, double h, double lon, double lat)
{
    WGS84_t w1 = {lat, lon, h};
    WGS84_t w2 = WGS84(ECEF(w1));
    printf("%-10s W1 = (%012.4f,%012.4f,%012.4f) W2=(%012.4f,%012.4f,%012.4f)\n", prompt, w1.lat, w1.lon, w1.alt, w2.lat, w2.lon, w2.alt);
}

static void run_ellipsoid_test()
{
    ellipsoid_test("Nominal", 2041.5504, rad(-104.80121891303988), rad(38.996328766277756));
    ellipsoid_test("Median 0", 1220, 0, M_PI/4.0);
    ellipsoid_test("Median 1", 1440, 0, 0);
    ellipsoid_test("Neg h", -100, M_PI/2.0, M_PI/4.0);
    ellipsoid_test("~Median", 1000, M_PI, 0.2);
    ellipsoid_test("~Median", 1000, -M_PI, 0.2);
    ellipsoid_test("N Pole", 0, 0, M_PI/2.0);
    ellipsoid_test("S Pole", 0, 0, -M_PI/2.0);
    ellipsoid_test("Large h", 20200000, 0,0);
    ellipsoid_test("Large h", 20200000, -1.3,0.7);
    ellipsoid_test("Large h", 20200000, M_PI,0);
    ellipsoid_test("Large h", 20200000, -M_PI,0);
    ellipsoid_test("Large h", 20200000, 0,M_PI/2.0);
    ellipsoid_test("Large h", 20200000, 0,-M_PI/2.0);
    ellipsoid_test("Large h", 20200000, M_PI,M_PI/2.0);
}
