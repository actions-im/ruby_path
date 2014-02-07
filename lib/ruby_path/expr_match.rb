module ExprMatch

  def match?(expr, context={})
    res=eval_expr(expr, context)
    if !!res==res
      res
    else
      raise "Expression #{expr} is not boolean"
    end
  end

  def calc(expr, context={})
    res=eval_expr(expr, context)
    if res.is_a?(Comparable)
      res
    else
      raise "Expression #{expr} is not comparable"
    end
  end

  def eval_expr(expr, context={})
    expression_processor, params=PathCache.get_expression(expr)
    if expression_processor.blank?
      expression=expr.gsub('@', 'main')
      params=expression.scan(/\$(?<param>\w+)/).flatten
      (0..(params.length-1)).each{|index| expression=expression.gsub("$#{params[index]}", "params[#{index}]")}
      proc_expression="lambda{|main, *params| #{expression} }"
      expression_processor=PathCache.add_expression(expr, params, eval(proc_expression))
    end
    values=context.values_at(*params)
    expression_processor.call(self, *values)
  end

end

class Hash

  include ExprMatch

end

class String

  include ExprMatch

end

class Integer

  include ExprMatch

end

class Fixnum

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
