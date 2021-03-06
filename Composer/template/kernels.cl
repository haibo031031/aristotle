
/*
	mixed opt. kernel with local memory (multiple data structures)
*/

#define WG 16
@radius
@WD	// the width of the local space
@HT	// the height of the local space

__kernel void kernelLMC(@inArgs, __global float *out, const int cdim, const int rdim, @inPairs)
{
	int tgx = get_global_id(0);
	int tgy = get_global_id(1);
	int tlx = get_local_id(0);
	int tly = get_local_id(1);
	int wgx = get_group_id(0);
	int wgy = get_group_id(1);
	int cc = 0;
	int rr = 0;
	int ll = 0;
	@bxy
	@lmAlc
	@varDec	
	@loadANDuse	
	out[tgy*cdim+tgx] = @lmOut;

	return ;
}

