class CommentsController < ApplicationController
  include CategoryPagination # requested_page
  include ProductComments

  skip_before_action :authenticate_request!, only: :index
  before_action :require_buyer!, only: [ :create, :destroy ]

  rescue_from ActiveRecord::RecordNotFound do
    respond_with_error("Ürün ya da yorum bulunamadı", :not_found)
  end

  # Yorumların sonraki sayfaları (Turbo-Frame: product_comments): ürün sayfasının tamamı yerine yalnızca liste
  # render edilir.
  def index
    @product = Product.active.find(params[:product_id])
    load_product_comments(@product, page: requested_page)
    render partial: "comments/list", locals: { product: @product, comments: @comments, pagy: @comments_pagy, my_reactions: @my_reactions, can_react: @purchase.present? }
  end

  # Controller seviyesi: yalnızca bu ürünü satın almış alıcı (product_purchases'te satır), dolu ve en fazla
  # 2000 karakterlik metin, ilk yorumda 1–5 yıldız. Model seviyesi: Comment ve ProductPurchase doğrulamaları.
  def create
    @product = Product.active.find(params[:product_id])
    @purchase = current_user.purchase_of(@product)
    return respond_with_error("Yorum yazmak için bu ürünü satın almış olmalısın", :forbidden) unless @purchase

    body = comment_params[:body].to_s.strip
    rating = comment_params[:rating].to_s
    errors = body_errors(body)
    errors << "İlk yorumunda 1 ile 5 arasında yıldız seçmelisin" if !@purchase.rated? && !rating.match?(/\A[1-5]\z/)
    return render_form(errors) if errors.any?

    @comment = Comment.transaction do
      comment = @product.comments.create!(user: current_user, body: body)
      @purchase.rate!(rating.to_i, comment: comment) unless @purchase.rated?
      comment
    end

    respond_to do |format|
      format.turbo_stream do
        @product.reload
        render turbo_stream: [
          turbo_stream.remove("comments_empty"),
          turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment, product: @product, my_reaction: nil, can_react: true }),
          turbo_stream.replace("comment_form", partial: "comments/form", locals: { product: @product, purchase: @purchase.reload }),
          turbo_stream.replace("comments_count", partial: "comments/count", locals: { product: @product }),
          turbo_stream.replace(dom_id(@product, :rating), partial: "products/rating_summary", locals: { product: @product })
        ], status: :created
      end
      format.html { redirect_to product_path(@product), notice: "Yorumun eklendi.", status: :see_other }
    end
  rescue ActiveRecord::RecordInvalid => error
    render_form(error.record.errors.full_messages)
  end

  # Yalnızca alıcı, yalnızca kendi yorumu; bağlı satıcı cevabı ve tepkiler de silinir. Puan kalır.
  def destroy
    comment = Comment.top_level.find(params[:id])
    return respond_with_error("Yalnızca kendi yorumunu silebilirsin", :forbidden) unless comment.user_id == current_user.id

    comment.destroy!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(comment),
          turbo_stream.replace("comments_count", partial: "comments/count", locals: { product: comment.product })
        ]
      end
      format.html { redirect_to product_path(comment.product), notice: "Yorumun silindi.", status: :see_other }
    end
  end

  private

  def require_buyer!
    require_role!("buyer", message: "Yalnızca alıcılar yorum yazabilir ve silebilir")
  end

  def body_errors(body)
    errors = []
    errors << "Yorum boş bırakılamaz" if body.blank?
    errors << "Yorum en fazla #{Comment::BODY_MAX_LENGTH} karakter olabilir" if body.length > Comment::BODY_MAX_LENGTH
    errors
  end

  def render_form(errors)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form",
                                                  locals: { product: @product, purchase: @purchase, errors: errors }),
               status: :unprocessable_entity
      end
      format.html { redirect_to product_path(@product), alert: errors.to_sentence, status: :see_other }
    end
  end

  def comment_params
    permitted_params(comment: [ :body, :rating ])[:comment] || ActionController::Parameters.new
  end
end
