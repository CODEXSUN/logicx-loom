export type JsonValue = boolean | null | number | string | JsonValue[] | { [key: string]: JsonValue };

export type LoomDataEvent = {
  contentBytes: number;
  id: number;
  payload: JsonValue;
  receivedAt: string;
  sourceIp: string;
  userAgent: string | null;
  uuid: string;
};

export type LoomDataPage = {
  items: LoomDataEvent[];
  nextBeforeId: number | null;
};
