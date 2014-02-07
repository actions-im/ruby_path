require 'strscan'

module PathMatch

  PathCache.clear

  GLOBAL_SELECTOR=/\$/
  CHILD_SELECTOR=/(\A\.(?<child>\w+)|\A\[\'(?<child>\w+)\'\])/
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

  def path_match(path, *params)
    path_extractor=PathCache.get(path) #|| compile_path(path, context.stringify_keys)
    full_params_list=[self]+params
    p full_params_list
    path_extractor.call(*full_params_list)
    #if path_extractor.present?
      #all_params=path_extractor.parameters.map(&:last)
      #all_params.shift
      #params=[self]+all_params.map{|p| context[p]}
      #path_extractor.call(*params)
    #end
  end

  attr_accessor :params_context

  def compile_path(path, context={})
    current_template=%Q{lambda{ |%{params}| \nres=[]\n$$body$$\nres}}
    current_obj_name='main_obj'
    path_extractor=[]
    current_object=self
    path_scanner=StringScanner.new(path)
    params_list=['main_obj']
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
        last_class=current_object.class
        extractor=(last_class::PATH_MATCHERS[key])

        object_template_pair=extractor.call(sub_expression, current_object, current_obj_name, context)
        current_object=object_template_pair[:val]
        body=object_template_pair[:template]
        params_list+=object_template_pair[:params].to_a
        current_template=current_template.gsub('$$body$$', body)
        current_obj_name=object_template_pair[:next_obj] || sub_expression || current_obj_name
      else
        raise "Unable to parse your path: #{path}.
               Here is the part, which I can't match: #{path_scanner.rest}.
               Here is your object: #{current_object}
               Verify pattern matchers on #{current_object.class}"
      end
    end
    final_operation=last_class=='Hash' ? "=" : "<<"
    generated_code=current_template.gsub('$$body$$', "res#{final_operation}#{current_obj_name}") % {params: params_list.compact.join(',')}
    puts generated_code
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


end

class Hash

  include PathMatch

  PATH_MATCHERS={
    GLOBAL_SELECTOR => proc{|key, obj| {val: obj, template: "$$body$$"}},
    GLOBAL_CHILD_SELECTOR =>proc{|obj,key, context| raise 'global search is not supported now'},
    EXPRESSION_SELECTOR =>
      lambda{|expr, obj, obj_name, context|
        expression, params=PathMatch.expr_to_str(expr, obj_name)
        {val: obj.match?(expr, context) ? obj:nil,
         template: %Q{if (#{expression})\n$$body$$\nend},
         params: params,
         next_obj: obj_name}
      },
    CHILD_SELECTOR=> proc{|key, obj, obj_name|
                         val = obj[key]
                         if val.present?
                           {val: val,
                            template: %Q{ #{key}=#{obj_name}['#{key}']\n$$body$$}}
                         elsif obj[key.to_sym].present?
                           val=obj[key.to_sym]
                           {val: val,
                            template: %Q{ #{key}=#{obj_name}[:#{key}]\n$$body$$}}
                         end
                       },
    #lambda{|key, obj, context| obj.match?(key, context) ? obj:nil},
    ALL_THINGS_SELECTOR => proc{|key, obj, obj_name|
                             val = obj.values
                             {val: val,
                              template: %Q{ #{key}=#{obj_name}['#{key}']\n$$body$$}}
                           },
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
    GLOBAL_SELECTOR => proc{|key, obj, context| {val: obj, template: '$$body$$'}},
    GLOBAL_CHILD_SELECTOR => proc{raise 'global search is not supported now'},
    CHILD_SELECTOR=> proc{|key, obj, obj_name|
                         val = obj.flat_map{|el| el[key]||el[key.to_sym] }.compact
                         {val: val,
                          template: %Q{#{obj_name}_index=0\n#{obj_name}_length=#{obj_name}.length\nwhile #{obj_name}_index<#{obj_name}_length do\n#{obj_name}_to_analyze=#{obj_name}[#{obj_name}_index]\n#{obj_name}_index+=1\nnext if #{obj_name}_to_analyze.nil?\n#{key}=#{obj_name}_to_analyze['#{key}'] || #{obj_name}_to_analyze[:#{key}]\n$$body$$\nend},
                          next_obj: key
                         }
                        },
    EXPRESSION_SELECTOR => proc{|expr, obj, obj_name, context|
                             expression, params=PathMatch.expr_to_str(expr, "#{obj_name}_to_analyze")
                             val=obj.select{|el| el.match?(expr, context)}.first
                             #val=val.first if val.to_a.length==1
                             {val: val,
                              template:%Q{#{obj_name}_index=0\n#{obj_name}_length=#{obj_name}.length\nwhile #{obj_name}_index<#{obj_name}_length do\n#{obj_name}_to_analyze=#{obj_name}[#{obj_name}_index]\n#{obj_name}_index+=1\nnext if #{obj_name}_to_analyze.nil?\nif (#{expression})\n  $$body$$\n  end\nend},
                              params:params,
                              next_obj: "#{obj_name}_to_analyze"}
                            },
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