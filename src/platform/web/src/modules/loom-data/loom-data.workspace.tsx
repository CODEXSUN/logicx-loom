import { ActivityIcon, DatabaseIcon, RadioIcon } from "lucide-react";
import { Button } from "@codexsun/ui/components/button";
import { Card, CardContent } from "@codexsun/ui/components/card";
import { Skeleton } from "@codexsun/ui/components/skeleton";
import { useLoomDataQuery } from "./loom-data.hooks";
import type { LoomDataEvent } from "./loom-data.types";

export function LoomDataWorkspace() {
  const query = useLoomDataQuery();
  const events = query.data?.pages.flatMap((page) => page.items) ?? [];

  return (
    <section className="mx-auto flex w-full max-w-6xl flex-col gap-5 px-2 py-2 sm:px-4 sm:py-4">
      <header className="flex flex-wrap items-end justify-between gap-4 border-b pb-5">
        <div className="flex flex-col gap-2">
          <div className="flex items-center gap-2 text-sm font-semibold text-primary">
            <RadioIcon className="size-4" /> Live machine feed
          </div>
          <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">Loom JSON data</h1>
          <p className="max-w-2xl text-sm leading-6 text-muted-foreground">
            Every JSON payload sent to https://log.logicx.in/loomdata is stored unchanged and shown
            newest first.
          </p>
        </div>
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <DatabaseIcon className="size-4" /> {events.length} loaded
        </div>
      </header>

      {query.isLoading ? <EventSkeleton /> : null}
      {query.isError ? (
        <Card className="border-destructive/40 bg-destructive/5">
          <CardContent className="p-4 text-sm text-destructive">
            {query.error instanceof Error
              ? query.error.message
              : "Machine data could not be loaded."}
          </CardContent>
        </Card>
      ) : null}
      {!query.isLoading && !query.isError && events.length === 0 ? (
        <div className="grid min-h-64 place-items-center border-y py-12 text-center">
          <div className="flex max-w-md flex-col items-center gap-3">
            <ActivityIcon className="size-8 text-muted-foreground" />
            <h2 className="text-lg font-semibold">Waiting for the first machine payload</h2>
            <p className="text-sm leading-6 text-muted-foreground">
              Send JSON with an HTTP POST request to https://log.logicx.in/loomdata.
            </p>
          </div>
        </div>
      ) : null}

      <div className="flex flex-col gap-3">
        {events.map((event) => (
          <EventCard event={event} key={event.id} />
        ))}
      </div>

      {query.hasNextPage ? (
        <Button
          className="self-center"
          disabled={query.isFetchingNextPage}
          onClick={() => void query.fetchNextPage()}
          type="button"
          variant="outline"
        >
          {query.isFetchingNextPage ? "Loading…" : "Load older JSON"}
        </Button>
      ) : null}
    </section>
  );
}

function EventCard({ event }: { event: LoomDataEvent }) {
  return (
    <article className="overflow-hidden rounded-lg border bg-background">
      <header className="flex flex-wrap items-center gap-x-5 gap-y-1 border-b border-primary bg-primary px-4 py-3 text-primary-foreground">
        <strong className="font-mono text-sm">#{event.id}</strong>
        <time className="text-sm text-primary-foreground/80" dateTime={event.receivedAt}>
          {new Date(event.receivedAt).toLocaleString()}
        </time>
        <span className="text-sm text-primary-foreground/80">{formatBytes(event.contentBytes)}</span>
        <span className="ml-auto font-mono text-xs text-primary-foreground/80">{event.sourceIp}</span>
      </header>
      <pre className="overflow-x-auto whitespace-pre-wrap break-words bg-white px-4 py-4 text-[13px] leading-6 text-slate-800">
        {JSON.stringify(event.payload, null, 2)}
      </pre>
    </article>
  );
}

function EventSkeleton() {
  return (
    <div className="flex flex-col gap-3">
      {Array.from({ length: 4 }, (_, index) => (
        <Skeleton className="h-40 w-full" key={index} />
      ))}
    </div>
  );
}

function formatBytes(bytes: number) {
  if (bytes < 1024) return `${bytes} B`;
  return `${(bytes / 1024).toFixed(bytes < 10_240 ? 1 : 0)} KB`;
}
