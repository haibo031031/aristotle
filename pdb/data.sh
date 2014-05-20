#!/bin/sh

#platform=(gtx280 gtx580 hd6970 e5620)
platform=(c1060 c2050 k20m hd7970 x5650 snb phi)
map=(107 108 109 110 112 113 114 115 116 204 205 211 302 303 306 407 408 409 410 412 413 414 415 416 507 508 509 510 512 513 514 515 516)
sDIR="./data"
#pf=gtx280
#db=$pf.dat
#mp=107

for pf in ${platform[@]}; do
	for index in {0..32..1}; do
		mp=${map[$index]}
		outname=$mp\_$pf.png
		db1=${sDIR}/${mp}_v1_vv0_data.${pf}.dat
		db2=${sDIR}/${mp}_v1_vv1_data.${pf}.dat
		#idx=$((index+2))
		#-----------------------------------------------------
		#		begin plotting
		#-----------------------------------------------------
		gnuplot <<EOF
		reset	
		set terminal png 20
		set output "$outname"	
		set key ins vert
		set key top left
		set style line 1  lt 1 lw 10 pt 8 ps 0 lc rgb "#D55E00"
		set style line 2  lt 2 lw 10 pt 6 ps 0 lc rgb "#56B4E9"
		set style line 3  lt 3 lw 4 pt 4 ps 3 lc rgb "#CC79A7"
		set style line 4  lt 4 lw 4 pt 12 ps 3 lc rgb "#009E73"
		set style line 5  lt 5 lw 4 pt 2 ps 3 lc rgb "#999999"		#set ytics nomirror
		#set tics out
		set autoscale  y
		set logscale y 2
		set xtics ("128" 0, "256" 1, "512" 2, "1024" 3, "2048" 4, "4096" 5)
		set xlabel "data sets"
		set ylabel "bandwidth (GB/s)"				
		plot "${db1}" using 0:23:24 with yerrorlines title '' ls 1, "${db2}" using 0:23:24 with yerrorlines title '' ls 2
EOF
		#-----------------------------------------------------
		#		end plotting
		#-----------------------------------------------------	    
	done
done



