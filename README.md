# Cetusql

Command-line based sqlite3 database explorer. The idea is to minimize typing of basic queries/tablenames and column names by allowing for selection of the same.

Some basic features:

- Lists databases in current folder and allows menu for selection.
- selection of tablenames from list, and of columns names and creates formatted output to a local temp file which 
is then displayed.
- bookmark/save common SQL queries and recall later.

Uses sqlite3 gem, readline for editing. In the case of columns, uses `fzf` for selection.

Also, uses 'term-table.rb' for formatting of output. This needs to be placed in your path as an executable.

You may replace that with your own formatter such as `csvlook` or `column -t`. However, these two crash on non-ascii characters on a Mac, so I've written a ruby replacement.
You can forgo it entirely and just have comma or tab separated output sent to a file.

## Installation

    $ gem install cetusql
    $ brew install fzf

## Usage

run `cetusql` on the command line.

If no database name is passed, will prompt for one from *.db and *.sqlite files in current directory.
After selection, one may select one or more tables from a list.
Then one may select one ore more columns from a list.
Edit the SQL statement if need be, and press ENTER.
The output is displayed in vim using a temp file.

Use the menu to change table or database file, or set other options, save last SQL query, select from favorite queries, etc.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rkumar/cetusql.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

