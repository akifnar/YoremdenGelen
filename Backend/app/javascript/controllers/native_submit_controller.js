import { Controller } from "@hotwired/stimulus"

// Turbo'suz (data-turbo="false") gönderilen formlarda turbo_submits_with yerine: gönderim sırasında düğmeyi
// kilitleyip metnini değiştirir. Tarayıcının "geri" ile sayfayı önbellekten (bfcache) açtığında düğme eski haline döner.
export default class extends Controller {
  static targets = ["button"]
  static values = { text: String }

  submit() {
    this.originalText ??= this.buttonTarget.textContent
    this.buttonTarget.disabled = true
    if (this.hasTextValue) this.buttonTarget.textContent = this.textValue
  }

  reset() {
    if (this.originalText === undefined) return

    this.buttonTarget.disabled = false
    this.buttonTarget.textContent = this.originalText
  }
}
