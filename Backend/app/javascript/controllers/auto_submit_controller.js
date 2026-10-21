import { Controller } from "@hotwired/stimulus"

// Formu değişiklikte (ör. sepet adedi) ya da immediate değeriyle bağlanır bağlanmaz gönderir.
export default class extends Controller {
  static values = { immediate: Boolean }

  connect() {
    if (this.immediateValue) this.submit()
  }

  submit() {
    this.element.requestSubmit()
  }
}
