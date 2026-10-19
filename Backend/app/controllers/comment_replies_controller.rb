# Satıcının, kendi ürünündeki bir alıcı yorumuna tek cevabı. Satıcı puan veremez ve cevabını silemez;
# cevap, alıcı yorumunu silince onunla birlikte silinir.
class CommentRepliesController < ApplicationController
  before_action -> { require_role!("seller", message: "Yalnızca satıcılar cevap yazabilir") }

  rescue_from ActiveRecord::RecordNotFound do
    respond_with_error("Yorum bulunamadı", :not_found)
  end

  def create
    parent = Comment.top_level.includes(:product).find(params[:comment_id])
    return respond_with_error("Yalnızca kendi ürünündeki yorumlara cevap yazabilirsin", :forbidden) unless parent.product.seller_id == current_user.id
    return respond_with_error("Bu yoruma zaten cevap verdin", :unprocessable_entity) if parent.reply

    body = reply_params[:body].to_s.strip
    return respond_with_error("Cevap boş bırakılamaz", :unprocessable_entity) if body.blank?
    return respond_with_error("Cevap en fazla #{Comment::BODY_MAX_LENGTH} karakter olabilir", :unprocessable_entity) if body.length > Comment::BODY_MAX_LENGTH

    parent.create_reply!(product: parent.product, user: current_user, body: body)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(parent, partial: "comments/comment",
                                                  locals: { comment: parent.reload, product: parent.product, my_reaction: nil })
      end
      format.html { redirect_to product_path(parent.product), notice: "Cevabın eklendi.", status: :see_other }
    end
  rescue ActiveRecord::RecordNotUnique
    respond_with_error("Bu yoruma zaten cevap verdin", :unprocessable_entity)
  rescue ActiveRecord::RecordInvalid => error
    respond_with_error(error.record.errors.full_messages.to_sentence, :unprocessable_entity)
  end

  private

  def reply_params
    permitted_params(reply: [ :body ])[:reply] || ActionController::Parameters.new
  end
end
