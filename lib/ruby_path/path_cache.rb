module PathCache

  class << self
    attr_accessor :path_cache, :expression_cache, :templates
  end

  def self.add(path, extractor)
    self.path_cache=self.path_cache||{}
    self.path_cache[path.to_sym]=extractor
    extractor
  end

  def self.get(path)
    self.path_cache=self.path_cache||{}
    self.path_cache[path.to_sym]
  end

  def self.add_expression(expression, params, proc)
    self.expression_cache=self.expression_cache||{}
    self.expression_cache[expression.to_sym]=[proc, params]
    proc
  end

  def self.get_expression(expression)
    self.expression_cache=self.expression_cache||{}
    self.expression_cache[expression.to_sym]
  end

  def self.clear
    self.path_cache={}
    self.expression_cache={}
  end

end