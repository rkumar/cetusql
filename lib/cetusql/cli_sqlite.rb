#!/usr/bin/env ruby -w
# ----------------------------------------------------------------------------- #
#         File: cli_sqlite.rb
#  Description: common sqlite routines to be sourced in ruby shell programs
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2017-03-18 - 17:53
#      License: MIT
#  Last update: 2017-03-19 20:19
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2016 j kepler
# ----------------------------------------------------------------------------- #
require 'sqlite3'

# get database names
def getdbname
  choices = Dir['*.db','*.sqlite']
  if choices
    if choices.size == 1
      return choices.first
    else
      # select_from is in cli_utils.rb
      db = select_from "Select database", choices
      return db
    end
  end 
  return nil
end
alias :select_database_name :getdbname
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
def view_data db, sql
  data = []
  str = db.get_data sql
  str.each {|line| data << line.join("\t");  }
  filename = "t.t"
  require 'tempfile'
  tmpfile = Tempfile.new('SQL.XXXXXX')
  filename = tmpfile.path
  #File.open(filename, 'w') {|f| f.write(data.join("\n")) }
  tmpfile.write(data.join("\n"))
  
  system("cat #{filename} | term-table.rb -H | sponge #{filename}")
  #system "$EDITOR #{filename}"
  system "vim -c ':set nowrap' #{filename}"
  tmpfile.close
  tmpfile.unlink
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
    tables = sql "select name from sqlite_master where type='table'"
    tables.collect!{|x| x[0] }  ## 1.9 hack, but will it run on 1.8 ??
    @tables = tables
  end
  def columns table
    raise ArgumentError, "#{$0}: table name cannot be nil" unless table
    columns, ignore = self.get_metadata table
    return columns
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
    rs = ResultSet.new(contents, columns, datatypes)
    return rs
  end
  def close
    @db = nil
    @tables = nil
  end
end
