# Project A

Algorithmics course project (2021/2022) at FIB-UPC, solving a graph dominance problem (MPIDS — Minimum Positive Influence Dominating Set) using multiple algorithmic approaches.

## Overview

Given a graph, find a minimum dominating set where a vertex is dominated if more than 50% of its neighbors belong to the set. Tested on real-world graph instances (ego-facebook, jazz, football, CA networks).

## Structure

```
├── sources/
│   ├── greedy.cpp              # Greedy algorithm
│   ├── local_search.cpp        # Local search algorithm
│   ├── basics.cc               # Dominance checks (is_dominant, is_minimal)
│   ├── Random.{cc,h}           # Random number utilities
│   ├── Timer.{cc,h}            # Timer utilities
│   ├── config.h                # Configuration
│   └── ILP_CPLEX/
│       ├── cplex.cpp           # Exact ILP solver using CPLEX
│       └── Makefile
├── PartC/
│   └── PartC.cc                # Part C implementation
├── PartD/
│   └── metaheuristic.cpp       # Metaheuristic approach
├── jocs_de_prova/              # Test graph instances
├── Plantilles/                 # Project templates
└── Makefile                    # Builds greedy, basics, local_search (-std=c++17)
```

## Building

```bash
make
```

## Tech Stack

- **C++17** for all algorithms
- **IBM CPLEX** for the ILP exact solver
