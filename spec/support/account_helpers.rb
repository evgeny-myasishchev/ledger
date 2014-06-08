module AccountHelpers
  refine Domain::Account do
    def make_created aggregate_id = nil, ledger_id = nil, name = nil, currency_code = 'UAH'
      aggregate_id = "account-#{Random.rand(100)}" unless aggregate_id
      ledger_id = "ledger-#{Random.rand(100)}" unless ledger_id
      name = "name-#{Random.rand(100)}" unless name
      self.apply_event I::AccountCreated.new aggregate_id, ledger_id, name, currency_code
      self
    end
  end
end