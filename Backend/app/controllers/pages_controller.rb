class PagesController < ApplicationController
  skip_before_action :authenticate_request!

  def about; end
  def faq; end
  def shipping_returns; end
  def privacy; end
  def terms; end

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.any { head :not_found }
    end
  end
end
