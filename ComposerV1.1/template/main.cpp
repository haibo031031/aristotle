#include <stdlib.h>
#include <stdio.h>
#include <omp.h>
#include "CLHelper.h"
#include "util.h"
#include "macro.h"

//void OMPRun(const float * in1, const float * in2, float * out, int cdim, int rdim);
//void OCLRun(cl_mem in1, cl_mem in2, cl_mem out, int cdim, int rdim);
void OMPRun(@argOMP, float * out, int cdim, int rdim, int cdimIn, int rdimIn);
void OCLRun(@argOCL, cl_mem out, int cdim, int rdim, int cdimIn, int rdimIn);

int main(int argc, char ** argv)
{
	//float *hIn1, *hIn2;
	//cl_mem dIn1, dIn2;
	@hIn;
	@dIn;
	float *hOut, *rOut;
	cl_mem dOut;
try{
	_clParseCommandLine(argc, argv);
	string strSubfix = string(argv[2]);
	_clInit(platform_id, device_type, device_id);
	int cdim = atoi(argv[1]); 
	int rdim = atoi(argv[1]); 
	int r = atoi(argv[3]);
	@cdimIn
	@rdimIn
	// different between iMAP1 and iMAP2
	printf("cdim=%d, rdim=%d, radius=%d\n", cdim, rdim, r);
	int iIter = 10;
	int elems = @elems;
	double dataAmount = (double)cdim * (double)rdim * (double)(elems) * (double)sizeof(float) * 1e-6;

	
#if defined TIME
	double start_time = 0;
	double end_time = 0;
	double delta_time = 0;
	int cnt = 0;
	string dat_name= string("data.") + strSubfix + string(".dat");

	FILE * fp = fopen(dat_name.c_str(), "a+");
	if(fp==NULL)
	{
		printf("failed to open file!!!\n");
		exit(-1);
	}
#endif
	
	//hIn1 = (float *)malloc(cdim * rdim * sizeof(float));
	//hIn2 = (float *)malloc(cdim * rdim * sizeof(float));
	@hAlc
	hOut = (float *)malloc(cdim * rdim * sizeof(float));
	rOut = (float *)malloc(cdim * rdim * sizeof(float));

	//fill<float>(hIn1, cdim * rdim, 5);
	//fill<float>(hIn2, cdim * rdim, 5);		
	@hFill

	//dIn1 = _clMalloc(cdim * rdim * sizeof(float));
	//dIn2 = _clMalloc(cdim * rdim * sizeof(float));
	@dAlc
	dOut = _clMalloc(cdim * rdim * sizeof(float));

	//_clMemcpyH2D(dIn1, hIn1, cdim * rdim * sizeof(float));
	//_clMemcpyH2D(dIn2, hIn2, cdim * rdim * sizeof(float));
	@h2dTrans

	_clFinish();
	
	// warmup
	//OCLRun(dIn1, dIn2, dOut, cdim, rdim);
	OCLRun(@oclArgs, dOut, cdim, rdim, cdimIn, rdimIn);

#ifdef VARIFY	
	//OMPRun(hIn1, hIn2, rOut, cdim, rdim);
	OMPRun(@ompArgs, rOut, cdim, rdim, cdimIn, rdimIn);
#endif //VARIFY
	

#ifdef TIME
	delta_time = 0;
	cnt = 0;
#endif	
	for(int i=0; i<iIter; i++)
	{
#ifdef TIME
	cnt++;
	start_time = gettime();
#endif

		OCLRun(@oclArgs, dOut, cdim, rdim, cdimIn, rdimIn);
#ifdef TIME	
	end_time = gettime();
	delta_time += end_time - start_time;
	if(fabs(delta_time-600000.0)>0.1) break;	// ????
#endif	
	}

#ifdef TIME
	fprintf(fp, "%lf\t", dataAmount * (double)cnt/delta_time);
#endif

#ifdef VARIFY
	_clMemcpyD2H(hOut, dOut, cdim * rdim * sizeof(float));	
	verify_array<float>(rOut, hOut, cdim * rdim);	
#endif //VARIFY


#ifdef TIME	
	fprintf(fp, "\n");	
	fclose(fp);
#endif	
}
catch(string msg){
	printf("ERR:%s\n", msg.c_str());
	printf("Error catched\n");
	exit(-1);
	}
	//_clFree(dIn1);
	//_clFree(dIn2);
	@clFree
	_clFree(dOut);
	_clRelease();
	//if(hIn1!=NULL) free(hIn1);
	//if(hIn2!=NULL) free(hIn2);
	@hFree
	if(hOut!=NULL) free(hOut);
	if(rOut!=NULL) free(rOut);

	return 1;
}


void OMPRun(@argOMP, float * out, int cdim, int rdim, int cdimIn, int rdimIn)
{

#pragma omp parallel for 	
	for(int r=0; r<rdim; r++)
		for(int c=0; c<cdim; c++)
		{
			// Note: difference between different iMAPs
			float val = 0.0f;
			int xIn = @xIn;						
			@inData
			int xOut = r * cdim + c;
			out[xOut] = val; 
		}
}

void OCLRun(@argOCL, cl_mem out, int cdim, int rdim, int cdimIn, int rdimIn)
{
	int kernel_id = 0;
	int arg_idx = 0;
	//_clSetArgs(kernel_id, arg_idx++, in1);
	//_clSetArgs(kernel_id, arg_idx++, in2);
	@clSetArgs
	_clSetArgs(kernel_id, arg_idx++, out);
	_clSetArgs(kernel_id, arg_idx++, &cdim, sizeof(int));
	_clSetArgs(kernel_id, arg_idx++, &rdim, sizeof(int));
	_clSetArgs(kernel_id, arg_idx++, &cdimIn, sizeof(int));
	_clSetArgs(kernel_id, arg_idx++, &rdimIn, sizeof(int));

	int range_x = cdim;
	int range_y = rdim;
	int group_x = WG;
	int group_y = WG;
	
	_clInvokeKernel2D(kernel_id, range_x, range_y, group_x, group_y);
	
	return ;
}

