#!/bin/sh

map=(107 108 109 110 112 113 114 115 116 204 205 211 302 303 306 401 407 408 409 410 412 413 414 415 416 507 508 509 510 512 513 514 515 516)
eMAP=(0000 1000 0100 0010 0001 1100 1010 1001 0101 0110 0011 0111 1011 1101 1110 1111) 
iMAP=("1" "cdim" "rdim" "(2*R+1)*(2*R+1)" "5")
R=(0 0 0 3 1)
WG=16
M=4	# M is maximum maps that is using local space (thus M<=N). 
N=4	# N is used to control the maximum of maps (input data structures)
host='main.cpp'
hostT='./template/main.cpp'
kernel='kernels.cl'
kernelT='./template/kernels5.cl'
report='lmReport.txt'
# ------------------------------------------------------------------
# 			start execution 
# ------------------------------------------------------------------
for index in {25..33..1}; do # for each map (ignore MAP-401 [MAP-15] for now)

	mp=${map[$index]}
	echo "map: ${mp}"
	echo -en "${mp}\t" >> ${report}
	if [ ! -d ${mp} ]; then
		mkdir ./${mp}	
	fi	
	# calculate the maximum number of data structures (let us assume 4 for now)
	for (( n=4; n<${N}+1; n++ ))
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
			idxW="" # x coordinate
			case "${bits:0:2}" in
				"00")  
				    idxW="(0+2)"
				    ;;
				"10") 
				    idxW="(cdim+2)"
				    ;;
				"01") 
				    idxW="(cdim+2)"
				    ;;
				"11") 
				    idxW="(2*cdim+2)"
				    ;;
				*)
				    idxW=""
				    ;;
			esac
			cdimIn="int cdimIn=${idxW};"
			cat ${dirName}/${host} | sed "s/@cdimIn/${cdimIn}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			# @rdimIn (TODO: mark)
			rdimIn=""
			idxH="" # y coordinate
			case "${bits:2:2}" in
				"00")  
				    idxH="(0+2)"
				    ;;
				"10") 
				    idxH="(rdim+2)"
				    ;;
				"01") 
				    idxH="(rdim+2)"
				    ;;
				"11") 
				    idxH="(2*rdim+2)"
				    ;;
				*)
				    idxH=""
				    ;;
			esac
			rdimIn="int rdimIn=${idxH};"
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
			xIn="0"
			cat ${dirName}/${host} | sed "s/@xIn/${xIn}/g" > ./tmp
			cat ./tmp > ${dirName}/${host}

			idxW="int idxW=" # x coodinate
			case "${bits:0:2}" in
				"00")  
				    idxW="${idxW}(0+1)"
				    ;;
				"10") 
				    idxW="${idxW}(c+1)"
				    ;;
				"01") 
				    idxW="${idxW}(r+1)"
				    ;;
				"11") 
				    idxW="${idxW}(r+c+1)"
				    ;;
				*)
				    idxW="${idxW}(0+1)"
				    ;;
			esac

			idxH="int idxH=" # y coordinate
			case "${bits:2:2}" in
				"00")  
				    idxH="${idxH}(0+1)"
				    ;;
				"10") 
				    idxH="${idxH}(c+1)"
				    ;;
				"01") 
				    idxH="${idxH}(r+1)"
				    ;;
				"11") 
				    idxH="${idxH}(r+c+1)"
				    ;;
				*)
				    idxH="${idxH}(0+1)"
				    ;;
			esac
			
			idxx="${idxW};\n\t\t\t${idxH};\n\t\t\t"

			# @inData: in1[xIn] + in2[xIn] (TODO: mark)
			inData="${idxx}\n"
			for (( nn=0; nn<${n}; nn++ ))
			  do
			    inData="${inData}\t\t\tfloat val${nn} = in${nn}[(idxH-1)*cdimIn+(idxW)]+in${nn}[(idxH)*cdimIn+(idxW-1)]+in${nn}[(idxH)*cdimIn+(idxW)]+in${nn}[(idxH)*cdimIn+(idxW+1)]+in${nn}[(idxH+1)*cdimIn+(idxW)];\n"
			  done
			inData="${inData}\t\t\tval="
			for (( nn=0; nn<${n}; nn++ ))
			  do
				inData="${inData}val${nn}+"
			  done
			
			inData="${inData%?}"
			inData="${inData};\n"

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
			#idx=${mp:1:2}
			#if [ ${idx:0:1} -eq '0' ]; then
			#	idx="${idx:1:1}"
			#fi
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

			# @lmLoad (TODO: mark)
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
			ceD1="\tint dl = (tly+R) * WD + (tlx+R);\n\t\tint dg = (bx+tlx+1)+(by+tly+1)*cdimIn;"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    ceD1="${ceD1}\n\t\tLM${mm}[dl] = in${mm}[dg];"
			  done
			ceD1="if(1==1){\/\/central data (base) \n\t${ceD1}\n\t}\n\t"

			# 2: Need to read data in the vertical direction?
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD2="\tint dl = (tly+R+WG) * WD + (tlx+R);\n\t\tint dg = (bx+tlx+1)+(by+tly+WG+1)*cdimIn;"
				for (( mm=0; mm<${m}; mm++ ))
				  do
				    ceD2="${ceD2}\n\t\tLM${mm}[dl] = in${mm}[dg];"
				  done
				ceD2="if(1==1){\/\/central data (vertical) \n\t${ceD2}\n\t}\n\t"	
			fi					

			# 3: Need to read data in the horizontal direction?
			if [ "${bits:0:2}" == "11" ]; then # get the last two bits of eMAP
				ceD3="\tint dl = (tly+R) * WD + (tlx+R+WG);\n\t\tint dg = (bx+tlx+WG+1)+(by+tly+1)*cdimIn;"
				for (( mm=0; mm<${m}; mm++ ))
				  do
				    ceD3="${ceD3}\n\t\tLM${mm}[dl] = in${mm}[dg];"
				  done
				ceD3="if(1==1){\/\/central data (horizontal) \n\t${ceD3}\n\t}\n\t"
			fi

			# 4: Need to read data in the diagonal direction?
			if [ "${bits:0:2}" == "11" ] && [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				ceD4="\tint dl = (tly+R+WG) * WD + (tlx+R+WG);\n\t\tint dg = (bx+tlx+WG+1)+(by+tly+WG+1)*cdimIn;"
				for (( mm=0; mm<${m}; mm++ ))
				  do
				    ceD4="${ceD4}\n\t\tLM${mm}[dl] = in${mm}[dg];"
				  done
				ceD4="if(1==1){\/\/central data (diagonal) \n\t${ceD4}\n\t}\n\t"
			fi
			ceD="${ceD1}${ceD2}${ceD3}${ceD4}"
			# top and bottom
			# 1-top
			# 1
			tbD="\tint bbx = bx + tlx;\n"
			tbD="${tbD}\t\tint bby = by - R + tly;\n"
			tbD="${tbD}\t\tint dl = (tly) * WD + (tlx+R);\n"
			tbD="${tbD}\t\tint dg = (bbx+1) + (bby+1) * cdimIn;\n"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    tbD="${tbD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done
			# 2
			tbD="${tbD}\n"
			if [ "${bits:0:2}" == "11" ]; then
				tbD="${tbD}\t\tdl = (tly) * WD + (tlx+R+WG);\n"
				tbD="${tbD}\t\tdg = (bbx+WG+1) + (bby+1) * cdimIn;\n"

				for (( mm=0; mm<${m}; mm++ ))
				  do
				    tbD="${tbD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
				  done
			fi
			# 2-bottom
			# 1
			tbD="${tbD}\n"
			tbD="${tbD}\t\tbby = by + ${offsetV} + tly;\n"
			tbD="${tbD}\t\tdl = (tly+R+${offsetV}) * WD + (tlx+R);\n"
			tbD="${tbD}\t\tdg = (bbx+1) + (bby+1) * cdimIn;\n"

			for (( mm=0; mm<${m}; mm++ ))
			  do
			    tbD="${tbD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done
			# 2
			tbD="${tbD}\n"
			if [ "${bits:0:2}" == "11" ]; then
				tbD="${tbD}\t\tdl = (tly+R+${offsetV}) * WD + (tlx+R+WG);\n"
				tbD="${tbD}\t\tdg = (bbx+WG+1) + (bby+1) * cdimIn;\n"
	
				for (( mm=0; mm<${m}; mm++ ))
				  do
				    tbD="${tbD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
				  done
			fi
			tbD="if(tly<R){\/\/top and bottom data \n\t${tbD}\n\t}"					
					
			# left and right (read 2 times in the vertical directions)
			# 1-left
			# 1
			lrD="\tint bbx = bx + tlx - R;\n"
			lrD="${lrD}\t\tint bby = by + tly;\n"
			lrD="${lrD}\t\tint dl = (tly+R) * WD + (tlx);\n"
			lrD="${lrD}\t\tint dg = (bbx+1) + (bby+1) * cdimIn;\n"

			for (( mm=0; mm<${m}; mm++ ))
			  do
			    lrD="${lrD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done
			lrD="${lrD}\n"
			# 2
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				lrD="${lrD}\t\tdl = (tly+R+WG) * WD + (tlx);\n"
				lrD="${lrD}\t\tdg = (bbx+1) + (bby+WG+1) * cdimIn;\n"

				for (( mm=0; mm<${m}; mm++ ))
				  do
				    lrD="${lrD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
				  done
			fi		

			# 2-right
			# 1
			lrD="${lrD}\n"
			lrD="${lrD}\t\tbbx = bx + tlx + ${offsetH};\n"
			lrD="${lrD}\t\tdl = (tly+R) * WD + (tlx+R+${offsetH});\n"
			lrD="${lrD}\t\tdg = (bbx+1) + (bby+1) * cdimIn;\n"

			for (( mm=0; mm<${m}; mm++ ))
			  do
			    lrD="${lrD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done
			# 2
			lrD="${lrD}\n"
			if [ "${bits:2:2}" == "11" ]; then # get the last two bits of eMAP
				lrD="${lrD}\t\tdl = (tly+R+WG) * WD + (tlx+R+${offsetH});\n"
				lrD="${lrD}\t\tdg = (bbx+1) + (bby+WG+1) * cdimIn;\n"

				for (( mm=0; mm<${m}; mm++ ))
				  do
				    lrD="${lrD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
				  done
			fi
			lrD="if(tlx<R){\/\/left and right data \n\t${lrD}\n\t}"					

			# corner data
			# 1: top-left
			coD="\tint bbx = bx + tlx - R;\n"
			coD="${coD}\t\tint bby = by + tly - R;\n"
			coD="${coD}\t\tint dl = (tly) * WD + (tlx);\n"
			coD="${coD}\t\tint dg = (bbx+1) + (bby+1) * cdimIn;\n"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    coD="${coD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done

			# 2: top-right
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx + tlx + ${offsetH};\n"
			coD="${coD}\t\tbby = by + tly - R;\n"
			coD="${coD}\t\tdl = (tly) * WD + (tlx+R+${offsetH});\n"
			coD="${coD}\t\tdg = (bbx+1) + (bby+1) * cdimIn;\n"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    coD="${coD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done

			# 3: bot-left
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx + tlx - R;\n"
			coD="${coD}\t\tbby = by + tly + ${offsetV};\n"
			coD="${coD}\t\tdl = (tly+R+${offsetV}) * WD + (tlx);\n"
			coD="${coD}\t\tdg = (bbx+1) + (bby+1) * cdimIn;\n"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    coD="${coD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done

			# 4: bot-right
			coD="${coD}\n"
			coD="${coD}\t\tbbx = bx + tlx + ${offsetH};\n"
			coD="${coD}\t\tbby = by + tly + ${offsetV};\n"
			coD="${coD}\t\tdl = (tly+R+${offsetV}) * WD + (tlx+R+${offsetH});\n"
			coD="${coD}\t\tdg = (bbx+1) + (bby+1) * cdimIn;\n"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    coD="${coD}\t\tLM${mm}[dl] = in${mm}[dg];\n"
			  done
			coD="if((tlx<R)\&\&(tly<R)){\/\/corner data \n\t${coD}\n\t}"
		
			lmLoad="${ceD}\n\t${tbD}\n\t${lrD}\n\t${coD}"
			cat ${dirName}/${kernel} | sed "s/@lmLoad/${lmLoad}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @lmUse
			idxww="" # x coodinate
			case "${bits:0:2}" in
				"00")  
				    idxww="(0)"
				    ;;
				"10") 
				    idxww="(tlx)"
				    ;;
				"01") 
				    idxww="(tly)"
				    ;;
				"11") 
				    idxww="(tly+tlx)"
				    ;;
				*)
				    idxww="(0)"
				    ;;
			esac

			idxH="" # y coordinate
			case "${bits:2:2}" in
				"00")  
				    idxhh="(0)"
				    ;;
				"10") 
				    idxhh="(tlx)"
				    ;;
				"01") 
				    idxhh="(tly)"
				    ;;
				"11") 
				    idxhh="(tly+tlx)"
				    ;;
				*)
				    idxhh="(0)"
				    ;;
			esac			
			lmUse="int idxww = (${idxww}+R);\n"
			lmUse="${lmUse}\tint idxhh = (${idxhh}+R);\n"
			for (( mm=0; mm<${m}; mm++ ))
			  do
			    lmUse="${lmUse}\tretVal${mm} = LM${mm}[(idxhh-1)*WD+(idxww)]+LM${mm}[(idxhh)*WD+(idxww-1)]+LM${mm}[(idxhh)*WD+(idxww)]+LM${mm}[(idxhh)*WD+(idxww+1)]+LM${mm}[(idxhh+1)*WD+(idxww)];\n"
			  done
			
			cat ${dirName}/${kernel} | sed "s/@lmUse/${lmUse}/g" > ./tmp
			cat ./tmp > ${dirName}/${kernel}

			# @gmUse
			idxW="" # x coodinate
			case "${bits:0:2}" in
				"00")  
				    idxW="${idxW}(0)"
				    ;;
				"10") 
				    idxW="${idxW}(tgx)"
				    ;;
				"01") 
				    idxW="${idxW}(tgy)"
				    ;;
				"11") 
				    idxW="${idxW}(tgy+tgx)"
				    ;;
				*)
				    idxW="${idxW}"
				    ;;
			esac
			idxW="int idxW=(${idxW}+R);"
			idxH="" # y coordinate
			case "${bits:2:2}" in
				"00")  
				    idxH="${idxH}(0)"
				    ;;
				"10") 
				    idxH="${idxH}(tgx)"
				    ;;
				"01") 
				    idxH="${idxH}(tgy)"
				    ;;
				"11") 
				    idxH="${idxH}(tgy+tgx)"
				    ;;
				*)
				    idxH="${idxH}"
				    ;;
			esac	
			idxH="int idxH=(${idxH}+R);"	
			idx="${idxW}\n\t${idxH}\n"
			gmUse="${idx}"
			for (( mm=${m}; mm<${n}; mm++ ))
			  do
			    gmUse="${gmUse}\tretVal${mm}=in${mm}[(idxH-1)*cdimIn+(idxW)]+in${mm}[(idxH)*cdimIn+(idxW-1)]+in${mm}[(idxH)*cdimIn+(idxW)]+in${mm}[(idxH)*cdimIn+(idxW+1)]+in${mm}[(idxH+1)*cdimIn+(idxW)];\n"
			  done
			
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


