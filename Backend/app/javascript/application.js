// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Sayfa geçişleri <turbo-frame id="main"> içinde olduğu için Turbo sayfayı kendiliğinden başa kaydırmaz.
document.addEventListener("turbo:frame-load", (event) => {
  if (event.target.id === "main") window.scrollTo({ top: 0 })
})

// Yanıt main frame'ini içermiyorsa (main_frame layout'u dışında render edilmiş bir sayfa) tam sayfa geçişine düş.
document.addEventListener("turbo:frame-missing", (event) => {
  if (event.target.id !== "main") return
  event.preventDefault()
  event.detail.visit(event.detail.response.url)
})
