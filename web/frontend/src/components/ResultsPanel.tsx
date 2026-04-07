import type { SolveResponse, VertexStatus } from "../lib/api";

interface Props {
  result: SolveResponse | null;
  manualSet: Set<number>;
  manualStatus: VertexStatus[] | null;
}

function TraceChart({ trace }: { trace: number[] }) {
  if (trace.length < 2) return null;
  const w = 250, h = 60, pad = 2;
  const max = Math.max(...trace);
  const min = Math.min(...trace);
  const range = max - min || 1;
  const points = trace
    .map((v, i) => {
      const x = pad + (i / (trace.length - 1)) * (w - 2 * pad);
      const y = pad + (1 - (v - min) / range) * (h - 2 * pad);
      return `${x},${y}`;
    })
    .join(" ");

  return (
    <div class="trace-chart">
      <div class="section-title">Set Size Trace</div>
      <svg viewBox={`0 0 ${w} ${h}`} style={{ background: "var(--bg-card)", borderRadius: "var(--radius-sm)", border: "1px solid var(--border)" }}>
        <polyline points={points} fill="none" stroke="var(--accent)" stroke-width="1.5" />
      </svg>
    </div>
  );
}

export default function ResultsPanel({ result, manualSet, manualStatus }: Props) {
  const status = manualStatus ?? result?.vertex_status ?? null;
  const setSize = result?.size ?? manualSet.size;
  const satisfied = status ? status.filter((s) => s.satisfied).length : 0;
  const total = status?.length ?? 0;
  const allSatisfied = status ? satisfied === total : false;

  if (!status && !result) {
    return (
      <div class="empty-state" style={{ fontSize: "0.82rem" }}>
        <div style={{ fontSize: "1.5rem" }}>🔍</div>
        <div>Click <b>Solve</b> or toggle nodes manually</div>
      </div>
    );
  }

  return (
    <div>
      <div class="section-title">Results</div>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-value">{setSize}</div>
          <div class="stat-label">|D| Size</div>
        </div>
        <div class="stat-card">
          <div class="stat-value" style={{ color: allSatisfied ? "var(--success)" : "var(--danger)" }}>
            {satisfied}/{total}
          </div>
          <div class="stat-label">Satisfied</div>
        </div>
        {result && (
          <>
            <div class="stat-card">
              <div class="stat-value">{result.time_ms.toFixed(1)}<span style={{ fontSize: "0.65rem", color: "var(--text-muted)" }}>ms</span></div>
              <div class="stat-label">Time</div>
            </div>
            <div class="stat-card">
              <div class="stat-value">{result.nodes_explored}</div>
              <div class="stat-label">Explored</div>
            </div>
          </>
        )}
      </div>

      <div
        style={{
          marginTop: "0.5rem",
          padding: "0.4rem 0.6rem",
          borderRadius: "var(--radius-sm)",
          background: allSatisfied ? "rgba(34,197,94,0.1)" : "rgba(239,68,68,0.1)",
          border: `1px solid ${allSatisfied ? "rgba(34,197,94,0.3)" : "rgba(239,68,68,0.3)"}`,
          fontSize: "0.78rem",
          fontWeight: 600,
          color: allSatisfied ? "var(--success)" : "var(--danger)",
        }}
      >
        {allSatisfied ? "Valid PIDS" : "Not a valid PIDS"}
      </div>

      {result?.trace && <TraceChart trace={result.trace} />}

      {status && (
        <>
          <div class="section-title">Unsatisfied Vertices</div>
          {status.filter((s) => !s.satisfied).length === 0 ? (
            <div style={{ fontSize: "0.78rem", color: "var(--text-muted)" }}>None — all vertices satisfied</div>
          ) : (
            <div style={{ maxHeight: "200px", overflow: "auto", fontSize: "0.75rem", fontFamily: "var(--font-mono)" }}>
              {status
                .filter((s) => !s.satisfied)
                .map((s) => (
                  <div
                    key={s.id}
                    style={{
                      padding: "0.2rem 0.4rem",
                      background: "var(--bg-card)",
                      borderRadius: "var(--radius-sm)",
                      border: "1px solid var(--border)",
                      marginBottom: "0.2rem",
                    }}
                  >
                    v{s.id}: {s.dom_neighbors}/{s.needed} neighbors
                  </div>
                ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
