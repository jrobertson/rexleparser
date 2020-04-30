#!/usr/bin/env ruby

# file: rexleparser.rb
# description: used by rexle.rb


class Attributes < Hash

  class Value < String
    
    def initialize(value)
      #jr2020-04-30 super(value.gsub("'", '&apos;'))
      super(value)
    end
          
    def <(val2)
      self.to_f < val2.to_f
    end      
    
    def >(val2)
      self.to_f > val2.to_f
    end
    
    def inspect()
      super().gsub('&lt;','<',).gsub('&gt;','>').gsub('&pos;',"'")
    end
    
    def to_s()
      self.gsub('&lt;','<',).gsub('&gt;','>').gsub('&pos;',"'")
    end
    
  end  
  
  def initialize(h={})
    super().merge! h
  end
  
  def []=(k,v)
    super(k, k != :class ? Value.new(v) : v)
  end
  
  def merge(h)

    h2 = h.inject({}) do |r, kv| 
      k, raw_v = kv
      v = raw_v.is_a?(String) ? Value.new(raw_v) : raw_v
      r.merge(k => v) 
    end
    
    super(h2)
    
  end
end

class RexleParserException < Exception
end

class RexleParser

  attr_reader :instructions, :doctype, :to_a

  def initialize(raw_s)

    super()
    s = raw_s.clone.strip
    return if s.empty?
    
    raw_xml, raw_instrctns = if s.lines.first =~ /<?xml/ then
      s.split(/(?=\?>\s*<\w)/,2).reverse
    else
      s
    end
    @instructions = raw_instrctns ? \
                              raw_instrctns.scan(/<\?([\w-]+) ([^\?]+)/) : []
    @doctype = s.slice!(/<!DOCTYPE html>\n?/) if s.lines.first =~ /<\!DOCTYPE/
    @to_a = reverse(parse_node(raw_xml.strip.reverse))

  end
    
  private

  
  def scan_next(r, tagname)

    j = tagname

    if r[0] == '>' then

      # end tag match
      tag = r[/^>[^<]+</]
      
      if tag[1][/[ \w"']/] and  tag[-2] != '/'  then

        # is it the end tag to match the start tag?
        tag = r.slice!(/^>[^<]+</)
        end_tag = tag[/^>[^>]*#{j}<$/]

        if end_tag then
          
          j = nil
          return   [:end_tag, end_tag]

        elsif tag[/^>[^>]*\w+<$/] then
          # broken tag found
          broken_tag = tag
          return [:child, [nil, [], broken_tag]] if broken_tag          
        else
          
          text, newtag =  tag.sub('>',';tg&').split(/>/,2)
          
          if newtag then
            tag = newtag
            r.prepend '>' + tag
          end

          return [:child, text]
        end
      elsif r[0,3] == '>--' then   # comment tag found
          
        r.slice!(0,3)
        i = r =~ /(\-\-!<)/
        s = r.slice!(0,i)
        r.slice!(0,4)

        tagname, content = ['-!',s]
      
        return [:child, [">#{tagname}<", [content], ">#{tagname}/<"]]
        
      elsif r[0,3] == '>]]' then   # CDATA tag found

        r.slice!(0,3)
        i = r =~ /(\[ATADC\[!<)/
        s = r.slice!(0,i)
        r.slice!(0,9)

        tagname, content = ['[!',s]

        return [:child, [">#{tagname}<", [content], ">#{tagname}/<"]]        
        
      elsif tag[/>\/|\/<$/] or tag[/^>.*[\w!]+\/<$/] then
                
        return [:newnode]        
        
      else
  
        r.sub!('>',';tg&')      
        i = r =~ />(?:[\-\/"'\w]|\]\])/ # collect until a tag is found or a CDATA element
        text = r.slice!(0,i)

        return [:child, text] if text

      end # end of tag match
      
    else

      # it's a text value
      i = r =~ />(?:[\-\/"'\w]|\]\])/ # collect until a tag is found or a CDATA element
      text = r.slice!(0,i)

      return [:child, text] if text
    end
  end
  
  def parse_node(r, j=nil)
    
    return unless r.length > 0
    tag = r.slice!(/^>[^<]+</) if (r =~ /^>[^<]+</) == 0
    tagname = tag[/([\w!:]+)\/?<$/,1] 

    # self closing tag?
    if tag[/^>\/.*#{tagname}<$/m] then
      return [">/#{tagname}<", [], "#{tag.sub(/>\//,'>')}"]
    end

    start_tag, children, end_tag = tag, [], nil

    unless start_tag[1..-3][/\w+$/] then
      raise RexleParserException, 'invalid closing tag found ' + \
                start_tag.reverse + '; context: ' + r[0..120].reverse.inspect
    end

    until end_tag do 
      
      key, res = scan_next r, tagname      
      
      case key 
      when :end_tag
        end_tag = res
        r2 = [start_tag, children, end_tag]
        end_tag = nil
        
        return r2
      when :child
        children << res
      when :newnode
        children << parse_node(r, tagname)
      else
        break
      end
    end

    [start_tag,  children, end_tag]
  end

  def get_attributes(raw_attributes)
    
    r1 = /([\w\-:\(\)]+\='[^']*)'/
    r2 = /([\w\-:\(\)]+\="[^"]*)"/
    
    r =  raw_attributes.scan(/#{r1}|#{r2}/).map(&:compact)\
                                  .flatten.inject(Attributes.new) do |r, x|
      attr_name, raw_val = x.split(/=/,2) 
      val = attr_name != 'class' ? raw_val[1..-1] : raw_val[1..-1].split
      r.merge(attr_name.to_sym => val)
    end

    return r
  end

  def reverse(raw_obj)
    
    return unless raw_obj
    obj = raw_obj.clone
    return obj.reverse! if obj.is_a? String

    tag = obj.pop.reverse
    
    children = obj[-1]

    r = children.reverse.map {|x| reverse(x)}
    
    return [tag[/[!\-\w:\[]+/], get_attributes(tag), *r]
  end  
end
