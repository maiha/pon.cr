module Pon
  class Error < Exception
  end

  class Bug < Error
  end

  class FieldError < Error
    getter field
    def initialize(@field : String? = nil, msg : String? = nil)
      super(msg)
    end
  end
  
  class RecordNotFound < Error
  end

  class RecordError < Error
    getter record : Model

    def initialize(@record)
      klass = @record.class
      msg = "#{self.class.name}: #{@record}"
      super(msg)
    end
  end

  class RecordInvalid < RecordError
  end
  
  class RecordNotSaved < RecordError
  end

  class RecordNotDeleted < RecordError
  end
end
