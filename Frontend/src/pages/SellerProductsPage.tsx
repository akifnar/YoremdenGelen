import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import type { Product } from "../components/ProductCard";
import productImageUrl from "../productImageUrl";

type SellerProduct = Product & {
  category: string | null;
  is_active: boolean;
};

const PRODUCT_CATEGORIES = [
  "Peynir",
  "Zeytin",
  "Zeytinyağı",
  "Et ve Şarküteri",
  "Tatlılar",
  "Hamur İşleri",
  "Süt Ürünleri",
  "Diğer Yöresel Ürünler",
] as const;
const DESCRIPTION_MAX_LENGTH = 2000;

type ProductForm = {
  name: string;
  description: string;
  category: string;
  price: string;
  stock: string;
};

const EMPTY_FORM: ProductForm = {
  name: "",
  description: "",
  category: "",
  price: "",
  stock: "",
};

function SellerProductsPage() {
  const navigate = useNavigate();
  const [products, setProducts] = useState<SellerProduct[]>([]);
  const [form, setForm] = useState<ProductForm>(EMPTY_FORM);
  const [image, setImage] = useState<File | null>(null);
  const [galleryImages, setGalleryImages] = useState<File[]>([]);
  const [editingProductId, setEditingProductId] = useState<number | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  useEffect(() => {
    let isCurrent = true;
    const loadProducts = async () => {
      try {
        const response = await fetch("/api/seller/products", {
          credentials: "same-origin",
        });
        if (response.status === 401) {
          navigate(`/login?returnTo=${encodeURIComponent("/satici/urunler")}`, {
            replace: true,
          });
          return;
        }
        const result = await response.json();
        if (!response.ok)
          throw new Error(result.errors?.join(", ") || "Ürünler alınamadı.");
        if (isCurrent) setProducts(result.data as SellerProduct[]);
      } catch (requestError) {
        if (isCurrent) {
          setError(
            requestError instanceof Error
              ? requestError.message
              : "Ürünler alınamadı.",
          );
        }
      } finally {
        if (isCurrent) setIsLoading(false);
      }
    };
    void loadProducts();
    return () => {
      isCurrent = false;
    };
  }, [navigate]);

  const resetForm = () => {
    setForm(EMPTY_FORM);
    setImage(null);
    setGalleryImages([]);
    setEditingProductId(null);
  };

  const submitProduct = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    setNotice("");
    setIsSaving(true);

    const body = new FormData();
    body.append("product[name]", form.name);
    body.append("product[description]", form.description);
    body.append("product[category]", form.category);
    body.append("product[price]", form.price);
    body.append("product[stock]", form.stock);
    if (image) body.append("product[main_image]", image);
    galleryImages.forEach((galleryImage) =>
      body.append("product[gallery_images][]", galleryImage),
    );

    try {
      const response = await fetch(
        editingProductId
          ? `/api/seller/products/${editingProductId}`
          : "/api/seller/products",
        {
          method: editingProductId ? "PATCH" : "POST",
          credentials: "same-origin",
          body,
        },
      );
      const result = await response.json();
      if (response.status === 401) {
        navigate(`/login?returnTo=${encodeURIComponent("/satici/urunler")}`, {
          replace: true,
        });
        return;
      }
      if (!response.ok)
        throw new Error(result.errors?.join(", ") || "Ürün kaydedilemedi.");

      const savedProduct = result as SellerProduct;
      setProducts((current) =>
        editingProductId
          ? current.map((product) =>
              product.id === savedProduct.id ? savedProduct : product,
            )
          : [savedProduct, ...current],
      );
      setNotice(editingProductId ? "Ürün güncellendi." : "Ürün yayınlandı.");
      resetForm();
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Ürün kaydedilemedi.",
      );
    } finally {
      setIsSaving(false);
    }
  };

  const editProduct = (product: SellerProduct) => {
    setEditingProductId(product.id);
    setForm({
      name: product.name,
      description: product.description,
      category: product.category ?? "",
      price: String(product.price),
      stock: String(product.stock),
    });
    setImage(null);
    setGalleryImages([]);
    setError("");
    setNotice("");
    window.scrollTo({ top: 0, left: 0, behavior: "smooth" });
  };

  const archiveProduct = async (productId: number) => {
    setError("");
    try {
      const response = await fetch(`/api/seller/products/${productId}`, {
        method: "DELETE",
        credentials: "same-origin",
      });
      const result = response.status === 204 ? null : await response.json();
      if (response.status === 401) {
        navigate(`/login?returnTo=${encodeURIComponent("/satici/urunler")}`, {
          replace: true,
        });
        return;
      }
      if (!response.ok)
        throw new Error(result?.errors?.join(", ") || "Ürün kaldırılamadı.");
      setProducts((current) =>
        current.map((product) =>
          product.id === productId ? { ...product, is_active: false } : product,
        ),
      );
      setNotice("Ürün yayından kaldırıldı.");
    } catch (requestError) {
      setError(
        requestError instanceof Error
          ? requestError.message
          : "Ürün kaldırılamadı.",
      );
    }
  };

  return (
    <main className="mx-auto w-full max-w-6xl px-5 py-8 sm:px-8 sm:py-12">
      <header className="border-b border-stone-200 pb-6">
        <p className="text-sm font-medium text-emerald-800">Üretici alanı</p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-emerald-950">
          Yöresel ürünlerini paylaş
        </h1>
        <p className="mt-3 max-w-2xl text-sm leading-6 text-stone-600">
          Ürünlerini yayınla, bilgilerini güncelle veya yayından kaldır. Tüm
          zorunlu alanlar sunucuda doğrulanır.
        </p>
      </header>

      <section className="mt-7 border border-stone-200 bg-white p-5 sm:p-7">
        <h2 className="text-lg font-semibold text-stone-900">
          {editingProductId ? "Ürünü düzenle" : "Yeni ürün ekle"}
        </h2>
        <form
          onSubmit={(event) => void submitProduct(event)}
          className="mt-5 grid gap-4 sm:grid-cols-2"
        >
          <label className="text-sm font-medium text-stone-700">
            Ürün adı
            <input
              required
              maxLength={120}
              value={form.name}
              onChange={(event) =>
                setForm({ ...form, name: event.target.value })
              }
              className="seller-field mt-1 w-full border border-stone-300 px-3 py-2.5 font-normal"
            />
          </label>
          <label className="text-sm font-medium text-stone-700">
            Kategori
            <select
              required
              value={form.category}
              onChange={(event) =>
                setForm({ ...form, category: event.target.value })
              }
              className="seller-field mt-1 w-full border border-stone-300 bg-white px-3 py-2.5 font-normal"
            >
              <option value="">Kategori seçin</option>
              {PRODUCT_CATEGORIES.map((category) => (
                <option key={category} value={category}>
                  {category}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm font-medium text-stone-700">
            Fiyat (₺)
            <input
              required
              type="number"
              max="99999999.99"
              min="0.01"
              step="0.01"
              value={form.price}
              onChange={(event) =>
                setForm({ ...form, price: event.target.value })
              }
              className="mt-1 w-full border border-stone-300 px-3 py-2.5 font-normal"
            />
          </label>
          <label className="text-sm font-medium text-stone-700">
            Stok adedi
            <input
              required
              type="number"
              max="2147483647"
              min="0"
              step="1"
              value={form.stock}
              onChange={(event) =>
                setForm({ ...form, stock: event.target.value })
              }
              className="mt-1 w-full border border-stone-300 px-3 py-2.5 font-normal"
            />
          </label>
          <label className="text-sm font-medium text-stone-700 sm:col-span-2">
            Açıklama
            <textarea
              required
              maxLength={DESCRIPTION_MAX_LENGTH}
              rows={4}
              value={form.description}
              onChange={(event) =>
                setForm({ ...form, description: event.target.value })
              }
              className="seller-field mt-1 w-full resize-y border border-stone-300 px-3 py-2.5 font-normal"
            />
            <span className="mt-1 block text-right text-xs font-normal text-stone-500">
              {form.description.length}/{DESCRIPTION_MAX_LENGTH}
            </span>
          </label>
          <label className="text-sm font-medium text-stone-700 sm:col-span-2">
            Ana ürün fotoğrafı
            <input
              required={!editingProductId}
              type="file"
              accept="image/*"
              onChange={(event) => setImage(event.target.files?.[0] ?? null)}
              className="seller-file mt-1 block w-full border border-stone-300 px-3 py-2 text-sm font-normal"
            />
          </label>
          <label className="text-sm font-medium text-stone-700 sm:col-span-2">
            Ek fotoğraflar (isteğe bağlı)
            <input
              type="file"
              accept="image/*"
              multiple
              onChange={(event) =>
                setGalleryImages(Array.from(event.target.files ?? []))
              }
              className="seller-file mt-1 block w-full border border-stone-300 px-3 py-2 text-sm font-normal"
            />
          </label>
          {error && (
            <p role="alert" className="text-sm text-red-700 sm:col-span-2">
              {error}
            </p>
          )}
          {notice && (
            <p role="status" className="text-sm text-emerald-800 sm:col-span-2">
              {notice}
            </p>
          )}
          <div className="flex flex-wrap gap-2 sm:col-span-2">
            <button
              type="submit"
              disabled={isSaving}
              className="seller-publish bg-emerald-900 px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-emerald-800 disabled:opacity-50"
            >
              {isSaving
                ? "Kaydediliyor…"
                : editingProductId
                  ? "Değişiklikleri kaydet"
                  : "Ürünü yayınla"}
            </button>
            {editingProductId && (
              <button
                type="button"
                onClick={resetForm}
                className="border border-stone-300 px-5 py-2.5 text-sm text-stone-700 transition-colors hover:bg-stone-100"
              >
                Vazgeç
              </button>
            )}
          </div>
        </form>
      </section>

      <section className="mt-10" aria-labelledby="seller-products-heading">
        <h2
          id="seller-products-heading"
          className="text-xl font-semibold text-emerald-950"
        >
          Ürün listen
        </h2>
        {isLoading ? (
          <div className="mt-4 h-28 animate-pulse bg-stone-100" />
        ) : products.length === 0 ? (
          <p className="mt-4 border border-stone-200 bg-white p-5 text-sm text-stone-600">
            Henüz ürün eklememişsin. İlk ürününü yukarıdaki formdan
            yayınlayabilirsin.
          </p>
        ) : (
          <ul className="mt-4 divide-y divide-stone-200 border-y border-stone-200 bg-white">
            {products.map((product) => (
              <li
                key={product.id}
                className="flex flex-wrap items-center gap-4 p-4 sm:flex-nowrap"
              >
                <img
                  src={productImageUrl(product)}
                  alt=""
                  className="h-16 w-16 shrink-0 object-cover"
                  loading="lazy"
                />
                <div className="min-w-0 flex-1">
                  <h3 className="truncate font-medium text-stone-900">
                    {product.name}
                  </h3>
                  <p className="mt-1 text-sm text-stone-600">
                    {product.price.toLocaleString("tr-TR", {
                      style: "currency",
                      currency: "TRY",
                    })}
                    <span className="px-2 text-stone-400">·</span>
                    Stok: {product.stock}
                    <span className="px-2 text-stone-400">·</span>
                    {product.is_active ? "Yayında" : "Yayından kaldırıldı"}
                  </p>
                </div>
                <div className="flex gap-2">
                  {product.is_active && (
                    <>
                      <button
                        type="button"
                        onClick={() => editProduct(product)}
                        className="border border-stone-300 px-3 py-2 text-sm text-stone-700 transition-colors hover:bg-stone-100"
                      >
                        Düzenle
                      </button>
                      <button
                        type="button"
                        onClick={() => void archiveProduct(product.id)}
                        className="border border-stone-300 px-3 py-2 text-sm text-stone-700 transition-colors hover:border-red-300 hover:bg-red-50 hover:text-red-800"
                      >
                        Yayından kaldır
                      </button>
                    </>
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}

export default SellerProductsPage;
