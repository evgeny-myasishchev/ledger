module LedgerHelpers
  refine Domain::Ledger do
    def make_created owner_user_id = 100, aggregate_id = nil, name = nil
      aggregate_id = "ledger-#{Random.rand(100)}" unless aggregate_id
      name = "name-#{Random.rand(100)}" unless name
      self.apply_event Domain::Events::LedgerCreated.new aggregate_id, owner_user_id, name
      self
    end
  end
end