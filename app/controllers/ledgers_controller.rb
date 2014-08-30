class LedgersController < ApplicationController
  def currency_rates
    @rates = Projections::Ledger.get_rates current_user, params[:ledger_id]
    respond_to do |format|
      format.json { render json: @rates }
    end
  end
end
