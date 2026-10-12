import type { ButtonHTMLAttributes, ReactNode } from "react";
import { Link } from "react-router-dom";

type ActionVariant =
  "primary" | "accent" | "secondary" | "danger" | "quiet" | "icon";
type ActionSize = "sm" | "md" | "lg" | "icon";

type ActionButtonProps = Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  "className" | "children" | "type"
> & {
  to?: string;
  variant?: ActionVariant;
  size?: ActionSize;
  className?: string;
  children: ReactNode;
  type?: "button" | "submit" | "reset";
};

const VARIANT_CLASSES: Record<ActionVariant, string> = {
  primary:
    "border-emerald-900 bg-emerald-900 text-white hover:border-emerald-800 hover:bg-emerald-800",
  accent:
    "border-lime-300 bg-lime-300 text-emerald-950 hover:border-lime-200 hover:bg-lime-200",
  secondary:
    "border-stone-300 bg-white text-stone-700 hover:border-emerald-700 hover:bg-emerald-50 hover:text-emerald-950",
  danger:
    "border-red-700 bg-white text-red-700 hover:bg-red-50 hover:text-red-800",
  quiet:
    "border-transparent bg-transparent text-stone-600 hover:bg-stone-100 hover:text-stone-950",
  icon: "border-transparent bg-transparent text-stone-600 hover:bg-stone-100 hover:text-stone-950",
};

const SIZE_CLASSES: Record<ActionSize, string> = {
  sm: "px-3 py-2 text-sm",
  md: "px-4 py-2.5 text-sm",
  lg: "px-5 py-3 text-sm",
  icon: "h-10 w-10 p-0 text-lg",
};

function ActionButton({
  to,
  variant = "secondary",
  size = "md",
  className = "",
  children,
  type = "button",
  title,
  "aria-label": ariaLabel,
  "aria-pressed": ariaPressed,
  "aria-busy": ariaBusy,
  ...buttonProps
}: ActionButtonProps) {
  const classes = `inline-flex items-center justify-center gap-2 border font-medium transition-colors duration-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-700 disabled:cursor-not-allowed disabled:opacity-50 ${VARIANT_CLASSES[variant]} ${SIZE_CLASSES[size]} ${className}`;

  if (to) {
    return (
      <Link
        to={to}
        title={title}
        aria-label={ariaLabel}
        aria-pressed={ariaPressed}
        aria-busy={ariaBusy}
        className={classes}
      >
        {children}
      </Link>
    );
  }

  return (
    <button
      {...buttonProps}
      type={type}
      title={title}
      aria-label={ariaLabel}
      aria-pressed={ariaPressed}
      aria-busy={ariaBusy}
      className={classes}
    >
      {children}
    </button>
  );
}

export default ActionButton;
