from __future__ import annotations

import math
import random
import time

from .models import Graph, SolveResult, VertexStatus


def _vertex_status(g: Graph, domset: set[int]) -> list[VertexStatus]:
    """Compute per-vertex domination status."""
    result: list[VertexStatus] = []
    for v in range(g.n):
        dom_nb = sum(1 for u in g.adj[v] if u in domset)
        needed = g.needed(v)
        result.append(VertexStatus(
            id=v,
            in_set=v in domset,
            dom_neighbors=dom_nb,
            needed=needed,
            satisfied=dom_nb >= needed,
        ))
    return result


def validate(g: Graph, domset: list[int]) -> list[VertexStatus]:
    """Check a candidate dominating set, return per-vertex status."""
    return _vertex_status(g, set(domset))


def greedy(g: Graph) -> SolveResult:
    """Greedy heuristic: add vertices from highest to lowest degree,
    tracking edge coverage. Stop when all edges are covered and |D| > n/2."""
    t0 = time.perf_counter()
    nodes_explored = 0

    order = sorted(range(g.n), key=lambda v: g.degree(v), reverse=True)
    domset: set[int] = set()
    covered_edges: set[tuple[int, int]] = set()
    trace: list[int] = []

    for v in order:
        nodes_explored += 1
        if g.degree(v) == 0 and len(covered_edges) >= len(g.edges):
            continue
        domset.add(v)
        for u in g.adj[v]:
            key = (min(u, v), max(u, v))
            covered_edges.add(key)
        trace.append(len(domset))
        if len(covered_edges) >= len(g.edges) and len(domset) > g.n // 2:
            break

    # Pruning pass: try removing vertices while maintaining domination
    for v in list(domset):
        nodes_explored += 1
        domset.discard(v)
        if _is_dominant(g, domset):
            trace.append(len(domset))
        else:
            domset.add(v)

    elapsed = (time.perf_counter() - t0) * 1000
    return SolveResult(
        dominating_set=sorted(domset),
        size=len(domset),
        time_ms=elapsed,
        nodes_explored=nodes_explored,
        vertex_status=_vertex_status(g, domset),
        trace=trace,
    )


def _is_dominant(g: Graph, domset: set[int]) -> bool:
    for v in range(g.n):
        dom_nb = sum(1 for u in g.adj[v] if u in domset)
        if dom_nb < g.needed(v):
            return False
    return True


def _dom_neighbor_counts(g: Graph, domset: set[int]) -> list[int]:
    counts = [0] * g.n
    for v in domset:
        for u in g.adj[v]:
            counts[u] += 1
    return counts


def _can_remove(g: Graph, v: int, dom_nb: list[int]) -> bool:
    """Check if removing v from D still satisfies all its neighbors."""
    for u in g.adj[v]:
        if dom_nb[u] - 1 < g.needed(u):
            return False
    return True


def local_search(
    g: Graph,
    iterations: int = 2000,
    temperature: float = 0.0,
    cooling: float = 0.995,
    seed: int | None = None,
) -> SolveResult:
    """SA-style local search. Starts with all vertices in D, tries to shrink."""
    t0 = time.perf_counter()
    rng = random.Random(seed)

    domset = set(range(g.n))
    rest: set[int] = set()
    dom_nb = _dom_neighbor_counts(g, domset)
    nodes_explored = 0
    trace: list[int] = [g.n]

    temp = temperature if temperature > 0 else float(g.n)
    best_set = set(domset)
    best_size = len(domset)

    for _ in range(iterations):
        nodes_explored += 1

        removable = [v for v in domset if _can_remove(g, v, dom_nb)]

        if removable:
            node = rng.choice(removable)
            domset.discard(node)
            rest.add(node)
            for u in g.adj[node]:
                dom_nb[u] -= 1
            is_del = True
        elif rest:
            node = rng.choice(list(rest))
            domset.add(node)
            rest.discard(node)
            for u in g.adj[node]:
                dom_nb[u] += 1
            is_del = False
        else:
            continue

        new_size = len(domset)
        diff = (best_size if is_del else len(domset) + 1) - new_size

        if diff > 0:
            if new_size < best_size:
                best_size = new_size
                best_set = set(domset)
        else:
            prob = math.exp(diff / max(temp, 1e-10))
            if rng.random() >= prob:
                # Reject: undo
                if is_del:
                    domset.add(node)
                    rest.discard(node)
                    for u in g.adj[node]:
                        dom_nb[u] += 1
                else:
                    domset.discard(node)
                    rest.add(node)
                    for u in g.adj[node]:
                        dom_nb[u] -= 1

        temp *= cooling
        trace.append(len(domset))

    elapsed = (time.perf_counter() - t0) * 1000
    return SolveResult(
        dominating_set=sorted(best_set),
        size=best_size,
        time_ms=elapsed,
        nodes_explored=nodes_explored,
        vertex_status=_vertex_status(g, best_set),
        trace=trace,
    )
