import ActionButton from "./ActionButton";

type Product = {
  id: number;
  name: string;
  description: string;
  price: number;
  stock: number;
  slug: string;
  category?: string | null;
  main_image_url: string | null;
  gallery_image_urls?: string[];
};

type ProductCardProps = {
  product: Product;
};

function ProductCard({ product }: ProductCardProps) {
  return (
    <article className="group overflow-hidden border border-emerald-100 bg-white">
      <div className="relative aspect-[4/3] overflow-hidden bg-emerald-50">
        {product.main_image_url ? (
          <img
            src={product.main_image_url}
            alt={product.name}
            className="h-full w-full object-cover"
          />
        ) : (
          <div
            className="grid h-full place-items-center text-5xl"
            aria-hidden="true"
          >
            🧺
          </div>
        )}
        {product.stock <= 0 && (
          <span className="absolute left-3 top-3 rounded-full bg-stone-900/80 px-3 py-1 text-xs font-semibold text-white">
            Tükendi
          </span>
        )}
      </div>
      <div className="p-5">
        <h3 className="truncate text-lg font-semibold text-emerald-950">
          {product.name}
        </h3>
        <p className="mt-2 min-h-12 text-sm leading-6 text-stone-600">
          {product.description}
        </p>
        <div className="mt-5 flex items-center justify-between gap-3">
          <strong className="text-lg text-emerald-800">
            {product.price.toLocaleString("tr-TR", {
              style: "currency",
              currency: "TRY",
            })}
          </strong>
          <ActionButton
            to={`/urunler/${product.slug}`}
            variant="secondary"
            size="sm"
          >
            İncele
          </ActionButton>
        </div>
      </div>
    </article>
  );
}

export type { Product };
export default ProductCard;
