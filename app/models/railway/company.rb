class Railway::Company < ApplicationRecord
  has_many :lines, dependent: :nullify, foreign_key: :line_id, inverse_of: :company
  has_many :links, dependent: :nullify, foreign_key: :line_id, inverse_of: :company
  enum :category, {
    other: 0,
    jr: 1,
    major_private: 2,
    semi_major_private: 3
  }
  # 0:運用中　1:運用前　2:廃止
  enum :status, {
    running: 0,
    before_use: 1,
    deleted: 2
  }
end
