# Alıcıların yorumlara like/dislike'ı. Aynı tepkiye tekrar basmak geri alır, diğerine basmak değiştirir.
class CommentReactionsController < ApplicationController
  before_action -> { require_role!("buyer", message: "Yalnızca alıcılar tepki verebilir") }

  rescue_from ActiveRecord::RecordNotFound do
    respond_with_error("Yorum bulunamadı", :not_found)
  end

  def create
    comment = Comment.top_level.find(params[:comment_id])
    kind = params[:kind].to_s
    return respond_with_error("Geçersiz tepki", :unprocessable_entity) unless CommentReaction::KINDS.include?(kind)
    return respond_with_error("Kendi yorumuna tepki veremezsin", :forbidden) if comment.user_id == current_user.id

    reaction = CommentReaction.toggle!(comment: comment, user: current_user, kind: kind)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(dom_id(comment, :reactions), partial: "comments/reactions",
                                                  locals: { comment: comment.reload, my_reaction: reaction&.kind })
      end
      format.html { redirect_to product_path(comment.product_id), status: :see_other }
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_with_error(error.record.errors.full_messages.to_sentence, :unprocessable_entity)
  end
end
