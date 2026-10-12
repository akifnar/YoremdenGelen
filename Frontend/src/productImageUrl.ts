type ProductImageSource = {
  id: number;
  slug: string;
  main_image_url: string | null;
};

const regionalFoodPhotos = [
  "photo-1547592180-85f173990554",
  "photo-1546069901-ba9599a7e63c",
  "photo-1504674900247-0877df9cc836",
];

export function foodImageUrl(productId: number, offset = 0): string {
  const photoIndex = Math.abs(productId + offset) % regionalFoodPhotos.length;
  return `https://images.unsplash.com/${regionalFoodPhotos[photoIndex]}?auto=format&fit=crop&w=900&q=80`;
}

function productImageUrl(product: ProductImageSource): string {
  return product.main_image_url || foodImageUrl(product.id);
}

export default productImageUrl;
