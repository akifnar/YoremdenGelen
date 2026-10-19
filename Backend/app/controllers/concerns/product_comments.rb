# Ürün sayfasının yorum bölümü için gereken veriler; ProductsController#show (ilk sayfa) ve
# CommentsController#index (Turbo Frame içinde sonraki sayfalar) aynı yükleyiciyi kullanır.
module ProductComments
  extend ActiveSupport::Concern
  include Pagy::Backend

  COMMENTS_PER_PAGE = 10

  private

  # Sorgular: alıcı yorumları kısmi index'le (product_id, created_at WHERE parent_id IS NULL) sayfalanır,
  # yazar ve satıcı cevabı tek seferde yüklenir (N+1 yok). Alıcının o sayfadaki tepkileri tek sorguyla,
  # yorum yetkisi ise product_purchases'in benzersiz index'iyle tek sorguyla bulunur.
  def load_product_comments(product, page: 1)
    scope = product.comments.top_level
    @comments_pagy, @comments = pagy(
      scope.includes(user: { avatar_attachment: :blob }, reply: { user: { avatar_attachment: :blob } })
           .order(created_at: :desc, id: :desc),
      count: scope.count, limit: COMMENTS_PER_PAGE, page: page, request_path: product_comments_path(product)
    )
    @my_reactions = if current_user&.buyer?
      CommentReaction.where(user: current_user, comment_id: @comments.map(&:id)).pluck(:comment_id, :kind).to_h
    else
      {}
    end
    @purchase = current_user&.purchase_of(product)
  end
end
