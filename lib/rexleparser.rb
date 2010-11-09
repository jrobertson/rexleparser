#!/usr/bin/ruby

# file: rexleparser.rb
# description: used by rexle.rb

class RexleParser

  def initialize(s)
    @a = scan_element(s.split(//))    
  end

  def to_a()
    @a
  end

  private
 
  def scan_element(a)

    a.shift until a[0] == '<' and a[1] != '/' or a.length < 1

    if a.length > 1 then
      a.shift

      name = ''
      name << a.shift
      name << a.shift while a[0] != ' ' and a[0] != '>'

      if name then

        a.shift until a[0] = '>'
        raw_values = ''
        a.shift 
        raw_values << a.shift until a[0] == '<'

        value = raw_values

        if raw_values.length > 0 then

          match_found = raw_values.match(/(.*)>([^>]*$)/)
          if match_found then
            raw_attributes, value = match_found.captures

            attributes = raw_attributes.scan(/(\w+\='[^']+')|(\w+\="[^"]+")/).map(&:compact).flatten.inject({}) do |r, x|
              attr_name, val = x.split(/=/) 
              r.merge(attr_name => val[1..-2])
            end
          end
        end

        element = [name, value, attributes]

        tag = a[0, name.length + 3].join

        if a.length > 0 then

          children = true
          children = false if tag == "</%s>" % name

          if children == true then
            r = scan_element(a)
            element << r if r

            (r = scan_element(a); element << r if r) until (a[0, name.length + 3].join == "</%s>" % [name]) or a.length < 2
          else
            #check for its end tag
            a.slice!(0, name.length + 3) if a[0, name.length + 3].join == "</%s>" % name
            a.shift until a[0] == '<' or a.length <= 1   
          end

        end

        element

      end
    end
  end
end
