#!/usr/bin/env ruby

# file: rexleparser.rb
# description: used by rexle.rb

class RexleParser

  attr_reader :instructions

  def initialize(s)
    super()
    @instructions = s.scan(/<\?([\w-]+) ([^>]+)\?>/)
    @a = scan_element(s.strip.gsub(/<\?[^>]+>/,'').split(//)) 
  end

  def to_a()  @a end

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

    return unless a.length > 1

    a.shift

    # CDATA ?
    if a[0..1].join == '![' then

      name = '!['
      8.times{ a.shift }
      value = ''

      value << a.shift until a[0..2].join == ']]>' or a.length <= 1
      a.slice!(0,3)
      return [name, value, {}]        
    elsif a[0..2].join == '!--' then
      name = '!-'
      #<![CDATA[
      #<!--
      3.times{ a.shift }
      value = ''

      value << a.shift until a[0..2].join == '-->' or a.length <= 1
      a.slice!(0,3)
      return [name, value, {}]    
    else

      name = ''
      name << a.shift
      name << a.shift while a[0] != ' ' and a[0] != '>' and a[0] != '/'

      return unless name

      # find the closing tag
      i = a.index('>')
      raw_values = ''

      # is it a self closing tag?
      if a[i-1] == '/' then          

        raw_values << a.shift until (a[0] + a[1..-1].join.strip[0]) == '/>'
        a.shift(2)

        after_text = []
        after_text << a.shift until a[0] == '<' or a.length <= 1 
        #a.shift until a[0] == '<' or a.length < 1
        raw_values.strip!

        attributes = get_attributes(raw_values) if raw_values.length > 0
        element = [name, '', attributes]            

        return element if after_text.empty?
        return [element, after_text.join]

      else

        raw_values << a.shift until a[0] == '<'

        if raw_values.length > 0 then
          value, attributes = get_value_and_attribs(raw_values) 
        end
        
        element = [name, value, attributes]        
        tag = a[0, name.length + 3].join

        return unless a.length > 0
                
        children = tag == ("</%s>" % name) ? false : true

        if children == true then

          xa = scan_elements(a, element) until (a[0, name.length + 3].join \
                                         == "</%s>" % [name]) or a.length < 2

          xa.shift until xa[0] == '>' or xa.length <= 1
          xa.shift                                
          after_text = []
          after_text << xa.shift until xa[0] == '<' or xa.length <= 1
          
          return after_text.length >= 1 ? [element, after_text.join] : element

        else

          #check for its end tag
          a.slice!(0, name.length + 3) if a[0, name.length + 3].join \
                                                  == "</%s>" % name
          after_text = []
          after_text << a.shift until a[0] == '<' or a.length <= 1   

          return after_text.length >= 1 ? [element, after_text.join] : element

        end
      end
    end

  end
  
  def scan_elements(a, element)
    r = scan_element(a)

    if r and r[0].is_a?(Array) then
      element = r.inject(element) {|r,x|  r << x} if r       
    elsif r      
      element << r
    end
    return a
  end
  
  def get_value_and_attribs(raw_values)

    match_found = raw_values.match(/([^>]*)>(.*)/m)
    
    if match_found then
      raw_attributes, value = match_found.captures
      attributes = get_attributes(raw_attributes)
    end

    [value.gsub('>','&gt;').gsub('<','&lt;'), attributes]
  end

  def get_attributes(raw_attributes)
    
    r1 = /([\w\-:]+\='[^']*)'/
    r2 = /([\w\-:]+\="[^"]*)"/
    
    r =  raw_attributes.scan(/#{r1}|#{r2}/).map(&:compact).flatten.inject({}) do |r, x|
      attr_name, val = x.split(/=/,2) 
      r.merge(attr_name.to_sym => val[1..-1])
    end

    return r
  end
end