#include "mex.h"
#include "matrix.h"
#include "math.h"
#include <iostream>

using namespace std;

#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

double mean_array( const double * vArray, const unsigned int lenArray )
{
    double mean = 0;
    unsigned int kk;

    for (kk = 0; kk < lenArray; kk++)
    {
        mean += vArray[kk];
    }
    mean /= lenArray;

    return mean;
}

double rms( const double * vDataIn, const unsigned int lenArray )
{
    double rms = 0;
    double meansq = 0;
    double * xsq = new double [lenArray];
    unsigned int kk;

    // squaring
    for (kk = 0; kk < lenArray; kk++)
    {
        xsq[kk] = vDataIn[kk] * vDataIn[kk];
    }

    // root mean
    meansq = mean_array( xsq, lenArray );
    rms    = sqrt( meansq );

    delete [] xsq;

    return rms;
}

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    mxArray * ptData = 0;
    mxArray * ptRMSout = 0;
    double * vDataIn = 0;
    double * rmsOut = 0;
    const mwSize * dims = 0;
    unsigned int numRows = 0;
    unsigned int numCols = 0;

    // get the input data and create the output data type
    ptData   = mxDuplicateArray(prhs[0]);
    ptRMSout = plhs[0] = mxCreateDoubleScalar(0);

    // get pointers to in- and output
    vDataIn = mxGetPr(ptData);
    rmsOut  = mxGetPr(ptRMSout);

    // get dimensions of the input
    dims = mxGetDimensions(prhs[0]);
    numRows = (unsigned int)dims[0];
    numCols = (unsigned int)dims[1];

    if (numRows > 1 && numCols > 1)
    {
        mexErrMsgTxt("This function is optimized for use with vector input! Use a vector as input or split the matrix into row or column vectors.");
    }

    // write the rms to the output scalar
    *rmsOut = rms(vDataIn,MAX(numRows,numCols));
    return;
}
