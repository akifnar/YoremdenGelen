class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validate :user_must_be_buyer, on: :create

  private

  def user_must_be_buyer
    errors.add(:user, "alıcı olmalıdır") unless user&.buyer?
  end
end
