#C compiler
CC = g++
CCFLAGS = -lOpenCL -fopenmp
#0
#CUDA_DIR = /usr/local/cuda/
#INC = $(CUDA_DIR)/include/
#LIB = $(CUDA_DIR)/lib64/

#APP_DIR = /cm/shared/package/amd-app-sdk/2.6/
#INC = $(APP_DIR)/include/
#LIB = $(APP_DIR)/lib/x86_64
#2
#INTEL_DIR = /cm/shared/package/intel-ocl-sdk/1.1
#INC = $(INTEL_DIR)/include/
#LIB = $(INTEL_DIR)/lib64

#3
#NV_DIR = /cm/shared/apps/cuda41/toolkit/current/
#INC = $(NV_DIR)/include/
#LIB = $(NV_DIR)/lib/x86_64

SRC = main.cpp 
EXE = app.${foo}

#release: $(SRC)
#	$(CC) $(SRC) -o $(EXE) -I$(INC) -L$(LIB) -D ERRMSG -lOpenCL  -fopenmp 

all: build

build: ${EXE}

main.o: main.cpp
	$(CC) -o $@ -c $< $(CCFLAGS)

#oclRun.o: oclRun.cpp
#	$(CC) -o $@ -c $< $(CCFLAGS)

#ompRun.o: ompRun.cpp
#	$(CC) -o $@ -c $< $(CCFLAGS)

${EXE}: main.o 
	$(CC) -o $@ $+ $(CCFLAGS)

run:
	./$(EXE)
	
clean: $(SRC)
	rm -f $(EXE) $(EXE).linkinfo result* ~* data.${foo}.dat *.o
