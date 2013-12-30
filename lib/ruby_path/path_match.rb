
module PathMatch

  PathCache.clear

  GLOBAL_SELECTOR=/\$/
  CHILD_SELECTOR=/(\.(?<child>\w+)|\[(?<child>\w+)\])/
  EXPRESSION_SELECTOR=/\[\?\((?<child>[\w\'\:\=\>\<\|\.\$\&\'\"\@\]\[\s\(\)\^[\]\)]]+)\)\]/
  GLOBAL_CHILD_SELECTOR=/\.\.\w+/
  ALL_THINGS_SELECTOR=/[(\.\*)(\[\*\])]/

  protected

  attr_accessor :params_context

  def compile_path(path, context={})
    path_extractor=[]
    current_object=self
    path_scanner=StringScanner.new(path)
    while path_scanner.rest?
      #find the regular expression, which match
      potential_matches=current_object.class::PATH_MATCHERS.keys
      match=key=nil
      while match.blank? && potential_matches.present?
        key=potential_matches.slice!(0)
        match=path_scanner.scan(key)
      end
      if match.present?
        match_data=key.match(match)
        expression_identifier=match_data.names.pop
        sub_expression=expression_identifier.present? ? match_data[expression_identifier] : nil
        extractor=(current_object.class::PATH_MATCHERS[key])
        #extractor_arity=extractor.arity
        #context_dependent=(extractor_arity==3)
        #raise "Incorrect path. Sub expression #{sub_expression} does not match #{key}" if sub_expression.present? && extractor.arity==1
        extractor=extractor.curry[sub_expression||'']
        #if sub_expression.present? && extractor.arity>1
        #  extractor=extractor.curry[sub_expression]
        #  extractor_arity=extractor_arity-1
        #end
        current_object=extractor.call(current_object, context)
        path_extractor<<extractor#{extractor: extractor, arity:extractor_arity}
      else
        raise "Unable to parse your path: #{path}.
               Here is the part, which I can't match: #{path_scanner.rest}.
               Verify pattern matchers on #{current_object.class}"
      end
    end
    PathCache.add(path, path_extractor)
    current_object
  end

  def path_match(path, context={})
    path_extractor=PathCache.get(path)
    stringified_context=context.stringify_keys
    if path_extractor.present?
      path_extractor.inject(self){|res, proc| proc.call(res, stringified_context)}
    else
      compile_path(path, stringified_context)
    end
  end

end

class Hash

  include ExprMatch
  include PathMatch

  PATH_MATCHERS={
    GLOBAL_SELECTOR => lambda{|key, obj, context| obj},
    GLOBAL_CHILD_SELECTOR => lambda{|obj,key| raise 'global search is not supported now'},
    CHILD_SELECTOR=> lambda{|key, obj, context|obj[key]||obj[key.to_sym]},
    EXPRESSION_SELECTOR => lambda{|key, obj, context| obj.match?(key, context) ? obj:nil},
    ALL_THINGS_SELECTOR => lambda{|key, obj, context| obj.values}
  }

  def path(path, context={})
    self.present? ? path_match(path,context):self
  end

  def stringify_keys
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end


end

class Array

  include PathMatch

  PATH_MATCHERS={
    GLOBAL_SELECTOR => lambda{|key, obj, context| obj},
    GLOBAL_CHILD_SELECTOR => lambda{|key, obj, context| raise 'global search is not supported now'},
    CHILD_SELECTOR => lambda{|child, obj, context| obj.flat_map{|el| el[child]}.compact},
    EXPRESSION_SELECTOR => lambda{|expr, obj, context| obj.select{|el| el.match?(expr, context)}},
    ALL_THINGS_SELECTOR => lambda{|key, obj, context| obj}
  }

  def path(path,context={})
    rv=self.present? ? path_match(path,context) : self
    rv.to_a.length==1 ? rv[0] : rv
  end

end

class String

  include ExprMatch

end

class Integer

  include ExprMatch

end

class Float

  include ExprMatch

end

class TrueClass

  include ExprMatch

end

class FalseClass

  include ExprMatch

end

class Object

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  # An object is present if it's not <tt>blank?</tt>.
  def present?
    !blank?
  end

end