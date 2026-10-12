function ShippingReturnsPage() {
  return (
    <main className="mx-auto w-full max-w-5xl px-5 py-12 sm:px-8 sm:py-16">
      <header className="max-w-2xl">
        <p className="font-semibold text-emerald-700">Sipariş desteği</p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight text-emerald-950 sm:text-5xl">
          Teslimat ve iade
        </h1>
        <p className="mt-4 text-lg leading-8 text-stone-600">
          Siparişinle ilgili bilmen gerekenleri burada bulabilirsin.
        </p>
      </header>

      <div className="mt-9 grid gap-5 md:grid-cols-2">
        <section className="rounded-3xl border border-emerald-100 bg-white p-7 shadow-sm">
          <span
            className="grid h-12 w-12 place-items-center rounded-2xl bg-emerald-50 text-2xl"
            aria-hidden="true"
          >
            📦
          </span>
          <h2 className="mt-5 text-xl font-semibold text-emerald-950">
            Teslimat
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Tahmini teslimat süresi ve varsa kargo ücreti, sipariş koşulları
            kesinleştiğinde burada ve sipariş adımlarında açıkça
            belirtilecektir.
          </p>
        </section>

        <section className="rounded-3xl border border-emerald-100 bg-white p-7 shadow-sm">
          <span
            className="grid h-12 w-12 place-items-center rounded-2xl bg-lime-50 text-2xl"
            aria-hidden="true"
          >
            ↩️
          </span>
          <h2 className="mt-5 text-xl font-semibold text-emerald-950">İade</h2>
          <p className="mt-3 leading-7 text-stone-600">
            İade koşulları ürünün niteliğine ve yürürlükteki mevzuata göre
            belirlenecektir. Gerçek iade süreci ve başvuru adımları burada
            yayımlanacaktır.
          </p>
        </section>
      </div>

      <aside className="mt-6 rounded-2xl border border-lime-200 bg-lime-50 p-5 text-sm leading-6 text-emerald-950">
        Bu sayfa şu an taslak içerik gösteriyor. Satış başlamadan önce gerçek
        teslimat ve iade koşullarıyla güncellenmelidir.
      </aside>
    </main>
  );
}

export default ShippingReturnsPage;
