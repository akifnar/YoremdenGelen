import { Controller } from "@hotwired/stimulus"

// Katalog kartında imleç belirli bir süre bekletilirse ürünün hover sayacını bir kez artırır.
// Kartın üzerinden hızla geçmek sayılmaz; aynı kart için sayfa başına tek istek gönderilir.
export default class extends Controller {
  static values = { url: String, delay: { type: Number, default: 600 } }

  disconnect() {
    this.cancel()
  }

  start() {
    if (this.sent) return

    this.timer = setTimeout(() => this.record(), this.delayValue)
  }

  cancel() {
    clearTimeout(this.timer)
  }

  record() {
    this.sent = true
    const token = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.urlValue, {
      method: "POST",
      credentials: "same-origin",
      keepalive: true,
      headers: { "X-CSRF-Token": token }
    }).catch(() => {
      // Ölçüm isteğe bağlıdır; ağ hatası kullanıcıya gösterilmez.
    })
  }
}
