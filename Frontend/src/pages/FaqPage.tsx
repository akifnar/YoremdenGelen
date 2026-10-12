const questions = [
  {
    question: "Yöremden Gelen nedir?",
    answer:
      "Yöremden Gelen, yerel üreticilerin özenle hazırladığı ürünleri bir araya getirmeyi amaçlayan bir alışveriş platformudur.",
  },
  {
    question: "Ürünler hakkında nereden bilgi alabilirim?",
    answer:
      "Ürünlerin açıklama ve özelliklerini ilgili ürün sayfasında bulabilirsin.",
  },
  {
    question: "Siparişimle ilgili nasıl bilgi alabilirim?",
    answer:
      "Sipariş ve teslimat bilgileri ilgili sipariş adımında ve teslimat-iade sayfasında paylaşılır.",
  },
];

function FaqPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-5 py-12 sm:px-8 sm:py-16">
      <header className="rounded-4xl bg-emerald-900 px-7 py-9 text-white sm:px-10 sm:py-11">
        <p className="font-semibold text-lime-300">Yardım merkezi</p>
        <h1 className="mt-3 text-4xl font-bold tracking-tight sm:text-5xl">
          Sıkça sorulan sorular
        </h1>
        <p className="mt-4 max-w-2xl leading-7 text-emerald-50/80">
          Yöremden Gelen ve alışveriş deneyimi hakkında merak ettiklerin için
          yanıtlar.
        </p>
      </header>

      <section aria-label="Sıkça sorulan sorular" className="mt-7 space-y-3">
        {questions.map((item, index) => (
          <details
            key={item.question}
            className="group rounded-2xl border border-emerald-100 bg-white p-5 shadow-sm transition open:border-emerald-200 open:shadow-md sm:p-6"
          >
            <summary className="flex cursor-pointer list-none items-center gap-4 font-semibold text-emerald-950 marker:hidden focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-emerald-700">
              <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-emerald-50 text-sm font-bold text-emerald-800">
                0{index + 1}
              </span>
              <span className="flex-1">{item.question}</span>
              <span
                className="text-xl text-emerald-700 transition group-open:rotate-45"
                aria-hidden="true"
              >
                +
              </span>
            </summary>
            <p className="ml-13 mt-4 max-w-2xl leading-7 text-stone-600 sm:ml-13">
              {item.answer}
            </p>
          </details>
        ))}
      </section>
    </main>
  );
}

export default FaqPage;
