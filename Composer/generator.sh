#!/bin/sh

map=(107 108 109 110 112 113 114 115 116 204 205 211 302 303 306 407 408 409 410 412 413 414 415 416 507 508 509 510 512 513 514 515 516)
eMAP=(0000 1000 0100 0010 0001 1100 1010 1001 0101 0110 0011 0111 1011 1101 1110 1111) 
iMAP=(1 2 3 4 5)
ELEM=("1" "cdim" "rdim" "(2*R+1)*(2*R+1)" "5")
R=(0 0 0 3 1)
WG=16
M=2	# M is maximum maps that is using local space (thus M<=N). 
N=2	# N is used to control the maximum of maps (input data structures)
host='main.cpp'
hostT='./template/main.cpp'
kernel='kernels.cl'
kernelT='./template/kernels.cl'
kernelloadANDuse='./template/loadANDuse'
report='lmReport.txt'

# ------------------------------------------------------------------
# 			subroutine
# ------------------------------------------------------------------
gvCDimIn=""

FunCDIM()
{
	lvCdim=""
	iibits=$1
	eebits=$2
	case "${iibits}" in
		"1")  			
		lvCdim="(${eebits:0:1}*cdim)+(${eebits:1:1}*rdim)"
		    ;;
		"2") 
		lvCdim="cdim"
		    ;;
		"3") 
		lvCdim="(${eebits:0:1}*cdim)+(${eebits:1:1}*rdim)"
		    ;;
		"4") 
		lvCdim="(${eebits:0:1}*cdim)+(${eebits:1:1}*rdim)"
		    ;;
		"5") 
		lvCdim="((${eebits:0:1}*cdim)+(${eebits:1:1}*rdim)+2)"
		    ;;
		*)
		lvCdim="1"
		    ;;
	esac	
	
	gvCDimIn=${lvCdim}
}

gvRDimIn=""
FunRDIM()
{
	lvRdim=""
	iibits=$1
	eebits=$2
	case "${iibits}" in
		"1")  	
		lvRdim="(${eebits:2:1}*cdim)+(${eebits:3:1}*rdim)"		
		    ;;
		"2") 
		lvRdim="(${eebits:2:1}*cdim)+(${eebits:3:1}*rdim)"		
		    ;;
		"3") 
		lvRdim="rdim"		
		    ;;
		"4") 
		lvRdim="(${eebits:2:1}*cdim)+(${eebits:3:1}*rdim)"		
		    ;;
		"5") 
		lvRdim="((${eebits:2:1}*cdim)+(${eebits:3:1}*rdim)+2)"		
		    ;;
		*)
		lvRdim="1"
		    ;;
	esac	
	
	gvRDimIn=${lvRdim}	
}

gvElem=""
GetElem()
{
	iibits=$1
	elem="1+${ELEM[${iibits}-1]}"		
	gvElem=${elem}		
}

gvOmpVal=""
GetOmpVal()
{
	iibits=$1
	eebits=$2
	n=$3
	iidxW="" # x coodinate
	case "${eebits:0:2}" in
		"00")  
		    iidxW="0"
		    ;;
		"10") 
		    iidxW="c"
		    ;;
		"01") 
		    iidxW="r"
		    ;;
		"11") 
		    iidxW="r+c"
		    ;;
		*)
		    iidxW="0"
		    ;;
	esac

	iidxH="" # y coordinate
	case "${eebits:2:2}" in
		"00")  
		    iidxH="0"
		    ;;
		"10") 
		    iidxH="c"
		    ;;
		"01") 
		    iidxH="r"
		    ;;
		"11") 
		    iidxH="r+c"
		    ;;
		*)
		    iidxH="0"
		    ;;
	esac

	lvOmpVal="float val${n}=0.0f;\n\t\t\t"

	case "${iibits}" in
		"1")  	
		    # xxIn="(${iidxH})*cdimIn${n}+(${iidxW})"	
		    xxIn="int xxIn${n}=(${iidxH})*cdimIn${n}+(${iidxW});\n\t\t\t"
		    lvOmpVal="${xxIn}${lvOmpVal}val${n}=in${nn}[xxIn${n}];"	  
		    ;;
		"2") 
		    xxIn="int xxIn${n}=(${iidxH})*cdimIn${n};\n\t\t\t"
		    lvOmpVal="${xxIn}${lvOmpVal}for(int cc=0; cc<cdim; cc++)\n\t\t\t{\n\t\t\t\tval${n}+="
		    lvOmpVal="${lvOmpVal}in${n}[xxIn${n}+cc]+"			
		    lvOmpVal="${lvOmpVal%?};\n\t\t\t}"		
		    ;;
		"3") 
		    xxIn="int xxIn${n}=${iidxW};\n\t\t\t"
		    lvOmpVal="${xxIn}${lvOmpVal}for(int rr=0; rr<rdim; rr++)\n\t\t\t{\n\t\t\t\tval${n}+="
		    lvOmpVal="${lvOmpVal}in${n}[rr*cdimIn${n}+xxIn${n}]+"
		    lvOmpVal="${lvOmpVal%?};\n\t\t\t}"		
		    ;;
		"4") 
		    iidxx="int idxW${n}=${iidxW};\n\t\t\tint idxH${n}=${iidxH};\n\t\t\t"
		    lvOmpVal="${iidxx}${lvOmpVal}for(int rr=-R; rr<=R; rr++){\n\t\t\t\tfor(int cc=-R; cc<=R; cc++){\n\t\t\t\t\t"
		    lvOmpVal="${lvOmpVal}int hh=idxH${n}+rr;\n\t\t\t\t\t"
		    lvOmpVal="${lvOmpVal}if(hh<0) hh=0;\n\t\t\t\t\t"
		    lvOmpVal="${lvOmpVal}if(hh>=rdimIn${n}) hh=(rdimIn${n}-1);\n\t\t\t\t\t"
		    lvOmpVal="${lvOmpVal}int ww=idxW${n}+cc;\n\t\t\t\t\t"
		    lvOmpVal="${lvOmpVal}if(ww<0) ww=0;\n\t\t\t\t\t"
		    lvOmpVal="${lvOmpVal}if(ww>=cdimIn${n}) ww=(cdimIn${n}-1);\n\t\t\t\t\t"
		    lvOmpVal="${lvOmpVal}int idx=(hh)*cdimIn${n}+(ww);\n\t\t\t\t\tval${n}+="
		    lvOmpVal="${lvOmpVal}in${n}[idx]+"
		    lvOmpVal="${lvOmpVal%?};\n\t\t\t\t}"
		    lvOmpVal="${lvOmpVal}\n\t\t\t}"		
		    ;;
		"5") 
		    iidxx="int idxW${n}=(${iidxW}+1);\n\t\t\tint idxH${n}=(${iidxH}+1);\n\t\t\t"
		    lvOmpVal="${iidxx}"
		    lvOmpVal="${lvOmpVal}float val${n} = in${n}[(idxH${n}-1)*cdimIn${n}+(idxW${n})]+in${n}[(idxH${n})*cdimIn${n}+(idxW${n}-1)]+in${n}[(idxH${n})*cdimIn${n}+(idxW${n})]+in${n}[(idxH${n})*cdimIn${n}+(idxW${n}+1)]+in${n}[(idxH${n}+1)*cdimIn${n}+(idxW${n})];\n"		
		    ;;
		*)
		
		    ;;
	esac		
	gvOmpVal=${lvOmpVal}
}

