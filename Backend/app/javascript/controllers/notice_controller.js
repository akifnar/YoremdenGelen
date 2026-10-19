import { Controller } from "@hotwired/stimulus"

// Bildirimi birkaç saniye sonra çıkış animasyonuyla kaldırır; üzerine gelince süre durur.
export default class extends Controller {
  static values = { timeout: { type: Number, default: 4000 } }

  connect() {
    this.resume()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  pause() {
    clearTimeout(this.timer)
  }

  resume() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.element.classList.add("cart-notice-exit")
    setTimeout(() => this.element.remove(), 240)
  }
}
