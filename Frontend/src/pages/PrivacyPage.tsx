function PrivacyPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-12 sm:px-8 sm:py-16">
      <header>
        <p className="font-semibold text-emerald-700">Yasal bilgilendirme</p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight text-emerald-950 sm:text-5xl">
          Gizlilik ve kişisel veriler
        </h1>
        <p className="mt-4 max-w-2xl text-lg leading-8 text-stone-600">
          Kişisel verilerin nasıl işlendiği ve korunduğu hakkında bilgilendirme.
        </p>
      </header>

      <aside className="mt-8 rounded-2xl border border-lime-200 bg-lime-50 p-5 text-sm leading-6 text-emerald-950">
        Bu sayfa taslak niteliğindedir. Gerçek veri işleme uygulamaları ve
        işletme bilgileri belirlenmeden yasal bilgilendirme olarak
        kullanılmamalıdır.
      </aside>

      <div className="mt-8 space-y-5">
        <section className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-emerald-950">
            Hangi bilgiler işlenebilir?
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Sipariş veya iletişim özellikleri kullanıma açıldığında, bu işlemler
            için gerekli bilgiler işlenebilir. Toplanan bilgi türleri, amaçları
            ve hukuki dayanakları gerçek uygulamaya göre burada açıklanmalıdır.
          </p>
        </section>
        <section className="rounded-3xl border border-emerald-100 bg-white p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-emerald-950">
            Bilgiler nasıl kullanılır?
          </h2>
          <p className="mt-3 leading-7 text-stone-600">
            Bilgilerin kullanım amaçları, saklama süreleri ve varsa hizmet
            sağlayıcılarla paylaşım koşulları işletmenin gerçek işleyişine göre
            belirtilmelidir.
          </p>
        </section>
      </div>
    </main>
  );
}

export default PrivacyPage;
