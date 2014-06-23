aristotle
=========

The OpenCL platform model has the concept of local memory, which is mapped to scrach-pad memory for a given OpenCL implementation. The question is whether using local memory is always benefitial? To answer this question, we have developed a code generator and a composer (Aristotle) for different memory access patterns. With the help of Aristotle, we can generate benchmarks with and without local memory use. In this way, we can quantify and predict the benefits of using local memory on diverse processors.

=========
It includes three major components:

(1) Generator -- Generate code with and without local memory (1 MAP)

(2) Composer -- Generate code with and without local memory (2+ MAPs)


=========
The script is written by Jianbin Fang from TU Delft. 

Date: 10/2012 ~ 12/2013

