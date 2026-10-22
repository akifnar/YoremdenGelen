# Satın almış alıcının ürüne verdiği 1–5 yıldız; yorumdan bağımsızdır ve bir kez verilir.
class ProductRatingsController < ApplicationController
  before_action -> { require_role!("buyer", message: "Yalnızca alıcılar puan verebilir") }

  rescue_from ActiveRecord::RecordNotFound do
    respond_with_error("Ürün bulunamadı", :not_found)
  end

  def create
    @product = Product.active.find(params[:product_id])
    purchase = current_user.purchase_of(@product)
    return respond_with_error("Puan vermek için bu ürünü satın almış olmalısın", :forbidden) unless purchase
    return respond_with_error("Bu ürüne zaten puan verdin", :unprocessable_entity) if purchase.rated?

    stars = rating_params[:rating].to_s
    return render_form([ "1 ile 5 arasında yıldız seçmelisin" ]) unless stars.match?(/\A[1-5]\z/)

    purchase.rate!(stars.to_i)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("rating_form"),
          turbo_stream.replace(dom_id(@product, :rating), partial: "products/rating_summary", locals: { product: @product })
        ], status: :created
      end
      format.html { redirect_to product_path(@product), notice: "Puanın kaydedildi.", status: :see_other }
    end
  rescue ActiveRecord::RecordInvalid => error
    render_form(error.record.errors.full_messages)
  end

  private

  def render_form(errors)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("rating_form", partial: "product_ratings/form", locals: { product: @product, errors: errors }),
               status: :unprocessable_entity
      end
      format.html { redirect_to product_path(@product), alert: errors.to_sentence, status: :see_other }
    end
  end

  def rating_params
    permitted_params(product_rating: [ :rating ])[:product_rating] || ActionController::Parameters.new
  end
end
