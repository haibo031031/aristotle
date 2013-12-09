
/*
	mixed opt. kernel with local memory (multiple data structures)
*/

#define WG 16
@radius
@WD	// the width of the local space
@HT	// the height of the local space

//__kernel void kernelLMC(const __global float *in1, const __global float *in2, __global float *out, const int cdim, const int rdim)
__kernel void kernelLMC(@inArgs, __global float *out, const int cdim, const int rdim, const int cdimIn, const int rdimIn)
{
	int tgx = get_global_id(0);
	int tgy = get_global_id(1);
	int tlx = get_local_id(0);
	int tly = get_local_id(1);
	int wgx = get_group_id(0);
	int wgy = get_group_id(1);
	@bxy
	// allocate local memory
	//__local float LM1[WG];
	//__local float LM2[WG];
	@lmAlc
	@varDec
	
	int rr = 0;
	int ll = 0;
	for(rr=0; rr<cdim; rr=rr+HT)
	{
		// load data from GM to LM	
		@lmLoad
		barrier(CLK_LOCAL_MEM_FENCE);	
		// use the data elements in LM
		@lmUse
		barrier(CLK_LOCAL_MEM_FENCE);		
	}
	// use global memory
	@gmUse

	// output
	//out[y*cdim+x] = retVal1 + retVal2;
	out[tgy*cdim+tgx] = @lmOut;

	return ;
}

