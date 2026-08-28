export const standardDeskPath = "/app/dashboard";

export function canAccessAdministratorSettings(role: string | undefined) {
  return role === "super-admin";
}

export function applicationEntryPath(_role: string | undefined) {
  return standardDeskPath;
}
