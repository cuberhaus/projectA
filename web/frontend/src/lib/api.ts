const BASE = import.meta.env.VITE_API_URL ?? "";

export interface InstanceInfo {
  name: string;
  file: string;
  n: number;
  e: number;
}

export interface VertexStatus {
  id: number;
  in_set: boolean;
  dom_neighbors: number;
  needed: number;
  satisfied: boolean;
}

export interface SolveResponse {
  dominating_set: number[];
  size: number;
  time_ms: number;
  nodes_explored: number;
  vertex_status: VertexStatus[];
  trace: number[];
  n: number;
  edges: [number, number][];
  degrees: number[];
}

export interface GenerateResponse {
  n: number;
  edges: [number, number][];
  degrees: number[];
}

export interface ValidateResponse {
  valid: boolean;
  size: number;
  vertex_status: VertexStatus[];
}

async function post<T>(url: string, body: unknown): Promise<T> {
  const r = await fetch(`${BASE}${url}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!r.ok) throw new Error(await r.text());
  return r.json();
}

async function get<T>(url: string): Promise<T> {
  const r = await fetch(`${BASE}${url}`);
  if (!r.ok) throw new Error(await r.text());
  return r.json();
}

export const getInstances = () => get<InstanceInfo[]>("/api/instances");

export const generate = (n: number, p: number, seed?: number) =>
  post<GenerateResponse>("/api/generate", { n, p, seed });

export const solve = (params: {
  instance?: string;
  graph_data?: { n: number; edges: [number, number][] };
  algorithm: string;
  iterations?: number;
  temperature?: number;
  cooling?: number;
  seed?: number;
}) => post<SolveResponse>("/api/solve", params);

export const validate = (params: {
  instance?: string;
  graph_data?: { n: number; edges: [number, number][] };
  dominating_set: number[];
}) => post<ValidateResponse>("/api/validate", params);
