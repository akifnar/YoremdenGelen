import ActionButton from "../components/ActionButton";

function NotFoundPage() {
  return (
    <main className="mx-auto grid min-h-[55vh] w-full max-w-4xl place-items-center px-5 py-16 text-center sm:px-8">
      <section>
        <p className="text-sm font-bold uppercase tracking-[0.2em] text-emerald-700">
          404 · Sayfa bulunamadı
        </p>
        <h1 className="mt-4 text-4xl font-bold text-emerald-950">
          Aradığın sayfa burada yok.
        </h1>
        <p className="mt-4 text-stone-600">
          Adres değişmiş veya sayfa henüz eklenmemiş olabilir.
        </p>
        <ActionButton to="/" variant="primary" size="lg" className="mt-7">
          Ana sayfaya dön
        </ActionButton>
      </section>
    </main>
  );
}

export default NotFoundPage;
