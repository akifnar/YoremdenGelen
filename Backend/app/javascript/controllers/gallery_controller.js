import { Controller } from "@hotwired/stimulus"

// Ürün detayındaki büyük görseli küçük resimler ve ‹ › düğmeleriyle değiştirir.
export default class extends Controller {
  static targets = ["image", "thumb"]

  connect() {
    this.index = 0
  }

  previous() {
    this.select(this.index - 1)
  }

  next() {
    this.select(this.index + 1)
  }

  show({ params: { index } }) {
    this.select(index)
  }

  select(index) {
    const count = this.thumbTargets.length
    if (count === 0) return

    this.index = (index + count) % count
    const thumb = this.thumbTargets[this.index]
    this.imageTarget.src = thumb.dataset.url
    this.imageTarget.alt = this.imageTarget.alt.replace(/ \d+$/, "") + ` ${this.index + 1}`
    this.restartAnimation()
    this.thumbTargets.forEach((element, position) => element.setAttribute("aria-pressed", position === this.index))
  }

  restartAnimation() {
    this.imageTarget.classList.remove("motion-safe:animate-photo-fade")
    void this.imageTarget.offsetWidth
    this.imageTarget.classList.add("motion-safe:animate-photo-fade")
  }
}
