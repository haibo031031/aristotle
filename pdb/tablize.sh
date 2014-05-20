#!/bin/sh
#platform=(gtx280 gtx580 hd6970 e5620)
platform=(c1060 c2050 k20m hd7970 phi snb x5650)
map=(107 108 109 110 112 113 114 115 116 204 205 211 302 303 306 407 408 409 410 412 413 414 415 416 507 508 509 510 512 513 514 515 516)

fName="items.dump"

# remove file
if [ -f "$fName" ]; then
	rm ${fName}
fi  


for index in {0..32..1}; do
	mp=${map[$index]}
	item="\\\tiny{${mp}} &\n"
	for pf in ${platform[@]}; do
		outname=$mp\_$pf.eps
		#-----------------------------------------------------
		#		begin generating item
		#-----------------------------------------------------
		item="${item}\\\resizebox{12.0mm}{!}{\\\includegraphics{base_data/${outname}}} &\n"
		#-----------------------------------------------------
		#		end generating item
		#-----------------------------------------------------	    
	done
	item="${item%?}"
	item="${item%?}"
	item="${item%?}"
	item="${item}\\\\\\\\ "
	echo -en "${item}\hline\n" >> ${fName}
done

