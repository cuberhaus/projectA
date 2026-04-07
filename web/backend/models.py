from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


@dataclass(slots=True)
class Graph:
    n: int
    edges: list[tuple[int, int]]
    adj: list[list[int]] = field(default_factory=list, repr=False)

    def __post_init__(self) -> None:
        if not self.adj:
            self.adj = [[] for _ in range(self.n)]
            for u, v in self.edges:
                self.adj[u].append(v)
                self.adj[v].append(u)

    def degree(self, v: int) -> int:
        return len(self.adj[v])

    def needed(self, v: int) -> int:
        """Minimum dominating neighbors required for vertex v."""
        return -(-self.degree(v) // 2)  # ceil(deg/2)


@dataclass(slots=True)
class VertexStatus:
    id: int
    in_set: bool
    dom_neighbors: int
    needed: int
    satisfied: bool


@dataclass(slots=True)
class SolveResult:
    dominating_set: list[int]
    size: int
    time_ms: float
    nodes_explored: int
    vertex_status: list[VertexStatus]
    trace: list[int] = field(default_factory=list)
