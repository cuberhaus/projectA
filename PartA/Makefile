TARGET = basics.x
CXXFLAGS = -ansi -O3 -fpermissive -std=c++17 

SYSTEM     = x86-64_linux
LIBFORMAT  = static_pic
GCC = gcc
CCC = g++
CCOPT = -m64 -O -fPIC -fexceptions -DNDEBUG -DIL_STD -std=c++17 -fpermissive -w

CCFLAGS = $(CCOPT)

all: ${TARGET} input
# $@ is the name of the target being generated, and $< the first prerequisite
basics.x: basics.cc
	$(CCC) $(CXXFLAGS) -o $@ $^
Input: 
	./basics.x < input
InputNoMinimal: 
	./basics.x < inputNoMinimal
InputNoPositiveInfluence: 
	./basics.x < inputNoPositiveInfluence
clean:
	rm -f *~ *.o *.exe *.x
