import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { CartRequestError, cartRequest, type Cart } from "../cartApi";

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
          className="flex w-full flex-1 items-center justify-end gap-2 text-sm sm:w-auto"
          aria-label="Hesap ve sepet işlemleri"
        >
          {user?.role === "admin" && (
            <Link
              to="/admin/users"
              className="link-underline border border-emerald-700 px-3 py-2 text-emerald-100"
            >
              Kullanıcılar
            </Link>
          )}
          {user ? (
            <>
              <Link
                to="/satici/urunler"
                className="link-underline border border-emerald-700 px-3 py-2 text-emerald-100"
              >
                Ürünlerini paylaş
              </Link>
              <span className="hidden text-emerald-100 sm:inline">
                Merhaba{user.name ? `, ${user.name}` : ""}
              </span>
              <button
                type="button"
                onClick={() => void logout()}
                className="border border-emerald-700 px-3 py-2 text-emerald-100 transition-colors duration-200 hover:border-red-400 hover:bg-red-600 hover:text-white focus-visible:border-red-400 focus-visible:bg-red-600 focus-visible:text-white"
              >
                Çıkış yap
              </button>
            </>
          ) : (
            <>
              <Link
                to="/login"
                className="link-underline border border-emerald-300/70 px-4 py-2 font-medium text-emerald-50 transition duration-200 hover:border-lime-300 hover:bg-emerald-800 hover:text-lime-200 active:scale-95 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lime-300"
              >
                Giriş yap
              </Link>
              <Link
                to="/register"
                className="link-underline bg-lime-300 px-4 py-2 font-semibold text-emerald-950 transition duration-200 hover:bg-lime-200 hover:shadow-[0_0_0_2px_rgba(217,249,157,0.35)] active:scale-95 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lime-200"
              >
                Kayıt ol
              </Link>
            </>
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
