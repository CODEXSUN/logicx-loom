import { timingSafeEqual } from "node:crypto";
import type { FastifyInstance, FastifyRequest } from "fastify";
import { AppError } from "@codexsun/framework/errors";
import { registerContractRoute } from "@codexsun/framework/http";
import { z } from "zod";
import { identityContext } from "../../auth/identity-context.js";
import { getLogicXLoomDatabase } from "../../database/logicx-loom-database.js";
import { env } from "../../env.js";
import { LoomDataRepository } from "./loom-data.repository.js";

const jsonValue = z.json();
const event = z.object({
  contentBytes: z.number().int().nonnegative(),
  id: z.number().int().positive(),
  payload: jsonValue,
  receivedAt: z.iso.datetime(),
  sourceIp: z.string(),
  userAgent: z.string().nullable(),
  uuid: z.string()
});
const page = z.object({ items: z.array(event), nextBeforeId: z.number().int().positive().nullable() });
const query = z.object({
  beforeId: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50)
});

export function registerLoomDataRoutes(app: FastifyInstance) {
  const repository = new LoomDataRepository(getLogicXLoomDatabase());
  registerContractRoute(app, {
    bodyLimit: 1024 * 1024,
    method: "POST",
    url: "/loomdata",
    schemas: { body: jsonValue, response: event },
    handler: ({ body, request }) => {
      authorizeMachine(request);
      return repository.create({
        payload: body,
        sourceIp: request.ip,
        userAgent: request.headers["user-agent"] ?? null
      });
    }
  });
  registerContractRoute(app, {
    method: "GET",
    url: "/loomdata/events",
    schemas: { querystring: query, response: page },
    handler: ({ query: input, request }) => {
      identityContext(request);
      return repository.page(input.limit, input.beforeId);
    }
  });
}

function authorizeMachine(request: FastifyRequest) {
  if (!env.LOGICX_LOOM_INGEST_KEY) return;
  const provided = request.headers["x-loom-key"];
  if (typeof provided !== "string" || !sameSecret(provided, env.LOGICX_LOOM_INGEST_KEY)) {
    throw AppError.unauthorized("The Loom machine key is invalid.");
  }
}

function sameSecret(left: string, right: string) {
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return leftBuffer.length === rightBuffer.length && timingSafeEqual(leftBuffer, rightBuffer);
}
