import { lazy, Suspense, useEffect } from "react";
import { useNavigate, useRouterState } from "@tanstack/react-router";
import { LayoutDashboardIcon, MessagesSquareIcon } from "lucide-react";
import { GlobalLoader } from "@codexsun/ui/components/global-loader";
import { ApplicationLayout } from "@codexsun/ui/layouts/application-layout";
import type { SidemenuItem } from "@codexsun/ui/blocks/menu/sidemenu/sub/sidemenu-section";
import { AuthGate } from "../../shared/auth/AuthGate";
import { getToken } from "../../shared/api/platform-api";

const Dashboard = lazy(() =>
  import("../../modules/loom-data").then((module) => ({ default: module.LoomDataWorkspace }))
);
const Messenger = lazy(() =>
  import("../../modules/messaging").then((module) => ({ default: module.MessagingWorkspace }))
);

type Page = "dashboard" | "messaging.inbox";

type Claims = {
  email: string;
  name?: string;
};

const dashboardPath = "/app/dashboard";
const messengerPath = "/app/messaging/inbox";

export function AppDesk() {
  const navigate = useNavigate();
  const pathname = useRouterState({ select: (state) => state.location.pathname });
  const claims = readClaims();
  const page = pageFromPath(pathname);

  useEffect(() => {
    const canonicalPath = page === "messaging.inbox" ? messengerPath : dashboardPath;
    if (pathname !== canonicalPath) void navigate({ replace: true, to: canonicalPath });
  }, [navigate, page, pathname]);

  useEffect(() => {
    document.title = `LogicX Loom | ${page === "messaging.inbox" ? "Messenger" : "Dashboard"}`;
  }, [page]);

  const select = (next: Page) => {
    void navigate({ to: next === "messaging.inbox" ? messengerPath : dashboardPath });
  };

  return (
    <AuthGate>
      <ApplicationLayout
        brand={{ href: dashboardPath, logoSrc: "/logo/logo.svg", subtitle: "", title: "LogicX Loom" }}
        headerTitle={page === "messaging.inbox" ? "Messenger" : "Dashboard"}
        menuItems={menuItems(page, select)}
        onLogout={() => window.location.replace("/sa/refresh")}
        profileHref={dashboardPath}
        showHomeAction={false}
        showAppLauncher={false}
        showGlobalSearch={false}
        showNotifications={false}
        showPageTitle={false}
        showSidebarUser={false}
        subtitle={null}
        title={null}
        user={{
          email: claims.email,
          fallback: initials(claims.name ?? claims.email),
          name: claims.name ?? claims.email
        }}
        versionLabel={`v ${__APP_VERSION__}`}
        workspaceItems={[
          {
            active: page === "dashboard",
            description: "Your LogicX Loom overview.",
            icon: LayoutDashboardIcon,
            title: "Dashboard",
            url: dashboardPath
          },
          {
            active: page === "messaging.inbox",
            description: "Private business conversations.",
            icon: MessagesSquareIcon,
            title: "Messenger",
            url: messengerPath
          }
        ]}
      >
        <main className="w-full px-2 py-2 lg:px-3 lg:py-3">
          <Suspense fallback={<GlobalLoader />}>
            {page === "messaging.inbox" ? (
              <Messenger actorEmail={claims.email} />
            ) : (
              <Dashboard />
            )}
          </Suspense>
        </main>
      </ApplicationLayout>
    </AuthGate>
  );
}

function menuItems(page: Page, select: (page: Page) => void): SidemenuItem[] {
  return [
    {
      icon: LayoutDashboardIcon,
      isActive: page === "dashboard",
      onSelect: () => select("dashboard"),
      title: "Dashboard"
    },
    {
      icon: MessagesSquareIcon,
      isActive: page === "messaging.inbox",
      onSelect: () => select("messaging.inbox"),
      title: "Messenger"
    }
  ];
}

function pageFromPath(pathname: string): Page {
  return pathname === messengerPath ? "messaging.inbox" : "dashboard";
}

function readClaims(): Claims {
  const token = getToken();
  if (!token) return { email: "" };
  try {
    const encoded = token.split(".")[1] ?? "";
    return JSON.parse(atob(encoded.replace(/-/g, "+").replace(/_/g, "/"))) as Claims;
  } catch {
    return { email: "" };
  }
}

function initials(value: string) {
  return value
    .trim()
    .split(/\s+/u)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");
}
