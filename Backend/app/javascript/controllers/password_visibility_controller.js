import { Controller } from "@hotwired/stimulus"

// Şifre yalnızca düğme basılı tutulduğu sürece görünür.
export default class extends Controller {
  static targets = ["input", "toggle"]

  show(event) {
    event.preventDefault()
    this.setVisible(true)
  }

  hide() {
    this.setVisible(false)
  }

  setVisible(visible) {
    this.inputTarget.type = visible ? "text" : "password"
    this.toggleTarget.setAttribute("aria-pressed", visible)
    this.toggleTarget.setAttribute("aria-label", visible ? "Şifreyi gizle" : "Şifreyi göster")
  }
}
