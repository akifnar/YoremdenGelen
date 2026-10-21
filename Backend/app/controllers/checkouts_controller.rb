# "Siparişi tamamla": sepeti siparişe çevirir (Checkout). Sipariş, alınan ürünlere yorum yetkisi verir.
class CheckoutsController < CartBaseController
  def create
    order = Checkout.new(cart).place!
    redirect_to cart_path, status: :see_other,
                notice: "Siparişin alındı (No: #{order.id}). Satın aldığın ürünlere artık yorum yazabilirsin."
  rescue Checkout::Error, ActiveRecord::RecordInvalid => error
    redirect_to cart_path, alert: error.message, status: :see_other
  end
end
