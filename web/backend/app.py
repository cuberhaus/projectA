from __future__ import annotations

# ── Phase 14 (Option A) — Sentry SDK + JSON-line stdout (no-op if missing) ─
try:
    from ._sentry_obs import (  # type: ignore[import-not-found]
        init_observability,
        breadcrumb as _crumb,
        span as _span,
        tag as _tag,
        register_flask_session_id as _register_flask_session_id,
    )

    init_observability(service="mpids")
except ImportError:
    from contextlib import contextmanager

    def _tag(*_a, **_kw):
        return None

    def _crumb(*_a, **_kw):
        return None

    @contextmanager
    def _span(*_a, **_kw):
        yield None

    def _register_flask_session_id(_app):
        return None

import os
from pathlib import Path

from flask import Flask, abort, jsonify, request, send_from_directory

from . import graph_io, solver
from .models import Graph

DIST_DIR = Path(__file__).parent.parent / "frontend" / "dist"

app = Flask(__name__, static_folder=None)
_register_flask_session_id(app)


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

    _tag("n", n)
    _tag("p", p)
    _crumb("graph", "generate random instance", n=n, p=p, seed=seed)
    with _span("graph.generate", description=f"random Erdős–Rényi n={n} p={p}", n=n, p=p):
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
    _tag("algorithm", algorithm)
    _tag("n", g.n)
    is_custom = bool(data.get("graph_data"))
    _crumb(
        "solver", f"{algorithm} run",
        n=g.n,
        edges=len(g.edges),
        source="custom" if is_custom else (data.get("instance") or "unknown"),
    )

    if algorithm == "greedy":
        with _span("solver.search", description="greedy", algorithm=algorithm, n=g.n):
            result = solver.greedy(g)
    elif algorithm == "local_search":
        iterations = data.get("iterations", 2000)
        temperature = data.get("temperature", 0.0)
        _tag("iterations", iterations)
        _tag("temperature", temperature)
        with _span(
            "solver.search",
            description="local search / SA",
            algorithm=algorithm,
            iterations=iterations,
            temperature=temperature,
            cooling=data.get("cooling", 0.995),
        ):
            result = solver.local_search(
                g,
                iterations=iterations,
                temperature=temperature,
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

    _crumb(
        "solver", "validate run",
        n=g.n,
        ds_size=len(dominating_set),
    )
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
