aristotle
=========

The OpenCL platform model has the concept of local memory, which is mapped to scrach-pad memory for a given OpenCL implementation. The question is whether using local memory is always benefitial? To answer this question, we have developed a code generator and a composer (Aristotle) for different memory access patterns. With the help of Aristotle, we can generate benchmarks with and with local memory use. In this way, we can quantify and predict the benefits of using local memory on diverse processors.

=========
It includes three major components:

(1) Generator V1.0-- Generate code with and without local memory (1 MAP)

(2) Composer V1.0-- Generate code with and without local memory (2+ same/different MAPs)

(3) Composer V1.1-- Generate code with and without local memory (2+ same MAPs)

=========
The script is written Jianbin Fang from Delft Unviersity of Tehchnology, the Netherlands. 

Date: 09/12/2013