gvBXY=""
GetBXY()
{
	bits=$1
	n=$2
	bx="" # x coodinate
	case "${bits:0:2}" in
		"00")  
		    bx="(0)"
		    ;;
		"10") 
		    bx="(wgx)"
		    ;;
		"01") 
		    bx="(wgy)"
		    ;;
		"11") 
		    bx="(wgy+wgx)"
		    ;;
		*)
		    bx="(0)"
		    ;;
	esac

	bx="int bx${n}=${bx}*WG;"
	by="" # y coordinate
	case "${bits:2:2}" in
		"00")  
		    by="(0)"
		    ;;
		"10") 
		    by="(wgx)"
		    ;;
		"01") 
		    by="(wgy)"
		    ;;
		"11") 
		    by="(wgy+wgx)"
		    ;;
		*)
		    by="(0)"
		    ;;
	esac
	by="int by${n}=${by}*WG;"
	gvBXY="${bx}\n\t${by}"
}

gvlmUse=""
gvlmLoad=""

GetLCLMem()
{
	n=$1 
	m=$2
	iibits=$3
	eebits=$4
	bits=$eebits

	idxW=""
	case "${eebits:0:2}" in
		"00")  
		    idxW="0"
		    ;;
		"10") 
		    idxW="tlx"
		    ;;
		"01") 
		    idxW="tly"
		    ;;
		"11") 
		    idxW="tly+tlx"
		    ;;
		*)
		    idxW=""
		    ;;
	esac
	idxH=""
	case "${eebits:2:2}" in
		"00")  
		    idxH="0"
		    ;;
		"10") 
		    idxH="tlx"
		    ;;
		"01") 
		    idxH="tly"
		    ;;
		"11") 
		    idxH="tly+tlx"
		    ;;
		*)
		    idxH=""
		    ;;
	esac


	# assume that R${n}<=WG (otherwise, the code refuses working:)
	offsetV="WG"	# WG or 2xWG
	if [ "${eebits:2:2}" == "11" ]; then
		offsetV="2*WG"
	fi
	offsetH="WG"	# WG or 2xWG
	if [ "${eebits:0:2}" == "11" ]; then
		offsetH="2*WG"
	fi


	case "${iibits}" in
		"1")	########################################################	
		
		gvlmUse=""
		gvlmLoad=""
		# load
			# central data
			ceD=""
			ceD1=""
			ceD2=""
			ceD3=""
			ceD4=""
			# 1:
			ceD1="\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n});\n\t\tint dg = (bx${n}+tlx)+(by${n}+tly)*cdimIn${n};"
			ceD1="${ceD1}\n\t\tLM${n}[dl] = in${n}[dg];"
			ceD1="if(1==1){\/\/central data (base) \n\t${ceD1}\n\t}\n\t"

			# 2: Need to read data in the vertical direction?
			if [ "${eebits:2:2}" == "11" ]; then # get the last two eebits of eMAP
				ceD2="\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n});\n\t\tint dg = (bx${n}+tlx)+(by${n}+tly+WG)*cdimIn${n};"
				ceD2="${ceD2}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD2="if(1==1){\/\/central data (vertical) \n\t${ceD2}\n\t}\n\t"	
			fi					

			# 3: Need to read data in the horizontal direction?
			if [ "${eebits:0:2}" == "11" ]; then # get the last two eebits of eMAP
				ceD3="\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n}+WG);\n\t\tint dg = (bx${n}+tlx+WG)+(by${n}+tly)*cdimIn${n};"
				ceD3="${ceD3}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD3="if(1==1){\/\/central data (horizontal) \n\t${ceD3}\n\t}\n\t"
			fi

			# 4: Need to read data in the diagonal direction?
			if [ "${eebits:0:2}" == "11" ] && [ "${eebits:2:2}" == "11" ]; then # get the last two eebits of eMAP
				ceD4="\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n}+WG);\n\t\tint dg = (bx${n}+tlx+WG)+(by${n}+tly+WG)*cdimIn${n};"
				ceD4="${ceD4}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD4="if(1==1){\/\/central data (diagonal) \n\t${ceD4}\n\t}\n\t"
			fi
			ceD="${ceD1}${ceD2}${ceD3}${ceD4}"
			gvlmLoad="${ceD}"

		# use		
			gvlmUse="retVal${n} += LM${n}[useIdx${n}];\n\t"		
			gvlmUse="int useIdx${n}=(${idxH})*WD${n}+(${idxW});\n\t${gvlmUse}"
			gvlmUse="${gvlmUse%?}"
			gvlmUse="${gvlmUse%?}"
	    ;;
		"2")	########################################################
		gvlmUse=""
		gvlmLoad=""
		# load
			# central data
			ceD=""
			ceD1=""
			ceD2=""
			ceD3=""
			ceD4=""
			# 1:
			ceD1="\t\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n});\n\t\t\tint dg = (bx${n}+tlx+cc)+(by${n}+tly)*cdimIn${n};"
			ceD1="${ceD1}\n\t\t\tLM${n}[dl] = in${n}[dg];"
			ceD1="if(1==1){\/\/central data (base) \n\t${ceD1}\n\t\t}\n\t"

			# 2: Need to read data in the vertical direction?
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD2="\t\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n});\n\t\t\tint dg = (bx${n}+tlx+cc)+(by${n}+tly+WG)*cdimIn${n};"
				ceD2="${ceD2}\n\t\t\tLM${n}[dl] = in${n}[dg];"
				ceD2="\tif(1==1){\/\/central data (vertical) \n\t${ceD2}\n\t\t}\n\t"	
			fi					

			# 3: Need to read data in the horizontal direction?
			if [ "${bits:0:2}" == "11" ]; then # get the last two bits of eMAP
				ceD3="\t\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n}+WG);\n\t\t\tint dg = (bx${n}+tlx+WG+cc)+(by${n}+tly)*cdimIn${n};"
				ceD3="${ceD3}\n\t\t\tLM${n}[dl] = in${n}[dg];"
				ceD3="\tif(1==1){\/\/central data (horizontal) \n\t${ceD3}\n\t\t}\n\t"
			fi

			# 4: Need to read data in the diagonal direction?
			if [ "${bits:0:2}" == "11" ] && [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD4="\t\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n}+WG);\n\t\t\tint dg = (bx${n}+tlx+WG+cc)+(by${n}+tly+WG)*cdimIn${n};"
				ceD4="${ceD4}\n\t\t\tLM${n}[dl] = in${n}[dg];"
				ceD4="\tif(1==1){\/\/central data (diagonal) \n\t${ceD4}\n\t\t}\n\t"
			fi
			ceD="${ceD1}${ceD2}${ceD3}${ceD4}"
			gvlmLoad="${ceD}"
		# use
			gvlmUse="int useIdx${n}=(${idxH})*WD${n};"
			gvlmUse="${gvlmUse}\n\t\tfor(ll=0; ll<WD${n}; ll++){"
			gvlmUse="${gvlmUse}\n\t\t\tretVal${n} += LM${n}[useIdx${n}+ll];"
			gvlmUse="${gvlmUse}\n\t\t}"

	    ;;
		"3")	########################################################
		gvlmUse=""
		gvlmLoad=""
		# load
			# central data
			ceD=""
			ceD1=""
			ceD2=""
			ceD3=""
			ceD4=""
			# 1:
			ceD1="\t\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n});\n\t\t\tint dg = (bx${n}+tlx)+(by${n}+tly+rr)*cdimIn${n};"
			ceD1="${ceD1}\n\t\t\tLM${n}[dl] = in${n}[dg];"
			ceD1="if(1==1){\/\/central data (base) \n\t${ceD1}\n\t\t}\n\t"

			# 2: Need to read data in the vertical direction?
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD2="\t\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n});\n\t\t\tint dg = (bx${n}+tlx)+(by${n}+tly+WG+rr)*cdimIn${n};"
				ceD2="${ceD2}\n\t\t\tLM${n}[dl] = in${n}[dg];"
				ceD2="\tif(1==1){\/\/central data (vertical) \n\t${ceD2}\n\t\t}\n\t"	
			fi					

			# 3: Need to read data in the horizontal direction?
			if [ "${bits:0:2}" == "11" ]; then # get the last two bits of eMAP
				ceD3="\t\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n}+WG);\n\t\t\tint dg = (bx${n}+tlx+WG)+(by${n}+tly+rr)*cdimIn${n};"
				ceD3="${ceD3}\n\t\t\tLM${n}[dl] = in${n}[dg];"
				ceD3="\tif(1==1){\/\/central data (horizontal) \n\t${ceD3}\n\t\t}\n\t"
			fi

			# 4: Need to read data in the diagonal direction?
			if [ "${bits:0:2}" == "11" ] && [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD4="\t\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n}+WG);\n\t\t\tint dg = (bx${n}+tlx+WG)+(by${n}+tly+WG+rr)*cdimIn${n};"
				ceD4="${ceD4}\n\t\t\tLM${n}[dl] = in${n}[dg];"
				ceD4="\tif(1==1){\/\/central data (diagonal) \n\t${ceD4}\n\t\t}\n\t"
			fi
			ceD="${ceD1}${ceD2}${ceD3}${ceD4}"
			gvlmLoad="${ceD}"
		# use
			gvlmUse="int useIdx${n}=(${idxW});"
			gvlmUse="${gvlmUse}\n\t\tfor(ll=0; ll<HT${n}; ll++)\n\t\t{"
			gvlmUse="${gvlmUse}\n\t\t\tretVal${n} += LM${n}[useIdx${n}+ll*WD${n}];"
			gvlmUse="${gvlmUse}\n\t\t}"

	    ;;
		"4")	########################################################
		gvlmUse=""
		gvlmLoad=""
		# load 
			# central data
			ceD=""
			ceD1=""
			ceD2=""
			ceD3=""
			ceD4=""
			# 1:
			ceD1="\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n});\n\t\tint dg = (bx${n}+tlx)+(by${n}+tly)*cdimIn${n};"
			ceD1="${ceD1}\n\t\tLM${n}[dl] = in${n}[dg];"
			ceD1="if(1==1){\/\/central data (base) \n\t${ceD1}\n\t}\n\t"

			# 2: Need to read data in the vertical direction?
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD2="\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n});\n\t\tint dg = (bx${n}+tlx)+(by${n}+tly+WG)*cdimIn${n};"
				ceD2="${ceD2}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD2="if(1==1){\/\/central data (vertical) \n\t${ceD2}\n\t}\n\t"	
			fi					

			# 3: Need to read data in the horizontal direction?
			if [ "${bits:0:2}" == "11" ]; then # get the last two bits of eMAP
				ceD3="\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n}+WG);\n\t\tint dg = (bx${n}+tlx+WG)+(by${n}+tly)*cdimIn${n};"
				ceD3="${ceD3}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD3="if(1==1){\/\/central data (horizontal) \n\t${ceD3}\n\t}\n\t"
			fi

			# 4: Need to read data in the diagonal direction?
			if [ "${bits:0:2}" == "11" ] && [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD4="\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n}+WG);\n\t\tint dg = (bx${n}+tlx+WG)+(by${n}+tly+WG)*cdimIn${n};"
				ceD4="${ceD4}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD4="if(1==1){\/\/central data (diagonal) \n\t${ceD4}\n\t}\n\t"
			fi
			ceD="${ceD1}${ceD2}${ceD3}${ceD4}"
			# top and bottom
			# 1-top
			# 1
			tbD="\tint bbx = bx${n} + tlx;\n"
			tbD="${tbD}\t\tint bby = by${n} - R${n} + tly;\n"
			tbD="${tbD}\t\tif(bby<0) bby = 0;\n"
			tbD="${tbD}\t\tint dl = (tly) * WD${n} + (tlx+R${n});\n"
			tbD="${tbD}\t\tint dg = (bbx) + (bby) * cdimIn${n};\n"
			tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			# 2
			tbD="${tbD}\n"
			if [ "${bits:0:2}" == "11" ]; then
				tbD="${tbD}\t\tdl = (tly) * WD${n} + (tlx+R${n}+WG);\n"
				tbD="${tbD}\t\tdg = (bbx+WG) + (bby) * cdimIn${n};\n"
				tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi
			# 2-bottom
			# 1
			tbD="${tbD}\n"
			tbD="${tbD}\t\tbby = by${n} + ${offsetV} + tly;\n"
			tbD="${tbD}\t\tif(bby>=(rdimIn${n})) bby = (rdimIn${n}-1);\n"
			tbD="${tbD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx+R${n});\n"
			tbD="${tbD}\t\tdg = (bbx) + (bby) * cdimIn${n};\n"
			tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			# 2
			tbD="${tbD}\n"
			if [ "${bits:0:2}" == "11" ]; then
				tbD="${tbD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx+R${n}+WG);\n"
				tbD="${tbD}\t\tdg = (bbx+WG) + (bby) * cdimIn${n};\n"
				tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi
			tbD="if(tly<R${n}){\/\/top and bottom data \n\t${tbD}\n\t}"					
					
			# left and right (read 2 times in the vertical directions)
			# 1-left
			# 1
			lrD="\tint bbx = bx${n} + tlx - R${n};\n"
			lrD="${lrD}\t\tif(bbx<0) bbx = 0;\n"
			lrD="${lrD}\t\tint bby = by${n} + tly;\n"
			lrD="${lrD}\t\tint dl = (tly+R${n}) * WD${n} + (tlx);\n"
			lrD="${lrD}\t\tint dg = (bbx) + (bby) * cdimIn${n};\n"
			lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			lrD="${lrD}\n"
			# 2
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				lrD="${lrD}\t\tdl = (tly+R${n}+WG) * WD${n} + (tlx);\n"
				lrD="${lrD}\t\tdg = (bbx) + (bby+WG) * cdimIn${n};\n"
				lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi		

			# 2-right
			# 1
			lrD="${lrD}\n"
			lrD="${lrD}\t\tbbx = bx${n} + tlx + ${offsetH};\n"
			lrD="${lrD}\t\tif(bbx>=cdimIn${n}) bbx = (cdimIn${n} - 1);\n"
			lrD="${lrD}\t\tdl = (tly+R${n}) * WD${n} + (tlx+R${n}+${offsetH});\n"
			lrD="${lrD}\t\tdg = (bbx) + (bby) * cdimIn${n};\n"
			lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			# 2
			lrD="${lrD}\n"
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				lrD="${lrD}\t\tdl = (tly+R${n}+WG) * WD${n} + (tlx+R${n}+${offsetH});\n"
				lrD="${lrD}\t\tdg = (bbx) + (bby+WG) * cdimIn${n};\n"
				lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi
			lrD="if(tlx<R${n}){\/\/left and right data \n\t${lrD}\n\t}"					

			# corner data
			# 1: top-left
			coD="\tint bbx = bx${n} + tlx - R${n};\n"
			coD="${coD}\t\tif(bbx<0) bbx = 0;\n"
			coD="${coD}\t\tint bby = by${n} + tly - R${n};\n"
			coD="${coD}\t\tif(bby<0) bby = 0;\n"
			coD="${coD}\t\tint dl = (tly) * WD${n} + (tlx);\n"
			coD="${coD}\t\tint dg = (bbx) + (bby) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"

			# 2: top-right
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx${n} + tlx + ${offsetH};\n"
			coD="${coD}\t\tif(bbx>=cdimIn${n}) bbx = (cdimIn${n}-1);\n"
			coD="${coD}\t\tbby = by${n} + tly - R${n};\n"
			coD="${coD}\t\tif(bby<0) bby = 0;\n"
			coD="${coD}\t\tdl = (tly) * WD${n} + (tlx+R${n}+${offsetH});\n"
			coD="${coD}\t\tdg = (bbx) + (bby) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"

			# 3: bot-left
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx${n} + tlx - R${n};\n"
			coD="${coD}\t\tif(bbx<0) bbx = 0;\n"
			coD="${coD}\t\tbby = by${n} + tly + ${offsetV};\n"
			coD="${coD}\t\tif(bby>=rdimIn${n}) bby = (rdimIn${n}-1);\n"
			coD="${coD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx);\n"
			coD="${coD}\t\tdg = (bbx) + (bby) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"

			# 4: bot-right
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx${n} + tlx + ${offsetH};\n"
			coD="${coD}\t\tif(bbx>=cdimIn${n}) bbx = (cdimIn${n}-1);\n"
			coD="${coD}\t\tbby = by${n} + tly + ${offsetV};\n"
			coD="${coD}\t\tif(bby>=rdimIn${n}) bby = (rdimIn${n}-1);\n"
			coD="${coD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx+R${n}+${offsetH});\n"
			coD="${coD}\t\tdg = (bbx) + (bby) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"
			coD="if((tlx<R${n})\&\&(tly<R${n})){\/\/corner data \n\t${coD}\n\t}"
		
			gvlmLoad="${ceD}\n\t${tbD}\n\t${lrD}\n\t${coD}"
		# use
			gvlmUse="${gvlmUse}int idxW${n} = (${idxW}+R${n});\n"
			gvlmUse="${gvlmUse}\tint idxH${n} = (${idxH}+R${n});\n"
			gvlmUse="${gvlmUse}\tfor(rr=-R${n}; rr<=R${n}; rr++){\n"
			gvlmUse="${gvlmUse}\t\tfor(cc=-R${n}; cc<=R${n}; cc++){\n"
			gvlmUse="${gvlmUse}\t\t\tint idx=(idxH${n}+rr)*WD${n}+(idxW${n}+cc);\n"
			gvlmUse="${gvlmUse}\t\t\tretVal${n} += LM${n}[idx];\n"
			gvlmUse="${gvlmUse}\t\t}\n"
			gvlmUse="${gvlmUse}\t}\n"
	    ;;
		"5")	########################################################
		gvlmUse=""
		gvlmLoad=""
		# load 
			# central data
			ceD=""
			ceD1=""
			ceD2=""
			ceD3=""
			ceD4=""
			# 1:
			ceD1="\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n});\n\t\tint dg = (bx${n}+tlx+1)+(by${n}+tly+1)*cdimIn${n};"
			ceD1="${ceD1}\n\t\tLM${n}[dl] = in${n}[dg];"
			ceD1="if(1==1){\/\/central data (base) \n\t${ceD1}\n\t}\n\t"

			# 2: Need to read data in the vertical direction?
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD2="\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n});\n\t\tint dg = (bx${n}+tlx+1)+(by${n}+tly+WG+1)*cdimIn${n};"
				ceD2="${ceD2}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD2="if(1==1){\/\/central data (vertical) \n\t${ceD2}\n\t}\n\t"	
			fi					

			# 3: Need to read data in the horizontal direction?
			if [ "${bits:0:2}" == "11" ]; then # get the last two bits of eMAP
				ceD3="\tint dl = (tly+R${n}) * WD${n} + (tlx+R${n}+WG);\n\t\tint dg = (bx${n}+tlx+WG+1)+(by${n}+tly+1)*cdimIn${n};"
				ceD3="${ceD3}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD3="if(1==1){\/\/central data (horizontal) \n\t${ceD3}\n\t}\n\t"
			fi

			# 4: Need to read data in the diagonal direction?
			if [ "${bits:0:2}" == "11" ] && [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD4="\tint dl = (tly+R${n}+WG) * WD${n} + (tlx+R${n}+WG);\n\t\tint dg = (bx${n}+tlx+WG+1)+(by${n}+tly+WG+1)*cdimIn${n};"
				ceD4="${ceD4}\n\t\tLM${n}[dl] = in${n}[dg];"
				ceD4="if(1==1){\/\/central data (diagonal) \n\t${ceD4}\n\t}\n\t"
			fi
			ceD="${ceD1}${ceD2}${ceD3}${ceD4}"
			# top and bottom
			# 1-top
			# 1
			tbD="\tint bbx = bx${n} + tlx;\n"
			tbD="${tbD}\t\tint bby = by${n} - R${n} + tly;\n"
			tbD="${tbD}\t\tint dl = (tly) * WD${n} + (tlx+R${n});\n"
			tbD="${tbD}\t\tint dg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			# 2
			tbD="${tbD}\n"
			if [ "${bits:0:2}" == "11" ]; then
				tbD="${tbD}\t\tdl = (tly) * WD${n} + (tlx+R${n}+WG);\n"
				tbD="${tbD}\t\tdg = (bbx+WG+1) + (bby+1) * cdimIn${n};\n"
				tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi
			# 2-bottom
			# 1
			tbD="${tbD}\n"
			tbD="${tbD}\t\tbby = by${n} + ${offsetV} + tly;\n"
			tbD="${tbD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx+R${n});\n"
			tbD="${tbD}\t\tdg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			# 2
			tbD="${tbD}\n"
			if [ "${bits:0:2}" == "11" ]; then
				tbD="${tbD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx+R${n}+WG);\n"
				tbD="${tbD}\t\tdg = (bbx+WG+1) + (bby+1) * cdimIn${n};\n"
				tbD="${tbD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi
			tbD="if(tly<R${n}){\/\/top and bottom data \n\t${tbD}\n\t}"					
					
			# left and right (read 2 times in the vertical directions)
			# 1-left
			# 1
			lrD="\tint bbx = bx${n} + tlx - R${n};\n"
			lrD="${lrD}\t\tint bby = by${n} + tly;\n"
			lrD="${lrD}\t\tint dl = (tly+R${n}) * WD${n} + (tlx);\n"
			lrD="${lrD}\t\tint dg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			lrD="${lrD}\n"
			# 2
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				lrD="${lrD}\t\tdl = (tly+R${n}+WG) * WD${n} + (tlx);\n"
				lrD="${lrD}\t\tdg = (bbx+1) + (bby+WG+1) * cdimIn${n};\n"
				lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi		

			# 2-right
			# 1
			lrD="${lrD}\n"
			lrD="${lrD}\t\tbbx = bx${n} + tlx + ${offsetH};\n"
			lrD="${lrD}\t\tdl = (tly+R${n}) * WD${n} + (tlx+R${n}+${offsetH});\n"
			lrD="${lrD}\t\tdg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			# 2
			lrD="${lrD}\n"
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				lrD="${lrD}\t\tdl = (tly+R${n}+WG) * WD${n} + (tlx+R${n}+${offsetH});\n"
				lrD="${lrD}\t\tdg = (bbx+1) + (bby+WG+1) * cdimIn${n};\n"
				lrD="${lrD}\t\tLM${n}[dl] = in${n}[dg];\n"
			fi
			lrD="if(tlx<R${n}){\/\/left and right data \n\t${lrD}\n\t}"					

			# corner data
			# 1: top-left
			coD="\tint bbx = bx${n} + tlx - R${n};\n"
			coD="${coD}\t\tint bby = by${n} + tly - R${n};\n"
			coD="${coD}\t\tint dl = (tly) * WD${n} + (tlx);\n"
			coD="${coD}\t\tint dg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"

			# 2: top-right
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx${n} + tlx + ${offsetH};\n"
			coD="${coD}\t\tbby = by${n} + tly - R${n};\n"
			coD="${coD}\t\tdl = (tly) * WD${n} + (tlx+R${n}+${offsetH});\n"
			coD="${coD}\t\tdg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"

			# 3: bot-left
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx${n} + tlx - R${n};\n"
			coD="${coD}\t\tbby = by${n} + tly + ${offsetV};\n"
			coD="${coD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx);\n"
			coD="${coD}\t\tdg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"

			# 4: bot-right
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx${n} + tlx + ${offsetH};\n"
			coD="${coD}\t\tbby = by${n} + tly + ${offsetV};\n"
			coD="${coD}\t\tdl = (tly+R${n}+${offsetV}) * WD${n} + (tlx+R${n}+${offsetH});\n"
			coD="${coD}\t\tdg = (bbx+1) + (bby+1) * cdimIn${n};\n"
			coD="${coD}\t\tLM${n}[dl] = in${n}[dg];\n"
			coD="if((tlx<R${n})\&\&(tly<R${n})){\/\/corner data \n\t${coD}\n\t}"
		
			gvlmLoad="${ceD}\n\t${tbD}\n\t${lrD}\n\t${coD}"
		# use
			gvlmUse="int idxW${n} = (${idxW}+R${n});\n"
			gvlmUse="${gvlmUse}\tint idxH${n} = (${idxH}+R${n});\n"
			gvlmUse="${gvlmUse}\tretVal${n} = LM${n}[(idxH${n}-1)*WD${n}+(idxW${n})]+LM${n}[(idxH${n})*WD${n}+(idxW${n}-1)]+LM${n}[(idxH${n})*WD${n}+(idxW${n})]+LM${n}[(idxH${n})*WD${n}+(idxW${n}+1)]+LM${n}[(idxH${n}+1)*WD${n}+(idxW${n})];\n"
	    ;;
		*)	########################################################		
	    ;;
	esac	
}


