function AboutPage() {
  return (
    <main className="mx-auto w-full max-w-6xl px-5 py-12 sm:px-8 sm:py-16">
      <section className="relative overflow-hidden rounded-[2rem] bg-emerald-900 px-7 py-10 text-white shadow-xl shadow-emerald-950/10 sm:px-12 sm:py-14">
        <div className="absolute -bottom-24 -right-10 h-64 w-64 rounded-full bg-lime-300/15 blur-3xl" />
        <div className="relative max-w-3xl">
          <p className="font-semibold text-lime-300">Hakkımızda</p>
          <h1 className="mt-3 text-4xl font-bold tracking-tight sm:text-5xl">
            Güzel şeyler, güzel insanlardan.
          </h1>
          <p className="mt-5 max-w-2xl text-lg leading-8 text-emerald-50/85">
            Yöremden Gelen, yerel üreticilerin özenle hazırladığı ürünleri bir
            araya getirmek için yola çıktı. Her ürünün arkasındaki emeği ve
            hikâyeyi daha görünür kılmayı önemsiyoruz.
          </p>
        </div>
      </section>

      <section className="mt-8 grid gap-5 md:grid-cols-2">
        <article className="rounded-3xl border border-emerald-100 bg-white p-7 shadow-sm">
          <span
            className="grid h-12 w-12 place-items-center rounded-2xl bg-emerald-50 text-2xl"
            aria-hidden="true"
          >
            🌿
          </span>
          <h2 className="mt-5 text-xl font-semibold text-emerald-950">
            Neye inanıyoruz?
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Alışverişin yalnızca bir ürün seçmek değil, onu üreten insanlarla
            bağ kurmak olduğuna inanıyoruz.
          </p>
        </article>
        <article className="rounded-3xl border border-emerald-100 bg-white p-7 shadow-sm">
          <span
            className="grid h-12 w-12 place-items-center rounded-2xl bg-lime-50 text-2xl"
            aria-hidden="true"
          >
            🤝
          </span>
          <h2 className="mt-5 text-xl font-semibold text-emerald-950">
            Amacımız
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Üretenlerle keşfetmek isteyenleri aynı yerde buluşturup yerel
            üretime alan açmak.
          </p>
        </article>
      </section>
    </main>
  );
}

export default AboutPage;
