#!/usr/bin/ruby

# file: test_rexleparser.rb
 
require 'testdata'
#require 'rexleparser'
require '/home/james/learning/ruby/rexleparser'

testdata = Testdata.new('testdata_rexleparser.xml')

testdata.paths do |path|

  testdata.find_by('XML validation').each do |title|

    path.tested? title do |input, output|
      result = input.data('xml') {|xml| RexleParser.new(xml).to_a.inspect}
      puts
      puts 'rsult : ' + result

      expected = output.data('xml')
      puts 'expected : ' + expected
      result == expected
    end
  end

end

puts testdata.passed?
puts testdata.score
puts testdata.instance_variable_get(:@success).map.with_index.select{|x,i| x == false}.map(&:last)


