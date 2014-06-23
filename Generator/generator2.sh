#!/bin/sh

map=(107 108 109 110 112 113 114 115 116 204 205 211 302 303 306 401 407 408 409 410 412 413 414 415 416 507 508 509 510 512 513 514 515 516)
eMAP=(0000 1000 0100 0010 0001 1100 1010 1001 0101 0110 0011 0111 1011 1101 1110 1111) 
iMAP=("1" "cdim" "rdim" "(2*R+1)*(2*R+1)" "5")
R=(0 0 0 3 1)
WG=16
M=1	# M is maximum maps that is using local space (thus M<=N). 
N=1	# N is used to control the maximum of maps (input data structures)
host='main.cpp'
hostT='./template/main.cpp'
kernel='kernels.cl'
kernelT='./template/kernels2.cl'
report='lmReport.txt'
# ------------------------------------------------------------------
# 			start execution 
# ------------------------------------------------------------------
for index in {9..11..1}; do # for each map

	mp=${map[$index]}
	echo "map: ${mp}"
	echo -en "${mp}\t" >> ${report}
	if [ ! -d ${mp} ]; then
		mkdir ./${mp}	
	fi	
	# calculate the maximum number of data structures (let us assume 4 for now)
	for (( n=${N}; n<${N}+1; n++ ))
		do
		odirName=./${mp}/v${n}
		if [ ! -d ${odirName} ]; then	# check dir exist
			mkdir ${odirName}	
		fi

		# perform local memory usage on m (of N MAPs) 
		# m=0 means that we do not use local space		
		for (( m=0; m<${n}+1; m++ ))	
		  do
			dirName=${odirName}/vv${m}
			if [ ! -d ${dirName} ]; then	# check dir exist
				mkdir ${dirName}	
			fi	
			# generate host (main)		
			# ---------------------------------------------------
			# get the four bits of a eMAP
			idx=${mp:1:2}
			if [ ${idx:0:1} -eq '0' ]; then
				idx="${idx:1:1}"
			fi
			bits=${eMAP[${idx}-1]}

			# @argOMP
			argOMP=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    argOMP="${argOMP} const float * in${nn},"
			  done
			argOMP="${argOMP%?}"
			if [ -f ${dirName}/${host} ]; then	# check file exist
				rm ${dirName}/${host}
			fi
			cat ${hostT} | sed "s/@argOMP/${argOMP}/g" > ${dirName}/${host}

			# @argOCL
			argOCL=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    argOCL="${argOCL} cl_mem dIn${nn},"
			  done
			argOCL="${argOCL%?}"
			cat ${dirName}/${host} | sed "s/@argOCL/${argOCL}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @hIn
			hIn="float "
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    hIn="${hIn} *hIn${nn},"
			  done
			hIn="${hIn%?}"
			cat ${dirName}/${host} | sed "s/@hIn/${hIn}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @dIn
			dIn="cl_mem "
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    dIn="${dIn} dIn${nn},"
			  done
			dIn="${dIn%?}"
			cat ${dirName}/${host} | sed "s/@dIn/${dIn}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @cdimIn (TODO: mark)
			cdimIn="int cdimIn=cdim;"
			# idxW="(${bits:0:1}*cdim)+(${bits:1:1}*rdim)"
			# cdimIn="${cdimIn} ${idxW};"
			cat ${dirName}/${host} | sed "s/@cdimIn/${cdimIn}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @rdimIn (TODO: mark)
			rdimIn="int rdimIn="
			idxH="(${bits:2:1}*cdim)+(${bits:3:1}*rdim)"
			rdimIn="${rdimIn} ${idxH};"
			cat ${dirName}/${host} | sed "s/@rdimIn/${rdimIn}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @elems
			elems=1+${iMAP[${mp:0:1}-1]}*${nn}
			cat ${dirName}/${host} | sed "s/@elems/${elems}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @hInAlc
			hAlc=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    hAlc="${hAlc}hIn${nn} = (float *)malloc(cdimIn * rdimIn * sizeof(float));\n\t"
			  done
			#dIn="${dIn%?}"
			cat ${dirName}/${host} | sed "s/@hAlc/${hAlc}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}
			
			# @hFill
			hFill=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    hFill="${hFill}fill<float>(hIn${nn}, cdimIn * rdimIn, 5);\n\t"
			  done

			cat ${dirName}/${host} | sed "s/@hFill/${hFill}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @dAlc
			dAlc=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    dAlc="${dAlc}dIn${nn} = _clMalloc(cdimIn * rdimIn * sizeof(float));\n\t"
			  done

			cat ${dirName}/${host} | sed "s/@dAlc/${dAlc}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}
			
			# @h2dTrans
			h2dTrans=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    h2dTrans="${h2dTrans}_clMemcpyH2D(dIn${nn}, hIn${nn}, cdimIn * rdimIn * sizeof(float));\n\t"
			  done

			cat ${dirName}/${host} | sed "s/@h2dTrans/${h2dTrans}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}
			
			# @oclArgs
			oclArgs=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    oclArgs="${oclArgs}dIn${nn}, "
			  done
			oclArgs="${oclArgs%?}"
			oclArgs="${oclArgs%?}"
			cat ${dirName}/${host} | sed "s/@oclArgs/${oclArgs}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @ompArgs
			ompArgs=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    ompArgs="${ompArgs}hIn${nn}, "
			  done
			ompArgs="${ompArgs%?}"
			ompArgs="${ompArgs%?}"
			cat ${dirName}/${host} | sed "s/@ompArgs/${ompArgs}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @clFree
			clFree=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    clFree="${clFree}_clFree(dIn${nn});\n\t"
			  done
			clFree="${clFree%?}"
			clFree="${clFree%?}"
			cat ${dirName}/${host} | sed "s/@clFree/${clFree}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}
			
			# @hFree
			hFree=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    hFree="${hFree}if(hIn${nn}!=NULL) free(hIn${nn});\n\t"
			  done
			hFree="${hFree%?}"
			hFree="${hFree%?}"
			cat ${dirName}/${host} | sed "s/@hFree/${hFree}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}
			
			# @xIn
			# TODO: mark (with kernel file)
			xIn=""
			idxW="" # x coodinate
			case "${bits:0:2}" in
				"00")  
				    idxW="0"
				    ;;
				"10") 
				    idxW="c"
				    ;;
				"01") 
				    idxW="r"
				    ;;
				"11") 
				    idxW="r+c"
				    ;;
				*)
				    idxW=""
				    ;;
			esac

			idxH="" # y coordinate
			case "${bits:2:2}" in
				"00")  
				    idxH="0"
				    ;;
				"10") 
				    idxH="c"
				    ;;
				"01") 
				    idxH="r"
				    ;;
				"11") 
				    idxH="r+c"
				    ;;
				*)
				    idxH=""
				    ;;
			esac

			xIn="(${idxH})*cdimIn"
			cat ${dirName}/${host} | sed "s/@xIn/${xIn}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @inData: in1[xIn] + in2[xIn] (TODO: mark)
			inData="for(int cc=0; cc<cdim; cc++)\n\t\t\t{\n\t\t\t\tval+="
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    inData="${inData}in${nn}[xIn+cc]+"
			  done
			inData="${inData%?};\n\t\t\t}"
			cat ${dirName}/${host} | sed "s/@inData/${inData}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}
			
			# @clSetArgs
			clSetArgs=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    clSetArgs="${clSetArgs}_clSetArgs(kernel_id, arg_idx++, dIn${nn});\n\t"
			  done
			clSetArgs="${clSetArgs%?}"
			clSetArgs="${clSetArgs%?}"
			cat ${dirName}/${host} | sed "s/@clSetArgs/${clSetArgs}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# generate kernel (kernels.cl) (based on m)
			# ---------------------------------------------------
			# @radius
			radius=${R[${mp:0:1}-1]}
			rad=${R[${mp:0:1}-1]}
			radius="#define R ${radius}"
			cat ${kernelT} | sed "s/@radius/${radius}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @WD
			WD=""
			wd=""
			idx=${mp:1:2}
			if [ ${idx:0:1} -eq '0' ]; then
				idx="${idx:1:1}"
			fi
			#bits=${eMAP[${idx}-1]}	# xxxx
			#bits=${bits:0:2}	# the first two bits
			if [ ${bits:0:2} -eq '11' ]; then # 11
				WD="WG*2"
				wd="${WG}*2"
			else
				WD="WG"
				wd="${WG}"
			fi
			WD="#define WD (${WD}+2*R)"
			wd="(${wd}+2*${rad})"
			cat ${dirName}/${kernel} | sed "s/@WD/${WD}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @HT
			HT=""
			ht=""
			#bits=${eMAP[${idx}-1]}	# xxxx
			#bits=${bits:2:2}	# the first two bits
			if [ ${bits:2:2} -eq '11' ]; then # 11
				HT="WG*2"
				ht="${WG}*2"
			else
				HT="WG"
				ht="${WG}"
			fi
			HT="#define HT (${HT}+2*R)"
			ht="(${ht}+2*${rad})"			
			cat ${dirName}/${kernel} | sed "s/@HT/${HT}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# write code generation report		
			echo -en "$((4*${wd}*${ht}*${m}/1024))\t" >> ${report}

			# @inArgs
			inArgs=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    inArgs="${inArgs}const __global float *in${nn}, "
			  done
			inArgs="${inArgs%?}"
			inArgs="${inArgs%?}"
			cat ${dirName}/${kernel} | sed "s/@inArgs/${inArgs}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}
		
			# @lmAlc (m)
			lmAlc=""
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    lmAlc="${lmAlc}__local float LM${mm}[WD*HT];\n\t"
			  done
			lmAlc="${lmAlc%?}"
			lmAlc="${lmAlc%?}"
			cat ${dirName}/${kernel} | sed "s/@lmAlc/${lmAlc}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @varDec
			varDec=""
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    varDec="${varDec}float retVal${nn} = 0.0f;\n\t"
			  done
			varDec="${varDec%?}"
			varDec="${varDec%?}"
			cat ${dirName}/${kernel} | sed "s/@varDec/${varDec}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @bxy information (TODO: mark)
			bxy=""
			bx="" # x coodinate
			#bits=${eMAP[${idx}-1]}
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
			bx="int bx=${bx}*WG;"
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
			by="int by=${by}*WG;"
			bxy="${bx}\n\t${by}"
			cat ${dirName}/${kernel} | sed "s/@bxy/${bxy}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}
	
			# @lmLoad (use different loading strategies for different eMAPs)
			# TODO: mark
			lmLoad=""			
			# assume that R<=WG (otherwise, the code refuses working:)
			offsetV="WG"	# WG or 2xWG
			if [ "${bits:2:2}" == "11" ]; then
				offsetV="2*WG"
			fi
			offsetH="WG"	# WG or 2xWG
			if [ "${bits:0:2}" == "11" ]; then
				offsetH="2*WG"
			fi
			# central data
			ceD=""
			ceD1=""
			ceD2=""
			ceD3=""
			ceD4=""
			# 1:
			ceD1="\t\tint dl = (tly+R) * WD + (tlx+R);\n\t\t\tint dg = (bx+tlx+cc)+(by+tly)*cdimIn;"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    ceD1="${ceD1}\n\t\t\tLM${mm}[dl] = in${mm}[dg];"
			  done
			ceD1="if(1==1){\/\/central data (base) \n\t${ceD1}\n\t\t}\n\t"

			# 2: Need to read data in the vertical direction?
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD2="\t\tint dl = (tly+R+WG) * WD + (tlx+R);\n\t\t\tint dg = (bx+tlx+cc)+(by+tly+WG)*cdimIn;"
				for (( mm=0; mm<${m}; mm++ ))
				  do
				    ceD2="${ceD2}\n\t\t\tLM${mm}[dl] = in${mm}[dg];"
				  done
				ceD2="\tif(1==1){\/\/central data (vertical) \n\t${ceD2}\n\t\t}\n\t"	
			fi					

			# 3: Need to read data in the horizontal direction?
			if [ "${bits:0:2}" == "11" ]; then # get the last two bits of eMAP
				ceD3="\t\tint dl = (tly+R) * WD + (tlx+R+WG);\n\t\t\tint dg = (bx+tlx+WG+cc)+(by+tly)*cdimIn;"
				for (( mm=0; mm<${m}; mm++ ))
				  do
				    ceD3="${ceD3}\n\t\\ttLM${mm}[dl] = in${mm}[dg];"
				  done
				ceD3="\tif(1==1){\/\/central data (horizontal) \n\t${ceD3}\n\t\t}\n\t"
			fi

			# 4: Need to read data in the diagonal direction?
			if [ "${bits:0:2}" == "11" ] && [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD4="\t\tint dl = (tly+R+WG) * WD + (tlx+R+WG);\n\t\t\tint dg = (bx+tlx+WG+cc)+(by+tly+WG)*cdimIn;"
				for (( mm=0; mm<${m}; mm++ ))
				  do
				    ceD4="${ceD4}\n\t\t\tLM${mm}[dl] = in${mm}[dg];"
				  done
				ceD4="\tif(1==1){\/\/central data (diagonal) \n\t${ceD4}\n\t\t}\n\t"
			fi
			ceD="${ceD1}${ceD2}${ceD3}${ceD4}"
			lmLoad="${ceD}"

			cat ${dirName}/${kernel} | sed "s/@lmLoad/${lmLoad}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}


			# @lmUse (TODO: mark)
			lmUse=""
			#bits=${eMAP[${idx}-1]}	# xxxx
			idxW=""
			case "${bits:0:2}" in
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
			case "${bits:2:2}" in
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
			lmUse="int useIdx=(${idxH})*WD;"
			lmUse="${lmUse}\n\t\tfor(ll=0; ll<WD; ll++)\n\t\t{"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    lmUse="${lmUse}\n\t\t\tretVal${mm} += LM${mm}[useIdx+ll];"
			  done
			lmUse="${lmUse}\n\t\t}"
			#lmUse="${lmUse%?}"
			cat ${dirName}/${kernel} | sed "s/@lmUse/${lmUse}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @gmUse
			# TODO: mark global load (n-m)
			idxW="" # x coodinate
			case "${bits:0:2}" in
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
			case "${bits:2:2}" in
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
			gmUse="\n\t\t"			
			for (( mm=${m}; mm<${n}; mm++ ))
			  do
				# do some work here
				gmUse="${gmUse}retVal${mm}+=in${mm}[gmIdx+cc];\n\t\t"
			  done
			gmUse="${gmUse%?}"
			gmUse="${gmUse%?}"
			gmUse="int gmIdx=(${idxH})*cdimIn+(${idxW});\n\tfor(cc=0; cc<cdim; cc=cc+1){\n\t\t${gmUse}}"
			cat ${dirName}/${kernel} | sed "s/@gmUse/${gmUse}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @lmOut
			lmOut=""			
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    lmOut="${lmOut}retVal${nn}+"
			  done
			lmOut="${lmOut%?}"
			cat ${dirName}/${kernel} | sed "s/@lmOut/${lmOut}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# copy makefile, runfile, helperfile, macro.h, config, 
			# ---------------------------------------------------
			cp ./template/Makefile ./${dirName}/
			cp ./template/macro.h ./${dirName}/
			cp ./template/kernel.config ./${dirName}/
			cp ./template/run ./${dirName}/
			cp ./template/CLHelper.h ./${dirName}/
			cp ./template/util.h ./${dirName}/
	
		  done

		done
	echo -en "\n" >> ${report}
done	# end for each map

# ------------------------------------------------------------------
# 			end execution 
# ------------------------------------------------------------------


