import {
  forceSimulation,
  forceLink,
  forceManyBody,
  forceCenter,
  forceCollide,
} from "d3-force";
import { select } from "d3-selection";
import { drag } from "d3-drag";
import { zoom } from "d3-zoom";

let sim = null;

function buildStatusMap(statusList) {
  if (!statusList) return null;
  const map = {};
  for (const s of statusList) map[s.id] = s;
  return map;
}

function nodeColor(id, statusMap, manualSetArr) {
  const ms = new Set(manualSetArr);
  if (statusMap && statusMap[id]) {
    const s = statusMap[id];
    if (s.inSet) return "#22c55e";
    return s.satisfied ? "#3b82f6" : "#ef4444";
  }
  return ms.has(id) ? "#22c55e" : "#64748b";
}

function nodeRadius(degree, n) {
  const base = n > 100 ? 3 : n > 50 ? 4 : 5;
  return base + Math.min(degree / 3, 6);
}

function titleText(d, statusMap) {
  const s = statusMap && statusMap[d.id];
  if (s)
    return `Node ${d.id}: ${s.domNeighbors}/${s.needed} dom neighbors${s.inSet ? " (in D)" : ""}`;
  return `Node ${d.id} (deg ${d.degree})`;
}

export function initForceGraph(app) {
  let currentStatusMap = null;
  let currentManualSet = [];

  app.ports.sendGraphData.subscribe(function (data) {
    const container = document.getElementById("graph-container");
    if (!container) return;

    if (sim) {
      sim.stop();
      sim = null;
    }
    container.innerHTML = "";

    const svgEl = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svgEl.style.width = "100%";
    svgEl.style.height = "100%";
    svgEl.style.display = "block";
    container.appendChild(svgEl);
    const svg = select(svgEl);

    const rect = container.getBoundingClientRect();
    const width = rect.width || 600;
    const height = rect.height || 600;

    currentStatusMap = buildStatusMap(data.vertexStatus);
    currentManualSet = data.manualSet || [];

    const nodes = Array.from({ length: data.n }, (_, i) => ({
      id: i,
      degree: data.degrees[i],
    }));

    const links = data.edges.map(([s, t]) => ({ source: s, target: t }));

    const g = svg.append("g");

    const zoomBehavior = zoom()
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
      .attr("r", (d) => nodeRadius(d.degree, data.n))
      .attr("fill", (d) => nodeColor(d.id, currentStatusMap, currentManualSet))
      .attr("stroke", "#0f0f1a")
      .attr("stroke-width", 1.5)
      .attr("cursor", "pointer")
      .on("click", (event, d) => {
        event.stopPropagation();
        app.ports.onNodeClick.send(d.id);
      });

    node.append("title").text((d) => titleText(d, currentStatusMap));

    const dragBehavior = drag()
      .on("start", (event, d) => {
        if (!event.active && sim) sim.alphaTarget(0.3).restart();
        d.fx = d.x;
        d.fy = d.y;
      })
      .on("drag", (event, d) => {
        d.fx = event.x;
        d.fy = event.y;
      })
      .on("end", (event, d) => {
        if (!event.active && sim) sim.alphaTarget(0);
        d.fx = null;
        d.fy = null;
      });

    node.call(dragBehavior);

    sim = forceSimulation(nodes)
      .force(
        "link",
        forceLink(links)
          .id((d) => d.id)
          .distance(data.n > 100 ? 20 : 40),
      )
      .force("charge", forceManyBody().strength(data.n > 100 ? -30 : -80))
      .force("center", forceCenter(width / 2, height / 2))
      .force("collide", forceCollide(data.n > 100 ? 4 : 8))
      .on("tick", () => {
        link
          .attr("x1", (d) => d.source.x)
          .attr("y1", (d) => d.source.y)
          .attr("x2", (d) => d.target.x)
          .attr("y2", (d) => d.target.y);
        node.attr("cx", (d) => d.x).attr("cy", (d) => d.y);
      });
  });

  app.ports.sendColorUpdate.subscribe(function (data) {
    const container = document.getElementById("graph-container");
    if (!container) return;
    const svg = select(container).select("svg");
    if (svg.empty()) return;

    currentStatusMap = buildStatusMap(data.vertexStatus);
    currentManualSet = data.manualSet || [];

    svg
      .selectAll("circle")
      .attr("fill", (d) => nodeColor(d.id, currentStatusMap, currentManualSet))
      .select("title")
      .text((d) => titleText(d, currentStatusMap));
  });
}
