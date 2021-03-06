#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: cli_utils.rb
#  Description: common stuff for command line utils such as menu, getting a single char
#     inline variable editing
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2017-03-18 - 14:33
#      License: MIT
#  Last update: 2017-04-02 19:47
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2016 j kepler


# edit a variable inline like zsh's vared
def vared var, prompt=">"
  Readline.pre_input_hook = -> do
    Readline.insert_text var
    Readline.redisplay
    # Remove the hook right away.
    Readline.pre_input_hook = nil
  end
  begin 
    input = Readline.readline(prompt, false)
  rescue Exception => e
    return nil
  end
  input
end


# What if we only want to allow the given keys and ignore others.
# In menu maybe ENTER and other such keys should be ignored, or atleast
# option should be there, so i don't accidentally hit enter.
# print in columns, but take into account size so we don't exceed COLS
# (Some entries like paths can be long)
def menu title, h
  return unless h

  pbold "#{title}"
  ctr = 0
  #h.each_pair { |k, v| puts " #{k}: #{v}" }
  h.each_pair { |k, v| 
    print " #{k}: %-20s" % [v]
    if ctr > 1
      print "\n"
      ctr = 0
    else
      ctr += 1
    end
  }
  print "\n >"
  #print "\r >"
  ch = get_char
  puts ch
  #system("clear") # ???
  binding = h[ch]
  binding = h[ch.to_sym] unless binding
  if binding
    if respond_to?(binding, true)
      # 2017-03-19 - we can't send return values from a method ??
      send(binding)
    end
  end
  return ch, binding
end
## get a character from user and return as a string
# Adapted from:
#http://stackoverflow.com/questions/174933/how-to-get-a-single-character-without-pressing-enter/8274275#8274275
# Need to take complex keys and matc against a hash.
def get_char
  begin
    system("stty raw -echo 2>/dev/null") # turn raw input on
    c = nil
    #if $stdin.ready?
      c = $stdin.getc
      cn=c.ord
      return "ENTER" if cn == 10 || cn == 13
      return "BACKSPACE" if cn == 127
      return "C-SPACE" if cn == 0
      return "SPACE" if cn == 32
      # next does not seem to work, you need to bind C-i
      return "TAB" if cn == 8
      if cn >= 0 && cn < 27
        x= cn + 96
        return "C-#{x.chr}"
      end
      if c == ''
        buff=c.chr
        while true
          k = nil
          if $stdin.ready?
            k = $stdin.getc
            #puts "got #{k}"
            buff += k.chr
          else
            x=$kh[buff]
            return x if x
            #puts "returning with  #{buff}"
            if buff.size == 2
              ## possibly a meta/alt char
              k = buff[-1]
              return "M-#{k.chr}"
            end
            return buff
          end
        end
      end
    #end
    return c.chr if c
  ensure
    #system "stty -raw echo" # turn raw input off
    system("stty -raw echo 2>/dev/null") # turn raw input on
  end
end
## clean this up a bit, copied from shell program and macro'd 
$kh=Hash.new
$kh["OP"]="F1"
$kh["[A"]="UP"
$kh["[5~"]="PGUP"
$kh['']="ESCAPE"
KEY_PGDN="[6~"
KEY_PGUP="[5~"
## I needed to replace the O with a [ for this to work
#  in Vim Home comes as ^[OH whereas on the command line it is correct as ^[[H
KEY_HOME='[H'
KEY_END="[F"
KEY_F1="OP"
KEY_UP="[A"
KEY_DOWN="[B"

