export type CartLine = {
  id: number;
  quantity: number;
  line_total: number;
  product: {
    id: number;
    name: string;
    slug: string;
    price: number;
    stock: number;
    is_active: boolean;
    main_image_url: string | null;
  };
};

export type Cart = {
  token: string;
  item_count: number;
  subtotal: number;
  items: CartLine[];
};

export function getCartToken(): string {
  let token = window.localStorage.getItem("cart-token");
  if (!token) {
    token = window.crypto.randomUUID();
    window.localStorage.setItem("cart-token", token);
  }
  return token;
}

export class CartRequestError extends Error {
  readonly status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export async function cartRequest(
  path: string,
  options: RequestInit = {},
): Promise<Cart> {
  const response = await fetch(`/api/cart${path}`, {
    ...options,
    credentials: "same-origin",
    headers: {
      "Content-Type": "application/json",
      "X-Cart-Token": getCartToken(),
      ...options.headers,
    },
  });
  const result = await response.json();
  if (!response.ok) {
    throw new CartRequestError(
      result.errors?.join(", ") || result.error || "Sepet işlemi başarısız",
      response.status,
    );
  }
  if (options.method && options.method.toUpperCase() !== "GET") {
    window.dispatchEvent(new Event("cart-changed"));
  }
  return result as Cart;
}
