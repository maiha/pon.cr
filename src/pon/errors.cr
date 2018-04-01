module Pon
  class Error < Exception
  end

  class FieldError < Error
    getter field
    def initialize(@field : String? = nil, msg : String? = nil)
      super(msg)
    end
  end
  
  class RecordInvalid < Error
  end
  
  class RecordNotFound < Error
  end

  class RecordNotSaved < Error
    getter record : Model

    def initialize(@record)
    end
  end
end
