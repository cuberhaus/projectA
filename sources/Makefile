TARGET = greedy local_search basics
CXXFLAGS = -ansi -O3 -fpermissive -std=c++17 
OBJS = Random.o Timer.o
CPLOBJS = Random.o Timer.o

SYSTEM     = x86-64_linux
LIBFORMAT  = static_pic
GCC = gcc
CCC = g++
CCOPT = -m64 -O -fPIC -fexceptions -DNDEBUG -DIL_STD -std=c++17 -fpermissive -w

CCFLAGS = $(CCOPT) -I$(CPLEXINCDIR) -I$(CONCERTINCDIR)

all: ${TARGET}

greedy: greedy.cpp $(OBJS)
	${CCC} ${CXXFLAGS} -o $@ $^

local_search: local_search.cpp $(OBJS)
	${CCC} ${CXXFLAGS} -o $@ $^

basics: basics.cc
	${CCC} ${CXXFLAGS} -o $@ $^

Input: 
	./basics < ./jocs_de_prova/input.txt
InputNoMinimal: 
	./basics < ./jocs_de_prova/inputNoMinimal.txt
InputNoPositiveInfluence: 
	./basics < ./jocs_de_prova/inputNoPositiveInfluence.txt

clean:
	@rm -f *~ *.o *.exe ${TARGET} core

