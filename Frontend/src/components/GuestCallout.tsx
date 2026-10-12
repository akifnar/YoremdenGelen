import { useEffect, useState } from "react";

import ActionButton from "./ActionButton";

function hasAuthenticatedUser() {
  try {
    return Boolean(localStorage.getItem("auth-user"));
  } catch {
    return false;
  }
}

function wasDismissed() {
  try {
    return sessionStorage.getItem("guest-callout-dismissed") === "true";
  } catch {
    return false;
  }
}

function GuestCallout() {
  const [isAuthenticated, setIsAuthenticated] = useState(hasAuthenticatedUser);
  const [isDismissed, setIsDismissed] = useState(wasDismissed);

  useEffect(() => {
    const syncAuthentication = () => setIsAuthenticated(hasAuthenticatedUser());
    window.addEventListener("auth-state-changed", syncAuthentication);
    window.addEventListener("storage", syncAuthentication);
    return () => {
      window.removeEventListener("auth-state-changed", syncAuthentication);
      window.removeEventListener("storage", syncAuthentication);
    };
  }, []);

  if (isAuthenticated || isDismissed) return null;

  const dismiss = () => {
    setIsDismissed(true);
    try {
      sessionStorage.setItem("guest-callout-dismissed", "true");
    } catch {
      // Dismissing still works for the current page if storage is unavailable.
    }
  };

  return (
    <>
      <div aria-hidden="true" className="h-28 sm:h-24" />
      <aside
        aria-label="Hesap oluşturma önerisi"
        className="fixed inset-x-0 bottom-0 z-40 border-t border-emerald-800 bg-emerald-950 text-white shadow-[0_-8px_28px_rgba(6,36,26,0.18)]"
      >
        <div className="relative mx-auto grid w-full max-w-6xl grid-cols-1 items-center gap-4 px-5 py-4 sm:grid-cols-[minmax(0,1fr)_auto] sm:px-8">
          <div className="min-w-0 pr-9">
            <p className="font-semibold tracking-tight">
              Yöresel lezzetleri keşfetmeye hazır mısın?
            </p>
            <p className="mt-1 text-sm text-emerald-100/75">
              Hesabın varsa giriş yap, yoksa hemen aramıza katıl.
            </p>
          </div>
          <div className="guest-callout-actions grid w-full grid-cols-2 gap-2 sm:w-auto sm:pr-12">
            <ActionButton
              to="/login"
              variant="quiet"
              size="md"
              className="guest-callout-cta guest-callout-login"
            >
              Giriş yap
            </ActionButton>
            <ActionButton
              to="/register"
              variant="accent"
              size="md"
              className="guest-callout-cta guest-callout-register"
            >
              Kayıt ol
            </ActionButton>
          </div>
          <ActionButton
            type="button"
            variant="quiet"
            size="icon"
            aria-label="Hesap önerisini kapat"
            onClick={dismiss}
            className="guest-callout-close absolute right-3 top-3 sm:right-8 sm:top-1/2 sm:-translate-y-1/2"
          >
            <svg
              aria-hidden="true"
              viewBox="0 0 20 20"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.7"
              strokeLinecap="round"
              className="h-4 w-4 shrink-0"
            >
              <path d="m5 5 10 10M15 5 5 15" />
            </svg>
          </ActionButton>
        </div>
      </aside>
    </>
  );
}

export default GuestCallout;
