import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import type { Product } from "./ProductCard";
import productImageUrl from "../productImageUrl";

type CircularProductShowcaseProps = { products: Product[] };
const galleryCache = new Map<string, string[]>();

function PopularProduct({ product }: { product: Product }) {
  const [images, setImages] = useState<string[]>([productImageUrl(product)]);
  const [imageIndex, setImageIndex] = useState(0);
  const [isHovered, setIsHovered] = useState(false);

  useEffect(() => {
    if (!isHovered) return;
    let cancelled = false;
    const loadGallery = async () => {
      try {
        let urls = galleryCache.get(product.slug);
        if (!urls) {
          const response = await fetch(
            `/api/products/${encodeURIComponent(product.slug)}`,
          );
          if (!response.ok) return;
          const detail = (await response.json()) as Product;
          urls = [
            productImageUrl(detail),
            ...(detail.gallery_image_urls ?? []),
          ].filter((url): url is string => Boolean(url));
          galleryCache.set(product.slug, urls);
        }
        if (!cancelled && urls.length > 1) setImages(urls);
      } catch {
        // Keep the main image if the optional gallery request fails.
      }
    };
    void loadGallery();
    return () => {
      cancelled = true;
    };
  }, [isHovered, product]);

  useEffect(() => {
    if (!isHovered || images.length < 2) return;
    const timer = window.setInterval(
      () => setImageIndex((index) => (index + 1) % images.length),
      1500,
    );
    return () => window.clearInterval(timer);
  }, [images.length, isHovered]);

  return (
    <Link
      to={`/urunler/${product.slug}`}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => {
        setIsHovered(false);
        setImageIndex(0);
      }}
      onFocus={() => setIsHovered(true)}
      onBlur={() => {
        setIsHovered(false);
        setImageIndex(0);
      }}
      className="flex min-w-0 flex-col items-center text-center text-stone-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-800"
    >
      <div className="aspect-square w-full max-w-24 overflow-hidden rounded-full border border-stone-200 bg-stone-100 sm:max-w-28">
        <img
          key={images[imageIndex]}
          src={images[imageIndex] ?? productImageUrl(product)}
          alt={product.name}
          loading="lazy"
          className="h-full w-full animate-photo-fade object-cover"
        />
      </div>
      <h3 className="mt-2 line-clamp-2 min-h-8 w-full text-xs font-medium leading-4 sm:text-sm">
        {product.name}
      </h3>
      <p className="mt-1 text-xs tabular-nums text-stone-600">
        {product.price.toLocaleString("tr-TR", {
          style: "currency",
          currency: "TRY",
        })}
      </p>
    </Link>
  );
}

function CircularProductShowcase({ products }: CircularProductShowcaseProps) {
  return (
    <div className="grid min-w-[680px] grid-cols-7 gap-4">
      {products.slice(0, 7).map((product) => (
        <PopularProduct key={product.id} product={product} />
      ))}
    </div>
  );
}

export default CircularProductShowcase;