# given an MAP, choose to use global memory or local memory
gvloadANDuse=""
GetloadANDuse()
{
	# parameter 1: n- the current MAP
	# parameter 2: m- the maximum number of MAP that needs local memory
	# parameter 3: iMAP- dispatch to different iMAP template
	# parameter 4: eMAP- 
	n=$1 
	m=$2
	iibits=$3
	eebits=$4

	lcloadANDuse=""	

	# get index base??
	idxW="" # x coodinate
	case "${eebits:0:2}" in
		"00")  
		    idxW="0"
		    ;;
		"10") 
		    idxW="tgx"
		    ;;
		"01") 
		    idxW="tgy"
		    ;;
		"11") 
		    idxW="tgy+tgx"
		    ;;
		*)
		    idxW=""
		    ;;
	esac

	idxH="" # y coordinate
	case "${eebits:2:2}" in
		"00")  
		    idxH="0"
		    ;;
		"10") 
		    idxH="tgx"
		    ;;
		"01") 
		    idxH="tgy"
		    ;;
		"11") 
		    idxH="tgy+tgx"
		    ;;
		*)
		    idxH=""
		    ;;
	esac

	# replacement
	# 1: global or local
	if [[ ${n} -lt ${m} ]]; then
		# local memory use
		# ----------------------------------------------------------------------
		GetLCLMem ${n} ${m} ${iibits} ${eebits}	
		strBarrier="barrier(CLK_LOCAL_MEM_FENCE);"
		case "${iibits}" in
			"1")  				
			lcloadANDuse="${lcloadANDuse}${gvlmLoad}\n"
			lcloadANDuse="${lcloadANDuse}\t${strBarrier}\n"
			lcloadANDuse="${lcloadANDuse}\t${gvlmUse}\n"
			;;
			"2")
			lcloadANDuse="for(cc=0; cc<cdim; cc=cc+WD${n}){\n"
			lcloadANDuse="${lcloadANDuse}\t\t${gvlmLoad}\n"
			lcloadANDuse="${lcloadANDuse}\t\t${strBarrier}\n"
			lcloadANDuse="${lcloadANDuse}\t\t${gvlmUse}\n"
			lcloadANDuse="${lcloadANDuse}\t\t${strBarrier}\n"
			lcloadANDuse="${lcloadANDuse}\t}\n"						
			;;
			"3")  
			lcloadANDuse="for(rr=0; rr<rdim; rr=rr+HT${n}){\n"
			lcloadANDuse="${lcloadANDuse}\t\t${gvlmLoad}\n"
			lcloadANDuse="${lcloadANDuse}\t\t${strBarrier}\n"
			lcloadANDuse="${lcloadANDuse}\t\t${gvlmUse}\n"
			lcloadANDuse="${lcloadANDuse}\t\t${strBarrier}\n"
			lcloadANDuse="${lcloadANDuse}\t}\n"				
			;;
			"4")
			lcloadANDuse="${lcloadANDuse}${gvlmLoad}\n"
			lcloadANDuse="${lcloadANDuse}\t${strBarrier}\n"
			lcloadANDuse="${lcloadANDuse}\t${gvlmUse}\n"
			;;
			"5")  				
			lcloadANDuse="${lcloadANDuse}${gvlmLoad}\n"
			lcloadANDuse="${lcloadANDuse}\t${strBarrier}\n"
			lcloadANDuse="${lcloadANDuse}\t${gvlmUse}\n"
			;;
			*)
			;;
		esac
	else
		# global memory use
		# ----------------------------------------------------------------------
		case "${iibits}" in
			"1")  				
				gmUse="int gmIdx${n}=(${idxH})*cdimIn${n}+(${idxW});\n\t"			
				gmUse="${gmUse}retVal${n}+=in${n}[gmIdx${n}];"
				lcloadANDuse="${gmUse}"
			    ;;
			"2") 
				gmUse="\t"
				gmUse="${gmUse}retVal${n}+=in${n}[gmIdx${n}+cc];\n\t"
				gmUse="int gmIdx${n}=(${idxH})*cdimIn${n}+(${idxW});\n\tfor(cc=0; cc<cdim; cc=cc+1){\n\t${gmUse}}"
				lcloadANDuse="${gmUse}"
			    ;;
			"3") 
				gmUse=""			
				gmUse="${gmUse}retVal${n}+=in${n}[gmIdx${n}+rr*cdimIn${n}];\n\t"
				gmUse="int gmIdx${n}=(${idxH})*cdimIn${n}+(${idxW});\n\tfor(rr=0; rr<rdim; rr=rr+1){\n\t\t${gmUse}}"
				lcloadANDuse="${gmUse}"
			    ;;
			"4") 
				idx="int idxW${n}=${idxW};\n\tint idxH${n}=${idxH};\n"
				gmUse="${idx}\tfor(rr=-R${n}; rr<=R${n}; rr++){\n"
				gmUse="${gmUse}\t\tfor(cc=-R${n}; cc<=R${n}; cc++){\n"
				gmUse="${gmUse}\t\t\tint hh=idxH${n}+rr;\n"
				gmUse="${gmUse}\t\t\tif(hh<0) hh=0;\n"
				gmUse="${gmUse}\t\t\tif(hh>=rdimIn${n}) hh=(rdimIn${n}-1);\n"
				gmUse="${gmUse}\t\t\tint ww=idxW${n}+cc;\n"
				gmUse="${gmUse}\t\t\tif(ww<0) ww=0;\n"
				gmUse="${gmUse}\t\t\tif(ww>=cdimIn${n}) ww=(cdimIn${n}-1);\n"
				gmUse="${gmUse}\t\t\tint idx=(hh)*cdimIn${n}+(ww);\n"
				gmUse="${gmUse}\t\t\tretVal${n}+=in${n}[idx];\n"
				gmUse="${gmUse}\t\t}\n"
				gmUse="${gmUse}\t}\n"
				lcloadANDuse="${gmUse}"
			    ;;
			"5") 
				idxW="int idxW${n}=(${idxW}+R${n});"
				idxH="int idxH${n}=(${idxH}+R${n});"	
				idx="${idxW}\n\t${idxH}\n"
				gmUse="${idx}"
				gmUse="${gmUse}\tretVal${n}=in${n}[(idxH${n}-1)*cdimIn${n}+(idxW${n})]+in${n}[(idxH${n})*cdimIn${n}+(idxW${n}-1)]+in${n}[(idxH${n})*cdimIn${n}+(idxW${n})]+in${n}[(idxH${n})*cdimIn${n}+(idxW${n}+1)]+in${n}[(idxH${n}+1)*cdimIn${n}+(idxW${n})];\n"
				lcloadANDuse="${gmUse}"
			    ;;
			*)
			lcloadANDuse="6global${n}"
			    ;;
		esac
	fi

	# the content is stored in a temporal file e.g., loadANDuse.cl
	gvloadANDuse="${lcloadANDuse}"

}

