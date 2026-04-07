import type { InstanceInfo } from "../lib/api";

interface Props {
  source: "instance" | "random";
  onSourceChange: (s: "instance" | "random") => void;
  instances: InstanceInfo[];
  instanceName: string;
  onInstanceChange: (n: string) => void;
  genN: number;
  onGenNChange: (n: number) => void;
  genP: number;
  onGenPChange: (p: number) => void;
  genSeed: number;
  onGenSeedChange: (s: number) => void;
  algorithm: string;
  onAlgorithmChange: (a: string) => void;
  iterations: number;
  onIterationsChange: (n: number) => void;
  temperature: number;
  onTemperatureChange: (t: number) => void;
  cooling: number;
  onCoolingChange: (c: number) => void;
  onSolve: () => void;
  onRandomize: () => void;
  solving: boolean;
}

export default function Controls(props: Props) {
  return (
    <div>
      <div class="section-title">Graph Source</div>
      <div class="form-group">
        <select
          class="form-select"
          value={props.source}
          onChange={(e) => props.onSourceChange((e.target as HTMLSelectElement).value as any)}
        >
          <option value="random">Random G(n,p)</option>
          <option value="instance">Preset Instance</option>
        </select>
      </div>

      {props.source === "instance" ? (
        <div class="form-group" style={{ marginTop: "0.4rem" }}>
          <label class="form-label">Instance</label>
          <select
            class="form-select"
            value={props.instanceName}
            onChange={(e) => props.onInstanceChange((e.target as HTMLSelectElement).value)}
          >
            <option value="">— select —</option>
            {props.instances.map((i) => (
              <option key={i.name} value={i.name}>
                {i.name} ({i.n}V, {i.e}E)
              </option>
            ))}
          </select>
        </div>
      ) : (
        <div class="controls-grid" style={{ marginTop: "0.4rem" }}>
          <div class="form-group">
            <label class="form-label">Nodes (N)</label>
            <input
              class="form-input"
              type="number"
              min={3}
              max={300}
              value={props.genN}
              onInput={(e) => props.onGenNChange(+(e.target as HTMLInputElement).value)}
            />
          </div>
          <div class="form-group">
            <label class="form-label">Edge prob (p)</label>
            <input
              class="form-input"
              type="number"
              min={0}
              max={1}
              step={0.01}
              value={props.genP}
              onInput={(e) => props.onGenPChange(+(e.target as HTMLInputElement).value)}
            />
          </div>
          <div class="form-group">
            <label class="form-label">Seed</label>
            <input
              class="form-input"
              type="number"
              value={props.genSeed}
              onInput={(e) => props.onGenSeedChange(+(e.target as HTMLInputElement).value)}
            />
          </div>
        </div>
      )}

      <div class="section-title">Algorithm</div>
      <div class="form-group">
        <select
          class="form-select"
          value={props.algorithm}
          onChange={(e) => props.onAlgorithmChange((e.target as HTMLSelectElement).value)}
        >
          <option value="greedy">Greedy</option>
          <option value="local_search">Local Search (SA)</option>
        </select>
      </div>

      {props.algorithm === "local_search" && (
        <div class="controls-grid" style={{ marginTop: "0.4rem" }}>
          <div class="form-group">
            <label class="form-label">Iterations</label>
            <input
              class="form-input"
              type="number"
              min={100}
              max={50000}
              step={100}
              value={props.iterations}
              onInput={(e) => props.onIterationsChange(+(e.target as HTMLInputElement).value)}
            />
          </div>
          <div class="form-group">
            <label class="form-label">Temperature</label>
            <input
              class="form-input"
              type="number"
              min={0}
              step={1}
              value={props.temperature}
              onInput={(e) => props.onTemperatureChange(+(e.target as HTMLInputElement).value)}
            />
          </div>
          <div class="form-group">
            <label class="form-label">Cooling</label>
            <input
              class="form-input"
              type="number"
              min={0.9}
              max={1}
              step={0.001}
              value={props.cooling}
              onInput={(e) => props.onCoolingChange(+(e.target as HTMLInputElement).value)}
            />
          </div>
        </div>
      )}

      <div class="btn-row">
        <button class="btn btn-primary" style={{ flex: 1 }} onClick={props.onSolve} disabled={props.solving}>
          {props.solving ? "Solving..." : "Solve"}
        </button>
        <button class="btn btn-secondary" onClick={props.onRandomize} disabled={props.solving}>
          Randomize
        </button>
      </div>

      <div style={{ marginTop: "0.75rem", fontSize: "0.72rem", color: "var(--text-muted)" }}>
        Click nodes to manually toggle them in/out of the dominating set.
      </div>
    </div>
  );
}
