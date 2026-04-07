from __future__ import annotations

import os
from pathlib import Path

from flask import Flask, abort, jsonify, request, send_from_directory

from . import graph_io, solver
from .models import Graph

DIST_DIR = Path(__file__).parent.parent / "frontend" / "dist"

app = Flask(__name__, static_folder=None)


def _parse_graph(data: dict) -> Graph:
    instance = data.get("instance")
    graph_data = data.get("graph_data")
    if instance:
        return graph_io.load_instance(instance)
    if graph_data:
        return Graph(
            n=graph_data["n"],
            edges=[(e[0], e[1]) for e in graph_data["edges"]],
        )
    abort(400, description="Provide instance name or graph_data")


@app.get("/api/status")
def status():
    return jsonify(status="ok")


@app.get("/api/instances")
def instances():
    return jsonify(graph_io.list_instances())


@app.post("/api/generate")
def generate():
    data = request.get_json(silent=True) or {}
    n = data.get("n", 30)
    p = data.get("p", 0.15)
    seed = data.get("seed")

    g = graph_io.generate_random(n, p, seed)
    return jsonify(
        n=g.n,
        edges=g.edges,
        degrees=[g.degree(v) for v in range(g.n)],
    )


@app.post("/api/solve")
def solve():
    data = request.get_json(silent=True) or {}
    g = _parse_graph(data)

    algorithm = data.get("algorithm", "greedy")
    if algorithm == "greedy":
        result = solver.greedy(g)
    elif algorithm == "local_search":
        result = solver.local_search(
            g,
            iterations=data.get("iterations", 2000),
            temperature=data.get("temperature", 0.0),
            cooling=data.get("cooling", 0.995),
            seed=data.get("seed"),
        )
    else:
        abort(400, description=f"Unknown algorithm: {algorithm}")

    return jsonify(
        dominating_set=result.dominating_set,
        size=result.size,
        time_ms=round(result.time_ms, 2),
        nodes_explored=result.nodes_explored,
        vertex_status=[
            dict(
                id=vs.id,
                in_set=vs.in_set,
                dom_neighbors=vs.dom_neighbors,
                needed=vs.needed,
                satisfied=vs.satisfied,
            )
            for vs in result.vertex_status
        ],
        trace=result.trace,
        n=g.n,
        edges=g.edges,
        degrees=[g.degree(v) for v in range(g.n)],
    )


@app.post("/api/validate")
def validate():
    data = request.get_json(silent=True) or {}
    g = _parse_graph(data)
    dominating_set = data.get("dominating_set", [])

    statuses = solver.validate(g, dominating_set)
    all_satisfied = all(s.satisfied for s in statuses)
    return jsonify(
        valid=all_satisfied,
        size=len(dominating_set),
        vertex_status=[
            dict(
                id=vs.id,
                in_set=vs.in_set,
                dom_neighbors=vs.dom_neighbors,
                needed=vs.needed,
                satisfied=vs.satisfied,
            )
            for vs in statuses
        ],
    )


if DIST_DIR.exists():

    @app.route("/", defaults={"path": ""})
    @app.route("/<path:path>")
    def serve_spa(path: str):
        file = DIST_DIR / path
        if file.is_file():
            return send_from_directory(DIST_DIR, path)
        return send_from_directory(DIST_DIR, "index.html")
