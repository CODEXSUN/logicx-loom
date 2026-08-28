import { defineModule } from "@codexsun/framework/modules";
import type { PlatformModuleDependencies } from "../../module-dependencies.js";
import { registerLoomDataRoutes } from "./loom-data.routes.js";

export const loomDataModule = defineModule<PlatformModuleDependencies>({
  key: "loom-data.ingest",
  label: "Loom machine data",
  register: ({ app }) => registerLoomDataRoutes(app)
});
