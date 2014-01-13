require 'strscan'

module PathMatch

  PathCache.clear

  GLOBAL_SELECTOR=/\$/
  CHILD_SELECTOR=/(\.(?<child>\w+)|\[\'(?<child>\w+)\'\])/
  EXPRESSION_SELECTOR=/\[\?\((?<child>.+?)\)\]/
  MIN_SELECTOR=/\[\?min\((?<child>.+?)\)\]/
  MAX_SELECTOR=/\[\?max\((?<child>.+?)\)\]/
  GLOBAL_CHILD_SELECTOR=/\.\.\w+/
  ALL_THINGS_SELECTOR=/[(\.\*)(\[\*\])]/
  AGG_SELECTOR=/\[\?\((?<child>.+?)\)\]/


  FIND_METHOD_SELECTOR=/^find_(?<key>\w+)_by_(?<sub_key>\w+)/
  FIND_ALL_METHOD_SELECTOR=/^find_all_(?<key>\w+)_by_(?<sub_key>\w+)/
  HAS_METHOD_SELECTOR=/has_(?<key>\w+)|(?<key>\w+)\?/

  def find_all_by_path(path, context={})
    path(path, context)
  end

  def find_by_path(path, context={})
    findings=path(path, context)
    findings.is_a?(Array) ? findings[0] : findings
  end

  def pathways(pathways, context={})
    pathways.flat_map{|path| self.path(path, context)}
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

  protected

  attr_accessor :params_context

  def compile_path(path, context={})
    global_wrapper=%q{proc{ |main_obj, %{params}|
      %{body}
    }
    }


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

        #extractor=extractor.curry[sub_expression||'']
        #current_object=extractor.call(current_object, context)
        #path_extractor<<extractor
      else
        raise "Unable to parse your path: #{path}.
               Here is the part, which I can't match: #{path_scanner.rest}.
               Here is your object: #{current_object}
               Verify pattern matchers on #{current_object.class}"
      end
    end
    PathCache.add(path, path_extractor)
    current_object
  end

  def method_missing(name, *args, &block)
   if (match=(HAS_METHOD_SELECTOR.match name))
      path=".#{match[:key]}"
      self.find_by_path(path).present?
   elsif (match=(FIND_METHOD_SELECTOR.match name))
        value=(args.length>0) ? args[0] : raise(ArgumentError, 'find methods value selector argument')
        path=".#{match[:key]}[?(@['#{match[:sub_key]}']==$value)]"
        self.find_by_path(path, {value: value})
   else
        raise NoMethodError
   end

  end

end

class Hash

  include PathMatch

  PATH_MATCHERS={
    GLOBAL_SELECTOR => lambda{|key, obj, context| obj},
    GLOBAL_CHILD_SELECTOR => lambda{|obj,key, context| raise 'global search is not supported now'},
    CHILD_SELECTOR=> %q{
                          %{key}_to_analyze=%{obj_name}['%{key}']
                          %{body}
                        },
    EXPRESSION_SELECTOR =>%q{
                              if %{exp}
                                %{body}
                              end
                            },
    #lambda{|key, obj, context| obj.match?(key, context) ? obj:nil},
    ALL_THINGS_SELECTOR => lambda{|key, obj, context| obj.values},
    #MULTIPLE_KEYS => lambda{|key, obj, context| obj.values}
  }

  def path(path, context={})
    self.present? ? path_match(path,context):self
  end

  def stringify_keys
    dup.stringify_keys!
  end

  def stringify_keys!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end

  def only(*keys)
    self.slice(*keys)
  end

end

class Array

  include PathMatch

  PATH_MATCHERS={
    GLOBAL_SELECTOR => lambda{|key, obj, context| obj},
    GLOBAL_CHILD_SELECTOR => lambda{|key, obj, context| raise 'global search is not supported now'},
    CHILD_SELECTOR => lambda{|child, obj, context| obj.flat_map{|el| el[child]||el[child.to_sym] }.compact},
    CHILD_SELECTOR =>
        %q{
           index=0
           each_%{obj}=nil
           length={obj_container}.length
           res=[]
           while index<length
              group_to_analyze=groups[index]
           end
    },
    EXPRESSION_SELECTOR => lambda{|expr, obj, context| obj.select{|el| el.match?(expr, context)}},
    MIN_SELECTOR => lambda{|expr, obj, context| obj.min_by{|el| el.calc(expr,context)}},
    MAX_SELECTOR => lambda{|expr, obj, context| obj.max_by{|el| el.calc(expr,context)}},
    ALL_THINGS_SELECTOR => lambda{|key, obj, context| obj},
    #MULTIPLE_KEYS => lambda{|key, obj, context| obj.values}
  }

  def path(path,context={})
    path_match(path,context)
  end

  def only(*keys)
    self.map{|el| el.slice(*keys)}.select{|el| el.present?}
  end

end

class String

  def parameterized?
    match /\$(?<param>\w+)/
  end

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