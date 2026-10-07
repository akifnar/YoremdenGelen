function TermsPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-12 sm:px-8 sm:py-16">
      <header>
        <p className="font-semibold text-emerald-700">Yasal bilgilendirme</p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight text-emerald-950 sm:text-5xl">
          Kullanım koşulları
        </h1>
        <p className="mt-4 max-w-2xl text-lg leading-8 text-stone-600">
          Yöremden Gelen web sitesinin kullanımına ilişkin genel bilgiler.
        </p>
      </header>

      <aside className="mt-8 rounded-2xl border border-lime-200 bg-lime-50 p-5 text-sm leading-6 text-emerald-950">
        Bu sayfa örnek taslaktır; gerçek satıcı ve satış koşulları belirlenmeden
        yürürlükteki kullanım koşulları olarak değerlendirilmemelidir.
      </aside>

      <div className="mt-8 space-y-5">
        <section className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-emerald-950">
            Site kullanımı
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Kullanıcıların siteyi yürürlükteki mevzuata uygun ve başkalarının
            haklarına zarar vermeyecek şekilde kullanması beklenir.
          </p>
        </section>
        <section className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-emerald-950">
            Ürün ve sipariş bilgileri
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Ürün açıklamaları, fiyatlandırma, siparişin kurulması, ödeme,
            teslimat ve iptal koşulları gerçek satış modeline göre burada
            açıklanmalıdır.
          </p>
        </section>
        <section className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-emerald-950">
            İşletme bilgileri
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Satıcı unvanı, adresi ve iletişim bilgileri: [gerçek işletme
            bilgileri buraya eklenmelidir].
          </p>
        </section>
      </div>
    </main>
  );
}

export default TermsPage;
