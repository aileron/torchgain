class Railway::Link < ApplicationRecord
  belongs_to :line
  belongs_to :station1
  belongs_to :station2
end
