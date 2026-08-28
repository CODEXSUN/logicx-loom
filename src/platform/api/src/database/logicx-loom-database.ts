import { existsSync, writeFileSync } from "node:fs";
import { createConnection } from "mysql2/promise";
import { createPool, type Pool, type PoolOptions } from "mysql2";
import { Kysely, MysqlDialect, sql } from "kysely";
import { env } from "../env.js";
import { migratePermissionModule } from "../modules/permission/permission.migration.js";
import { seedPermissionModule } from "../modules/permission/permission.seed.js";
import { migrateRoleModule } from "../modules/role/role.migration.js";
import { seedRoleModule } from "../modules/role/role.seed.js";
import { migrateUserModule } from "../modules/user/user.migration.js";
import { seedUserModule } from "../modules/user/user.seed.js";
import { migrateUserRoleModule } from "../modules/user-role/user-role.migration.js";
import { seedUserRoleModule } from "../modules/user-role/user-role.seed.js";
import { migrateRolePermissionModule } from "../modules/role-permission/role-permission.migration.js";
import { seedRolePermissionModule } from "../modules/role-permission/role-permission.seed.js";
import { migrateNotificationModule } from "../modules/notification/notification.migration.js";
import { migrateHoneyModule } from "../modules/honey/honey.migration.js";
import { migrateMessagingModule } from "../modules/messaging/messaging.migration.js";
import { migrateLoomDataModule } from "../modules/loom-data/loom-data.migration.js";
import { assertDatabaseName, quoteIdentifier } from "./database-utils.js";
import type { LogicXLoomDatabase } from "./schema.js";

let database: Kysely<LogicXLoomDatabase> | null = null;
let bootstrapped = false;

export const logicxLoomMigrationOrder = Object.freeze([
  "identity.role",
  "identity.permission",
  "identity.user",
  "identity.user-role",
  "identity.role-permission",
  "notification.inbox",
  "ai.honey",
  "messaging",
  "loom-data.ingest"
]);

export const logicxLoomSeedOrder = Object.freeze([
  "identity.role",
  "identity.permission",
  "identity.user",
  "identity.user-role",
  "identity.role-permission"
]);

export function logicxLoomDatabaseName() {
  return assertDatabaseName(env.DB_NAME, "LogicX Loom database name");
}

export function logicxLoomDatabaseConfig() {
  return {
    database: logicxLoomDatabaseName(),
    host: env.DB_HOST,
    password: env.DB_PASSWORD,
    port: env.DB_PORT,
    user: env.DB_USER
  };
}

export function getLogicXLoomDatabase() {
  if (!database) {
    database = new Kysely<LogicXLoomDatabase>({
      dialect: new MysqlDialect({
        pool: createUtcPool()
      })
    });
  }
  return database;
}

function createUtcPool(): Pool {
  const pool = createPool({
    ...logicxLoomDatabaseConfig(),
    connectionLimit: 10,
    timezone: "Z"
  } satisfies PoolOptions);
  // DATETIME has no timezone. Keep database-generated and JavaScript dates on
  // the same UTC clock before converting them to the viewer's local timezone.
  pool.on("connection", (connection) => {
    connection.query("SET time_zone = '+00:00'");
  });
  return pool;
}

export async function bootstrapLogicXLoomDatabase() {
  if (bootstrapped || process.env.LOGICX_LOOM_DEV_SKIP_DB === "1") return;
  if (env.LOGICX_LOOM_DB_FRESH_ON_START === "1") {
    const sessionFile = process.env.LOGICX_LOOM_DB_FRESH_SESSION_FILE;
    if (!sessionFile || !existsSync(sessionFile)) {
      await resetLogicXLoomDatabase();
      if (sessionFile) writeFileSync(sessionFile, new Date().toISOString(), "utf8");
      return;
    }
  }
  await createLogicXLoomDatabase();
  await migrateLogicXLoomDatabase();
  await seedLogicXLoomDatabase();
  bootstrapped = true;
  console.info(`[database] LogicX Loom database ready: "${logicxLoomDatabaseName()}"`);
}

export async function createLogicXLoomDatabase() {
  const connection = await createConnection({
    host: env.DB_HOST,
    password: env.DB_PASSWORD,
    port: env.DB_PORT,
    user: env.DB_USER,
    timezone: "Z"
  });
  try {
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS ${quoteIdentifier(logicxLoomDatabaseName())} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    );
  } finally {
    await connection.end();
  }
}

export async function migrateLogicXLoomDatabase() {
  const db = getLogicXLoomDatabase();
  await sql
    .raw(
      `CREATE TABLE IF NOT EXISTS schema_migrations (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(160) NOT NULL UNIQUE,
        applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
      ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    )
    .execute(db);
  await migrateRoleModule(db);
  await migratePermissionModule(db);
  await migrateUserModule(db);
  await migrateUserRoleModule(db);
  await migrateRolePermissionModule(db);
  await migrateNotificationModule(db);
  await migrateHoneyModule(db);
  await migrateMessagingModule(db);
  await migrateLoomDataModule(db);
}

export async function seedLogicXLoomDatabase() {
  const db = getLogicXLoomDatabase();
  await seedRoleModule(db);
  await seedPermissionModule(db);
  await seedUserModule(db);
  await seedUserRoleModule(db);
  await seedRolePermissionModule(db);
}

export async function closeLogicXLoomDatabase() {
  if (database) await database.destroy();
  database = null;
  bootstrapped = false;
}

export async function resetLogicXLoomDatabase() {
  assertDestructiveDatabaseAction();
  await closeLogicXLoomDatabase();
  const connection = await createConnection({
    host: env.DB_HOST,
    password: env.DB_PASSWORD,
    port: env.DB_PORT,
    user: env.DB_USER,
    timezone: "Z"
  });
  try {
    await connection.query(`DROP DATABASE IF EXISTS ${quoteIdentifier(logicxLoomDatabaseName())}`);
  } finally {
    await connection.end();
  }
  await createLogicXLoomDatabase();
  await migrateLogicXLoomDatabase();
  await seedLogicXLoomDatabase();
  bootstrapped = true;
}

function assertDestructiveDatabaseAction() {
  if (env.LOGICX_LOOM_DB_RESET_CONFIRM !== "DROP_DATABASE") {
    throw new Error(
      "Set LOGICX_LOOM_DB_RESET_CONFIRM=DROP_DATABASE to reset the LogicX Loom database."
    );
  }
  if (env.NODE_ENV === "production" && env.LOGICX_LOOM_ALLOW_PRODUCTION_DB_RESET !== "1") {
    throw new Error("Production database reset is disabled.");
  }
}
