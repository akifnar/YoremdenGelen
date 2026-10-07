import { Link } from "react-router-dom";

function HomePage() {
  return (
    <main className="mx-auto w-full max-w-6xl px-5 py-12 sm:px-8 sm:py-16">
      <section className="relative overflow-hidden rounded-[2rem] bg-emerald-950 px-7 py-12 text-white shadow-xl shadow-emerald-950/10 sm:px-12 sm:py-16">
        <div className="absolute -right-16 -top-20 h-64 w-64 rounded-full bg-emerald-800/50 blur-3xl" />
        <div className="relative max-w-2xl">
          <p className="inline-flex rounded-full border border-emerald-300/30 bg-emerald-900/70 px-4 py-2 text-sm font-medium text-emerald-100">
            Yerel üreticilerden, özenle seçildi
          </p>
          <h1 className="mt-6 text-4xl font-bold tracking-tight sm:text-6xl">
            Evin için güzel şeyler, güzel insanlardan.
          </h1>
          <p className="mt-5 max-w-xl text-lg leading-8 text-emerald-100/85">
            Yöremden Gelen’de küçük üreticilerin emek verdiği ürünleri keşfet;
            evine ve günlük hayatına yerel dokunuşlar kat.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link
              to="/urunler"
              className="rounded-full bg-lime-300 px-6 py-3 font-semibold text-emerald-950 transition hover:bg-lime-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
            >
              Ürünleri keşfet
            </Link>
            <Link
              to="/hakkimizda"
              className="rounded-full border border-emerald-100/40 px-6 py-3 font-semibold text-white transition hover:bg-white/10 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
            >
              Hikâyemiz
            </Link>
          </div>
        </div>
      </section>

      <section className="grid gap-5 py-12 sm:grid-cols-3">
        <article className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm shadow-emerald-950/5">
          <span className="text-2xl" aria-hidden="true">
            🌱
          </span>
          <h2 className="mt-4 text-lg font-semibold text-emerald-950">
            Yerel üretim
          </h2>
          <p className="mt-2 leading-7 text-stone-600">
            Üreticilerin hikâyelerini ve emeklerini keşfet.
          </p>
        </article>
        <article className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm shadow-emerald-950/5">
          <span className="text-2xl" aria-hidden="true">
            🧺
          </span>
          <h2 className="mt-4 text-lg font-semibold text-emerald-950">
            Özenle seçilmiş
          </h2>
          <p className="mt-2 leading-7 text-stone-600">
            Evin için düşünülmüş, kendine özgü ürünlere göz at.
          </p>
        </article>
        <article className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm shadow-emerald-950/5">
          <span className="text-2xl" aria-hidden="true">
            🤝
          </span>
          <h2 className="mt-4 text-lg font-semibold text-emerald-950">
            Güzel bir bağ
          </h2>
          <p className="mt-2 leading-7 text-stone-600">
            Üretenlerle alışveriş yapanları aynı yerde buluştur.
          </p>
        </article>
      </section>
    </main>
  );
}

export default HomePage;
