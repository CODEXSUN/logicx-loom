import { apiGet } from "../../shared/api/platform-api";
import type { LoomDataPage } from "./loom-data.types";

export function listLoomData(beforeId?: number) {
  const query = new URLSearchParams({ limit: "50" });
  if (beforeId) query.set("beforeId", String(beforeId));
  return apiGet<LoomDataPage>(`/loomdata/events?${query}`);
}
