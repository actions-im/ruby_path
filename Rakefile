require File.join(File.dirname(__FILE__),'/lib/ruby_path.rb')
require 'oj'
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

  def deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end

  task :generate_file do
    number_of_samples=500000
    content=open(File.join(File.dirname(__FILE__),'/spec/fixtures/benefits.json')){ |f| f.read }
    open(File.join(File.dirname(__FILE__),'/spec/fixtures/large_file.json'), 'w'){|f|
      f.write "["
      number_of_samples.times{|tick|
        s=content.gsub('"code": 123', "\"code\": #{tick+1}")
        f.write s + (tick<(number_of_samples-1) ? ',' : "" )
      }
      f.write "]"
    }
  end


  task :whilevsflatmap do
    iterations=1000000
    puts Time.now
    plans=Oj.load(open(File.join(File.dirname(__FILE__),'/spec/fixtures/small_file.json')){ |f| f.read })
    GC.start
    p Time.now
    lambda=lambda{ |main_obj,code,lower_bound,upper_bound|
     res=[]
     groups=main_obj['groups']
     groups_length=groups.length
     groups_index=0
     while groups_index < groups_length do
      groups_to_analyze=groups[groups_index]
      groups_index+=1
      if groups_to_analyze['code']==code
       benefits=groups_to_analyze['benefits']
       next if benefits.nil?
       benefits_length=benefits.length
       benefits_index=0
       while benefits_index < benefits_length do
         benefits_to_analyze=benefits[benefits_index]
         benefits_index+=1
         if benefits_to_analyze['code']=='401k'
           funds=benefits_to_analyze['funds']
           next if funds.nil?
           funds_length=funds.length
           funds_index=0
           while funds_index<funds_length
            funds_to_analyze=funds[funds_index]
            funds_index+=1
            if funds_to_analyze['target_year']>=lower_bound && funds_to_analyze['target_year']<upper_bound
             name=funds_to_analyze['name']
             res<<name
            end
           end
         end
       end
      end
     end
    res}
    #p "Loading complete - #{Time.now}"
    res=plans[1].compile_path(".groups[?(@['code']==$code)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>=$lower_bound && @['target_year']<$upper_bound)].name",{code:2,lower_bound:2030, upper_bound:2060}.stringify_keys)
    Benchmark.bmbm{|bm|

      bm.report('select'){
              iterations.times{
                #group=plans[Random.rand(10)]['groups'].select{|b| b['code']==123}.first
                r=Random.rand(plans.length)
                funds = plans[r]['groups']
                .select{|group| group['code']==r+1}
                .flat_map{|group| group['benefits']}
                .select{|benefit| benefit['code']=='401k'}
                .flat_map{|benefit| benefit['funds']}.compact
                .select{|funds_to_analyze| funds_to_analyze['target_year']>=2030 && funds_to_analyze['target_year']<2060 }
                .map{|fund| fund['name']}
                #p funds
              }
            }

      bm.report('lambda'){
        iterations.times{
          r=Random.rand(plans.length)
          res=lambda.call(plans[r],r+1,2030,2060)
          #p res
        }
      }

      bm.report('whiles'){
        iterations.times{
          r=Random.rand(plans.length)
          res=plans[r].path_match(".groups[?(@['code']==$code)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>=$lower_bound && @['target_year']<$upper_bound)].name",r+1,2030,2060)
          #p res
        }
      }
    }
  end

  task :whilevsfor do
    iterations=10000#00
    objects=[]
    iterations.times{objects<<Random.rand(iterations)}

      Benchmark.bm{|bm|
        bm.report('for'){
          iterations.times{
            for x in objects do
              x*2
            end
          }
        }

        bm.report('while'){
          iterations.times{
            index=0
            length=objects.length
            while index<length do
              x=objects[index]
              index+=1
              x*2
            end
          }
        }
      }

  end


  task :store do
    iterations=35
    store=JSON.parse(open(File.join(File.dirname(__FILE__),'/spec/fixtures/benefits.json')){ |f| f.read })
    res=store.path("$.store.book[?(@['price'] < 10 && @['price'] >4)].title")
    p res
    Benchmark.bm{|bm|
      bm.report('extract items'){
        iterations.times{
          res=store.find_all_by_path("$.store.book[?(@['price'] < 10 && @['price'] >4)].title")
        }
      }

    }
  end

  task :file do
    iterations=10000
    plans=[]
    10.times{
      plans<<open(File.join(File.dirname(__FILE__),'/spec/fixtures/benefits.json')){ |f| f.read }
    }
    Benchmark.bm{|bm|
      bm.report('By File'){
        iterations.times{
          #year=Random.rand(10000)
          #plan=open(File.join(File.dirname(__FILE__),'/spec/fixtures/benefits.json')){ |f| f.read }
          plan=Oj.load(plan)
          #benefit=plan['groups'].select{|b| b['code']==123}.first['benefits'].select{|b| b['code']=='401k'}.first
          #funds=benefit['funds'].select{|el| (el['target_year']>year && el['target_year']<=(10000-year))}
          #funds.flat_map{|el| el['name']}
        }
      }

      bm.report('Memory'){
        iterations.times{
          #year=Random.rand(10000)
          plan=Oj.load(plans[Random.rand(10)])
          #benefit=plan['groups'].select{|b| b['code']==123}.first['benefits'].select{|b| b['code']=='401k'}.first
          #funds=benefit['funds'].select{|el| (el['target_year']>year && el['target_year']<=(10000-year))}
          #funds.flat_map{|el| el['name']}
        }
      }

    }
  end

end


lambda{ |main_obj,code,lower_bound,upper_bound|
res=[]
 groups=main_obj['groups']
 for groups_to_analyze in groups.to_a do
  if (groups_to_analyze['code']==code)
   benefits=groups_to_analyze['benefits']
  for benefits_to_analyze in benefits.to_a do
   if (benefits_to_analyze['code']=='401k')
   funds=benefits_to_analyze['funds']
   for funds_to_analyze in funds.to_a do
    if (funds_to_analyze['target_year']>=lower_bound && funds_to_analyze['target_year']<upper_bound)
     name=funds_to_analyze['name']
     res<<name
    end
   end
   end
  end
  end
 end
res}