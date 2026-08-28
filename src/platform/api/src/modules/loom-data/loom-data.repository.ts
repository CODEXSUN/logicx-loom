import { randomUUID } from "node:crypto";
import type { Kysely } from "kysely";
import type { LogicXLoomDatabase } from "../../database/schema.js";
import type { JsonValue, LoomDataEvent, LoomDataPage } from "./loom-data.types.js";

export class LoomDataRepository {
  constructor(private readonly database: Kysely<LogicXLoomDatabase>) {}

  async create(input: {
    payload: JsonValue;
    sourceIp: string;
    userAgent: string | null;
  }): Promise<LoomDataEvent> {
    const payloadJson = JSON.stringify(input.payload);
    const result = await this.database
      .insertInto("loom_data_events")
      .values({
        content_bytes: Buffer.byteLength(payloadJson, "utf8"),
        payload_json: payloadJson,
        source_ip: input.sourceIp,
        user_agent: input.userAgent,
        uuid: randomUUID().replaceAll("-", "")
      })
      .executeTakeFirstOrThrow();
    return this.byId(Number(result.insertId));
  }

  async page(limit: number, beforeId?: number): Promise<LoomDataPage> {
    let query = this.database
      .selectFrom("loom_data_events")
      .selectAll()
      .orderBy("id", "desc")
      .limit(limit + 1);
    if (beforeId) query = query.where("id", "<", beforeId);
    const rows = await query.execute();
    const hasMore = rows.length > limit;
    const items = rows.slice(0, limit).map(mapEvent);
    return { items, nextBeforeId: hasMore ? (items.at(-1)?.id ?? null) : null };
  }

  private async byId(id: number): Promise<LoomDataEvent> {
    const row = await this.database
      .selectFrom("loom_data_events")
      .selectAll()
      .where("id", "=", id)
      .executeTakeFirstOrThrow();
    return mapEvent(row);
  }
}

function mapEvent(row: {
  content_bytes: number;
  id: number;
  payload_json: string;
  received_at: Date;
  source_ip: string;
  user_agent: string | null;
  uuid: string;
}): LoomDataEvent {
  return {
    contentBytes: row.content_bytes,
    id: row.id,
    payload: JSON.parse(row.payload_json) as JsonValue,
    receivedAt: row.received_at.toISOString(),
    sourceIp: row.source_ip,
    userAgent: row.user_agent,
    uuid: row.uuid
  };
}
