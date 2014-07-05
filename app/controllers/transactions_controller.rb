class TransactionsController < ApplicationController
  def index
    @transactions = Projections::Transaction.get_account_transactions current_user, params[:account_id]
    respond_to do |format|
      format.json { render json: @transactions }
    end
  end
end
