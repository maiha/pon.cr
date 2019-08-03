require "./placeholder"

class Pon::Context(T)
  var database : DB::Database
  var placeholder : Pon::Placeholder

  delegate sql, template, to: placeholder
  
  def initialize(@database, @placeholder)
  end

  def bind(*args, **opts)
    placeholder.bind(*args, **opts)
    return self
  end
  
  def all
    database.query_all(sql, as: T::ResultTypes).map{|t| T.new(t)}
  end

  def scalar
    database.scalar(sql)
  end

  def csv(header : Bool = false, quoting : CSV::Builder::Quoting = :rfc)
    CSV.build(quoting: quoting) do |csv|
      csv.row T::FIELD_NAMES if header
      all.each do |record|
        csv.row record.to_h.values
      end
    end.strip
  end
end
