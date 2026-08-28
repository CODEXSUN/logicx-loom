import { lazy, Suspense, useEffect } from "react";
import { useNavigate, useRouterState } from "@tanstack/react-router";
import { LayoutDashboardIcon, MessagesSquareIcon, UserRoundIcon, UsersIcon } from "lucide-react";
import { GlobalLoader } from "@codexsun/ui/components/global-loader";
import { ApplicationLayout } from "@codexsun/ui/layouts/application-layout";
import type { SidemenuItem } from "@codexsun/ui/blocks/menu/sidemenu/sub/sidemenu-section";
import { AuthGate } from "../../shared/auth/AuthGate";
import { getToken } from "../../shared/api/platform-api";
import { markNotificationRead, useNotificationInboxQuery } from "../../modules/notification";

const Dashboard = lazy(() =>
  import("../../modules/loom-data").then((module) => ({ default: module.LoomDataWorkspace }))
);
const Messenger = lazy(() =>
  import("../../modules/messaging").then((module) => ({ default: module.MessagingWorkspace }))
);
const Users = lazy(() =>
  import("../../modules/user").then((module) => ({ default: module.UserWorkspace }))
);
const UserProfile = lazy(() =>
  import("../../modules/user").then((module) => ({ default: module.UserProfileWorkspace }))
);

type Page = "dashboard" | "identity.profile" | "identity.users" | "messaging.inbox";
type Claims = { email: string; name?: string; role?: string };

const dashboardPath = "/app/dashboard";
const profilePath = "/app/identity/profile";
const usersPath = "/app/identity/users";
const messengerPath = "/app/messaging/inbox";

export function AppDesk() {
  const navigate = useNavigate();
  const pathname = useRouterState({ select: (state) => state.location.pathname });
  const claims = readClaims();
  const canManageUsers = claims.role === "super-admin";
  const notificationInbox = useNotificationInboxQuery(Boolean(getToken()));
  const requestedPage = pageFromPath(pathname);
  const page = requestedPage === "identity.users" && !canManageUsers ? "dashboard" : requestedPage;

  useEffect(() => {
    const canonicalPath = pagePath(page);
    if (pathname !== canonicalPath) void navigate({ replace: true, to: canonicalPath });
  }, [navigate, page, pathname]);

  useEffect(() => {
    document.title = `LogicX Loom | ${pageTitle(page)}`;
  }, [page]);

  const select = (next: Page) => void navigate({ to: pagePath(next) });

  return (
    <AuthGate>
      <ApplicationLayout
        brand={{
          href: dashboardPath,
          logoSrc: "/logo/logo.svg",
          subtitle: "",
          title: "LogicX Loom"
        }}
        headerTitle={pageTitle(page)}
        menuItems={menuItems(page, canManageUsers, select)}
        onLogout={() => window.location.replace("/sa/refresh")}
        notifications={(notificationInbox.data ?? []).map((notification) => ({
          body: notification.body,
          id: String(notification.id),
          title: notification.title
        }))}
        onNotificationDismiss={(id) => void markNotificationRead(Number(id))}
        profileHref={profilePath}
        showHomeAction={false}
        showGlobalSearch={false}
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
        workspaceItems={workspaceItems(page, canManageUsers)}
      >
        <main
          className={
            page === "messaging.inbox" ? "min-h-0 w-full" : "w-full px-2 py-2 lg:px-3 lg:py-3"
          }
        >
          <Suspense fallback={<GlobalLoader />}>
            {page === "messaging.inbox" ? (
              <Messenger actorEmail={claims.email} canManageUsers={canManageUsers} />
            ) : page === "identity.profile" ? (
              <UserProfile />
            ) : page === "identity.users" ? (
              <Users actorEmail={claims.email} />
            ) : (
              <Dashboard />
            )}
          </Suspense>
        </main>
      </ApplicationLayout>
    </AuthGate>
  );
}

function menuItems(
  page: Page,
  canManageUsers: boolean,
  select: (page: Page) => void
): SidemenuItem[] {
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
    },
    ...(canManageUsers
      ? [
          {
            icon: UsersIcon,
            isActive: page === "identity.users",
            onSelect: () => select("identity.users"),
            title: "Users"
          }
        ]
      : [])
  ];
}

function workspaceItems(page: Page, canManageUsers: boolean) {
  return [
    {
      active: page === "identity.profile",
      avatar: true,
      description: "Your account and Frappe credentials.",
      icon: UserRoundIcon,
      title: "Account",
      url: profilePath
    },
    {
      active: page !== "identity.profile",
      description: canManageUsers
        ? "Dashboard, messaging, and user administration."
        : "Dashboard and private business messaging.",
      icon: LayoutDashboardIcon,
      title: "Platform",
      url: dashboardPath
    }
  ];
}

function pageFromPath(pathname: string): Page {
  if (pathname === profilePath) return "identity.profile";
  if (pathname === messengerPath) return "messaging.inbox";
  if (pathname === usersPath) return "identity.users";
  return "dashboard";
}

function pagePath(page: Page) {
  if (page === "identity.profile") return profilePath;
  if (page === "messaging.inbox") return messengerPath;
  if (page === "identity.users") return usersPath;
  return dashboardPath;
}

function pageTitle(page: Page) {
  if (page === "identity.profile") return "Account";
  if (page === "messaging.inbox") return "Messenger";
  if (page === "identity.users") return "Users";
  return "Dashboard";
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
