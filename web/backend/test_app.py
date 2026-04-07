"""Tests for the Flask backend (MPIDS Solver)."""

import pytest

from .app import app
from .models import Graph


@pytest.fixture()
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_status(client):
    r = client.get("/api/status")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_instances_returns_list(client):
    r = client.get("/api/instances")
    assert r.status_code == 200
    data = r.get_json()
    assert isinstance(data, list)


def test_generate_default(client):
    r = client.post("/api/generate", json={})
    assert r.status_code == 200
    data = r.get_json()
    assert "n" in data
    assert "edges" in data
    assert "degrees" in data
    assert data["n"] == 30


def test_generate_custom(client):
    r = client.post("/api/generate", json={"n": 10, "p": 0.5, "seed": 42})
    assert r.status_code == 200
    data = r.get_json()
    assert data["n"] == 10
    assert len(data["degrees"]) == 10


def test_generate_deterministic(client):
    r1 = client.post("/api/generate", json={"n": 15, "p": 0.3, "seed": 123})
    r2 = client.post("/api/generate", json={"n": 15, "p": 0.3, "seed": 123})
    assert r1.get_json()["edges"] == r2.get_json()["edges"]


def test_solve_greedy_inline(client):
    r = client.post("/api/solve", json={
        "graph_data": {"n": 4, "edges": [[0, 1], [1, 2], [2, 3]]},
        "algorithm": "greedy",
    })
    assert r.status_code == 200
    data = r.get_json()
    assert "dominating_set" in data
    assert "size" in data
    assert "time_ms" in data
    assert data["n"] == 4


def test_solve_local_search(client):
    r = client.post("/api/solve", json={
        "graph_data": {"n": 5, "edges": [[0, 1], [1, 2], [2, 3], [3, 4]]},
        "algorithm": "local_search",
        "iterations": 100,
    })
    assert r.status_code == 200
    data = r.get_json()
    assert data["size"] > 0
    assert data["size"] <= data["n"]


def test_solve_unknown_algorithm(client):
    r = client.post("/api/solve", json={
        "graph_data": {"n": 3, "edges": [[0, 1], [1, 2]]},
        "algorithm": "quantum",
    })
    assert r.status_code == 400


def test_solve_missing_graph(client):
    r = client.post("/api/solve", json={"algorithm": "greedy"})
    assert r.status_code == 400


def test_validate_valid_set(client):
    g = {"n": 4, "edges": [[0, 1], [1, 2], [2, 3]]}
    solve_r = client.post("/api/solve", json={
        "graph_data": g,
        "algorithm": "greedy",
    })
    ds = solve_r.get_json()["dominating_set"]

    r = client.post("/api/validate", json={
        "graph_data": g,
        "dominating_set": ds,
    })
    assert r.status_code == 200
    data = r.get_json()
    assert data["valid"] is True


def test_validate_empty_set(client):
    r = client.post("/api/validate", json={
        "graph_data": {"n": 3, "edges": [[0, 1], [1, 2]]},
        "dominating_set": [],
    })
    assert r.status_code == 200
    assert r.get_json()["valid"] is False


class TestGraphModel:
    def test_construction(self):
        g = Graph(n=3, edges=[(0, 1), (1, 2)])
        assert g.degree(0) == 1
        assert g.degree(1) == 2
        assert g.degree(2) == 1

    def test_needed(self):
        g = Graph(n=4, edges=[(0, 1), (0, 2), (0, 3)])
        assert g.needed(0) == 2  # ceil(3/2)
        assert g.needed(1) == 1  # ceil(1/2)
