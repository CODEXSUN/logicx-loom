import type { FastifyInstance } from "fastify";
import { registerContractRoute } from "@codexsun/framework/http";
import { z } from "zod";
import { identityContext } from "../../auth/identity-context.js";
import { getLogicXLoomDatabase } from "../../database/logicx-loom-database.js";
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
