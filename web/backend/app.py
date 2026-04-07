from __future__ import annotations

import os
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel

from . import graph_io, solver
from .models import Graph

app = FastAPI(title="MPIDS Solver")
_pool = ThreadPoolExecutor(max_workers=2)

DIST_DIR = Path(__file__).parent.parent / "frontend" / "dist"


class GenerateRequest(BaseModel):
    n: int = 30
    p: float = 0.15
    seed: Optional[int] = None


class SolveRequest(BaseModel):
    instance: Optional[str] = None
    graph_data: Optional[dict] = None
    algorithm: str = "greedy"
    iterations: int = 2000
    temperature: float = 0.0
    cooling: float = 0.995
    seed: Optional[int] = None


class ValidateRequest(BaseModel):
    instance: Optional[str] = None
    graph_data: Optional[dict] = None
    dominating_set: list[int]


def _parse_graph(instance: str | None, graph_data: dict | None) -> Graph:
    if instance:
        return graph_io.load_instance(instance)
    if graph_data:
        return Graph(
            n=graph_data["n"],
            edges=[(e[0], e[1]) for e in graph_data["edges"]],
        )
    raise HTTPException(400, "Provide instance name or graph_data")


@app.get("/api/status")
async def status():
    return {"status": "ok"}


@app.get("/api/instances")
async def instances():
    return graph_io.list_instances()


@app.post("/api/generate")
async def generate(req: GenerateRequest):
    g = graph_io.generate_random(req.n, req.p, req.seed)
    return {
        "n": g.n,
        "edges": g.edges,
        "degrees": [g.degree(v) for v in range(g.n)],
    }


@app.post("/api/solve")
async def solve(req: SolveRequest):
    g = _parse_graph(req.instance, req.graph_data)

    if req.algorithm == "greedy":
        fn = lambda: solver.greedy(g)
    elif req.algorithm == "local_search":
        fn = lambda: solver.local_search(
            g,
            iterations=req.iterations,
            temperature=req.temperature,
            cooling=req.cooling,
            seed=req.seed,
        )
    else:
        raise HTTPException(400, f"Unknown algorithm: {req.algorithm}")

    loop = __import__("asyncio").get_event_loop()
    result = await loop.run_in_executor(_pool, fn)

    return {
        "dominating_set": result.dominating_set,
        "size": result.size,
        "time_ms": round(result.time_ms, 2),
        "nodes_explored": result.nodes_explored,
        "vertex_status": [
            {
                "id": vs.id,
                "in_set": vs.in_set,
                "dom_neighbors": vs.dom_neighbors,
                "needed": vs.needed,
                "satisfied": vs.satisfied,
            }
            for vs in result.vertex_status
        ],
        "trace": result.trace,
        "n": g.n,
        "edges": g.edges,
        "degrees": [g.degree(v) for v in range(g.n)],
    }


@app.post("/api/validate")
async def validate(req: ValidateRequest):
    g = _parse_graph(req.instance, req.graph_data)
    statuses = solver.validate(g, req.dominating_set)
    all_satisfied = all(s.satisfied for s in statuses)
    return {
        "valid": all_satisfied,
        "size": len(req.dominating_set),
        "vertex_status": [
            {
                "id": vs.id,
                "in_set": vs.in_set,
                "dom_neighbors": vs.dom_neighbors,
                "needed": vs.needed,
                "satisfied": vs.satisfied,
            }
            for vs in statuses
        ],
    }


if DIST_DIR.exists():
    app.mount("/", StaticFiles(directory=str(DIST_DIR), html=True), name="static")
