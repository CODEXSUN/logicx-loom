import { ArrowRight, Building2, CheckCircle2 } from "lucide-react";
import { useEffect, useState, type ReactNode } from "react";

export function LogicXLoomLandingLayout({ children }: { children: ReactNode }) {
  const [slide, setSlide] = useState(0);

  useEffect(() => {
    const timer = window.setInterval(
      () => setSlide((current) => (current + 1) % messages.length),
      4200
    );
    return () => window.clearInterval(timer);
  }, []);

  return (
    <main className="logicx-loom-login-page">
      <section className="logicx-loom-login-shell" aria-label="LogicX Loom Login">
        <div className="logicx-loom-login-story">
          <div className="logicx-loom-login-brand">
            <span className="auth-surface-mark" data-surface="app">
              <Logo />
              <span className="auth-surface-badge">
                <Building2 size={13} strokeWidth={2.25} />
              </span>
            </span>
            <span>
              <strong>LogicX Loom</strong>
              <small>Live CRM workspace</small>
            </span>
          </div>
          <div className="logicx-loom-login-slider" aria-live="polite">
            <span className="logicx-loom-login-eyebrow">
              <CheckCircle2 size={14} /> Connected to Frappe
            </span>
            <p key={messages[slide]}>{messages[slide]}</p>
            <div className="logicx-loom-login-dots" aria-hidden="true">
              {messages.map((message, index) => (
                <span className={index === slide ? "is-active" : ""} key={message} />
              ))}
            </div>
          </div>
          <p className="logicx-loom-login-footnote">
            Enquiries, estimates, and follow-up in one focused desk <ArrowRight size={14} />
          </p>
        </div>
        <div className="logicx-loom-login-panel">
          <div className="logicx-loom-login-panel-brand" aria-hidden="true">
            <Logo />
            <span>LogicX Loom</span>
          </div>
          <div className="auth-card-frame auth-card-frame-app logicx-loom-login-card-frame">
            <div className="auth-card logicx-loom-login-card">
              <header className="auth-card-header">
                <h1>Welcome back</h1>
                <p>Access LogicX Loom with your registered credentials.</p>
              </header>
              {children}
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}

function Logo() {
  return (
    <>
      <img
        className="auth-logo-image logicx-loom-auth-logo-light"
        src="/logo/logo.svg"
        alt=""
        aria-hidden="true"
      />
      <img
        className="auth-logo-image logicx-loom-auth-logo-dark"
        src="/logo/logo-dark.svg"
        alt=""
        aria-hidden="true"
      />
    </>
  );
}

const messages = [
  "See every assigned enquiry without losing the next action.",
  "Create and update estimates directly on the connected Frappe site.",
  "Keep customer follow-up clear, current, and accountable."
];
