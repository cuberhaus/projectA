from __future__ import annotations

import os
import random
from pathlib import Path

from .models import Graph

INSTANCES_DIR = Path(__file__).parent / "instances"


def list_instances() -> list[dict]:
    """Return metadata for each bundled graph instance."""
    result = []
    for f in sorted(INSTANCES_DIR.glob("*.txt")):
        with open(f) as fh:
            parts = fh.readline().split()
            n = int(parts[0])
            if len(parts) > 1:
                e = int(parts[1])
            else:
                e = int(fh.readline())
        result.append({"name": f.stem, "file": f.name, "n": n, "e": e})
    return result


def load_instance(name: str) -> Graph:
    """Load a graph from the instances directory.

    Supports two formats:
      A) ``n e`` on first line, then ``u v`` edge pairs (1-based)
      B) ``n`` on first line, ``e`` on second line, then ``u v`` pairs (1-based)
    """
    path = INSTANCES_DIR / f"{name}.txt"
    if not path.exists():
        path = INSTANCES_DIR / name
    if not path.exists():
        raise FileNotFoundError(f"Instance {name!r} not found")

    with open(path) as fh:
        first = fh.readline().split()
        if len(first) == 2:
            n, e = int(first[0]), int(first[1])
        else:
            n = int(first[0])
            e = int(fh.readline())

        edges: list[tuple[int, int]] = []
        seen: set[tuple[int, int]] = set()
        for line in fh:
            parts = line.split()
            if len(parts) < 2:
                continue
            u, v = int(parts[0]) - 1, int(parts[1]) - 1
            key = (min(u, v), max(u, v))
            if key not in seen:
                seen.add(key)
                edges.append(key)

    return Graph(n=n, edges=edges)


def generate_random(n: int, p: float, seed: int | None = None) -> Graph:
    """Generate an Erdos-Renyi G(n,p) graph."""
    rng = random.Random(seed)
    edges: list[tuple[int, int]] = []
    for u in range(n):
        for v in range(u + 1, n):
            if rng.random() < p:
                edges.append((u, v))
    return Graph(n=n, edges=edges)
