module ExprMatch

  def match?(expr, context={})
    expression_processor, params=PathCache.get_expression(expr)
    if expression_processor.blank?
      expression=expr.gsub('@', 'main')
      params=expression.scan(/\$(?<param>\w+)/).flatten
      (0..(params.length-1)).each{|index| expression=expression.gsub("$#{params[index]}", "params[#{index}]")}
      proc_expression="lambda{|main, *params| #{expression} }"
      expression_processor=PathCache.add_expression(expr, params, eval(proc_expression))
    end
    values=context.values_at(*params)
    match_res=expression_processor.call(self, *values)
    if !!match_res==match_res
      match_res
    else
      raise "Expression #{expr} is not boolean"
    end
  end

end