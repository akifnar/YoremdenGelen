class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  before_validation :generate_token, on: :create

  validates :token, presence: true, uniqueness: true, format: { with: /\A[0-9a-f-]{36}\z/i }

  private

  def generate_token
    self.token ||= SecureRandom.uuid
  end
end
