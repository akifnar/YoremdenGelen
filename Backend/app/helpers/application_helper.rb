module ApplicationHelper
  # pagy_url_for (sayfa bağlantısı üretimi) için; Pagy::Backend'in hesapladığı Pagy nesnesini kullanır.
  include Pagy::Frontend

  BUTTON_BASE_CLASSES = "inline-flex items-center justify-center gap-2 rounded-[4px] border font-semibold transition-colors duration-200 " \
                        "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--blue)] " \
                        "disabled:cursor-not-allowed disabled:opacity-50".freeze

  BUTTON_VARIANT_CLASSES = {
    # primary/accent: temanın mavi eylem düğmesi (.btn-blue: basılı his + parlama efekti).
    primary: "btn-blue border-transparent",
    accent: "btn-blue border-transparent",
    secondary: "border-[var(--line)] bg-[var(--paper-hi)] text-[var(--ink-2)] hover:border-[rgba(34,30,23,0.32)] hover:bg-[var(--kraft)] hover:text-[var(--ink)]",
    danger: "border-[#a94438] bg-[var(--paper-hi)] text-[#a94438] hover:bg-[#a94438] hover:text-[var(--paper-hi)]",
    quiet: "border-transparent bg-transparent text-[var(--ink-2)] hover:bg-[var(--kraft)] hover:text-[var(--ink)]"
  }.freeze

  BUTTON_SIZE_CLASSES = {
    sm: "px-3 py-2 text-sm",
    md: "px-4 py-2.5 text-sm",
    lg: "px-5 py-3 text-sm",
    icon: "h-10 w-10 p-0 text-lg"
  }.freeze

  # React'teki ActionButton bileşeninin sınıf karşılığı; link_to / button_to / f.submit ile kullanılır.
  def button_classes(variant: :secondary, size: :md, extra: nil)
    [ BUTTON_BASE_CLASSES, BUTTON_VARIANT_CLASSES.fetch(variant), BUTTON_SIZE_CLASSES.fetch(size), extra ].compact.join(" ")
  end

  ROLE_LABELS = { "buyer" => "Alıcı", "seller" => "Satıcı", "admin" => "Admin" }.freeze

  def role_label(role)
    ROLE_LABELS.fetch(role.to_s, role.to_s)
  end

  # Büyük sayıları kısaltır: 1.284 / 12,9 B / 4,2 Mn
  def compact_number(value)
    return number_with_delimiter(value, delimiter: ".") if value < 10_000

    number_to_human(value, units: { thousand: "B", million: "Mn", billion: "Mr" }, format: "%n %u",
                           precision: 1, significant: false, separator: ",", delimiter: ".")
  end

  # tr-TR para biçimi: ₺1.234,50
  def format_price(amount)
    number_to_currency(amount.to_d, unit: "₺", separator: ",", delimiter: ".", format: "%u%n", precision: 2)
  end

  def cart_icon(css_class: "h-5 w-5 shrink-0")
    tag.svg(aria: { hidden: true }, viewBox: "0 0 24 24", class: css_class, fill: "none", stroke: "currentColor",
            "stroke-width": "1.7", "stroke-linecap": "square", "stroke-linejoin": "miter") do
      safe_join([
        tag.path(d: "M3 4h2l2.1 10.2a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 1.9-1.4L21 8H6"),
        tag.circle(cx: "10", cy: "20", r: "1"),
        tag.circle(cx: "18", cy: "20", r: "1")
      ])
    end
  end
end
