import { useEffect, useRef } from "preact/hooks";
import {
  forceSimulation,
  forceLink,
  forceManyBody,
  forceCenter,
  forceCollide,
  type SimulationNodeDatum,
  type SimulationLinkDatum,
} from "d3-force";
import { select } from "d3-selection";
import { drag } from "d3-drag";
import { zoom, zoomIdentity } from "d3-zoom";
import type { GraphData } from "../App";
import type { VertexStatus } from "../lib/api";

interface Props {
  graphData: GraphData;
  vertexStatus: VertexStatus[] | null;
  manualSet: Set<number>;
  onNodeClick: (id: number) => void;
}

interface GNode extends SimulationNodeDatum {
  id: number;
  degree: number;
}

interface GLink extends SimulationLinkDatum<GNode> {
  source: number | GNode;
  target: number | GNode;
}

function nodeColor(id: number, status: VertexStatus[] | null, manualSet: Set<number>): string {
  if (status) {
    const s = status[id];
    if (s.in_set) return "#22c55e";
    return s.satisfied ? "#3b82f6" : "#ef4444";
  }
  return manualSet.has(id) ? "#22c55e" : "#64748b";
}

function nodeRadius(degree: number, n: number): number {
  const base = n > 100 ? 3 : n > 50 ? 4 : 5;
  return base + Math.min(degree / 3, 6);
}

export default function ForceGraph({ graphData, vertexStatus, manualSet, onNodeClick }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const svgRef = useRef<SVGSVGElement>(null);
  const simRef = useRef<ReturnType<typeof forceSimulation<GNode>> | null>(null);

  useEffect(() => {
    if (!svgRef.current || !containerRef.current) return;

    const svg = select(svgRef.current);
    svg.selectAll("*").remove();

    const rect = containerRef.current.getBoundingClientRect();
    const width = rect.width || 600;
    const height = rect.height || 600;

    const nodes: GNode[] = Array.from({ length: graphData.n }, (_, i) => ({
      id: i,
      degree: graphData.degrees[i],
    }));

    const links: GLink[] = graphData.edges.map(([s, t]) => ({ source: s, target: t }));

    const g = svg.append("g");

    const zoomBehavior = zoom<SVGSVGElement, unknown>()
      .scaleExtent([0.2, 5])
      .on("zoom", (event) => g.attr("transform", event.transform));
    svg.call(zoomBehavior);

    const link = g
      .append("g")
      .attr("stroke", "#2a2a40")
      .attr("stroke-opacity", 0.6)
      .selectAll("line")
      .data(links)
      .join("line")
      .attr("stroke-width", 1);

    const node = g
      .append("g")
      .selectAll("circle")
      .data(nodes)
      .join("circle")
      .attr("r", (d) => nodeRadius(d.degree, graphData.n))
      .attr("fill", (d) => nodeColor(d.id, vertexStatus, manualSet))
      .attr("stroke", "#0f0f1a")
      .attr("stroke-width", 1.5)
      .attr("cursor", "pointer")
      .on("click", (event: MouseEvent, d: GNode) => {
        event.stopPropagation();
        onNodeClick(d.id);
      });

    node.append("title").text((d) => {
      const s = vertexStatus?.[d.id];
      if (s) return `Node ${d.id}: ${s.dom_neighbors}/${s.needed} dom neighbors${s.in_set ? " (in D)" : ""}`;
      return `Node ${d.id} (deg ${d.degree})`;
    });

    const dragBehavior = drag<SVGCircleElement, GNode>()
      .on("start", (event, d) => {
        if (!event.active) simRef.current?.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
      })
      .on("drag", (event, d) => {
        d.fx = event.x;
        d.fy = event.y;
      })
      .on("end", (event, d) => {
        if (!event.active) simRef.current?.alphaTarget(0);
        d.fx = null;
        d.fy = null;
      });

    node.call(dragBehavior as any);

    const sim = forceSimulation(nodes)
      .force("link", forceLink(links).id((d: any) => d.id).distance(graphData.n > 100 ? 20 : 40))
      .force("charge", forceManyBody().strength(graphData.n > 100 ? -30 : -80))
      .force("center", forceCenter(width / 2, height / 2))
      .force("collide", forceCollide(graphData.n > 100 ? 4 : 8))
      .on("tick", () => {
        link
          .attr("x1", (d: any) => d.source.x)
          .attr("y1", (d: any) => d.source.y)
          .attr("x2", (d: any) => d.target.x)
          .attr("y2", (d: any) => d.target.y);
        node.attr("cx", (d: any) => d.x).attr("cy", (d: any) => d.y);
      });

    simRef.current = sim;

    return () => { sim.stop(); };
  }, [graphData]);

  useEffect(() => {
    if (!svgRef.current) return;
    select(svgRef.current)
      .selectAll<SVGCircleElement, GNode>("circle")
      .attr("fill", (d) => nodeColor(d.id, vertexStatus, manualSet))
      .select("title")
      .text((d) => {
        const s = vertexStatus?.[d.id];
        if (s) return `Node ${d.id}: ${s.dom_neighbors}/${s.needed} dom neighbors${s.in_set ? " (in D)" : ""}`;
        return `Node ${d.id} (deg ${d.degree})`;
      });
  }, [vertexStatus, manualSet]);

  return (
    <div ref={containerRef} style={{ width: "100%", height: "100%", position: "relative" }}>
      <svg ref={svgRef} style={{ width: "100%", height: "100%", display: "block" }} />
    </div>
  );
}
