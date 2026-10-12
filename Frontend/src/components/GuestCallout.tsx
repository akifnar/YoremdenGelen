import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

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
        <div className="mx-auto flex max-w-6xl flex-col gap-4 px-5 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-8">
          <div className="pr-8">
            <p className="font-semibold tracking-tight">
              Yöresel lezzetleri keşfetmeye hazır mısın?
            </p>
            <p className="mt-1 text-sm text-emerald-100/75">
              Hesabın varsa giriş yap, yoksa hemen aramıza katıl.
            </p>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <Link
              to="/login"
              className="border border-emerald-200 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-emerald-800 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lime-300"
            >
              Giriş yap
            </Link>
            <Link
              to="/register"
              className="bg-lime-300 px-4 py-2 text-sm font-semibold text-emerald-950 transition-colors hover:bg-lime-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lime-200"
            >
              Kayıt ol
            </Link>
          </div>
          <button
            type="button"
            aria-label="Hesap önerisini kapat"
            onClick={dismiss}
            className="absolute right-3 top-3 grid h-8 w-8 place-items-center text-xl text-emerald-100/75 transition-colors hover:text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lime-300 sm:right-[max(1rem,calc((100vw-72rem)/2))]"
          >
            ×
          </button>
        </div>
      </aside>
    </>
  );
}

export default GuestCallout;
