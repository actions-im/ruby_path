require File.dirname(__FILE__) + '/../spec_helper'

describe 'Basic Operations' do

  before :all do
    @simple_hash={fname: "Jack", lname: "Doe"}
    @int_array=[1,2,3,4,5,6]
    @float_array=[1.0,2.3,3.4,4.5,5.6,6.7]
    @string_array=["Jack", "John", "Don", "Dave"]
    @array_of_hashes=[{fname: "Jack", lname: "Doe"},
                      {fname: "John", lname: "Walker"},
                      {fname: "Don", lname: "Pedro"}]
  end

  it 'should support global extractor' do
    @simple_hash.path('$').should eql(@simple_hash)
  end

  it 'supports dot notation for child extractor' do
    @simple_hash.path('$.fname').should eql(@simple_hash[:fname])
  end

  it 'supports bracket notation for child extractor' do
    @simple_hash.path("$['lname']").should eql(@simple_hash[:lname])
  end

  it 'supports expression extractor for integer arrays' do
    @int_array.path("[?(@>4)]").min.should eql(5)
  end

  it 'supports expression extractor for float arrays' do
    @float_array.path("[?(@>4.2)]").min.should eql(4.5)
  end

  it 'supports expression extractor for string arrays' do
    extractor=@string_array.path("[?(@.start_with?('J'))]")
    extractor.length.should eql(2)
    extractor.should include "Jack"
    extractor.should_not include "Don"
  end

  it 'supports expression extractor for arrays of hashes with sym keys' do
    expr="@[:fname].start_with?('J')"
    result=@array_of_hashes.path("[?(#{expr})].lname")
    result.length.should eql(2)
    result.should include "Doe"
    result.should_not include "Pedro"
  end

  it 'supports expression extractor for arrays of hashes with string keys' do
    expr="@['fname'].start_with?('J')"
    result=@array_of_hashes.map{|el| el.stringify_keys}.path("[?(#{expr})].lname")
    result.length.should eql(2)
    result.should include "Doe"
    result.should_not include "Pedro"
  end

  it 'supports expression extractor for arrays of hashes with string keys' do
    expr="@['fname'].start_with?('J')"
    result=@array_of_hashes.map{|el| el.stringify_keys}.path("[?(#{expr})].lname")
    result.length.should eql(2)
    result.should include "Doe"
    result.should_not include "Pedro"
  end


end