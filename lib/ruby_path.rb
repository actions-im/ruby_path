require "strscan"
Dir[File.dirname(__FILE__) + '/ruby_path/*.rb'].each do |file|
  require file
end