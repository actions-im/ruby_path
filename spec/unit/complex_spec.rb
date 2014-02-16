require File.dirname(__FILE__) + '/../spec_helper'

describe 'Complex Operations' do

  before :all do
    PathCache.clear
    @plan=JSON.parse(open("#{fixture_path}/benefits.json"){ |f| f.read })
  end

  it 'supports long path' do
    funds=@plan.find_all_by_path(".groups[?(@['code']==123)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>=2030 && @['target_year']<2060)].name")
    funds.length.should eql(3)
  end

  it 'supports long path with parameters' do
    funds=@plan.find_all_by_path(".groups[?(@['code']==123)].benefits[?(@['code']=='401k')].funds[?(@['target_year']>=$lower_bound && @['target_year']<$upper_bound)].name", {lower_bound:2030, upper_bound:2060})
    funds.length.should eql(3)
  end


  it 'supports array path with child selector parameters' do
    path=".groups.benefits[?(@['code']=='401k')].funds[?(@['target_year']>=$lower_bound && @['target_year']<$upper_bound)].name"
    funds=@plan.path_match(path, 2030, 2060)
    funds.length.should eql(3)
  end

  it 'supports multiple pathways' do
    benefit=@plan.find_by_path(".groups[?(@['code']==123)].benefits[?(@['code']=='401k')]")
    selected_funds=benefit.pathways([".funds[?(@['target_year']==2030)]",
                                     ".funds[?(@['target_year']==2040)]",
                                     ".funds[?(@['target_year']==2050)]"])
    selected_funds.length.should eql(3)
  end

  it 'supports max and min method' do
    group=@plan.path(".groups[?max(@['code'])]")
    group['code'].should eql(124)
    fund=@plan.path(".groups[?(@['code']==123)].benefits[?(@['code']=='401k')].funds[?min((@['target_year']-(Time.now.year+10)).abs)]")
    (fund['target_year']-Time.now.year).should be < 10
  end


  it 'supports find methods' do
    group=@plan.find_groups_by_code(123)
    group['code'].should eql(123)
  end

  it 'supports has methods' do
    @plan.find_by_path(".groups[?(@['code']==123)]").has_benefits.should eql(true)
    @plan.find_by_path(".groups[?(@['code']==123)]").benefits?.should eql(true)
  end

end