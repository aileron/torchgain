class ApplicationProps
  def self.collection(context, records, **options) = records&.map { |record| self.for(context, record, **options) } || []
  def self.for(context, record, **options) = new(context, record, options).to_builder.attributes!

  attr_reader :view_context, :record, :options

  def initialize(view_context, record, options = {})
    @record = record
    @view_context = view_context
    @options = options
  end
end
