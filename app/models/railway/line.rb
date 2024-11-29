class Railway::Line < ApplicationRecord
  has_many :links, dependent: false
  has_many :stations, dependent: false
  belongs_to :company, class_name: "Railway::Company"
end
