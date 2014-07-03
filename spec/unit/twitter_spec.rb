require File.dirname(__FILE__) + '/../spec_helper'

describe 'Twitter' do

  before :all do
    @timeline=Oj.load(open("#{fixture_path}/twitter.json"){ |f| f.read })
    PathCache.clear
  end

  it 'can find by name on timeline' do
    @timeline.find_all_by_path('$.user.name[?(@.start_with?("V"))]').length.should eql(2)
  end

end