# ------------------------------------------------------------------
# 			start execution 
# ------------------------------------------------------------------
rm ${report}
echo -en "   \tvv0\tvv1\tvv2\tvv3\tvv4\n" >> ${report}

# let us start with 2 MAPs
for m1 in {0..32..1}; do
for m2 in {0..32..1}; do	# for each combination

	# check dir exist
	mmDirName="${map[${m1}]}_${map[${m2}]}"
	if [ ! -d ${mmDirName} ]; then	
		mkdir ${mmDirName}
	fi
	
	# global vars
	mp=(${map[$m1]} ${map[$m2]}) # e.g., (107, 512)
	echo "map1: ${mp[0]}, map2: ${mp[1]}"

	for (( nn=0; nn<${N}; nn++ ))
	  do
		idxE=${mp[${nn}]:1:2}
		idxI=${mp[${nn}]:0:1}
		if [ ${idxE:0:1} -eq '0' ]; then
			idxE="${idxE:1:1}"
		fi
		ebits[${nn}]=${eMAP[${idxE}-1]}
		ibits[${nn}]=${iMAP[${idxI}-1]}
	  done

	echo "${ebits[0]}, ${ebits[1]}, ${ibits[0]}, ${ibits[1]}"


	# use local memory one-by-one (M=2, see above)
	for (( m=0; m<${M}+1; m++ )); do
		# check dir exist
		subDirName="./${mmDirName}/v${m}"
		if [ ! -d ${subDirName} ]; then	
			mkdir ${subDirName}
		fi
		# generate host (main)		
		# ---------------------------------------------------
		# @argOMP
		argOMP=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    argOMP="${argOMP} const float * in${nn},"
		  done
		argOMP="${argOMP%?}"
		if [ -f ${subDirName}/${host} ]; then	# check file exist
			rm ${subDirName}/${host}
		fi
		cat ${hostT} | sed "s/@argOMP/${argOMP}/g" > ${subDirName}/${host}

		# @argOCL
		argOCL=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    argOCL="${argOCL} cl_mem dIn${nn},"
		  done
		argOCL="${argOCL%?}"
		cat ${subDirName}/${host} | sed "s/@argOCL/${argOCL}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @argcdimIn
		argcdimIn=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    argcdimIn="${argcdimIn} int cdimIn${nn},"
		  done
		argcdimIn="${argcdimIn%?}"
		cat ${subDirName}/${host} | sed "s/@argcdimIn/${argcdimIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @argrdimIn
		argrdimIn=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    argrdimIn="${argrdimIn} int rdimIn${nn},"
		  done
		argrdimIn="${argrdimIn%?}"
		cat ${subDirName}/${host} | sed "s/@argrdimIn/${argrdimIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}


		# @hIn
		hIn="float "
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    hIn="${hIn} *hIn${nn},"
		  done
		hIn="${hIn%?}"
		cat ${subDirName}/${host} | sed "s/@hIn/${hIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @dIn
		dIn="cl_mem "
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    dIn="${dIn} dIn${nn},"
		  done
		dIn="${dIn%?}"
		cat ${subDirName}/${host} | sed "s/@dIn/${dIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}
	
		# @cdimIn
		cdimIn=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
			FunCDIM ${ibits[${nn}]} ${ebits[${nn}]}
			cdimIn="${cdimIn}int cdimIn${nn}=${gvCDimIn};\n\t"
		  done
		cat ${subDirName}/${host} | sed "s/@cdimIn/${cdimIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @rdimIn
		rdimIn=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
			FunRDIM ${ibits[${nn}]} ${ebits[${nn}]}
			rdimIn="${rdimIn}int rdimIn${nn}=${gvRDimIn};\n\t"
		  done			
		cat ${subDirName}/${host} | sed "s/@rdimIn/${rdimIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @elems
		elems=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
			GetElem ${ibits[${nn}]}
			elems="${elems}${gvElem}+"
		  done
		elems="${elems%?}"
		cat ${subDirName}/${host} | sed "s/@elems/${elems}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @hInAlc
		hAlc=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    hAlc="${hAlc}hIn${nn} = (float *)malloc(cdimIn${nn} * rdimIn${nn} * sizeof(float));\n\t"
		  done
		cat ${subDirName}/${host} | sed "s/@hAlc/${hAlc}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}
			
		# @hFill
		hFill=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    hFill="${hFill}fill<float>(hIn${nn}, cdimIn${nn} * rdimIn${nn}, 5);\n\t"
		  done
		cat ${subDirName}/${host} | sed "s/@hFill/${hFill}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @dAlc
		dAlc=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    dAlc="${dAlc}dIn${nn} = _clMalloc(cdimIn${nn} * rdimIn${nn} * sizeof(float));\n\t"
		  done

		cat ${subDirName}/${host} | sed "s/@dAlc/${dAlc}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}
			
		# @h2dTrans
		h2dTrans=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    h2dTrans="${h2dTrans}_clMemcpyH2D(dIn${nn}, hIn${nn}, cdimIn${nn} * rdimIn${nn} * sizeof(float));\n\t"
		  done

		cat ${subDirName}/${host} | sed "s/@h2dTrans/${h2dTrans}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}
			
		# @oclArgs
		oclArgs=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    oclArgs="${oclArgs}dIn${nn}, "
		  done
		oclArgs="${oclArgs%?}"
		oclArgs="${oclArgs%?}"
		cat ${subDirName}/${host} | sed "s/@oclArgs/${oclArgs}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}


		# @oclcdimIn
		oclcdimIn=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    oclcdimIn="${oclcdimIn}cdimIn${nn}, "
		  done
		oclcdimIn="${oclcdimIn%?}"
		oclcdimIn="${oclcdimIn%?}"
		cat ${subDirName}/${host} | sed "s/@oclcdimIn/${oclcdimIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @oclrdimIn
		oclrdimIn=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    oclrdimIn="${oclrdimIn}rdimIn${nn}, "
		  done
		oclrdimIn="${oclrdimIn%?}"
		oclrdimIn="${oclrdimIn%?}"
		cat ${subDirName}/${host} | sed "s/@oclrdimIn/${oclrdimIn}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}


		# @ompArgs
		ompArgs=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    ompArgs="${ompArgs}hIn${nn}, "
		  done
		ompArgs="${ompArgs%?}"
		ompArgs="${ompArgs%?}"
		cat ${subDirName}/${host} | sed "s/@ompArgs/${ompArgs}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @clFree
		clFree=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    clFree="${clFree}_clFree(dIn${nn});\n\t"
		  done
		clFree="${clFree%?}"
		clFree="${clFree%?}"
		cat ${subDirName}/${host} | sed "s/@clFree/${clFree}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}
			
		# @hFree
		hFree=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    hFree="${hFree}if(hIn${nn}!=NULL) free(hIn${nn});\n\t"
		  done
		hFree="${hFree%?}"
		hFree="${hFree%?}"
		cat ${subDirName}/${host} | sed "s/@hFree/${hFree}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @ompVal
		ompVal=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    GetOmpVal ${ibits[${nn}]} ${ebits[${nn}]} ${nn}
		    ompVal="${ompVal}${gvOmpVal}\n\n\t\t\t"
		  done
		cat ${subDirName}/${host} | sed "s/@ompVal/${ompVal}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @ompSum
		ompSum="val+="
		for (( nn=0; nn<${N}; nn++ ))
		  do		    
		    ompSum="${ompSum}val${nn}+"
		  done
		ompSum="${ompSum%?};"
		cat ${subDirName}/${host} | sed "s/@ompSum/${ompSum}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @clSetArgs
		clSetArgs=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    clSetArgs="${clSetArgs}_clSetArgs(kernel_id, arg_idx++, dIn${nn});\n\t"
		  done
		clSetArgs="${clSetArgs%?}"
		clSetArgs="${clSetArgs%?}"
		cat ${subDirName}/${host} | sed "s/@clSetArgs/${clSetArgs}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# @clSetDims
		clSetDims=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    clSetDims="${clSetDims}_clSetArgs(kernel_id, arg_idx++, \&cdimIn${nn}, sizeof(int));\n\t"
		    clSetDims="${clSetDims}_clSetArgs(kernel_id, arg_idx++, \&rdimIn${nn}, sizeof(int));\n\t"
		  done
		clSetDims="${clSetDims%?}"
		clSetDims="${clSetDims%?}"
		cat ${subDirName}/${host} | sed "s/@clSetDims/${clSetDims}/g" > ./tmp
		cat ./tmp > ${subDirName}/${host}

		# generate kernel (kernels.cl)
		# ---------------------------------------------------
		# @radius
		radius=""
		for (( nn=0; nn<${N}; nn++ ))
		  do		    
		    radius="${radius}#define R${nn} ${R[${ibits[$nn]}-1]}\n"
		    rad[${nn}]="${R[${ibits[$nn]}-1]}"
		  done
		radius="${radius%?}"
		radius="${radius%?}"
		cat ${kernelT} | sed "s/@radius/${radius}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @WD
		WD=""
		wd=""
		for (( nn=0; nn<${N}; nn++ ))
		  do		    
			if [ ${ebits[${nn}]:0:2} -eq '11' ]; then # 11
				LMWD="WG*2"				
				lmwd[${nn}]="${WG}*2"
			else
				LMWD="WG"
				lmwd[${nn}]="${WG}"
			fi
			WD="${WD}#define WD${nn} (${LMWD}+2*R${nn})\n"
			wd[${nn}]="(${lmwd[$nn]}+2*${rad[$nn]})"
		  done
		WD="${WD%?}"
		WD="${WD%?}"
		cat ${subDirName}/${kernel} | sed "s/@WD/${WD}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @HT
		HT=""
		ht=""
		for (( nn=0; nn<${N}; nn++ ))
		  do		    
			if [ ${ebits[${nn}]:2:2} -eq '11' ]; then # 11
				LMHT="WG*2"				
				lmht[${nn}]="${WG}*2"
			else
				LMHT="WG"
				lmht[${nn}]="${WG}"
			fi
			HT="${HT}#define HT${nn} (${LMHT}+2*R${nn})\n"
			ht[${nn}]="(${lmht[$nn]}+2*${rad[$nn]})"
		  done
		HT="${HT%?}"
		HT="${HT%?}"
		cat ${subDirName}/${kernel} | sed "s/@HT/${HT}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @inArgs
		inArgs=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    inArgs="${inArgs}const __global float *in${nn}, "
		  done
		inArgs="${inArgs%?}"
		inArgs="${inArgs%?}"
		cat ${subDirName}/${kernel} | sed "s/@inArgs/${inArgs}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @inPairs
		inPairs=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    inPairs="${inPairs}const int cdimIn${nn}, "
		    inPairs="${inPairs}const int rdimIn${nn}, "
		  done
		inPairs="${inPairs%?}"
		inPairs="${inPairs%?}"
		cat ${subDirName}/${kernel} | sed "s/@inPairs/${inPairs}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @bxy information (TODO: mark)
		bxy=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
			GetBXY ${ebits[${nn}]} ${nn}
			bxy="${bxy}${gvBXY}\n\t"
		  done
		cat ${subDirName}/${kernel} | sed "s/@bxy/${bxy}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @lmAlc (m: the number of data structures that require local memory)
		lmAlc=""
		for (( mm=0; mm<${m}; mm++ ))
		  do
		    lmAlc="${lmAlc}__local float LM${mm}[WD${mm}*HT${mm}];\n\t"
		  done
		lmAlc="${lmAlc%?}"
		lmAlc="${lmAlc%?}"
		cat ${subDirName}/${kernel} | sed "s/@lmAlc/${lmAlc}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @varDec
		varDec=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    varDec="${varDec}float retVal${nn} = 0.0f;\n\t"
		  done
		varDec="${varDec%?}"
		varDec="${varDec%?}"
		cat ${subDirName}/${kernel} | sed "s/@varDec/${varDec}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

		# @loadANDuse
		loadANDuse=""
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    GetloadANDuse ${nn} ${m} ${ibits[${nn}]} ${ebits[${nn}]} 
		    loadANDuse="${loadANDuse}${gvloadANDuse}\n\t"
		  done
		cat ${subDirName}/${kernel} | sed "s/@loadANDuse/${loadANDuse}/g" > ./tmp
		cat ./tmp  > ${subDirName}/${kernel}		
		#cat ${subDirName}/${kernel} | sed -e "s/@loadANDuse/`cat ./loadANDuse.cl`/g" > ./tmp
		#cat ${subDirName}/${kernel} | sed "s/@loadANDuse/`read -r  < loadANDuse.cl`/g" > ./tmp
		#line=`cat ${subDirName}/${kernel} |  sed -n '/@loadANDuse/{=;p;}' | head -1`
		#cat ${subDirName}/${kernel} | sed -e "${line}r loadANDuse.cl"  > ./tmp
		#cat ./tmp | sed "${line}d" > ${subDirName}/${kernel}		

		# @lmOut
		lmOut=""			
		for (( nn=0; nn<${N}; nn++ ))
		  do
		    lmOut="${lmOut}retVal${nn}+"
		  done
		lmOut="${lmOut%?}"
		cat ${subDirName}/${kernel} | sed "s/@lmOut/${lmOut}/g" > ./tmp
		cat ./tmp > ${subDirName}/${kernel}

			# copy makefile, runfile, helperfile, macro.h, config, 
			# ---------------------------------------------------
		cp ./template/Makefile ./${subDirName}/
		cp ./template/macro.h ./${subDirName}/
		cp ./template/kernel.config ./${subDirName}/
		cp ./template/run ./${subDirName}/
		cp ./template/CLHelper.h ./${subDirName}/
		cp ./template/util.h ./${subDirName}/

	done # end for using local memory one-by-one

	# 
done
done

# ------------------------------------------------------------------
# 			end execution 
# ------------------------------------------------------------------
