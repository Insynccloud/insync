class Sourcedatabase < ActiveRecord::Base
   validates :DBName, presence: true , length: { minimum: 3, maximum:50}
end