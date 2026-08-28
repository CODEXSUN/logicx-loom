import { sql, type Kysely } from "kysely";
import type { LogicXLoomDatabase } from "../../database/schema.js";

const migrationKey = "loom-data.events-v1";

export async function migrateLoomDataModule(database: Kysely<LogicXLoomDatabase>) {
  await sql
    .raw(
      `CREATE TABLE IF NOT EXISTS loom_data_events (
        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        uuid VARCHAR(32) NOT NULL UNIQUE,
        payload_json MEDIUMTEXT NOT NULL,
        content_bytes INT UNSIGNED NOT NULL,
        source_ip VARCHAR(64) NOT NULL,
        user_agent VARCHAR(500) NULL,
        received_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
        INDEX loom_data_events_received (received_at, id)
      ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    )
    .execute(database);
  await database.insertInto("schema_migrations").ignore().values({ name: migrationKey }).execute();
}
