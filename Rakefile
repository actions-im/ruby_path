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

  task :generate_file do
    number_of_samples=400000
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


  task :pathvsdirect do
    iterations=1000000
    puts Time.now
    plans=Oj.load(open(File.join(File.dirname(__FILE__),'/spec/fixtures/large_file.json')){ |f| f.read })
    p Time.now
    #p "Loading complete - #{Time.now}"
    #res=plans[1].compile_path(".groups[?(@['code']==$code)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>=$lower_bound && @['target_year']<$upper_bound)].name")
    GC::Profiler.enable

    def path_selector(plan, r, upper_bound, lower_bound)
      plan['groups'].select{|group| group['code']==r+1}
      .flat_map{|group| group['benefits']}
      .select{|benefit| benefit['code']=='401k'}
      .flat_map{|benefit| benefit['funds']}.compact
      .select{|funds_to_analyze| funds_to_analyze['target_year']>=upper_bound && funds_to_analyze['target_year']<lower_bound }
      .map{|fund| fund['name']}
    end

    Benchmark.bmbm{|bm|

      bm.report('path'){
        iterations.times{
          r=Random.rand(plans.length)
          res=plans[r].find_all_by_path(".groups[?(@['code']==$code)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>=$lower_bound && @['target_year']<$upper_bound)].name",{code:r+1,lower_bound: 2030,upper_bound: 2060})
          #p res
        }

       #GC::Profiler.disable
        puts "\n#{GC::Profiler.result}"
      }


      bm.report('direct'){
       #GC::Profiler.enable
        iterations.times{
          #group=plans[Random.rand(10)]['groups'].select{|b| b['code']==123}.first
          r=Random.rand(plans.length)
          path_selector(plans[r], r, 2030, 2060)
        }
        puts "\n#{GC::Profiler.result}"
      }

    }
    GC::Profiler.disable
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

end