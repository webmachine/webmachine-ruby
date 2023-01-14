module Webmachine
  module Decision
    Falsey = Object.new

    def Falsey.===(other)
      !other
    end
  end
end
