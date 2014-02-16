

module PathMatch

  PathCache.clear


  def find_all_by_path(path, context={})
    path_match(path, *context.values)
  end

  def find_by_path(path, context={})
    findings=path_match(path, *context.values)
    findings.is_a?(Array) ? findings[0] : findings
  end

  def pathways(pathways, context={})
    pathways.flat_map{|path| self.path_match(path, *context.values)}
  end

  def path_match(path, *params)
    path_extractor=PathCache.get(path) || compile_path(path)
    full_params_list=params.insert(0,self)
    path_extractor.call(*full_params_list)
  end

  attr_accessor :params_context

  def compile_path(path)
    #init
    current_template=%Q{lambda{ |%{params}| \nres=[]\n$$body$$\nres}}
    current_obj_name='main_obj'
    current_object=self
    params_list=['main_obj']
    last_class=current_object.class
    #loop
    begin
      PATH_PARSER.for(path).each_match do |match|
          sub_expression=match.captures.compact.first
          last_class=current_object.class
          extractor=(last_class::PATH_MATCHERS[match.regexp])
          object_template_pair=extractor.call(sub_expression, current_object, current_obj_name)
          current_object=object_template_pair[:val]
          body=object_template_pair[:template]
          params_list+=object_template_pair[:params].to_a
          current_template=current_template.gsub('$$body$$', body)
          current_obj_name=object_template_pair[:next_obj] || sub_expression || current_obj_name
      end
    rescue NoMatchError=>ex
      raise "Unable to parse your path: #{path}.
             Here is the part, which I can't match: #{ex.rest}.
             Here is your object: #{current_object}
             Verify pattern matchers on #{current_object.class}"
    end
    #finalization
    final_operation=last_class=='Hash' ? "=" : "<<"
    generated_code=current_template.gsub('$$body$$', "res#{final_operation}#{current_obj_name}") % {params: params_list.compact.join(',')}
    #puts generated_code
    path_extractor=eval(generated_code)
    PathCache.add(path, path_extractor)
    path_extractor
  end

  protected

  def self.expr_to_str(expr, obj_name)
    expression=expr.gsub('@', obj_name)
    params=expression.scan(/\$(?<param>\w+)/).flatten
    (0..(params.length-1)).each{|index| expression=expression.gsub("$#{params[index]}", "#{params[index]}")}
    [expression, params]
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
        raise NoMethodError.new("undefined method #{name} for #{self}:#{self.class}", name)
   end
  end

  private
  GLOBAL_SELECTOR=/\$/
  CHILD_SELECTOR=/(\.(?<expr>\w+)|\[\'(?<expr>\w+)\'\])/
  EXPRESSION_SELECTOR=/\[\?\((?<expr>.+?)\)\]/
  MIN_SELECTOR=/\[\?min\((?<expr>.+?)\)\]/
  MAX_SELECTOR=/\[\?max\((?<expr>.+?)\)\]/
  GLOBAL_CHILD_SELECTOR=/\.\.\w+/
  ALL_THINGS_SELECTOR=/[(\.\*)(\[\*\])]/
  AGG_SELECTOR=/\[\?\((?<expr>.+?)\)\]/

  PATH_PARSER=Parser.build(
          GLOBAL_SELECTOR,
          CHILD_SELECTOR,
          EXPRESSION_SELECTOR,
          MIN_SELECTOR,
          MAX_SELECTOR,
          GLOBAL_CHILD_SELECTOR,
          ALL_THINGS_SELECTOR,
          AGG_SELECTOR)


  FIND_METHOD_SELECTOR=/^find_(?<key>\w+)_by_(?<sub_key>\w+)/
  FIND_ALL_METHOD_SELECTOR=/^find_all_(?<key>\w+)_by_(?<sub_key>\w+)/
  HAS_METHOD_SELECTOR=/has_(?<key>\w+)|(?<key>\w+)\?/

end

class Hash

  include PathMatch

  def path(path, context={})
    self.present? ? path_match(path,context):self
  end

  def only(*keys)
    self.slice(*keys)
  end

  private
  PATH_MATCHERS={
    GLOBAL_SELECTOR => proc{|key, obj| {val: obj, template: "$$body$$"}},
    GLOBAL_CHILD_SELECTOR =>proc{|obj,key, context| raise 'global search is not supported now'},
    EXPRESSION_SELECTOR =>
      lambda{|expr, obj, obj_name|
        expression, params=PathMatch.expr_to_str(expr, obj_name)
        {val: obj,
         template: %Q{if (#{expression})\n$$body$$\nend},
         params: params,
         next_obj: obj_name}
      },
    CHILD_SELECTOR=> proc{|key, obj, obj_name|
                         val = obj[key]
                         if obj[key].present?
                           {val: val,
                            template: %Q{ #{key}=#{obj_name}['#{key}']\n$$body$$}}
                         elsif obj[key.to_sym].present?
                           val=obj[key.to_sym]
                           {val: val,
                            template: %Q{ #{key}=#{obj_name}[:#{key}]\n$$body$$}}
                         end
                       },
    ALL_THINGS_SELECTOR => proc{|key, obj, obj_name|
                             val = obj.values
                             {val: val,
                              template: %Q{ #{key}=#{obj_name}['#{key}']\n$$body$$}}
                           },
  }

end

class Array

  include PathMatch

  PATH_MATCHERS={
    GLOBAL_SELECTOR => proc{|key, obj| {val: obj, template: '$$body$$'}},
    GLOBAL_CHILD_SELECTOR => proc{raise 'global search is not supported now'},
    CHILD_SELECTOR=> proc{|key, obj, obj_name|
                         val = obj.flat_map{|el| el[key]||el[key.to_sym] }.compact
                         {val: val,
                          template: %Q{unless #{obj_name}.nil?\n#{obj_name}_index=0\n#{obj_name}_length=#{obj_name}.length\nwhile #{obj_name}_index<#{obj_name}_length do\n#{obj_name}_to_analyze=#{obj_name}[#{obj_name}_index]\n#{obj_name}_index+=1\n#{key}=#{obj_name}_to_analyze['#{key}'] || #{obj_name}_to_analyze[:#{key}]\n$$body$$\nend\nend},
                          next_obj: key}
                        },
    EXPRESSION_SELECTOR => proc{|expr, obj, obj_name|
                             expression, params=PathMatch.expr_to_str(expr, "#{obj_name}_to_analyze")
                             val=obj.first
                             {val: val,
                              #template:%Q{unless #{obj_name}.nil?\n#{obj_name}_index=0\n#{obj_name}_length=#{obj_name}.length\nwhile #{obj_name}_index<#{obj_name}_length do\n#{obj_name}_to_analyze=#{obj_name}[#{obj_name}_index]\n#{obj_name}_index+=1\nnext if #{obj_name}_to_analyze.nil?\nif (#{expression})\n  $$body$$\n  end\nend\nend},
                              template:%Q{unless #{obj_name}.nil?\n#{obj_name}_index=0\n#{obj_name}_length=#{obj_name}.length\nwhile #{obj_name}_index<#{obj_name}_length do\n#{obj_name}_to_analyze=#{obj_name}[#{obj_name}_index]\n#{obj_name}_index+=1\nif (#{expression})\n  $$body$$\n  end\nend\nend},
                              params:params,
                              next_obj: "#{obj_name}_to_analyze"}
                            },
    #MIN_SELECTOR => lambda{|expr, obj, context| obj.min_by{|el| el.calc(expr,context)}},
    #MAX_SELECTOR => lambda{|expr, obj, context| obj.max_by{|el| el.calc(expr,context)}},
    #ALL_THINGS_SELECTOR => lambda{|key, obj, context| obj},
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