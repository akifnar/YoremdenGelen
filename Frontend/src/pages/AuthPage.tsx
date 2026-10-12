import { useEffect, useRef, useState } from "react";
import type { FormEvent } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import ActionButton from "../components/ActionButton";

type AuthPageProps = { mode: "login" | "register" };

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (options: {
            client_id: string;
            callback: (response: { credential: string }) => void;
          }) => void;
          renderButton: (
            element: HTMLElement,
            options: { theme: string; size: string; width: number },
          ) => void;
        };
      };
    };
  }
}

function AuthPage({ mode }: AuthPageProps) {
  const isRegister = mode === "register";
  const navigate = useNavigate();
  const location = useLocation();
  const requestedReturnTo = new URLSearchParams(location.search).get(
    "returnTo",
  );
  const returnTo =
    requestedReturnTo?.startsWith("/") && !requestedReturnTo.startsWith("//")
      ? requestedReturnTo
      : "/";
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [busy, setBusy] = useState(false);
  const [passwordVisible, setPasswordVisible] = useState(false);
  const googleButton = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const clientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
    if (!clientId || !googleButton.current) return;
    const initializeGoogle = () => {
      window.google?.accounts.id.initialize({
        client_id: clientId,
        callback: ({ credential }) => {
          setBusy(true);
          void fetch("/api/auth/google", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ credential }),
          })
            .then(async (response) => {
              const result = await response.json();
              if (!response.ok)
                throw new Error(
                  result.errors?.join(", ") || "Google ile giriş başarısız.",
                );
              localStorage.setItem("auth-user", JSON.stringify(result.user));
              window.dispatchEvent(new Event("auth-state-changed"));
              navigate(returnTo, { replace: true });
            })
            .catch((requestError: unknown) => {
              setError(
                requestError instanceof Error
                  ? requestError.message
                  : "Google ile giriş başarısız.",
              );
            })
            .finally(() => setBusy(false));
        },
      });
      if (googleButton.current)
        window.google?.accounts.id.renderButton(googleButton.current, {
          theme: "outline",
          size: "large",
          width: 360,
        });
    };
    if (window.google) {
      initializeGoogle();
      return;
    }
    const script = document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client";
    script.async = true;
    script.onload = initializeGoogle;
    document.head.appendChild(script);
    return () => {
      script.onload = null;
    };
  }, [navigate, returnTo]);

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    setNotice("");
    setBusy(true);
    const formData = new FormData(event.currentTarget);
    const payload: Record<string, string> = {
      email: String(formData.get("email") || ""),
      password: String(formData.get("password") || ""),
    };
    payload.remember_me = String(formData.get("remember_me") === "on");
    if (isRegister) payload.name = String(formData.get("name") || "");
    try {
      const response = await fetch(
        `/api/auth/${isRegister ? "register" : "login"}`,
        {
          method: "POST",
          credentials: "same-origin",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ user: payload }),
        },
      );
      const result = await response.json();
      if (!response.ok)
        throw new Error(result.errors?.join(", ") || "İşlem tamamlanamadı.");
      localStorage.setItem("auth-user", JSON.stringify(result.user));
      window.dispatchEvent(new Event("auth-state-changed"));
      navigate(returnTo, { replace: true });
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "İşlem tamamlanamadı.",
      );
    } finally {
      setBusy(false);
    }
  };

  if (isRegister && localStorage.getItem("auth-user")) {
    return <Navigate to="/" replace />;
  }

  return (
    <main className="mx-auto w-full max-w-md px-5 py-12">
      <h1 className="text-2xl font-semibold">
        {isRegister ? "Hesap oluştur" : "Giriş yap"}
      </h1>
      <form onSubmit={(event) => void submit(event)} className="mt-6 space-y-4">
        {isRegister && (
          <label className="block text-sm">
            Ad soyad
            <input
              name="name"
              required
              className="mt-1 block w-full border border-stone-300 px-3 py-3"
            />
          </label>
        )}
        <label className="block text-sm">
          E-posta
          <input
            type="email"
            name="email"
            required
            autoComplete="email"
            className="mt-1 block w-full border border-stone-300 px-3 py-3"
          />
        </label>
        <div className="block text-sm">
          <label htmlFor="auth-password">Şifre</label>
          <div className="mt-1 flex border border-stone-300">
            <input
              id="auth-password"
              type={passwordVisible ? "text" : "password"}
              name="password"
              required
              minLength={8}
              autoComplete={isRegister ? "new-password" : "current-password"}
              className="min-w-0 flex-1 px-3 py-3 outline-none"
            />
            <ActionButton
              type="button"
              variant="quiet"
              size="icon"
              aria-label={passwordVisible ? "Şifreyi gizle" : "Şifreyi göster"}
              aria-pressed={passwordVisible}
              onPointerDown={(event) => {
                event.preventDefault();
                setPasswordVisible(true);
              }}
              onPointerUp={() => setPasswordVisible(false)}
              onPointerLeave={() => setPasswordVisible(false)}
              onPointerCancel={() => setPasswordVisible(false)}
              onKeyDown={(event) => {
                if (event.key === " " || event.key === "Enter") {
                  event.preventDefault();
                  setPasswordVisible(true);
                }
              }}
              onKeyUp={() => setPasswordVisible(false)}
              onBlur={() => setPasswordVisible(false)}
              className="border-0 px-3 text-lg text-stone-500 hover:bg-stone-100"
            >
              <span aria-hidden="true">◉</span>
            </ActionButton>
          </div>
        </div>
        <label className="flex items-center gap-2 text-sm text-stone-700">
          <input
            type="checkbox"
            name="remember_me"
            className="h-4 w-4 accent-stone-900"
          />
          Beni hatırla
        </label>
        <ActionButton
          type="submit"
          variant="primary"
          size="lg"
          disabled={busy}
          className="w-full border-stone-900 bg-stone-900 hover:border-stone-700 hover:bg-stone-700"
        >
          {busy ? "İşleniyor…" : isRegister ? "Kayıt ol" : "Giriş yap"}
        </ActionButton>
      </form>
      <div
        ref={googleButton}
        className="mt-3 flex min-h-10 justify-center"
        aria-label="Google ile devam et"
      />
      {!import.meta.env.VITE_GOOGLE_CLIENT_ID && (
        <p className="mt-2 text-center text-xs text-stone-500">
          Google girişi için VITE_GOOGLE_CLIENT_ID ayarlanmalıdır.
        </p>
      )}
      {error && (
        <p role="alert" className="mt-4 text-sm text-red-700">
          {error}
        </p>
      )}
      {notice && (
        <p role="status" className="mt-4 text-sm text-emerald-800">
          {notice}
        </p>
      )}
      <p className="mt-6 text-sm text-stone-600">
        {isRegister ? "Zaten hesabın var mı?" : "Hesabın yok mu?"}{" "}
        <Link
          className="font-semibold underline"
          to={isRegister ? "/login" : "/register"}
        >
          {isRegister ? "Giriş yap" : "Kayıt ol"}
        </Link>
      </p>
    </main>
  );
}

export default AuthPage;
