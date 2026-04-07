import { useState, useEffect, useRef, useCallback } from "preact/hooks";
import type { InstanceInfo, SolveResponse, GenerateResponse, VertexStatus } from "./lib/api";
import { getInstances, generate, solve, validate } from "./lib/api";
import ForceGraph from "./components/ForceGraph";
import Controls from "./components/Controls";
import ResultsPanel from "./components/ResultsPanel";

export interface GraphData {
  n: number;
  edges: [number, number][];
  degrees: number[];
}

export default function App() {
  const [instances, setInstances] = useState<InstanceInfo[]>([]);
  const [source, setSource] = useState<"instance" | "random">("random");
  const [instanceName, setInstanceName] = useState("");
  const [genN, setGenN] = useState(40);
  const [genP, setGenP] = useState(0.15);
  const [genSeed, setGenSeed] = useState(42);

  const [algorithm, setAlgorithm] = useState("greedy");
  const [iterations, setIterations] = useState(2000);
  const [temperature, setTemperature] = useState(0);
  const [cooling, setCooling] = useState(0.995);

  const [graphData, setGraphData] = useState<GraphData | null>(null);
  const [result, setResult] = useState<SolveResponse | null>(null);
  const [manualSet, setManualSet] = useState<Set<number>>(new Set());
  const [manualStatus, setManualStatus] = useState<VertexStatus[] | null>(null);
  const [solving, setSolving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [leftW, setLeftW] = useState(280);
  const [rightW, setRightW] = useState(280);
  const [dragging, setDragging] = useState<"left" | "right" | null>(null);

  useEffect(() => { getInstances().then(setInstances).catch(() => {}); }, []);

  useEffect(() => {
    setResult(null);
    setManualSet(new Set());
    setManualStatus(null);
    if (source === "random") {
      generate(genN, genP, genSeed)
        .then((r) => setGraphData({ n: r.n, edges: r.edges, degrees: r.degrees }))
        .catch(() => {});
    } else if (instanceName) {
      solve({ instance: instanceName, algorithm: "greedy" })
        .then((r) => {
          setGraphData({ n: r.n, edges: r.edges, degrees: r.degrees });
        })
        .catch(() => {});
    }
  }, [source, instanceName, genN, genP, genSeed]);

  const handleSolve = useCallback(async () => {
    if (!graphData) return;
    setSolving(true);
    setError(null);
    try {
      const params: any = {
        algorithm,
        iterations,
        temperature,
        cooling,
        seed: genSeed,
      };
      if (source === "instance" && instanceName) {
        params.instance = instanceName;
      } else {
        params.graph_data = { n: graphData.n, edges: graphData.edges };
      }
      const r = await solve(params);
      setResult(r);
      setManualSet(new Set(r.dominating_set));
      setManualStatus(r.vertex_status);
    } catch (e: any) {
      setError(e.message ?? "Solve failed");
    } finally {
      setSolving(false);
    }
  }, [graphData, algorithm, iterations, temperature, cooling, source, instanceName, genSeed]);

  const handleNodeClick = useCallback(
    async (nodeId: number) => {
      if (!graphData) return;
      const next = new Set(manualSet);
      if (next.has(nodeId)) next.delete(nodeId);
      else next.add(nodeId);
      setManualSet(next);

      try {
        const params: any = { dominating_set: Array.from(next) };
        if (source === "instance" && instanceName) params.instance = instanceName;
        else params.graph_data = { n: graphData.n, edges: graphData.edges };
        const v = await validate(params);
        setManualStatus(v.vertex_status);
      } catch {}
    },
    [graphData, manualSet, source, instanceName]
  );

  const handleRandomize = useCallback(() => {
    setGenSeed(Math.floor(Math.random() * 100000));
  }, []);

  const startDrag = (side: "left" | "right") => (e: PointerEvent) => {
    e.preventDefault();
    setDragging(side);
    const startX = e.clientX;
    const startW = side === "left" ? leftW : rightW;
    const onMove = (ev: PointerEvent) => {
      const delta = side === "left" ? ev.clientX - startX : startX - ev.clientX;
      const setter = side === "left" ? setLeftW : setRightW;
      setter(Math.min(450, Math.max(200, startW + delta)));
    };
    const onUp = () => {
      setDragging(null);
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
    };
    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
  };

  const activeStatus = manualStatus ?? result?.vertex_status ?? null;

  return (
    <>
      <header class="top-bar">
        <h1>MPIDS<span>Graph Dominance Solver</span></h1>
      </header>
      <div
        class={`solver-layout${dragging ? " dragging" : ""}`}
        style={{ gridTemplateColumns: `${leftW}px 4px 1fr 4px ${rightW}px` }}
      >
        <aside class="panel">
          <Controls
            source={source}
            onSourceChange={setSource}
            instances={instances}
            instanceName={instanceName}
            onInstanceChange={setInstanceName}
            genN={genN}
            onGenNChange={setGenN}
            genP={genP}
            onGenPChange={setGenP}
            genSeed={genSeed}
            onGenSeedChange={setGenSeed}
            algorithm={algorithm}
            onAlgorithmChange={setAlgorithm}
            iterations={iterations}
            onIterationsChange={setIterations}
            temperature={temperature}
            onTemperatureChange={setTemperature}
            cooling={cooling}
            onCoolingChange={setCooling}
            onSolve={handleSolve}
            onRandomize={handleRandomize}
            solving={solving}
          />
        </aside>
        <div class={`drag-handle${dragging === "left" ? " active" : ""}`} onPointerDown={startDrag("left")} />
        <section class="graph-area">
          {error && <div style={{ padding: "0.5rem 1rem", background: "var(--danger)", color: "white", fontSize: "0.82rem", textAlign: "center" }}>{error}</div>}
          {graphData ? (
            <ForceGraph
              graphData={graphData}
              vertexStatus={activeStatus}
              manualSet={manualSet}
              onNodeClick={handleNodeClick}
            />
          ) : (
            <div class="empty-state">
              <div style={{ fontSize: "2rem" }}>📊</div>
              <div>Generate or load a graph to begin</div>
            </div>
          )}
          {solving && <div class="badge badge-solving">Solving...</div>}
          {!solving && graphData && !result && <div class="badge badge-manual">Interactive</div>}
          <div class="legend">
            <span class="legend-item"><span class="legend-dot" style={{ background: "#22c55e" }} /> In D</span>
            <span class="legend-item"><span class="legend-dot" style={{ background: "#3b82f6" }} /> Satisfied</span>
            <span class="legend-item"><span class="legend-dot" style={{ background: "#ef4444" }} /> Unsatisfied</span>
          </div>
        </section>
        <div class={`drag-handle${dragging === "right" ? " active" : ""}`} onPointerDown={startDrag("right")} />
        <aside class="panel">
          <ResultsPanel result={result} manualSet={manualSet} manualStatus={manualStatus} />
        </aside>
      </div>
    </>
  );
}
