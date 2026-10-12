import { useEffect, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  CartRequestError,
  cartRequest,
  type Cart,
  type CartLine,
} from "../cartApi";
import { queueCartAction } from "../cartActions";
import productImageUrl from "../productImageUrl";
import ActionButton from "../components/ActionButton";

function CartPage() {
  const [cart, setCart] = useState<Cart | null>(null);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const cartRequestVersion = useRef(0);
  const navigate = useNavigate();

  useEffect(() => {
    let isCurrent = true;
    const loadCart = async () => {
      const requestVersion = ++cartRequestVersion.current;
      try {
        const loadedCart = await cartRequest("");
        if (isCurrent && requestVersion === cartRequestVersion.current)
          setCart(loadedCart);
      } catch (requestError) {
        if (
          requestError instanceof CartRequestError &&
          requestError.status === 401
        ) {
          navigate(`/login?returnTo=${encodeURIComponent("/sepet")}`);
        }
        if (isCurrent && requestVersion === cartRequestVersion.current)
          setError(
            requestError instanceof Error
              ? requestError.message
              : "Sepet yüklenemedi",
          );
      } finally {
        if (isCurrent && requestVersion === cartRequestVersion.current)
          setIsLoading(false);
      }
    };
    const restoreRemovedLine = (event: Event) => {
      const detail = (
        event as CustomEvent<{
          restoreLine?: CartLine;
          restoreLines?: CartLine[];
          restoreIndex?: number;
        }>
      ).detail;
      const lines =
        detail.restoreLines ?? (detail.restoreLine ? [detail.restoreLine] : []);
      if (!lines.length) return;
      setCart((current) => {
        if (!current) return current;
        const missing = lines.filter(
          (line) => !current.items.some((item) => item.id === line.id),
        );
        if (!missing.length) return current;
        const items = [...current.items];
        items.splice(detail.restoreIndex ?? items.length, 0, ...missing);
        return {
          ...current,
          items,
          item_count:
            current.item_count +
            missing.reduce((sum, line) => sum + line.quantity, 0),
          subtotal:
            current.subtotal +
            missing.reduce((sum, line) => sum + line.line_total, 0),
        };
      });
    };
    const commitCart = (event: Event) => {
      const { cart: committedCart } = (event as CustomEvent<{ cart: Cart }>)
        .detail;
      cartRequestVersion.current += 1;
      setCart(committedCart);
    };
    void loadCart();
    window.addEventListener("cart-action-undone", restoreRemovedLine);
    window.addEventListener("cart-action-failed", restoreRemovedLine);
    window.addEventListener("cart-action-committed", commitCart);
    return () => {
      isCurrent = false;
      window.removeEventListener("cart-action-undone", restoreRemovedLine);
      window.removeEventListener("cart-action-failed", restoreRemovedLine);
      window.removeEventListener("cart-action-committed", commitCart);
    };
  }, [navigate]);

  const changeQuantity = async (lines: CartLine[], quantity: number) => {
    const [primary, ...duplicates] = lines;
    if (!primary || quantity < 1) return;
    cartRequestVersion.current += 1;
    try {
      let updatedCart = await cartRequest(`/items/${primary.id}`, {
        method: "PATCH",
        body: JSON.stringify({ quantity }),
      });
      for (const duplicate of duplicates) {
        updatedCart = await cartRequest(`/items/${duplicate.id}`, {
          method: "DELETE",
        });
      }
      setCart(updatedCart);
      setError("");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Adet değiştirilemedi",
      );
    }
  };

  const removeItem = (lines: CartLine[]) => {
    if (!cart || !lines.length) return;
    cartRequestVersion.current += 1;
    const ids = new Set(lines.map((line) => line.id));
    const restoreIndex = cart.items.findIndex((line) => ids.has(line.id));
    const totalQuantity = lines.reduce((sum, line) => sum + line.quantity, 0);
    const totalPrice = lines.reduce((sum, line) => sum + line.line_total, 0);
    setCart((current) =>
      current
        ? {
            ...current,
            items: current.items.filter((line) => !ids.has(line.id)),
            item_count: current.item_count - totalQuantity,
            subtotal: current.subtotal - totalPrice,
          }
        : current,
    );
    setError("");
    queueCartAction({
      message: `${lines[0].product.name} sepetten kaldırıldı.`,
      delta: { item_count: -totalQuantity, subtotal: -totalPrice },
      restoreLines: lines,
      restoreIndex,
      execute: async () => {
        let updatedCart = cart;
        for (const line of lines) {
          updatedCart = await cartRequest(`/items/${line.id}`, {
            method: "DELETE",
          });
        }
        return updatedCart;
      },
    });
  };

  const groupedItems =
    cart?.items.reduce<
      Array<{ lines: CartLine[]; quantity: number; line_total: number }>
    >((groups, line) => {
      const existing = groups.find(
        (group) => group.lines[0].product.id === line.product.id,
      );
      if (existing) {
        existing.lines.push(line);
        existing.quantity += line.quantity;
        existing.line_total += line.line_total;
      } else {
        groups.push({
          lines: [line],
          quantity: line.quantity,
          line_total: line.line_total,
        });
      }
      return groups;
    }, []) ?? [];

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
            {groupedItems.map((group) => {
              const item = group.lines[0];
              return (
                <article
                  key={item.product.id}
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
                    {group.lines.length > 1 && (
                      <span className="mt-1 inline-flex rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-800">
                        Sepette {group.quantity} adet
                      </span>
                    )}
                    <p className="mt-1 text-sm tabular-nums text-stone-600">
                      {item.product.price.toLocaleString("tr-TR", {
                        style: "currency",
                        currency: "TRY",
                      })}
                    </p>
                    <p className="mt-1 text-xs text-stone-500">
                      Güncel stok: {item.product.stock}
                    </p>
                    {group.quantity > item.product.stock && (
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
                      value={group.quantity}
                      onChange={(event) =>
                        void changeQuantity(
                          group.lines,
                          Number(event.target.value),
                        )
                      }
                      className="w-16 border border-stone-300 p-2 text-center text-sm tabular-nums"
                    />
                    <ActionButton
                      type="button"
                      variant="quiet"
                      size="sm"
                      onClick={() => removeItem(group.lines)}
                      className="h-auto border-0 px-1 py-0 text-xs underline underline-offset-2"
                    >
                      Kaldır
                    </ActionButton>
                    <p className="text-sm font-semibold tabular-nums text-stone-900">
                      {group.line_total.toLocaleString("tr-TR", {
                        style: "currency",
                        currency: "TRY",
                      })}
                    </p>
                  </div>
                </article>
              );
            })}
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
