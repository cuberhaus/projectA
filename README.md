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

## Web App

An interactive web frontend for exploring and solving MPIDS instances with a D3.js force-directed graph visualization.

**Stack:** Elm (via `vite-plugin-elm`) + D3.js force simulation (via Elm ports) + FastAPI backend

### Quick Start

```bash
# Docker (recommended)
docker compose up -d        # http://localhost:8084

# Dev mode
make web-dev                # Backend :8084, Vite dev server
```

### Features

- Interactive force-directed graph — click nodes to toggle domination set membership
- Greedy and simulated annealing solvers with real-time trace visualization
- Preset real-world graph instances (ego-facebook, jazz, football, CA networks)
- Random graph generation (Erdos-Renyi) with configurable N, P, seed
- Domination validation with unsatisfied vertex highlighting

### Web Structure

```
web/
├── frontend/          # Elm + Vite + D3.js
│   ├── src/
│   │   ├── Main.elm           # TEA application (model, update, view)
│   │   ├── Types.elm          # Domain types + JSON decoders/encoders
│   │   ├── Api.elm            # HTTP requests to FastAPI
│   │   ├── Ports.elm          # Elm ↔ JS interop (D3 graph)
│   │   ├── View/              # Controls, Results, Layout modules
│   │   ├── js/forceGraph.js   # D3.js force simulation
│   │   └── styles/            # Dark theme CSS
│   └── elm.json
├── backend/           # FastAPI + NetworkX
│   └── app.py
└── requirements.txt
```

## Tech Stack

- **C++17** for all algorithms
- **IBM CPLEX** for the ILP exact solver
- **Elm** + **D3.js** (via ports) for the interactive web frontend
- **FastAPI** + **NetworkX** for the web backend
