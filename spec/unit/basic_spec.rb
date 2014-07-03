require File.dirname(__FILE__) + '/../spec_helper'

describe 'Basic Operations' do

  before :all do
    @simple_hash={fname: "Jack", lname: "Doe"}
    @simple_hash_strings={'fname'=> "Jack", 'lname'=> "Doe"}
    @nested_hash={person: {fname: "Jack", lname: "Doe"}}
    @int_array=[1,2,3,4,5,6]
    @float_array=[1.0,2.3,3.4,4.5,5.6,6.7]
    @string_array=["Jack", "John", "Don", "Dave"]
    @array_of_hashes=[{fname: "Jack", lname: "Doe"},
                      {fname: "John", lname: "Walker"},
                      {fname: "Don", lname: "Pedro"}]

    @array_of_hashes_string_keys=
                      [{'fname'=> "Jack", 'lname'=> "Doe"},
                      {'fname'=> "John", 'lname'=> "Walker"},
                      {'fname' => "Don", 'lname' => "Pedro"}]

  end

  before :each do
    PathCache.clear
  end

  it 'should support global extractor' do
    @simple_hash.find_by_path('$').should eql(@simple_hash)
  end

  it 'supports dot notation for child extractor' do
    @simple_hash.find_by_path('$.fname').should eql(@simple_hash[:fname])
    @simple_hash.find_by_path('$.fname').should eql(@simple_hash[:fname])
    @simple_hash.find_by_path('$.fname').should eql(@simple_hash[:fname])
  end

  it 'supports bracket notation for child extractor' do
    @simple_hash_strings.find_by_path("$['lname']").should eql(@simple_hash_strings['lname'])
  end

  it 'supports nested hash' do
    @nested_hash.find_by_path("$.person.lname").should eql(@nested_hash[:person][:lname])
    @nested_hash.find_by_path("$.person.lname").should eql(@nested_hash[:person][:lname])
  end

  it 'supports expressions on hash' do
    @nested_hash.find_by_path("$.person[?(@[:lname].start_with?($start))]", {start: 'D'}).should  be_an_instance_of(Hash)
    @nested_hash.find_by_path("$.person[?(@[:lname].start_with?($start))]", {start: 'F'}).should be_nil
  end

  it 'supports expression extractor for integer arrays' do
    @int_array.find_all_by_path('[?(@>4)]').min.should eql(5)
  end

  it 'supports expression extractor for float arrays' do
    @float_array.find_all_by_path("[?(@>4.2)]").min.should eql(4.5)
  end

  it 'supports expression extractor for string arrays' do
    extractor=@string_array.find_all_by_path("[?(@.start_with?('J'))]")
    extractor.length.should eql(2)
    extractor.should include "Jack"
    extractor.should_not include "Don"
  end

  it 'supports expression extractor for arrays of hashes with sym keys' do
    expr="@[:fname].start_with?('J')"
    result=@array_of_hashes.find_all_by_path("[?(#{expr})].lname")
    result.length.should eql(2)
    result.should include "Doe"
    result.should_not include "Pedro"
  end

  it 'supports expression extractor for arrays of hashes with string keys' do
    expr="@['fname'].start_with?('J')"
    result=@array_of_hashes_string_keys.find_all_by_path("[?(#{expr})].lname")
    result.length.should eql(2)
    result.should include "Doe"
    result.should_not include "Pedro"
  end



end