import { useEffect, useState } from "react";
import ActionButton from "./ActionButton";
import {
  pauseCartAction,
  resumeCartAction,
  undoCartAction,
} from "../cartActions";

type CartNotice = {
  id: string;
  message: string;
  isError?: boolean;
  undoable?: boolean;
  exiting?: boolean;
};

function CartNotifications() {
  const [notices, setNotices] = useState<CartNotice[]>([]);

  useEffect(() => {
    const addNotice = (event: Event) => {
      const detail = (event as CustomEvent<Omit<CartNotice, "isError">>).detail;
      setNotices((current) => [
        ...current.filter((notice) => notice.id !== detail.id),
        { ...detail, undoable: true },
      ]);
    };
    const dismissNotice = (event: Event) => {
      const { id } = (event as CustomEvent<{ id: string }>).detail;
      setNotices((current) =>
        current.map((notice) =>
          notice.id === id
            ? { ...notice, exiting: true, undoable: false }
            : notice,
        ),
      );
      window.setTimeout(() => {
        setNotices((current) => current.filter((notice) => notice.id !== id));
      }, 240);
    };
    const showError = (event: Event) => {
      const detail = (event as CustomEvent<{ id: string; message: string }>)
        .detail;
      setNotices((current) => [
        ...current.filter((notice) => notice.id !== detail.id),
        { ...detail, isError: true, undoable: false },
      ]);
      window.setTimeout(() => {
        setNotices((current) =>
          current.filter((notice) => notice.id !== detail.id),
        );
      }, 4000);
    };

    window.addEventListener("cart-action-notice", addNotice);
    window.addEventListener("cart-action-dismiss", dismissNotice);
    window.addEventListener("cart-action-failed", showError);
    return () => {
      window.removeEventListener("cart-action-notice", addNotice);
      window.removeEventListener("cart-action-dismiss", dismissNotice);
      window.removeEventListener("cart-action-failed", showError);
    };
  }, []);

  if (notices.length === 0) return null;

  return (
    <div
      aria-live="polite"
      aria-relevant="additions removals"
      className="pointer-events-none fixed inset-x-3 top-3 z-[70] flex flex-col items-end gap-2 sm:left-auto sm:right-5 sm:top-5 sm:w-[min(26rem,calc(100vw-2.5rem))]"
    >
      {notices.map((notice) => (
        <section
          key={notice.id}
          role={notice.isError ? "alert" : "status"}
          onMouseEnter={() => pauseCartAction(notice.id)}
          onMouseLeave={() => resumeCartAction(notice.id)}
          onFocus={() => pauseCartAction(notice.id)}
          onBlur={() => resumeCartAction(notice.id)}
          className={`cart-notice pointer-events-auto flex w-full items-center gap-3 border bg-white px-4 py-3 shadow-lg ${notice.isError ? "border-red-200" : "border-emerald-200"} ${notice.exiting ? "cart-notice-exit" : ""}`}
        >
          <span
            aria-hidden="true"
            className={`grid h-8 w-8 shrink-0 place-items-center ${notice.isError ? "bg-red-50 text-red-700" : "bg-emerald-50 text-emerald-800"}`}
          >
            {notice.isError ? "!" : "✓"}
          </span>
          <p className="min-w-0 flex-1 text-sm font-medium leading-5 text-emerald-950">
            {notice.message}
          </p>
          {notice.undoable && (
            <ActionButton
              type="button"
              variant="quiet"
              size="sm"
              onClick={() => undoCartAction(notice.id)}
              className="shrink-0 border-0 px-2 py-1 font-bold text-emerald-800 underline underline-offset-2 hover:bg-emerald-50"
            >
              Geri al
            </ActionButton>
          )}
        </section>
      ))}
    </div>
  );
}

export default CartNotifications;
