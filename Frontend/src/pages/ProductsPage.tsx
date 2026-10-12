import ActionButton from "../components/ActionButton";

function ProductsPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-16 sm:px-8">
      <section className="rounded-[2rem] border border-emerald-100 bg-white px-7 py-12 text-center shadow-sm sm:px-12">
        <span
          className="mx-auto grid h-16 w-16 place-items-center rounded-2xl bg-emerald-50 text-3xl"
          aria-hidden="true"
        >
          🧺
        </span>
        <p className="mt-6 font-semibold text-emerald-700">Ürünler</p>
        <h1 className="mt-2 text-3xl font-bold tracking-tight text-emerald-950 sm:text-4xl">
          Güzel şeyleri hazırlıyoruz.
        </h1>
        <p className="mx-auto mt-4 max-w-xl leading-7 text-stone-600">
          Ürünlerimiz burada yakında yerini alacak. Bu sayfa şimdilik tasarım
          aşamasındadır.
        </p>
        <ActionButton
          to="/hakkimizda"
          variant="primary"
          size="lg"
          className="mt-7"
        >
          Yöremden Gelen’i tanı
        </ActionButton>
      </section>
    </main>
  );
}

export default ProductsPage;
