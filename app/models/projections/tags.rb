class Projections::Tags < ActiveRecord::Base
  include CommonDomain::Projections::ActiveRecord
  include Domain::Events
  include Projections
  
  projection do
    on TagCreated do
      
    end
    
    on TagRenamed do
      
    end
    
    on TagRemoved do
      
    end
  end
end
