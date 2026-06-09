# projectA

Frozen FIB-UPC Algorithmics coursework (2021/2022): Minimum Positive Influence Dominating Set (MPIDS) on real-world graphs, solved with greedy, local search, metaheuristic, and exact ILP (CPLEX) approaches. An interactive Elm + D3 + Flask web frontend was added later to visualize instances and solvers.

## Architecture

- `sources/` — C++17 algorithms: [greedy.cpp](sources/greedy.cpp), [local_search.cpp](sources/local_search.cpp), [basics.cc](sources/basics.cc) (dominance checks), plus [ILP_CPLEX/cplex.cpp](sources/ILP_CPLEX/cplex.cpp) exact solver.
- [PartC/PartC.cc](PartC/PartC.cc), [PartD/metaheuristic.cpp](PartD/metaheuristic.cpp) — additional algorithmic parts.
- `jocs_de_prova/MPIDS/` — graph instances (ego-Facebook, jazz, football, CA-…).
- `web/` — Elm frontend + Flask backend wrapping the solvers.
- PDFs ([Informe_MPIDS.pdf](Informe_MPIDS.pdf), [Experiments.pdf](Experiments.pdf), [Manual.pdf](Manual.pdf)) are the deliverables.

## Build and Test

- C++ algorithms: build via the Makefile under `sources/` (and `sources/ILP_CPLEX/` for the CPLEX solver, which requires a local IBM CPLEX install).
- Web app: top-level [Makefile](Makefile) targets — `make install`, `make dev`, or `docker compose up -d` (http://localhost:8084).

## Pitfalls

- Frozen coursework — do not refactor the C++ algorithms or report content; benchmarks in [Experiments.pdf](Experiments.pdf) were run once and re-running across all instances can take a very long time (especially CPLEX and metaheuristic on CA networks).
- The top-level `Makefile` is for the web app only, not the algorithms; the README's `make` instruction refers to the per-folder Makefiles under `sources/`.
- CPLEX is proprietary and not bundled; the ILP solver will not build without it.

See [README.md](README.md).
