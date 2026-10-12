import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { CartRequestError, cartRequest, type Cart } from "../cartApi";
import ActionButton from "./ActionButton";

type AuthUser = { role: string; name?: string };

function readAuthUser(): AuthUser | null {
  try {
    return JSON.parse(
      localStorage.getItem("auth-user") || "null",
    ) as AuthUser | null;
  } catch {
    return null;
  }
}

function Header() {
  const [user, setUser] = useState<AuthUser | null>(readAuthUser);
  const [logoutError, setLogoutError] = useState("");
  const [cart, setCart] = useState<Pick<
    Cart,
    "item_count" | "subtotal"
  > | null>(null);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const syncUser = () => {
      const currentUser = readAuthUser();
      setUser(currentUser);
      if (!currentUser) setCart(null);
    };
    window.addEventListener("auth-state-changed", syncUser);
    window.addEventListener("storage", syncUser);
    return () => {
      window.removeEventListener("auth-state-changed", syncUser);
      window.removeEventListener("storage", syncUser);
    };
  }, []);

  useEffect(() => {
    if (!user) return;

    let isCurrent = true;
    const updateCart = async () => {
      try {
        const latestCart = await cartRequest("");
        if (isCurrent) {
          setCart({
            item_count: latestCart.item_count,
            subtotal: latestCart.subtotal,
          });
        }
      } catch (requestError) {
        if (!isCurrent) return;
        setCart(null);
        if (
          requestError instanceof CartRequestError &&
          requestError.status === 401
        ) {
          localStorage.removeItem("auth-user");
          setUser(null);
          window.dispatchEvent(new Event("auth-state-changed"));
        }
      }
    };
    const refreshCart = () => void updateCart();

    refreshCart();
    window.addEventListener("cart-changed", refreshCart);
    return () => {
      isCurrent = false;
      window.removeEventListener("cart-changed", refreshCart);
    };
  }, [user, location.pathname]);

  const logout = async () => {
    setLogoutError("");
    try {
      const response = await fetch("/api/auth/logout", {
        method: "DELETE",
        credentials: "same-origin",
      });
      if (!response.ok)
        throw new Error("Çıkış yapılamadı. Lütfen tekrar deneyin.");
      localStorage.removeItem("auth-user");
      setUser(null);
      setCart(null);
      window.dispatchEvent(new Event("auth-state-changed"));
      navigate("/", { replace: true });
    } catch (error) {
      setLogoutError(
        error instanceof Error ? error.message : "Çıkış yapılamadı.",
      );
    }
  };

  return (
    <header className="bg-emerald-950 text-white">
      <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-4 px-5 py-4 sm:flex-nowrap sm:py-5 sm:px-8">
        <Link
          to="/"
          className="group inline-flex shrink-0 items-center gap-3 rounded-xl focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lime-300"
        >
          <span className="grid h-11 w-11 place-items-center border border-lime-300 bg-lime-300 text-xl font-black text-emerald-950">
            Y
          </span>
          <span>
            <span className="block text-2xl font-bold tracking-tight">
              Yöremden Gelen<span className="text-lime-300">.</span>
            </span>
            <span className="mt-0.5 block text-xs tracking-wide text-emerald-100/75">
              Güzel şeyler, güzel insanlardan
            </span>
          </span>
        </Link>

        <nav
          className="ml-auto flex w-full flex-wrap items-center justify-end gap-2 text-sm sm:w-auto sm:flex-nowrap"
          aria-label="Hesap ve sepet işlemleri"
        >
          {user ? (
            <div className="flex w-auto max-w-full flex-wrap items-center justify-end gap-2">
              {user.role === "admin" && (
                <ActionButton
                  to="/admin/users"
                  variant="quiet"
                  size="sm"
                  className="site-header-action site-header-action--plain"
                >
                  Kullanıcılar
                </ActionButton>
              )}
              <ActionButton
                to="/satici/urunler"
                variant="quiet"
                size="sm"
                className="site-header-action site-header-action--seller"
              >
                Ürünlerini paylaş
              </ActionButton>
              <span className="hidden whitespace-nowrap px-1 text-xs text-emerald-100/80 lg:inline">
                Merhaba{user.name ? `, ${user.name}` : ""}
              </span>
              <ActionButton
                type="button"
                variant="quiet"
                size="sm"
                onClick={() => void logout()}
                className="site-header-action site-header-action--logout"
              >
                Çıkış yap
              </ActionButton>
            </div>
          ) : (
            <div className="flex w-auto max-w-full flex-wrap items-center justify-end gap-2">
              <ActionButton
                to="/login"
                variant="quiet"
                size="sm"
                className="site-header-action site-header-action--login"
              >
                Giriş yap
              </ActionButton>
              <ActionButton
                to="/register"
                variant="accent"
                size="sm"
                className="site-header-action site-header-action--register"
              >
                Kayıt ol
              </ActionButton>
            </div>
          )}
          {user && (
            <Link
              to="/sepet"
              aria-label={
                cart
                  ? `Sepet, ${cart.item_count} ürün, ${cart.subtotal.toLocaleString("tr-TR", { style: "currency", currency: "TRY" })}`
                  : "Sepet"
              }
              className="ml-1 flex shrink-0 items-center gap-2 border border-emerald-200 bg-emerald-100 px-3 py-2 font-semibold text-emerald-950 transition-colors hover:border-emerald-300 hover:bg-emerald-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-200 sm:px-4"
            >
              <svg
                aria-hidden="true"
                viewBox="0 0 24 24"
                className="h-5 w-5 shrink-0"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.7"
              >
                <path
                  strokeLinecap="square"
                  strokeLinejoin="miter"
                  d="M3 4h2l2.1 10.2a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 1.9-1.4L21 8H6"
                />
                <circle cx="10" cy="20" r="1" />
                <circle cx="18" cy="20" r="1" />
              </svg>
              <span>Sepet</span>
              {cart && (
                <span className="border-l border-emerald-950/20 pl-2 text-[0.68rem] leading-4">
                  <span className="block">{cart.item_count} ürün</span>
                  <span className="block tabular-nums">
                    {cart.subtotal.toLocaleString("tr-TR", {
                      style: "currency",
                      currency: "TRY",
                    })}
                  </span>
                </span>
              )}
            </Link>
          )}
        </nav>
      </div>
      {logoutError && (
        <p
          role="alert"
          className="mx-auto max-w-6xl px-5 pb-3 text-sm text-red-200"
        >
          {logoutError}
        </p>
      )}
    </header>
  );
}

export default Header;
