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

    def to_s(unescape: true)
      unescape ? self.gsub('&amp;','&').gsub('&pos;',"'") : self
    end
    
  end  
  
  def initialize(h={})
    super().merge! h
  end
  
  def []=(k,v)
    super(k, k != :class ? Value.new(v) : v)
  end

  def delete(key=nil)

    if key then
      super(key)
    else
      keys.each {|key| super(key)}
    end

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

  attr_reader :stack

  def initialize(raws, debug: false)

    s = raws.strip
    @debug = debug
    @a = []
    @stack = []
    
    raw_xml, raw_instrctns = if s.lines.first =~ /<?xml/ then
      s.split(/(?<=\?>)/,2).reverse
    else
      s
    end
    puts 'raw_xml: ' + raw_xml.inspect if @debug
    @instructions = raw_instrctns ? \
                              raw_instrctns.scan(/<\?([\w-]+) ([^\?]+)/) : []
    @doctype = s.slice!(/<!DOCTYPE html>\n?/) if s.lines.first =~ /<\!DOCTYPE/
        
    # scancom is run twice because we 1st check for comment tags and then cdata tags
    @a = parse(scancom(scancom(raw_xml), type: :cdata)).flatten(1)

  end

  def to_a()
    @a
  end

  private
  
  def ehead(raws)

    s = raws.lstrip
    puts '_s: ' + s.inspect if @debug
    # fetch the element head
    tag = s =~ /<[^>]+\/?>/
    s2 = s[tag+1..-1]
    tagb = s2 =~ />/
    return unless tag

    len = tagb+1-tag
    
    if @debug then
      puts 'ehead()/detail: ' + [tag, tagb, len, s[tag,len+1]].inspect
    end

    [s[tag,len+1], s[len+1..-1]]

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

  def parse(raws, a=[], cur=nil)

    s = raws #.lstrip
    
    if @debug then
      puts '.parse() s: ' + s.inspect[0..600]
      puts '.parse() a: ' + a.inspect[0..699]
      puts '.parse() cur: ' + cur.inspect[0..799]
    end

    # if self-closing tag
    if s =~ /^<[^<]+\/>/ then

      tag = s[/^<[^<]+\/>/]
      puts 'parse() self-closing/tag: ' + tag.inspect  if @debug
      tail = $'
      
      if @debug then
        puts 'parse() self-closing tag found'
        puts 'parse()/tail: ' + tail.inspect
      end
      
      a2 = parsetag(tag)
      puts '_a: ' + a.inspect if @debug
      cur ? a.last << a2 : a << a2
      
      parse(tail, a, cur)

    # is it the head?
    elsif (s =~ /^<[^\/>]+>/) == 0 then
      
      puts 'parse()/head found' if @debug

      tag, tail = ehead(s)
      
      if @debug then
        puts 'parse() tag: ' + tag.inspect
        puts 'parse() tail: ' + tail.inspect
      end
      # add it to the list
      a2 = parsetag(tag)

      puts '_cur: ' + cur.inspect  if @debug
      if cur then
        cur << a2
        cur2 = cur.last
      else
        a << a2
        cur2 = a.last
      end

      puts '_a: ' + a.inspect  if @debug

      # add it to the stack
      @stack.push cur2

      parse(tail, a, cur2)
      
    elsif (s =~ /^[^<]/) == 0

      puts 'parse() we have text!'  if @debug
      text = raws[/[^<]+/m] #
      remaining = $'
      
      if @debug then
        puts 'parse() text: ' + text.inspect
        puts 'cur tag: ' + cur[0].inspect
      end
      
      cur << if cur[0][0] == '!' then
        text.gsub('&lt;','<').gsub('&gt;','>').gsub('&amp;','&')
      else
        text.gsub(/>/,'&gt;').gsub(/</, '&lt;')
      end

      puts 'remaining: ' + remaining.inspect  if @debug
      parse(remaining, a, cur) if remaining.length > 0
            
      
    # is it a closing tag?
    elsif s =~ /^\s?<\/\w+>/m

      tail = s[/^\s*<\/\w+>(.*)/m,1]
      
      if @debug then
        puts 'parse()/closing tag ' + s[/^\s*<\/\w+>/].inspect
        puts '>a: ' + a.inspect
      end
      
      @stack.pop
      #a << []
      parse(tail, a, @stack.last)
        
    elsif s.empty? and @stack.length > 0
      
      puts 'parse() no end tag!'  if @debug

    end

    return a

  end

  # we parse the tag because it contains more than just the name it often contains attributes
  #
  def parsetag(s)
    
    puts 'parsetag:' + s.inspect  if @debug
    rawtagname, rawattr = s[1..-2].sub(/\/$/,'').match(/^(\w+) *(.*)/)\
      .values_at(1,2)

    tagname = case rawtagname.to_sym
    when :_comment
      '!-'
    when :_cdata
      '!['
    else
      rawtagname
    end

    [tagname, get_attributes(rawattr)]
  end

  def scancom(s, type=:comment)

    tag1 = ['<!--', '-->', 'comment', '<!--']
    tag2 = ['<![CDATA[', '\]\]>', 'cdata', '\<!\[CDATA\[']
    tag = type == :comment ? tag1 : tag2

    #puts 'tag: ' + tag.inspect
    istart = s =~ /#{tag[3]}/
    return s unless istart

    iend = s =~ /#{tag[1]}/
    comment ="<_%s>%s</_%s>" % [tag[2], s[istart+tag[0].length.. iend-1].gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;'), tag[2]]

    if @debug then
      puts 'comment: ' + comment.inspect
      # construct the new string
      puts 'istart: ' + istart.inspect
    end
                                              
    s3 = s[0,istart].to_s + comment + s[iend+3..-1]
    scancom(s3, type)

  end

end
