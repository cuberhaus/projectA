import { Elm } from "./Main.elm";
import "./styles/theme.css";
import "./styles/app.css";
import { initForceGraph } from "./js/forceGraph.js";

const app = Elm.Main.init({
  node: document.getElementById("app"),
  flags: null,
});

initForceGraph(app);
