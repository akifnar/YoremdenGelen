import { useCallback, useEffect, useRef, useState } from "react";
import CircularProductShowcase from "../components/CircularProductShowcase";
import LargeProductShowcase from "../components/LargeProductShowcase";
import type { Product } from "../components/ProductCard";

type ProductsResponse = {
  data: Product[];
  metadata: {
    current_page: number;
    next_page: number | null;
    total_pages: number;
    total_count: number;
  };
};

function productTypeCategory(product: Product): string {
  const category = product.category?.trim();
  const knownCategories = [
    "Peynir",
    "Zeytin",
    "Zeytinyağı",
    "Et ve Şarküteri",
    "Tatlılar",
    "Hamur İşleri",
    "Süt Ürünleri",
  ];
  if (category && knownCategories.includes(category)) return category;

  const name = product.name.toLocaleLowerCase("tr-TR");
  if (/zeytin|zeytinyağı/.test(name)) return "Zeytin ve Zeytinyağı";
  if (/peynir|kuymak|kaymak|höşmerim/.test(name))
    return "Peynir ve Süt Ürünleri";
  if (/baklava|künefe|kayısı|dondurma|kadayıf|mesir|tatlı/.test(name))
    return "Tatlılar";
  if (/mantı|boyoz|ekmek|pide|hangel|cimcik|pilav/.test(name))
    return "Hamur İşleri";
  if (/kebap|köfte|ciğer|hamsi|tantuni|şiş|kaburga/.test(name))
    return "Et ve Ana Yemekler";
  if (/leblebi/.test(name)) return "Atıştırmalıklar";
  return "Diğer Yöresel Ürünler";
}

function categoryAnchorId(category: string): string {
  return category
    .toLocaleLowerCase("tr-TR")
    .replace(/ı/g, "i")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function popularSelection(products: Product[]): Product[] {
  return products.length > 7 ? products.slice(0, 7) : [];
}

function HomePage() {
  const initialRequestStartedRef = useRef(false);
  const [products, setProducts] = useState<Product[]>([]);
  const [popularProducts, setPopularProducts] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  const loadAllProducts = useCallback(async () => {
    setError("");
    setIsLoading(true);
    try {
      const fetchPage = async (
        pageNumber: number,
      ): Promise<ProductsResponse> => {
        const response = await fetch(`/api/products?page=${pageNumber}`, {
          cache: "no-store",
        });
        if (!response.ok) throw new Error("Ürünler yüklenemedi.");
        return (await response.json()) as ProductsResponse;
      };

      const firstPage = await fetchPage(1);
      const otherPages = await Promise.all(
        Array.from(
          { length: Math.max(0, firstPage.metadata.total_pages - 1) },
          (_, index) => fetchPage(index + 2),
        ),
      );
      const allProducts = [firstPage, ...otherPages]
        .flatMap((page) => page.data)
        .filter((product) => product.stock > 0);
      setProducts(allProducts);
      setPopularProducts(popularSelection(allProducts));
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Ürünler yüklenemedi.",
      );
      setProducts([]);
      setPopularProducts([]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    if (initialRequestStartedRef.current) return;
    initialRequestStartedRef.current = true;
    void loadAllProducts();
  }, [loadAllProducts]);

  const catalogProducts = products.length > 7 ? products.slice(7) : products;
  const productsByCategory = catalogProducts.reduce<Record<string, Product[]>>(
    (groups, product) => {
      const category = productTypeCategory(product);
      (groups[category] ??= []).push(product);
      return groups;
    },
    {},
  );
  const categories = Object.keys(productsByCategory);

  return (
    <main className="mx-auto w-full max-w-7xl px-4 py-7 sm:px-6 lg:px-8">
      {(popularProducts.length > 0 || (isLoading && products.length === 0)) && (
        <section
          aria-labelledby="popular-heading"
          className="mb-8 overflow-hidden border border-emerald-100 bg-white px-4 py-5 shadow-sm sm:px-6"
        >
          <div className="mb-4 flex items-end justify-between gap-4 border-b border-emerald-100 pb-3">
            <div>
              <p className="text-[0.65rem] font-bold uppercase tracking-[0.18em] text-emerald-700">
                Üreticilerden seçtiklerimiz
              </p>
              <h1
                id="popular-heading"
                className="mt-1 text-xl font-bold tracking-tight text-emerald-950"
              >
                Popüler ürünler
              </h1>
            </div>
            <span className="hidden text-xs font-medium text-stone-500 sm:inline">
              Beğenilen yöresel tatlar
            </span>
          </div>
          <div className="overflow-x-auto pb-1">
            {isLoading && popularProducts.length === 0 ? (
              <div className="h-36 min-w-[680px] animate-pulse bg-stone-100" />
            ) : (
              <CircularProductShowcase products={popularProducts} />
            )}
          </div>
        </section>
      )}

      <section aria-labelledby="catalog-heading" className="pt-2">
        <div className="mb-5 flex items-end justify-between gap-4 border-b border-emerald-200 pb-3">
          <div>
            <p className="text-[0.65rem] font-bold uppercase tracking-[0.18em] text-emerald-700">
              Tazesi, yöreseli, sana özel
            </p>
            <h2
              id="catalog-heading"
              className="mt-1 text-xl font-bold tracking-tight text-emerald-950"
            >
              Kategorilere göre keşfet
            </h2>
          </div>
        </div>

        {isLoading && products.length === 0 ? (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
            {Array.from({ length: 10 }, (_, index) => (
              <div
                key={index}
                className="aspect-[4/5] animate-pulse bg-stone-100"
              />
            ))}
          </div>
        ) : error && products.length === 0 ? (
          <p
            role="alert"
            className="border border-stone-200 p-5 text-sm text-stone-600"
          >
            {error}
          </p>
        ) : (
          <>
            {error && (
              <p role="status" className="mb-3 text-sm text-stone-500">
                {error}
              </p>
            )}
            <div className="space-y-10">
              {Object.entries(productsByCategory).map(
                ([category, categoryProducts]) => (
                  <section
                    key={category}
                    id={`kategori-${categoryAnchorId(category)}`}
                    aria-label={category}
                    className="scroll-mt-8"
                  >
                    <div className="mb-4 border-b border-stone-300 pb-2">
                      <h3 className="text-xl font-semibold tracking-tight text-emerald-950">
                        {category}
                      </h3>
                    </div>
                    <LargeProductShowcase products={categoryProducts} />
                  </section>
                ),
              )}
            </div>
            {isLoading && products.length > 0 && (
              <p
                role="status"
                className="mt-6 text-center text-xs text-stone-500"
              >
                Ürünler güncelleniyor…
              </p>
            )}
            {categories.length > 0 && (
              <nav
                aria-label="Ürün kategorileri"
                className="mt-12 border-t border-stone-200 pt-6"
              >
                <h2 className="mb-4 text-sm font-semibold text-stone-800">
                  Kategoriler
                </h2>
                <ul className="flex flex-wrap gap-2">
                  {categories.map((category) => (
                    <li key={category}>
                      <a
                        href={`#kategori-${categoryAnchorId(category)}`}
                        className="inline-flex border border-stone-300 bg-white px-4 py-2 text-sm text-stone-700 transition-colors hover:border-emerald-800 hover:bg-emerald-50 hover:text-emerald-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
                      >
                        {category}
                      </a>
                    </li>
                  ))}
                </ul>
              </nav>
            )}
          </>
        )}
      </section>
    </main>
  );
}

export default HomePage;
