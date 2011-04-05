class Object
  def blank?
    respond_to?(:empty?) ? empty? : (is_a?(FalseClass) || is_a?(TrueClass) ? false : !self)
  end
end