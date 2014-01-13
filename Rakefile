require File.join(File.dirname(__FILE__),'/lib/ruby_path.rb')
require 'json'
require 'benchmark'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |spec|
    spec.pattern = 'spec/unit/*_spec.rb'
    spec.rspec_opts = ['--backtrace']
  end
end

task :default => 'spec:unit'

namespace :benchmarking do

  task :path do
     iterations=1000000
     path="$.groups[?(@['code']==123)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>$lower_year && @['target_year']<=$higher_year)].name"
     plans=[]
     PathCache.clear
     10.times{
       plans<<JSON.parse(open(File.join(File.dirname(__FILE__),'/spec/fixtures/benefits.json')){ |f| f.read })
     }
     Benchmark.bm{ |bm|

       bm.report ('By Path') {
         iterations.times{
           year=Random.rand(10000)
           plans[Random.rand(10)].path(path, {lower_year:year, higher_year:10000-year})
         }
       }

       bm.report('Native'){
         iterations.times{
           year=Random.rand(10000)
           benefit=plans[Random.rand(10)]['groups'].select{|b| b['code']==123}.first['benefits'].select{|b| b['code']=='401k'}.first
           funds=benefit['funds'].select{|el| (el['target_year']>year && el['target_year']<=(10000-year))}
           funds.flat_map{|el| el['name']}
         }
       }


     }

  end

  task :proc do
    iterations=1000
    plans=[]
    10.times{
      plans<<JSON.parse(open(File.join(Rails.root.join('public','plans') , "jetblue.json")){ |f| f.read })
    }
    Benchmark.bm{|bm|
      bm.report('By Proc'){
        iterations.times{
          year=Random.rand(10000)
          lambda{|plan|
            benefit=plan['groups'].select{|b| b['code']==123}.first['benefits'].select{|b| b['code']=='401k'}.first
            funds=benefit['funds'].select{|el| (el['target_year']>year && el['target_year']<=(10000-year))}
            funds.flat_map{|el| el['name']}
          }[plans[Random.rand(10)]]
        }
      }

      bm.report('Native'){
        iterations.times{
          year=Random.rand(10000)
          benefit=plans[Random.rand(10)]['groups'].select{|b| b['code']==123}.first['benefits'].select{|b| b['code']=='401k'}.first
          funds=benefit['funds'].select{|el| (el['target_year']>year && el['target_year']<=(10000-year))}
          funds.flat_map{|el| el['name']}
        }
      }

    }
  end

  task :whilevsflatmap do
    iterations=1000000
    plans=[]
    10.times{
      plans<<JSON.parse(open(File.join(File.dirname(__FILE__),'/spec/fixtures/benefits.json')){ |f| f.read })
    }
    Benchmark.bm{|bm|
      bm.report('whiles'){
        l=eval(%q{proc{ |plan, upper, lower|
          keep_searching=true
          groups=plan['groups']
          index=0
          group=nil
          length=groups.length
          res=[]
          while index<length
            group_to_analyze=groups[index]
            index+=1
            if group_to_analyze['code']==123
              group=group_to_analyze
              index2=0
              benefits=group['benefits'].to_a
              length2=benefits.length
              benefit=nil
              while index2<length2
                benefit_to_analyze=benefits[index2]
                index2+=1
                if benefit_to_analyze['code']=='401k'
                  benefit=benefit_to_analyze
                  index3=0
                  funds=benefit['funds'].to_a
                  length3=funds.length
                  while index3<length3
                    fund=funds[index3]
                    if fund['target_year']>upper && fund['target_year']<=lower
                      res<<fund
                    end
                    index3+=1
                  end
                end
              end
            end
          end
          res
        }
        })
        iterations.times{
          res=l[plans[Random.rand(10)],2010, 2050]
          #p res
        }
      }

      bm.report('select'){
        iterations.times{
          #group=plans[Random.rand(10)]['groups'].select{|b| b['code']==123}.first
          year=Random.rand(10000)
          funds = plans[Random.rand(10)]['groups'].select{|b|
            b['code']==123
          }.flat_map{|group|
            group['benefits'].select{|b| b['code']=='401k'}
          }.flat_map{|benefit| benefit['funds']}.compact.select{|el| (el['target_year']>2010 && el['target_year']<=2050)}
          #p funds
        }
      }

    }
  end

end

