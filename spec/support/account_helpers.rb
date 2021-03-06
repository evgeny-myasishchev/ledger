module AccountHelpers
  module D
    refine ::Domain::Account do
      def make_created aggregate_id = nil, ledger_id = nil, name = nil, initial_balance = 0, currency_code = 'UAH', unit: nil
        aggregate_id = "account-#{Random.rand(100)}" unless aggregate_id
        ledger_id = "ledger-#{Random.rand(100)}" unless ledger_id
        name = "name-#{Random.rand(100)}" unless name
        self.apply_event Domain::Events::AccountCreated.new aggregate_id, ledger_id, 1, name, initial_balance, currency_code, unit
        self
      end
    end
  end
  
  module P
    def create_account_projection! aggregate_id, ledger_id = 'ledger-1', owner_user_id = 100, authorized_user_ids: "{#{owner_user_id}}", currency_code: 'UAH', unit: nil
      last_sequential_number = Projections::Account.where(ledger_id: ledger_id).maximum(:sequential_number) || 0
      a = Projections::Account.create! aggregate_id: aggregate_id,
        ledger_id: ledger_id,
        sequential_number: last_sequential_number + 1,
        owner_user_id: 100,
        authorized_user_ids: authorized_user_ids,
        currency_code: currency_code,
        unit: unit,
        name: 'A 1',
        balance: 0,
        is_closed: false
    end
  end
end