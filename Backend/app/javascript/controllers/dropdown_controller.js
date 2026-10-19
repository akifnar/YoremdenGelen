import { Controller } from "@hotwired/stimulus"

// Header'daki açılır menüler (Kategoriler, profil). Açık durum wrapper'daki data-open ile tutulur; görünüm ve
// açılış animasyonu CSS'te (group-data-[open]:…). Odak tabanlı CSS (focus-within) kullanılmaz: header sayfa
// geçişlerinde yerinde kaldığından tıklanan öğe odakta kalır ve menü açık takılırdı.
export default class extends Controller {
  static targets = ["button"]
  static values = { closeDelay: { type: Number, default: 120 } }

  connect() {
    this.closeOnNavigation = () => this.close()
    document.addEventListener("turbo:visit", this.closeOnNavigation)
    document.addEventListener("turbo:frame-render", this.closeOnNavigation)
  }

  disconnect() {
    clearTimeout(this.timer)
    document.removeEventListener("turbo:visit", this.closeOnNavigation)
    document.removeEventListener("turbo:frame-render", this.closeOnNavigation)
  }

  open() {
    clearTimeout(this.timer)
    this.element.dataset.open = ""
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  // İmleç menüden çıkınca kısa bir gecikmeyle kapanır; düğme ile panel arasında geçerken kırpışmaz.
  scheduleClose() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.close(), this.closeDelayValue)
  }

  close() {
    clearTimeout(this.timer)
    delete this.element.dataset.open
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  toggle() {
    "open" in this.element.dataset ? this.close() : this.open()
  }

  // Menüden bir öğe seçilince menü kapanır ve odak bırakılır.
  select() {
    this.close()
    document.activeElement?.blur()
  }

  // Klavyeyle menünün dışına çıkılınca kapanır.
  closeIfFocusLeft(event) {
    if (!this.element.contains(event.relatedTarget)) this.close()
  }
}
