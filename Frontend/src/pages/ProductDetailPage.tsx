import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import ProductInformation from "../components/ProductInformation";
import { CartRequestError, cartRequest } from "../cartApi";
import type { Product } from "../components/ProductCard";
import ActionButton from "../components/ActionButton";

type ProductDetails = Product & {
  category: string | null;
  is_active: boolean;
};

function ProductDetailPage() {
  const { slug } = useParams<{ slug: string }>();
  const navigate = useNavigate();
  const [product, setProduct] = useState<ProductDetails | null>(null);
  const [isLoading, setIsLoading] = useState(Boolean(slug));
  const [hasError, setHasError] = useState(false);
  const [cartMessage, setCartMessage] = useState("");
  const [isAdding, setIsAdding] = useState(false);
  const [quantity, setQuantity] = useState(1);

  useEffect(() => {
    if (!slug) return;
    let isCurrent = true;
    const loadProduct = async () => {
      try {
        const response = await fetch(
          `/api/products/${encodeURIComponent(slug)}`,
        );
        if (!response.ok) throw new Error("Ürün bulunamadı");
        const result: ProductDetails = await response.json();
        if (isCurrent) setProduct(result);
      } catch {
        if (isCurrent) setHasError(true);
      } finally {
        if (isCurrent) setIsLoading(false);
      }
    };
    void loadProduct();
    return () => {
      isCurrent = false;
    };
  }, [slug]);

  if (isLoading) {
    return (
      <main className="mx-auto w-full max-w-6xl px-5 py-8 sm:px-8 sm:py-12">
        <div className="h-5 w-28 animate-pulse bg-[var(--muted)]" />
        <section
          aria-label="Ürün bilgileri yükleniyor"
          aria-busy="true"
          className="mt-7 grid overflow-hidden border-y border-[var(--line)] bg-[var(--surface)] lg:grid-cols-[1.05fr_0.95fr]"
        >
          <div className="border-b border-[var(--line)] bg-[var(--muted)] lg:border-b-0 lg:border-r">
            <div className="aspect-[4/3] animate-pulse lg:aspect-auto lg:min-h-[34rem]" />
            <div className="grid grid-cols-4 gap-2 border-t border-[var(--line)] p-2">
              {Array.from({ length: 4 }, (_, index) => (
                <div
                  key={index}
                  className="aspect-square animate-pulse bg-[var(--muted)]"
                />
              ))}
            </div>
          </div>
          <div className="flex min-h-[34rem] flex-col px-6 py-8 sm:px-10 sm:py-12 lg:px-12">
            <div className="h-4 w-28 animate-pulse bg-[var(--muted)]" />
            <div className="mt-8 h-9 w-3/4 animate-pulse bg-[var(--muted)]" />
            <div className="mt-5 h-7 w-32 animate-pulse bg-[var(--muted)]" />
            <div className="mt-10 space-y-3">
              <div className="h-4 w-full animate-pulse bg-[var(--muted)]" />
              <div className="h-4 w-5/6 animate-pulse bg-[var(--muted)]" />
              <div className="h-4 w-2/3 animate-pulse bg-[var(--muted)]" />
            </div>
            <div className="mt-auto h-12 w-40 animate-pulse bg-[var(--muted)]" />
          </div>
        </section>
      </main>
    );
  }

  if (!slug || hasError || !product) {
    return (
      <main className="mx-auto grid min-h-[55vh] w-full max-w-4xl place-items-center px-5 py-16 text-center sm:px-8">
        <section>
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--subtle)]">
            Ürün bulunamadı
          </p>
          <h1 className="mt-4 text-3xl font-semibold text-[var(--ink)]">
            Bu ürün artık mevcut değil.
          </h1>
          <ActionButton
            to="/"
            variant="secondary"
            size="md"
            className="mt-7 border-[var(--line)] text-[var(--ink)] hover:border-[var(--ink)] hover:bg-[var(--muted)]"
          >
            <span aria-hidden="true">←</span>
            Ürünlere dön
          </ActionButton>
        </section>
      </main>
    );
  }

  const addToCart = async () => {
    setIsAdding(true);
    setCartMessage("");
    try {
      const cart = await cartRequest("/items", {
        method: "POST",
        body: JSON.stringify({ product_id: product.id, quantity }),
      });
      setCartMessage(
        `Sepete eklendi. Sepetinizde ${cart.item_count} ürün var.`,
      );
    } catch (requestError) {
      if (
        requestError instanceof CartRequestError &&
        requestError.status === 401
      ) {
        navigate(
          `/login?returnTo=${encodeURIComponent(`/urunler/${product.slug}`)}`,
        );
      } else {
        setCartMessage(
          requestError instanceof Error
            ? requestError.message
            : "Ürün sepete eklenemedi.",
        );
      }
    } finally {
      setIsAdding(false);
    }
  };

  return (
    <main className="mx-auto w-full max-w-6xl px-5 py-8 sm:px-8 sm:py-12">
      <Link
        to="/"
        className="inline-flex border-b border-[var(--line)] pb-1 text-sm text-[var(--subtle)]"
      >
        ← Tüm ürünler
      </Link>
      <ProductInformation
        key={product.id}
        product={product}
        quantity={quantity}
        onQuantityChange={setQuantity}
        onAddToCart={() => void addToCart()}
        isAdding={isAdding}
        cartMessage={cartMessage}
      />
    </main>
  );
}

export default ProductDetailPage;
