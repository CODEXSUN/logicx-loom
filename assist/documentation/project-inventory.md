# Project Inventory

## Applications

- `src/platform/api`: Fastify API and composition root.
- `src/platform/web`: React application with one login and one desk.
- `src/mobile`: Ionic React and Capacitor mobile-first client. It owns mobile UI composition and
  uses shared LogicX Loom authentication and API contracts through native runtime adapters.
- `apps/logicx_loom_flutter`: connected Flutter client for Login, Dashboard Loom data, and
  Messenger. It also checks the portal APK release manifest during startup. It uses the LogicX Loom
  HTTP and WebSocket contracts and does not share Ionic UI code.
- `storage/mobile/release`: portal-hosted Android APK and update manifest.
- `KMP-Mobile`: preserved Kotlin Multiplatform LogicX Loom client for future native-only shared logic.

## API Modules

- `user`
- `role`
- `permission`
- `user-role`
- `role-permission`
- `frappe`
- `notification`
- `crm`
- `hr`
- `estimate`
- `quotation`
- `ishop`
- `honey`
- `messaging`
- `loom-data`

Honey includes the system-administrator global availability control for TEMA chat and mascot
surfaces, plus separate web and mobile pet visibility controls. The shared responsive side menu
contains the current device's personal pet toggle.

## Shared Dependencies

- `packages/framework`: repository-owned backend infrastructure and public module contracts.
- `packages/ui`: repository-owned React components, layouts, and workspace primitives.

No parent-folder or sibling product repository is part of the LogicX Loom install, build, or runtime.

## Web Documentation

- `src/platform/web/src/modules/docs`: authenticated documentation index and article renderer.
- `src/platform/web/src/modules/docs/content`: repository-owned MDX guides compiled during the web build.
- `assist/documentation/CHANGELOG.md`: the single changelog source rendered directly in Docs.

## Generated Layout

- `node_modules`: the only dependency installation directory.
- `dist/packages/framework`: compiled Framework runtime.
- `dist/platform/api`: compiled API runtime.
- `dist/platform/web`: production web bundle.
- `dist/mobile/web`: Capacitor web bundle copied into the native Android and iOS projects.

Workspace-local `node_modules`, `dist`, and `dist-types` directories are prohibited.
