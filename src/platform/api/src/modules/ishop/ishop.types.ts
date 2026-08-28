import type { Kysely } from "kysely";
import type { LogicXLoomDatabase } from "../../database/schema.js";
export type IshopContext = { actorUser: () => Promise<{ id: number } | undefined>; authorize: (permission: string) => Promise<void>; database: Kysely<LogicXLoomDatabase> };
