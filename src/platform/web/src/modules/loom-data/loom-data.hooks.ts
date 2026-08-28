import { type InfiniteData, useInfiniteQuery } from "@tanstack/react-query";
import { listLoomData } from "./loom-data.services";
import type { LoomDataPage } from "./loom-data.types";

const queryKey = ["loom-data", "events"] as const;

export function useLoomDataQuery() {
  return useInfiniteQuery<
    LoomDataPage,
    Error,
    InfiniteData<LoomDataPage>,
    typeof queryKey,
    number | undefined
  >({
    getNextPageParam: (page) => page.nextBeforeId ?? undefined,
    initialPageParam: undefined as number | undefined,
    queryFn: ({ pageParam }) => listLoomData(pageParam),
    queryKey,
    refetchInterval: 3_000,
    refetchIntervalInBackground: true
  });
}
