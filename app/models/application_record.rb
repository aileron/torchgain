class ApplicationRecord < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions
  primary_abstract_class
end
