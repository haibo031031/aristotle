reset
set term postscript eps color solid 20
set output "bw_etm.eps"
set grid
set key bottom right
set xlabel "stride in log scale (in double-precision words)"
set ylabel "stride bandwidth (GB/s)"
#set xrange [8:16]
#set yrange [-5:105]
#set xtic rotate by -45 scale 0
set logscale y 2

set style line 1  lt 0 lw 5 pt 0 ps 2
set style line 2  lt 1 lw 2 pt 1 ps 2 lc rgb "#D55E00"
set style line 3  lt 2 lw 2 pt 2 ps 2 lc rgb "#56B4E9"
set style line 4  lt 3 lw 2 pt 3 ps 1
set style line 5  lt 4 lw 2 pt 4 ps 1
set style line 6  lt 5 lw 2 pt 5 ps 1
set style line 7  lt 6 lw 2 pt 6 ps 1
set style line 8  lt 7 lw 2 pt 7 ps 1
set style line 9  lt 8 lw 2 pt 8 ps 1
set style line 10  lt 9 lw 2 pt 9 ps 1
set style line 11  lt 10 lw 2 pt 10 ps 1
set style line 12  lt 11 lw 2 pt 11 ps 1
set style line 13  lt 12 lw 2 pt 12 ps 1
set style line 14  lt 13 lw 2 pt 13 ps 1
set style line 15  lt 14 lw 2 pt 14 ps 1


plot "bw_etm.dat" using 1:2:7 with yerrorlines title 'r2w2', '' using 1:3:9 with yerrorlines title 'r3w3', '' using 1:4:11 with yerrorlines title 'r4w4', '' using 1:5:13 with yerrorlines title 'r5w5'

