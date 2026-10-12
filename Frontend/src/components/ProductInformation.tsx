import { useState } from "react";
import type { Product } from "./ProductCard";
import productImageUrl, { foodImageUrl } from "../productImageUrl";
import AddToCartButton from "./AddToCartButton";
import ActionButton from "./ActionButton";

type ProductInformationProps = {
  product: Product & {
    category?: string | null;
  };
  quantity: number;
  onQuantityChange: (quantity: number) => void;
  onAddToCart: () => void;
  isAdding: boolean;
  cartMessage: string;
};

function ProductInformation({
  product,
  quantity,
  onQuantityChange,
  onAddToCart,
  isAdding,
  cartMessage,
}: ProductInformationProps) {
  const photos = product.gallery_image_urls?.length
    ? [productImageUrl(product), ...product.gallery_image_urls]
    : [
        productImageUrl(product),
        ...[1, 2, 3].map((offset) => foodImageUrl(product.id, offset)),
      ];
  const [selectedPhoto, setSelectedPhoto] = useState(0);
  const [isEditingQuantity, setIsEditingQuantity] = useState(false);
  const [quantityDraft, setQuantityDraft] = useState("");

  const beginQuantityEdit = () => {
    setQuantityDraft(String(quantity));
    setIsEditingQuantity(true);
  };

  const commitQuantityEdit = () => {
    const parsedQuantity = Number(quantityDraft);
    onQuantityChange(
      Number.isFinite(parsedQuantity) ? Math.trunc(parsedQuantity) : 0,
    );
    setIsEditingQuantity(false);
  };

  return (
    <section className="mt-7 grid overflow-hidden border-y border-[var(--line)] bg-[var(--surface)] lg:grid-cols-[1.05fr_0.95fr]">
      <div className="border-b border-[var(--line)] bg-[var(--muted)] lg:border-b-0 lg:border-r">
        <div className="relative aspect-[4/3] overflow-hidden lg:aspect-auto lg:min-h-[34rem]">
          <img
            key={`${product.id}-${selectedPhoto}`}
            src={photos[selectedPhoto]}
            alt={`${product.name} görseli ${selectedPhoto + 1}`}
            className="absolute inset-0 h-full w-full object-cover motion-safe:animate-photo-fade"
          />
          {photos.length > 1 && (
            <>
              <ActionButton
                type="button"
                variant="quiet"
                size="icon"
                aria-label="Önceki ürün fotoğrafı"
                onClick={() =>
                  setSelectedPhoto(
                    (index) => (index - 1 + photos.length) % photos.length,
                  )
                }
                className="absolute left-3 top-1/2 h-10 w-10 -translate-y-1/2 bg-white/90 hover:bg-white"
              >
                ‹
              </ActionButton>
              <ActionButton
                type="button"
                variant="quiet"
                size="icon"
                aria-label="Sonraki ürün fotoğrafı"
                onClick={() =>
                  setSelectedPhoto((index) => (index + 1) % photos.length)
                }
                className="absolute right-3 top-1/2 h-10 w-10 -translate-y-1/2 bg-white/90 hover:bg-white"
              >
                ›
              </ActionButton>
            </>
          )}
        </div>
        {photos.length > 1 && (
          <div className="grid grid-cols-4 gap-2 border-t border-[var(--line)] p-2">
            {photos.map((photo, index) => (
              <ActionButton
                key={photo}
                type="button"
                variant="quiet"
                size="icon"
                aria-label={`${index + 1}. fotoğrafı göster`}
                aria-pressed={selectedPhoto === index}
                onClick={() => setSelectedPhoto(index)}
                className={`aspect-square h-auto w-full overflow-hidden p-0 ${selectedPhoto === index ? "border-[var(--ink)]" : "border-[var(--line)]"}`}
              >
                <img
                  src={photo}
                  alt=""
                  loading="lazy"
                  className="h-full w-full object-cover"
                />
              </ActionButton>
            ))}
          </div>
        )}
      </div>
      <div className="flex flex-col px-6 py-8 text-[var(--ink)] sm:px-10 sm:py-12 lg:px-12">
        <div className="flex items-center justify-between gap-4 border-b border-[var(--line)] pb-5">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--subtle)]">
            {product.category || "Yöresel ürün"}
          </p>
          <p className="text-xs text-[var(--subtle)]">
            {product.stock > 0 ? "Stokta" : "Tükendi"}
          </p>
        </div>
        <h1 className="mt-7 text-3xl font-semibold leading-tight tracking-tight sm:text-4xl">
          {product.name}
        </h1>
        <p className="mt-5 text-2xl font-medium tabular-nums">
          {product.price.toLocaleString("tr-TR", {
            style: "currency",
            currency: "TRY",
          })}
        </p>
        <div className="mt-8 border-t border-[var(--line)] pt-6">
          <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--subtle)]">
            Ürün açıklaması
          </h2>
          <p className="mt-3 max-w-prose text-[15px] leading-7 text-[var(--subtle)]">
            {product.description}
          </p>
          <div className="mt-6 flex flex-wrap items-center gap-3">
            <div
              className="inline-flex items-center border border-[var(--line)]"
              aria-label="Ürün adedi"
            >
              <ActionButton
                type="button"
                variant="quiet"
                size="sm"
                aria-label="Adedi azalt"
                onClick={() => onQuantityChange(Math.max(1, quantity - 1))}
                disabled={quantity <= 1 || product.stock < 1}
                className="border-0 px-3 py-2 text-lg hover:bg-transparent disabled:opacity-40"
              >
                −
              </ActionButton>
              {isEditingQuantity ? (
                <input
                  type="number"
                  autoFocus
                  aria-label="İstenen ürün adedi"
                  value={quantityDraft}
                  onChange={(event) => setQuantityDraft(event.target.value)}
                  onBlur={commitQuantityEdit}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") event.currentTarget.blur();
                    if (event.key === "Escape") setIsEditingQuantity(false);
                  }}
                  className="w-14 border-0 bg-transparent px-1 py-2 text-center text-sm tabular-nums outline-none"
                />
              ) : (
                <span
                  role="button"
                  tabIndex={0}
                  aria-live="polite"
                  aria-label="Adedi düzenlemek için çift tıklayın"
                  onDoubleClick={beginQuantityEdit}
                  onKeyDown={(event) => {
                    if (event.key === "Enter" || event.key === " ")
                      beginQuantityEdit();
                  }}
                  className="min-w-9 cursor-text text-center text-sm tabular-nums"
                >
                  {quantity}
                </span>
              )}
              <ActionButton
                type="button"
                variant="quiet"
                size="sm"
                aria-label="Adedi artır"
                onClick={() =>
                  onQuantityChange(Math.min(product.stock, quantity + 1))
                }
                disabled={quantity >= product.stock || product.stock < 1}
                className="border-0 px-3 py-2 text-lg hover:bg-transparent disabled:opacity-40"
              >
                +
              </ActionButton>
            </div>
            <AddToCartButton
              onClick={onAddToCart}
              disabled={product.stock < 1}
              isAdding={isAdding}
              className="grid h-11 w-11 place-items-center border border-[var(--line)] bg-[var(--muted)] text-[var(--ink)] opacity-75 transition-opacity hover:opacity-100 disabled:cursor-not-allowed"
            />
            {cartMessage && (
              <p
                role="status"
                className="basis-full text-sm text-[var(--subtle)]"
              >
                {cartMessage}
              </p>
            )}
          </div>
        </div>
        <dl className="mt-auto grid grid-cols-2 gap-4 border-t border-[var(--line)] pt-6">
          <div>
            <dt className="text-xs uppercase tracking-wide text-[var(--subtle)]">
              Stok adedi
            </dt>
            <dd className="mt-1 text-sm font-medium">
              {product.stock > 0 ? `${product.stock} adet` : "Tükendi"}
            </dd>
          </div>
        </dl>
      </div>
    </section>
  );
}

export default ProductInformation;
