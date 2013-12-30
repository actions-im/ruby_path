require File.join(File.dirname(__FILE__),'../../app/modules/hash_path.rb')

namespace :benchmarking do

  task :path do
     iterations=1000000
     path="$.groups[?(@['code']==123)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>$lower_year && @['target_year']<=$higher_year)].name"
     plans=[]
     PathCache.clear
     10.times{
       plans<<JSON.parse(open(File.join(Rails.root.join('public','plans') , "jetblue.json")){ |f| f.read })
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

end

