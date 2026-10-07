import { Link } from "react-router-dom";

function Footer() {
  return (
    <footer className="mt-12 bg-emerald-950 text-emerald-50">
      <div className="mx-auto grid max-w-6xl gap-8 px-5 py-10 sm:px-8 md:grid-cols-[1fr_auto] md:items-end">
        <div>
          <Link
            to="/"
            className="text-xl font-bold tracking-tight focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lime-300"
          >
            Yöremden Gelen<span className="text-lime-300">.</span>
          </Link>
          <p className="mt-3 max-w-md text-sm leading-6 text-emerald-100/75">
            Yerel üreticilerin emeğini evlere taşıyan güzel bir keşif yolculuğu.
          </p>
        </div>

        <nav
          aria-label="Alt menü"
          className="flex flex-wrap gap-x-5 gap-y-3 text-sm text-emerald-100/80"
        >
          <Link className="transition hover:text-lime-300" to="/sss">
            S.S.S.
          </Link>
          <Link className="transition hover:text-lime-300" to="/teslimat-iade">
            Teslimat ve İade
          </Link>
          <Link className="transition hover:text-lime-300" to="/gizlilik">
            Gizlilik
          </Link>
          <Link
            className="transition hover:text-lime-300"
            to="/kullanim-kosullari"
          >
            Kullanım Koşulları
          </Link>
        </nav>
      </div>

      <div className="border-t border-emerald-800/80">
        <p className="mx-auto max-w-6xl px-5 py-4 text-xs text-emerald-100/60 sm:px-8">
          © {new Date().getFullYear()} Yöremden Gelen. Tüm hakları saklıdır.
        </p>
      </div>
    </footer>
  );
}

export default Footer;
