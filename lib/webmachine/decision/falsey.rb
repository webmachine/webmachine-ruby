unless defined? Falsey
  Falsey = Object.new

  def Falsey.===(other)
    !other
  end
end

