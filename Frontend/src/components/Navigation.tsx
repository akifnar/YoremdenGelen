import { NavLink } from "react-router-dom";

const links = [
  { to: "/", label: "Ana Sayfa", end: true },
  { to: "/urunler", label: "Ürünler" },
  { to: "/hakkimizda", label: "Hakkımızda" },
  { to: "/iletisim", label: "İletişim" },
  { to: "/sss", label: "S.S.S." },
  { to: "/teslimat-iade", label: "Teslimat ve İade" },
];

function Navigation() {
  return (
    <nav
      aria-label="Ana menü"
      className="border-b border-emerald-100 bg-white shadow-sm shadow-emerald-950/[0.03]"
    >
      <div className="mx-auto max-w-6xl overflow-x-auto px-4 sm:px-7">
        <ul className="flex min-w-max items-center gap-1 py-2">
          {links.map((link) => (
            <li key={link.to}>
              <NavLink
                to={link.to}
                end={link.end}
                className={({ isActive }) =>
                  `inline-flex rounded-full px-4 py-2.5 text-sm font-medium transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-700 ${
                    isActive
                      ? "bg-emerald-800 text-white shadow-sm"
                      : "text-emerald-950 hover:bg-emerald-50 hover:text-emerald-800"
                  }`
                }
              >
                {link.label}
              </NavLink>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  );
}

export default Navigation;