$kh[KEY_PGDN]="PgDn"
$kh[KEY_PGUP]="PgUp"
$kh[KEY_HOME]="Home"
$kh[KEY_END]="End"
$kh[KEY_F1]="F1"
$kh[KEY_UP]="UP"
$kh[KEY_DOWN]="DOWN"
KEY_LEFT='[D' 
KEY_RIGHT='[C' 
$kh["OQ"]="F2"
$kh["OR"]="F3"
$kh["OS"]="F4"
$kh[KEY_LEFT] = "LEFT"
$kh[KEY_RIGHT]= "RIGHT"
KEY_F5='[15~'
KEY_F6='[17~'
KEY_F7='[18~'
KEY_F8='[19~'
KEY_F9='[20~'
KEY_F10='[21~'
KEY_S_F1='[1;2P'
$kh[KEY_F5]="F5"
$kh[KEY_F6]="F6"
$kh[KEY_F7]="F7"
$kh[KEY_F8]="F8"
$kh[KEY_F9]="F9"
$kh[KEY_F10]="F10"
# testing out shift+Function. these are the codes my kb generates
$kh[KEY_S_F1]="S-F1"
$kh['[1;2Q']="S-F2"

def pbold text
  puts "#{BOLD}#{text}#{BOLD_OFF}"
end
def pgreen text
  puts "#{GREEN}#{text}#{CLEAR}"
end
def perror text
  pred text
  get_char
end
def pred text
  puts "#{RED}#{text}#{CLEAR}"
end
def pause text=" Press a key ..."
  print text
  get_char
end
# alternative of menu that takes an array and uses numbers as indices.
# Hey wait, if there aer more than 10 then we are screwed since we take one character
# I have handled this somewhere, should check, maybe we should use characters
# returns text, can be nil if selection not one of choices
# How do we communicate to caller, that user pressed C-c
def select_from title, array
  h = {}
  array.each_with_index {|e,ix| ix += 1; h[ix.to_s] = e }
  ch, text = menu title, h
  unless text
    if ch == "ENTER"
      return array.first
    end
  end
  return text
end
# multiselect from an array using fzf
def multi_select title, array
  arr = %x[ echo "#{array.join("\n")}" | fzf --multi --reverse --prompt="#{title} >"]
  return arr.split("\n")
end
# single select from an array using fzf
# CAUTION: this messes with single and double quotes, so don't pass a query in
def single_select title, array
  str = %x[ echo "#{array.join("\n")}" | fzf --reverse --prompt="#{title} >" -1 -0 ]
  return str
end
def editline array
  Readline::HISTORY.push(*array) 
  begin
    command = Readline::readline('>', true)
  rescue Exception => e
    return nil
  end
  return command
end

