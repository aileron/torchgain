class Railway::Station < ApplicationRecord
  belongs_to_active_hash :prefecture, class_name: "Railway::Prefecture"
  belongs_to :line
  has_many :links, dependent: false
  enum :status, {
    running: 0,
    before_use: 1,
    deleted: 2
  }
end
