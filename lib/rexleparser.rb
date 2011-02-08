#!/usr/bin/ruby

# file: rexleparser.rb
# description: used by rexle.rb

class RexleParser

  def initialize(s)    
    @a = scan_element(s.sub(/<\?[^>]+>/,'').split(//))    
  end

  def to_a()
    @a
  end

  private
 
  def scan_element(a)

    a.shift until a[0] == '<' and a[1] != '/' or a.length < 1        

    if a.length > 1 then
      a.shift

      # CDATA ?
      if a[0..1].join == '![' then

        name = '!['
        8.times{ a.shift }
        value = ''

        value << a.shift until a[0..2].join == ']]>' or a.length <= 1
        a.slice!(0,3)
        element = [name, value, {}]        
      else

        name = ''
        name << a.shift
        name << a.shift while a[0] != ' ' and a[0] != '>' and a[0] != '/'

        if name then

          # find the closing tag
          i = a.index('>')
          raw_values = ''

          # is it a self closing tag?
          if a[i-1] == '/' then          
            raw_values << a.shift until a[0] == '/'
            a.shift until a[0] == '<' or a.length < 1
            raw_values.strip!

            attributes = get_attributes(raw_values) if raw_values.length > 0
            element = [name, '', attributes]
          else

            raw_values << a.shift until a[0] == '<'
            value, attributes = get_value_and_attributes(raw_values) if raw_values.length > 0

            element = [name, value, attributes]
            
            tag = a[0, name.length + 3].join

            if a.length > 0 then

              children = true
              children = false if tag == "</%s>" % name

              if children == true then

                (r = scan_element(a); element << r if r) until (a[0, name.length + 3].join == "</%s>" % [name]) or a.length < 2
                a.slice!(0, name.length + 3) if a[0, name.length + 3].join == "</%s>" % name
                a.shift until a[0] == '<' or a.length <= 1   
              else
                #check for its end tag
                a.slice!(0, name.length + 3) if a[0, name.length + 3].join == "</%s>" % name
                a.shift until a[0] == '<' or a.length <= 1   
              end
            end
            
          end

          return element

        end
      end

    end
  end
  
  def get_value_and_attributes(raw_values)
    attributes = {}

    match_found = raw_values.match(/(.*)>([^>]*$)/)
    if match_found then
      raw_attributes, value = match_found.captures
      attributes = get_attributes(raw_attributes)
    end

    [value, attributes]
  end

  def get_attributes(raw_attributes)
    raw_attributes.scan(/(\w+\='[^']+')|(\w+\="[^"]+")/).map(&:compact).flatten.inject({}) do |r, x|
      attr_name, val = x.split(/=/) 
      r.merge(attr_name.to_sym => val[1..-2])
    end
  end

end