import type { Cart, CartLine } from "./cartApi";

export const CART_UNDO_WINDOW_MS = 1800;

type CartDelta = { item_count: number; subtotal: number };

type QueuedCartAction = {
  id: string;
  message: string;
  delta: CartDelta;
  execute: () => Promise<Cart>;
  restoreLine?: CartLine;
  restoreLines?: CartLine[];
  restoreIndex?: number;
  timeout: number | null;
  remaining: number;
  deadline: number;
  paused: boolean;
  executing: boolean;
};

const queuedActions = new Map<string, QueuedCartAction>();

function dispatch(name: string, detail: unknown) {
  window.dispatchEvent(new CustomEvent(name, { detail }));
}

function beginTimer(action: QueuedCartAction) {
  action.deadline = Date.now() + action.remaining;
  action.timeout = window.setTimeout(
    () => void executeAction(action),
    action.remaining,
  );
}

async function executeAction(action: QueuedCartAction) {
  if (!queuedActions.has(action.id) || action.paused) return;
  action.timeout = null;
  action.executing = true;
  dispatch("cart-action-dismiss", { id: action.id });

  try {
    const cart = await action.execute();
    queuedActions.delete(action.id);
    dispatch("cart-action-committed", { id: action.id, cart });
  } catch (error) {
    queuedActions.delete(action.id);
    dispatch("cart-preview-cancel", { id: action.id });
    dispatch("cart-action-failed", {
      id: action.id,
      message: error instanceof Error ? error.message : "Sepet güncellenemedi.",
      restoreLine: action.restoreLine,
      restoreLines: action.restoreLines,
      restoreIndex: action.restoreIndex,
    });
  }
}

export function queueCartAction(input: {
  message: string;
  delta: CartDelta;
  execute: () => Promise<Cart>;
  restoreLine?: CartLine;
  restoreLines?: CartLine[];
  restoreIndex?: number;
}): string {
  const id = window.crypto.randomUUID();
  const action: QueuedCartAction = {
    ...input,
    id,
    timeout: null,
    remaining: CART_UNDO_WINDOW_MS,
    deadline: 0,
    paused: false,
    executing: false,
  };
  queuedActions.set(id, action);
  dispatch("cart-preview-change", { id, delta: action.delta });
  dispatch("cart-action-notice", { id, message: action.message });
  beginTimer(action);
  return id;
}

export function pauseCartAction(id: string) {
  const action = queuedActions.get(id);
  if (!action || action.executing || action.paused || action.timeout === null)
    return;

  action.remaining = Math.max(0, action.deadline - Date.now());
  window.clearTimeout(action.timeout);
  action.timeout = null;
  action.paused = true;
}

export function resumeCartAction(id: string) {
  const action = queuedActions.get(id);
  if (!action || action.executing || !action.paused) return;

  action.paused = false;
  beginTimer(action);
}

export function undoCartAction(id: string) {
  const action = queuedActions.get(id);
  if (!action || action.executing) return;

  if (action.timeout !== null) window.clearTimeout(action.timeout);
  queuedActions.delete(id);
  dispatch("cart-preview-cancel", { id });
  dispatch("cart-action-undone", {
    id,
    restoreLine: action.restoreLine,
    restoreLines: action.restoreLines,
    restoreIndex: action.restoreIndex,
  });
  dispatch("cart-action-dismiss", { id });
}
