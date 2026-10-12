import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { CartRequestError, cartRequest, type Cart } from "../cartApi";
import productImageUrl from "../productImageUrl";

function CartPage() {
  const [cart, setCart] = useState<Cart | null>(null);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    let isCurrent = true;
    const loadCart = async () => {
      try {
        const loadedCart = await cartRequest("");
        if (isCurrent) setCart(loadedCart);
      } catch (requestError) {
        if (
          requestError instanceof CartRequestError &&
          requestError.status === 401
        ) {
          navigate(`/login?returnTo=${encodeURIComponent("/sepet")}`);
        }
        if (isCurrent)
          setError(
            requestError instanceof Error
              ? requestError.message
              : "Sepet yüklenemedi",
          );
      } finally {
        if (isCurrent) setIsLoading(false);
      }
    };
    void loadCart();
    return () => {
      isCurrent = false;
    };
  }, [navigate]);

  const changeQuantity = async (itemId: number, quantity: number) => {
    try {
      setCart(
        await cartRequest(`/items/${itemId}`, {
          method: "PATCH",
          body: JSON.stringify({ quantity }),
        }),
      );
      setError("");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Adet değiştirilemedi",
      );
    }
  };

  const removeItem = async (itemId: number) => {
    try {
      setCart(await cartRequest(`/items/${itemId}`, { method: "DELETE" }));
      setError("");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Ürün kaldırılamadı",
      );
    }
  };

  if (isLoading) {
    return (
      <main className="mx-auto w-full max-w-5xl px-5 py-12 sm:px-8">
        <div className="h-48 animate-pulse bg-stone-100" />
      </main>
    );
  }

  return (
    <main className="mx-auto w-full max-w-5xl px-5 py-8 sm:px-8 sm:py-12">
      <h1 className="border-b border-stone-200 pb-4 text-2xl font-semibold text-stone-900">
        Sepetim
      </h1>
      {error && (
        <p
          role="alert"
          className="mt-4 border border-red-200 bg-red-50 p-3 text-sm text-red-800"
        >
          {error}
        </p>
      )}
      {!cart?.items.length ? (
        <div className="py-16 text-center">
          <p className="text-stone-600">Sepetiniz henüz boş.</p>
          <Link
            to="/"
            className="mt-5 inline-flex border border-stone-800 px-5 py-3 text-sm font-semibold text-stone-900"
          >
            Ürünleri incele
          </Link>
        </div>
      ) : (
        <div className="grid gap-8 py-6 lg:grid-cols-[1fr_18rem]">
          <div className="divide-y divide-stone-200 border-y border-stone-200">
            {cart.items.map((item) => (
              <article
                key={item.id}
                className="grid grid-cols-[5rem_1fr_auto] items-center gap-4 py-4 sm:grid-cols-[6rem_1fr_auto]"
              >
                <img
                  src={productImageUrl(item.product)}
                  alt={item.product.name}
                  className="aspect-square w-20 object-cover sm:w-24"
                />
                <div className="min-w-0">
                  <Link
                    to={`/urunler/${item.product.slug}`}
                    className="line-clamp-2 font-medium text-stone-900"
                  >
                    {item.product.name}
                  </Link>
                  <p className="mt-1 text-sm tabular-nums text-stone-600">
                    {item.product.price.toLocaleString("tr-TR", {
                      style: "currency",
                      currency: "TRY",
                    })}
                  </p>
                  <p className="mt-1 text-xs text-stone-500">
                    Güncel stok: {item.product.stock}
                  </p>
                  {item.quantity > item.product.stock && (
                    <p className="mt-1 text-xs font-medium text-red-700">
                      Stok değişti; adedi güncelleyin.
                    </p>
                  )}
                </div>
                <div className="flex flex-col items-end gap-2">
                  <label className="sr-only" htmlFor={`quantity-${item.id}`}>
                    Adet
                  </label>
                  <input
                    id={`quantity-${item.id}`}
                    type="number"
                    min="1"
                    max={item.product.stock}
                    value={item.quantity}
                    onChange={(event) =>
                      void changeQuantity(item.id, Number(event.target.value))
                    }
                    className="w-16 border border-stone-300 p-2 text-center text-sm tabular-nums"
                  />
                  <button
                    type="button"
                    onClick={() => void removeItem(item.id)}
                    className="text-xs text-stone-500 underline underline-offset-2"
                  >
                    Kaldır
                  </button>
                  <p className="text-sm font-semibold tabular-nums text-stone-900">
                    {item.line_total.toLocaleString("tr-TR", {
                      style: "currency",
                      currency: "TRY",
                    })}
                  </p>
                </div>
              </article>
            ))}
          </div>
          <aside className="h-fit border border-stone-200 p-5">
            <h2 className="font-semibold text-stone-900">Sipariş özeti</h2>
            <div className="mt-5 flex justify-between border-t border-stone-200 pt-4 text-sm">
              <span>Ara toplam</span>
              <strong className="tabular-nums">
                {cart.subtotal.toLocaleString("tr-TR", {
                  style: "currency",
                  currency: "TRY",
                })}
              </strong>
            </div>
            <p className="mt-3 text-xs leading-5 text-stone-500">
              Fiyat ve stok bilgileri her sepet isteğinde ürün kataloğundan
              güncellenir.
            </p>
          </aside>
        </div>
      )}
    </main>
  );
}

export default CartPage;
