import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";

export default defineConfig({
  plugins: [elmPlugin()],
  server: { proxy: { "/api": "http://127.0.0.1:8084" } },
});
