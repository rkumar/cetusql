#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: cli_sqlite.rb
#  Description: common sqlite routines to be sourced in ruby shell programs
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2017-03-18 - 17:53
#      License: MIT
#  Last update: 2017-03-26 12:40
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2016 j kepler
# ----------------------------------------------------------------------------- #
require 'sqlite3'
require 'shellwords'
require 'pp'

def get_table_names db
  #raise "No database file selected." unless $current_db

  tables = get_data "select name from sqlite_master where type='table'"
  tables.collect!{|x| x[0] }  ## 1.9 hack, but will it run on 1.8 ??
  tables
end
def get_column_names tbname
  get_metadata tbname
end
# connect to given database, and if no name supplied then allow user to choose
def connect dbname=nil
  dbname ||= getdbname
  return nil unless dbname
  #$log.debug "XXX:  CONNECT got #{dbname} "
  $current_db = dbname
  $db = SQLite3::Database.new(dbname) if dbname
  return $db
end
def get_data db, sql
  #$log.debug "SQL: #{sql} "
  $columns, *rows = db.execute2(sql)
  #$log.debug "XXX COLUMNS #{sql}, #{rows.count}  "
  content = rows
  return nil if content.nil? or content[0].nil?
  $datatypes = content[0].types #if @datatypes.nil?
  return content
end
def get_metadata table
  get_data "select * from #{table} limit 1"
  return $columns
end
# TODO option of headers
# run query and put into a temp table and view it using vim
# If no outputfile name passed, then use temp table
# What about STDOUT
# TODO use temp file, format it there and append to given file only after termtable
def view_data db, sql, options
  outputfile = options[:output_to]
  formatting = options[:formatting]
  headers = options[:headers]
  #str = db.get_data sql
  rs = db.execute_query sql
  str = rs.content
  columns = rs.columns
  #puts "SQL: #{sql}.\nstr: #{str.size}"
  data = []
  if headers
    data << columns.join("\t")
  end
  str.each {|line| data << line.join("\t");  }
  #puts "Rows: #{data.size}"
  require 'tempfile'
  tmpfile = Tempfile.new('SQL.XXXXXX')
  filename = tmpfile.path
  filename = Shellwords.escape(filename)
  #puts "Writing to #{filename}"
  tmpfile.write(data.join("\n"))
  tmpfile.close # need to flush, otherwise write is buffered
  headerstr=nil
  if formatting
    headerstr = "-H" unless headers
    # sometimes this can be slow, and it can fault on UTF-8 chars
    system("cat #{filename} | term-table.rb #{headerstr} | sponge #{filename}")
  end
  if outputfile
    #puts "comes here"
    system("cp #{filename} #{outputfile}")
    filename = outputfile
  end
  system "wc -l #{filename}" if $opt_debug
  
  #system "$EDITOR #{filename}"
  system "vim -c ':set nowrap' #{filename}"
  tmpfile.close
  tmpfile.unlink
end
# given content returned by get_data, formats and returns in a file
def tabulate content, options
  data = []
  content.each {|line| data << line.join("\t");  }
  puts "Rows: #{data.size}" if $opt_verbose
  require 'tempfile'
  tmpfile = Tempfile.new('SQL.XXXXXX')
  filename = tmpfile.path
  #filename = Shellwords.escape(filename)
  #puts "Writing to #{filename}"
  tmpfile.write(data.join("\n"))
  tmpfile.close # need to flush, otherwise write is buffered
  if options[:formatting]
    system("term-table.rb < #{filename} | sponge #{filename}")
  end
  return filename
end
class Database

  ResultSet = Struct.new(:content, :columns, :datatypes)
  
  def initialize(name)
    raise ArgumentError, "Database name cannot be nil" unless name
    @name = name
    connect name
  end
  def connect name
    raise ArgumentError, "Database name cannot be nil" unless name
    @tables = nil
    @db = SQLite3::Database.new(name) 
  end
  def tables
    return @tables if @tables
    tables = sql "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    tables.collect!{|x| x[0] }  ## 1.9 hack, but will it run on 1.8 ??
    @tables = tables
  end
  def columns table
    raise ArgumentError, "#{$0}: table name cannot be nil" unless table
    columns, ignore = self.get_metadata table
    return columns
  end
  def indexed_columns table
    indexes = sql %Q{select sql from sqlite_master where type='index' and tbl_name = "#{table}" }
    return nil if indexes == []
    #pp indexes
    arr = []
    indexes.each do |ind|
      if ind.first.nil?
        arr << "auto?"
        next
      end
      m = ind.first.match /\((.*)\)/
      arr << m[1] if m
    end
    return arr.join(",")
  end
  def get_metadata table
    raise ArgumentError, "#{$0}: table name cannot be nil" unless table
    sql =  "select * from #{table} limit 1"
    columns, *rows = @db.execute2(sql)
    content = rows
    return nil if content.nil? or content[0].nil?
    datatypes = content[0].types 
    return columns, datatypes
  end
  # runs sql query and returns an array of arrays
  def get_data sql
    #$log.debug "SQL: #{sql} "
    columns, *rows = @db.execute2(sql)
    #$log.debug "XXX COLUMNS #{sql}, #{rows.count}  "
    content = rows
    return content
  end
  alias :sql :get_data 
  def execute_query sql
    columns, *rows = @db.execute2(sql)
    content = rows
    return nil if content.nil? or content[0].nil?
    datatypes = content[0].types 
    rs = ResultSet.new(content, columns, datatypes)
    return rs
  end
  def sql_recent_rows tablename
    sql =  "SELECT * from #{tablename} ORDER by rowid DESC LIMIT 100"
  end
  def close
    @db = nil
    @tables = nil
  end
end
