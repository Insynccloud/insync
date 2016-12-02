class Sourcedatabase < ActiveRecord::Base
    belongs_to :user    
   validates :DBName, presence: true , length: { minimum: 3, maximum:50}
   validates :user_id, presence: true
end