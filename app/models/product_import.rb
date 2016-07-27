class ProductImport
  # switch to ActiveModel::Model in Rails 4
  extend ActiveModel::Model
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :file
  validates :file, presence:true

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end

  def save
    if imported_products.map(&:valid?).all?
      imported_products.each(&:save!)
      true
    else
      imported_products.each_with_index do |product, index|
        product.errors.full_messages.each do |message|
          errors.add :base, "Columna #{index+2}: #{message}"
        end
      end
      false
    end
  end

  def imported_products
    @imported_products ||= load_imported_products
  end

  def load_imported_products
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      puts '<<<<<<<<<'
        p row
      puts '<<<<<<<<<'
      product = Product.find_by_id(row["id"]) || Product.new
      puts '<<<<<<<<<'
        p product
      puts '<<<<<<<<<'
      product.attributes = Hash[row.map{ |k, v| [k.to_sym, v] }]
      puts '<<<<<<<<<'
        p product.attributes
      puts '<<<<<<<<<'
      product
    end
  end

  def open_spreadsheet
    case File.extname(file.original_filename)
    when ".csv" then Roo::CSV.new(file.path, packed: false, file_warning: :ignore)
    when ".xls" then Roo::Excel.new(file.path, packed: false, file_warning: :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, packed: false, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end