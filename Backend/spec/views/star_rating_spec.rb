require "rails_helper"

RSpec.describe "Yıldızlı puan bileşenleri", type: :view do
  it "renders five required star radios valued 5..1 in DOM order (shown 1..5) instead of a number field" do
    render inline: <<~ERB
      <%= form_with url: "/yorum", scope: :comment do |form| %>
        <%= render "shared/star_rating_field", form: form %>
      <% end %>
    ERB

    radios = rendered.scan(/<input[^>]*type="radio"[^>]*>/)
    expect(radios.size).to eq(5)
    expect(radios.map { |radio| radio[/value="(\d)"/, 1] }).to eq(%w[5 4 3 2 1])
    expect(radios).to all(include('name="comment[rating]"', "required"))
    expect(rendered).to include('class="star-input', "★", "3 yıldız")
    expect(rendered).not_to include('type="number"')
  end

  it "fills the read-only stars in proportion to the average rating" do
    render partial: "shared/stars", locals: { rating: 4.3, count: 12 }

    expect(rendered).to include("width: 86.0%", "4,3 · 12 değerlendirme", 'aria-label="4,3 / 5 puan"')
  end
end
