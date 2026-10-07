function ContactPage() {
  return (
    <main className="mx-auto w-full max-w-6xl px-5 py-12 sm:px-8 sm:py-16">
      <header className="max-w-2xl">
        <p className="font-semibold text-emerald-700">İletişim</p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight text-emerald-950 sm:text-5xl">
          Bize yazın.
        </h1>
        <p className="mt-4 text-lg leading-8 text-stone-600">
          Soruların, önerilerin veya iş birliği fikirlerin için bize
          ulaşabilirsin.
        </p>
      </header>

      <div className="mt-9 grid gap-6 lg:grid-cols-[0.8fr_1.2fr]">
        <aside className="rounded-3xl bg-emerald-900 p-7 text-white sm:p-9">
          <span
            className="grid h-12 w-12 place-items-center rounded-2xl bg-white/10 text-2xl"
            aria-hidden="true"
          >
            ✉️
          </span>
          <h2 className="mt-6 text-2xl font-semibold">
            Sana yardımcı olmak için buradayız.
          </h2>
          <p className="mt-3 leading-7 text-emerald-50/80">
            İletişim kanallarımız ve yanıt sürelerimiz kesinleştiğinde bu alana
            eklenecek.
          </p>
          <div className="mt-8 rounded-2xl border border-white/15 bg-white/5 p-4 text-sm leading-6 text-emerald-50/80">
            Sık karşılaşılan soruların yanıtları için S.S.S. sayfasına da göz
            atabilirsin.
          </div>
        </aside>

        <form className="space-y-5 rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm sm:p-9">
          <label className="block text-sm font-semibold text-emerald-950">
            Adın
            <input
              type="text"
              autoComplete="name"
              placeholder="Adını yaz"
              className="mt-2 block w-full rounded-xl border border-emerald-100 bg-[#fbfdf9] px-4 py-3 font-normal text-stone-800 outline-none transition placeholder:text-stone-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-100"
            />
          </label>

          <label className="block text-sm font-semibold text-emerald-950">
            E-posta adresin
            <input
              type="email"
              autoComplete="email"
              placeholder="ornek@eposta.com"
              className="mt-2 block w-full rounded-xl border border-emerald-100 bg-[#fbfdf9] px-4 py-3 font-normal text-stone-800 outline-none transition placeholder:text-stone-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-100"
            />
          </label>

          <label className="block text-sm font-semibold text-emerald-950">
            Mesajın
            <textarea
              rows={5}
              placeholder="Nasıl yardımcı olabiliriz?"
              className="mt-2 block w-full resize-y rounded-xl border border-emerald-100 bg-[#fbfdf9] px-4 py-3 font-normal text-stone-800 outline-none transition placeholder:text-stone-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-100"
            />
          </label>

          <button
            type="button"
            disabled
            className="rounded-full bg-emerald-800 px-6 py-3 font-semibold text-white opacity-60"
          >
            Mesaj gönderme yakında
          </button>
          <p className="text-sm leading-6 text-stone-500">
            Bu form şimdilik tasarım amaçlıdır ve mesaj göndermiyor.
          </p>
        </form>
      </div>
    </main>
  );
}

export default ContactPage;
