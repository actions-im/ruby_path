require File.dirname(__FILE__) + '/../spec_helper'

describe 'Params Operations' do

  before :all do
    PathCache.clear
    @array_of_hashes=[{fname: "Jack", lname: "Doe", age: 30},
                      {fname: "John", lname: "Walker", age: 35},
                      {fname: "Don", lname: "Pedro", age: 60}]
  end

  it 'supports one parameter' do
    expr='@[:age]<$age_limit'
    result1=@array_of_hashes.path("[?(#{expr})].lname", {age_limit: 40})
    result1.length.should eql(2)
    result1.should include "Doe"
    result1.should_not include "Pedro"
  end

  it "should return one element array" do
    expr='@[:age]<$age_limit'
    result2=@array_of_hashes.path("[?(#{expr})].lname", {age_limit: 31})
    result2.should eql("Doe")
  end


end