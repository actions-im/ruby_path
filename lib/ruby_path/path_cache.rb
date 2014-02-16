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

  def self.clear
    self.path_cache={}
  end

end