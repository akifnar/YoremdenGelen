import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { cartRequest } from "../cartApi";
import { queueCartAction } from "../cartActions";
import AddToCartButton from "./AddToCartButton";
import ActionButton from "./ActionButton";
import type { Product } from "./ProductCard";
import productImageUrl, { foodImageUrl } from "../productImageUrl";

type LargeProductShowcaseProps = {
  products: Product[];
};

type ProductGallery = { gallery_image_urls?: string[] };

function galleryCacheKey(productId: number) {
  return `yoremden-gelen:product-gallery:${productId}:v1`;
}

function readGalleryCache(productId: number): string[] | undefined {
  try {
    const cached = localStorage.getItem(galleryCacheKey(productId));
    return cached ? (JSON.parse(cached) as string[]) : undefined;
  } catch {
    return undefined;
  }
}

function writeGalleryCache(productId: number, photos: string[]) {
  try {
    localStorage.setItem(galleryCacheKey(productId), JSON.stringify(photos));
  } catch {
    // Storage can be unavailable or full; the in-memory cache still works.
  }
}

function LargeProductShowcase({ products }: LargeProductShowcaseProps) {
  const [photosByProduct, setPhotosByProduct] = useState<
    Record<number, string[]>
  >({});
  const [photoIndexByProduct, setPhotoIndexByProduct] = useState<
    Record<number, number>
  >({});
  const [loadingProductId, setLoadingProductId] = useState<number | null>(null);
  const [addingProductId, setAddingProductId] = useState<number | null>(null);
  const [cartError, setCartError] = useState("");
  const navigate = useNavigate();

  const addToCart = async (product: Product) => {
    if (!localStorage.getItem("auth-user")) {
      navigate(`/login?returnTo=${encodeURIComponent("/")}`);
      return;
    }
    setAddingProductId(product.id);
    setCartError("");
    queueCartAction({
      message: `${product.name} sepetinize eklendi.`,
      delta: { item_count: 1, subtotal: product.price },
      execute: () =>
        cartRequest("/items", {
          method: "POST",
          body: JSON.stringify({ product_id: product.id, quantity: 1 }),
        }),
    });
    setAddingProductId(null);
  };

  const changePhoto = async (
    event: React.MouseEvent<HTMLButtonElement>,
    product: Product,
    direction: number,
  ) => {
    event.preventDefault();
    event.stopPropagation();
    const cachedPhotos =
      photosByProduct[product.id] ?? readGalleryCache(product.id);
    let loadedPhotos: string[];
    if (cachedPhotos) {
      loadedPhotos = cachedPhotos;
    } else {
      setLoadingProductId(product.id);
      try {
        const response = await fetch(
          `/api/products/${encodeURIComponent(product.slug)}`,
        );
        if (!response.ok) throw new Error("Ürün fotoğrafları yüklenemedi");
        const details: ProductGallery = await response.json();
        loadedPhotos = [
          productImageUrl(product),
          ...(details.gallery_image_urls?.length
            ? details.gallery_image_urls
            : [1, 2, 3].map((offset) => foodImageUrl(product.id, offset))),
        ];
      } catch {
        loadedPhotos = [
          productImageUrl(product),
          ...[1, 2, 3].map((offset) => foodImageUrl(product.id, offset)),
        ];
      } finally {
        setLoadingProductId(null);
      }
      writeGalleryCache(product.id, loadedPhotos);
      setPhotosByProduct((current) => ({
        ...current,
        [product.id]: loadedPhotos,
      }));
    }
    if (!photosByProduct[product.id]) {
      setPhotosByProduct((current) => ({
        ...current,
        [product.id]: loadedPhotos,
      }));
    }
    setPhotoIndexByProduct((current) => ({
      ...current,
      [product.id]:
        ((current[product.id] ?? 0) + direction + loadedPhotos.length) %
        loadedPhotos.length,
    }));
  };

  return (
    <>
      {cartError && (
        <p role="alert" className="col-span-full text-sm text-red-700">
          {cartError}
        </p>
      )}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
        {products.map((product) => {
          const photos = photosByProduct[product.id];
          const photoIndex = photoIndexByProduct[product.id] ?? 0;
          return (
            <article
              key={product.id}
              className="group min-w-0 overflow-hidden rounded-sm border border-stone-200 bg-white text-stone-900 transition-[border-color,box-shadow] duration-200 hover:border-emerald-200 hover:shadow-md"
            >
              <div className="relative">
                <Link
                  to={`/urunler/${product.slug}`}
                  className="block focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
                >
                  <div className="aspect-[4/3] overflow-hidden bg-emerald-50">
                    <img
                      key={`${product.id}-${photoIndex}`}
                      src={photos?.[photoIndex] ?? productImageUrl(product)}
                      alt={product.name}
                      loading="lazy"
                      className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.035] motion-safe:animate-photo-fade"
                    />
                  </div>
                </Link>
                <ActionButton
                  type="button"
                  variant="quiet"
                  size="icon"
                  aria-label={`${product.name} önceki fotoğraf`}
                  disabled={loadingProductId === product.id}
                  onClick={(event) => void changePhoto(event, product, -1)}
                  className="absolute left-2 top-1/2 h-9 w-9 -translate-y-1/2 bg-white/90 text-xl opacity-100 hover:bg-white disabled:opacity-50 sm:opacity-0 sm:group-hover:opacity-100 sm:group-focus-within:opacity-100"
                >
                  ‹
                </ActionButton>
                <ActionButton
                  type="button"
                  variant="quiet"
                  size="icon"
                  aria-label={`${product.name} sonraki fotoğraf`}
                  disabled={loadingProductId === product.id}
                  onClick={(event) => void changePhoto(event, product, 1)}
                  className="absolute right-2 top-1/2 h-9 w-9 -translate-y-1/2 bg-white/90 text-xl opacity-100 hover:bg-white disabled:opacity-50 sm:opacity-0 sm:group-hover:opacity-100 sm:group-focus-within:opacity-100"
                >
                  ›
                </ActionButton>
              </div>
              <Link
                to={`/urunler/${product.slug}`}
                className="block focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
              >
                <div className="flex min-h-28 flex-col justify-between p-3.5">
                  <div>
                    {product.category && (
                      <p className="mb-1.5 text-[0.65rem] font-semibold uppercase tracking-[0.12em] text-emerald-700">
                        {product.category}
                      </p>
                    )}
                    <h3 className="line-clamp-2 min-h-10 text-sm font-semibold leading-5 text-emerald-950">
                      {product.name}
                    </h3>
                  </div>
                  <p className="mt-3 text-base font-bold tabular-nums tracking-tight text-emerald-900">
                    {product.price.toLocaleString("tr-TR", {
                      style: "currency",
                      currency: "TRY",
                    })}
                  </p>
                </div>
              </Link>
              <AddToCartButton
                onClick={() => void addToCart(product)}
                disabled={product.stock < 1}
                isAdding={addingProductId === product.id}
                className="flex w-full justify-center border-t border-stone-200 py-2 text-[var(--subtle)] transition-all duration-500 ease-out hover:bg-stone-50 disabled:opacity-50 sm:translate-y-2 sm:opacity-0 sm:group-hover:translate-y-0 sm:group-hover:opacity-100 sm:group-focus-within:translate-y-0 sm:group-focus-within:opacity-100 motion-reduce:transition-none"
              />
            </article>
          );
        })}
      </div>
    </>
  );
}

export default LargeProductShowcase;
