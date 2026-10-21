import { Controller } from "@hotwired/stimulus"

// Ürün detayındaki − / + düğmeleri; değer input'un min/max sınırları içinde tutulur.
export default class extends Controller {
  static targets = ["input"]

  decrement() {
    this.change(-1)
  }

  increment() {
    this.change(1)
  }

  change(delta) {
    const input = this.inputTarget
    const min = Number(input.min) || 1
    const max = Number(input.max) || Infinity
    const current = Number(input.value) || min
    input.value = Math.min(max, Math.max(min, current + delta))
  }
}