# allows user to select from list, returning string if user pressed ENTER
#  Aborts if user presses Q or C-c or ESCAPE
def ctrlp arr
  patt = nil
  curr = 0
  while true
    # clear required otherwise will keep drawing itself
    system("clear")
    if patt and patt != ""
      # need fuzzy match here
      view = arr.grep(/^#{patt}/)
      view = view | arr.grep(/#{patt}/)
      fuzzypatt = patt.split("").join(".*")
      view = view | arr.grep(/#{fuzzypatt}/)
    else
      view = arr
    end
    curr = [view.size-1, curr].min
    # if empty then curr becomes -1
    curr = 0 if curr < 0
    view.each_with_index do |a, i|
      mark = " "
      mark = ">" if curr == i
      print "#{mark}  #{a} \n"
    end
    #puts " "
    print "\r#{patt} >"
    ch = get_char
    if  ch =~ /^[a-z]$/
      patt ||= ""
      patt << ch
    elsif ch == "BACKSPACE"
      if patt && patt.size > 0
        patt = patt[0..-2]
      end
    elsif ch == "Q" or ch == "C-c" or ch == "ESCAPE"
      break
    elsif ch == "UP"
      curr -= 1
      curr = 0 if curr < 0
    elsif ch == "DOWN"
      curr += 1
      curr = [view.size-1, curr].min
      # if empty then curr becomes -1
      curr = 0 if curr < 0
    elsif ch == "ENTER"
      return view[curr]
    else
      # do right and left arrow

      # get arrow keys here
    end

  end
end
## CONSTANTS
GMARK      = '*'
CURMARK    = '>'
SPACE      = " "
CLEAR      = "\e[0m"
BOLD       = "\e[1m"
BOLD_OFF   = "\e[22m"
RED        = "\e[31m"
ON_RED     = "\e[41m"
GREEN      = "\e[32m"
YELLOW     = "\e[33m"
BLUE       = "\e[1;34m"

ON_BLUE    = "\e[44m"
REVERSE    = "\e[7m"
UNDERLINE  = "\e[4m"
#CURSOR_COLOR = ON_BLUE
CURSOR_COLOR = CLEAR

# --- end constants
## check screen size and accordingly adjust some variables
#
def screen_settings
  $glines=%x(tput lines).to_i
  $gcols=%x(tput cols).to_i
  $grows = $glines - 3
  $pagesize = 60
  #$gviscols = 3
  $pagesize = $grows * $gviscols
end

# readline version of gets
def input(prompt="", newline=false)
  prompt += "\n" if newline
  ret = nil
  begin
    ret = Readline.readline(prompt, true).squeeze(" ").strip
  rescue Exception => e
    return nil
  end
  return ret
end
def agree(prompt="")
  x = input(prompt)
  return true if x.upcase == "Y"
  false
end
alias :confirm :agree
## 
#
# print in columns
# ary - array of data
# sz  - lines in one column
#
def columnate ary, sz
  buff=Array.new
  return buff if ary.nil? || ary.size == 0
  
  # determine width based on number of files to show
  # if less than sz then 1 col and full width
  #
  wid = 30
  ars = ary.size
  ars = [$pagesize, ary.size].min
  d = 0
  if ars <= sz
    wid = $gcols - d
  else
    tmp = (ars * 1.000/ sz).ceil
    wid = $gcols / tmp - d
  end
  #elsif ars < sz * 2
    #wid = $gcols/2 - d
  #elsif ars < sz * 3
    #wid = $gcols/3 - d
  #else
    #wid = $gcols/$gviscols - d
  #end

  # ix refers to the index in the complete file list, wherease we only show 60 at a time
  ix=0
  while true
    ## ctr refers to the index in the column
    ctr=0
    while ctr < sz

      f = ary[ix]
      fsz = f.size
      if fsz > wid
        f = f[0, wid-2]+"$ "
        ## we do the coloring after trunc so ANSI escpe seq does not get get
        if ix + $sta == $cursor
          f = "#{CURSOR_COLOR}#{f}#{CLEAR}"
        end
      else
        ## we do the coloring before padding so the entire line does not get padded, only file name
        if ix + $sta == $cursor
          f = "#{CURSOR_COLOR}#{f}#{CLEAR}"
        end
        #f = f.ljust(wid)
        f << " " * (wid-fsz)
      end

      if buff[ctr]
        buff[ctr] += f
      else
        buff[ctr] = f
      end

      ctr+=1
      ix+=1
      break if ix >= ary.size
    end
    break if ix >= ary.size
  end
  return buff
end
# print an array in columns
# default number of columns is 3 and can be supplied. I actually much prefer that this be derived, so we can get more 
    # columns if possible, and te width should be caclulated too
def print_in_cols a, noc=nil
  unless noc
    noc = 3
    if a.size < 7
      noc = 1
    elsif a.size < 15
      noc = 2
    end
  end

  x = noc - 1
  cols = a.each_slice((a.size+x)/noc).to_a
  # todo width should be determined based on COLS of screen, and width of data
  cols.first.zip( *cols[1..-1] ).each{|row| puts row.map{|e| e ? '%-30s' % e : '     '}.join("  ") }
end
## expects array of arrays
#class Array
  #def to_table l = []
    #self.each{|r|r.each_with_index{|f,i|l[i] = [l[i]||0, f.length].max}}
    #self.each{|r|r.each_with_index{|f,i|print "#{f.ljust l[i]}|"};puts ""}
  #end
#end
