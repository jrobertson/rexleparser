#!/usr/bin/env ruby

# file: rexleparser.rb
# description: used by rexle.rb

class RexleParser

  attr_reader :instructions, :doctype, :to_a

  def initialize(raw_s)
    
    super()
    s = raw_s.clone
    @instructions = s.scan(/<\?([\w-]+) ([^>]+)\?>/)
    @doctype = s.slice!(/<!DOCTYPE html>\n?/)

    @to_a = reverse(parse_node(s.strip.gsub(/<\?[^>]+>/,'').reverse))

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
      elsif tag[/>\/|\/<$/] then
        return [:newnode]
      elsif r[/^(?:>--|>\]\]).*(?:--!|\[ATADC\[!<)/m] then

        i = r =~ /(\-\-!<|\[ATADC\[!<)/
        len = ($1).length
        tag = r.slice!(0,i+len)

        # it's a comment tag
        return [:child, create_comment(tag)]
      else

        # it's a start tag?
        return [:newnode] if tag[/^>.*[\w!]+\/<$/]

      end # end of tag match
      
    else

      # it's a text value
      i = r =~ />(?:[\-\/"'\w]|\]\])/ # collect until a tag is found or a CDATA element
      text = r.slice!(0,i)

      return [:child, text] if text
    end
  end

  def create_comment(tag)
    
    tagname = tag[0,3] == '>--' ? '-!' : '[!'   
    rt =  [">#{tagname}<", 
           [tag[/(?:>--|>\]\])(.*)(?:--!|\[ATADC\[!<)/m,1]], ">#{tagname}/<"
          ]

    return rt
  end
  
  def parse_node(r, j=nil)
    
    return unless r.length > 0

    tag = r.slice!(/^>[^<]+</) if (r =~ /^>[^<]+</) == 0

    if tag and tag[0,3][/>--|>\]\]/] then

      i = r =~ /(\-\-!<|\[ATADC\[!<)/
      len = ($1).length
      tag += r.slice!(0,i+len)
  
      # it's a comment tag
      return create_comment tag
    end
    
    tagname = tag[/([\w!]+)\/?<$/,1] 

    # self closing tag?
    if tag[/^>\/.*#{tagname}<$/] then
      return [">/#{tagname}<", [], "#{tag.sub(/>\//,'>')}"]
    end

    start_tag, children, end_tag = tag, [], nil

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
    
    r1 = /([\w\-:]+\='[^']*)'/
    r2 = /([\w\-:]+\="[^"]*)"/
    
    r =  raw_attributes.scan(/#{r1}|#{r2}/).map(&:compact)\
                                                .flatten.inject({}) do |r, x|
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

    tag = obj.pop.reverse.sub('!cdata','!-')
    
    children = obj[-1]

    if children.last.is_a?(String) then
      ltext ||= ''
      ltext << children.pop.reverse 
    end
    
    ltext << children.pop.reverse if children.last.is_a?(String) 

    r = children.reverse.map do |x|
      reverse(x)
    end
    
    return [tag[/[!\-\w\[]+/], ltext, get_attributes(tag), *r]
  end  
end