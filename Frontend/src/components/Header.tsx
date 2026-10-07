import { Link } from "react-router-dom";

function Header() {
  return (
    <header className="bg-emerald-950 text-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-5 py-5 sm:px-8">
        <Link
          to="/"
          className="group inline-flex items-center gap-3 rounded-xl focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-lime-300"
        >
          <span className="grid h-11 w-11 place-items-center rounded-2xl bg-lime-300 text-xl font-black text-emerald-950 transition group-hover:rotate-[-6deg]">
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

        <p className="hidden rounded-full border border-emerald-700 px-4 py-2 text-sm text-emerald-100 md:block">
          Yerel üreticileri keşfet
        </p>
      </div>
    </header>
  );
}

export default Header;
