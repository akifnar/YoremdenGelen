type AddToCartButtonProps = {
  onClick: () => void;
  disabled?: boolean;
  isAdding?: boolean;
  className?: string;
};

function AddToCartButton({
  onClick,
  disabled = false,
  isAdding = false,
  className = "",
}: AddToCartButtonProps) {
  return (
    <button
      type="button"
      aria-label={isAdding ? "Sepete ekleniyor" : "Sepete ekle"}
      aria-busy={isAdding}
      title="Sepete ekle"
      onClick={onClick}
      disabled={disabled || isAdding}
      className={className}
    >
      <svg
        aria-hidden="true"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="square"
        strokeLinejoin="miter"
        className={`h-5 w-5 ${isAdding ? "opacity-40" : "opacity-70"}`}
      >
        <path d="M3 4h2l2.1 10.1a2 2 0 0 0 2 1.6h7.8a2 2 0 0 0 1.9-1.4L21 8H6" />
        <circle cx="10" cy="20" r="1" />
        <circle cx="18" cy="20" r="1" />
      </svg>
      <span className="sr-only">{isAdding ? "Sepete ekleniyor" : "Sepete ekle"}</span>
    </button>
  );
}

export default AddToCartButton;
