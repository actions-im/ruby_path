require 'strscan'

module Parser

  def self.build(*expressions)
    if expressions.to_a.length>0
      expressions.each {|expr|
        unless expr.is_a?(Regexp)
          raise(ArgumentError, 'All arguments have to be regular expressions')
        end
      }
      Base.new(*expressions)
    else
      raise(ArgumentError, 'At least one regular expression is needed to proceed')
    end
  end

  class Base

    def initialize(*expressions)
      @expressions=expressions
    end

    def for(scannable)
      Processor.new(@expressions,scannable)
    end

    class Processor

      def initialize(expressions, scannable)
        @expressions=expressions
        @scannable=scannable
      end

      def each_match(&block)
        scannable_length=@scannable.length
        number_of_expressions=@expressions.length
        pos=0
        while pos<scannable_length
          match=nil
          expression_index=0
          while expression_index<number_of_expressions
            expression=@expressions[expression_index]
            match=@scannable.match(expression,pos)
            expression_index+=1
            break if match && match.begin(0)==pos
          end
          if match.present?
            pos = match.end(0)
            block.call(match)
          else
            raise NoMatchError.new(rest.slice(0,pos))
          end
        end
      end

    end
  end

end

class NoMatchError < StandardError

  attr_reader :rest

  def initialize(rest)
    @rest=rest
  end

end