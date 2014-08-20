class Projections::Category < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  include UserAuthorizable

  def self.get_user_categories(user)
    Category.select('id, category_id, name').where('authorized_user_ids LIKE ?', "%{#{user.id}}%")
  end

  projection do
    on LedgerShared do |event|
      Category.where(ledger_id: event.aggregate_id).each { |a|
        a.authorize_user event.user_id
        a.save!
      }
    end

    on CategoryCreated do |event|
      unless Category.exists? ledger_id: event.aggregate_id, category_id: event.category_id
        ledger = Ledger.find_by_aggregate_id event.aggregate_id
        tag = Category.new ledger_id: event.aggregate_id, category_id: event.category_id, name: event.name
        tag.set_authorized_users ledger.authorized_user_ids
        tag.save!
      end
    end

    on CategoryRenamed do |event|
      Category.where(ledger_id: event.aggregate_id, category_id: event.category_id).update_all(name: event.name)
    end

    on CategoryRemoved do |event|
      Category.where(ledger_id: event.aggregate_id, category_id: event.category_id).delete_all
    end
  end
end
