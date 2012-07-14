#!/usr/bin/env ruby

# file: rexleparser.rb
# description: used by rexle.rb

class RexleParser

  def initialize(s)

    super()
    @a = scan_element(s.gsub(/<\?[^>]+>/,'').split(//))        
  end

  def to_a()
    @a
  end

  def to_s()
    name, value, attributes, *remaining = @a
   [value.strip, scan_a(remaining)].flatten.join(' ')
  end
  
  private
    
  def scan_a(a)
    a.inject([]) do |r, x|
      name, value, attributes, *remaining = x
      text_remaining = scan_a remaining if remaining
      r << value.strip << text_remaining if value
    end
  end
   
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
      elsif a[0..2].join == '!--' then
        name = '!-'
        #<![CDATA[
        #<!--
        3.times{ a.shift }
        value = ''

        value << a.shift until a[0..2].join == '-->' or a.length <= 1
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

            raw_values << a.shift until (a[0] + a[1..-1].join.strip[0]) == '/>'

            a.shift until a[0] == '<' or a.length < 1
            raw_values.strip!

            attributes = get_attributes(raw_values) if raw_values.length > 0
            
            element = [name, '', attributes]

            element
          else

            raw_values << a.shift until a[0] == '<'
            #puts 'raw_values: ' + raw_values.inspect
            value, attributes = get_value_and_attributes(raw_values) if raw_values.length > 0

            element = [name, value, attributes]
            
            tag = a[0, name.length + 3].join

            if a.length > 0 then

              children = true
              children = false if tag == "</%s>" % name

              if children == true then

                scan_elements(a, element) until (a[0, name.length + 3].join == "</%s>" % [name]) or a.length < 2

                #(r = scan_element(a); element << r if r) until (a[0, name.length + 3].join == "</%s>" % [name]) or a.length < 2                
                a.slice!(0, name.length + 3) if a[0, name.length + 3].join == "</%s>" % name
                a.shift until a[0] == '<' or a.length <= 1   
              else

                #check for its end tag
                a.slice!(0, name.length + 3) if a[0, name.length + 3].join == "</%s>" % name
                text_remaining = []
                text_remaining << a.shift until a[0] == '<' or a.length <= 1   

                remaining = text_remaining.join unless text_remaining.empty?
                #puts 'element: ' + element.inspect
              end
            end

            element
          end

          
          if remaining.nil? then #or remaining.strip.empty? then
            return element
          else
            return [element, remaining]
          end

        end
      end

    end
  end
  
  def scan_elements(a, element)
    r = scan_element(a)

    if r and r[0].is_a?(Array) then
      element = r.inject(element) {|r,x| r << x} if r       
    elsif r      
      element << r
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
    
    r1 = /([\w\-:]+\='[^']*)'/
    r2 = /([\w\-:]+\="[^"]*)"/
    
    r =  raw_attributes.scan(/#{r1}|#{r2}/).map(&:compact).flatten.inject({}) do |r, x|
      attr_name, val = x.split(/=/) 
      r.merge(attr_name.to_sym => val[1..-1])
    end

    return r
  end
end