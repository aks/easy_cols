ec [FIELD | FIELD1..FIELD2 | FIELD1-FIELD2] ...

Ranges of fields can be specified with STARTFIELD..STOPFIELD or STARTFIELD-STOPFIELD.
FIELD can be a field index (an integer), or a field name.

The basic idea is to make it *easy* to fetch specific columns of STDIN (or a file).
There are several supported *formats* for parsing:

  csv           Comma-separated columns; fields can be quoted; there can be one header line
  tsv           Tab-separated columns; fields can be quoted; there can be one header line
  tbl           An ASCII table format, with a header, a separator line (using -+-), and data rows (using | separator)


Options:

  --in=FORMAT                              # input format (default: auto)
  --out=FORMAT                             # output format (default: same)
  --delim=CHARS       | -d CHARS           # split fields by SEPARATOR
  --pattern=PATTERN   | -p PATTERN         # split fields by PATTERN
  --format FORMAT     | -f FORMAT          # assume input is in FORMAT (deprecated, use --in)
  --quotes            | -q                 # parse matching quotes before splitting
  --headers[=NUM]     | -h NUM             # ignore header line(s), NUM=1 by default
  --lines             | -l                 # ignore horizontal lines ("---*", "___*")
  --blanklines        | -b                 # ignore blank lines
  --comments=PATTERN  | -c PATTERN         # strip any comment prefix
  --cprefix=PATTERN   | -c PATTERN
  --cblock=PATTERN    | -
  --start=[NUM | PAT] | -s NUM_PAT         # ignore lines before NUM or PAT
  --stop=[NUM | PAT]  | -S NUM_PAT         # stop at line NUM, or first line matching PAT
  --no-quotes         | -Q                 # do not parse out matched quotes
  --no-headers[=NUM]  | -H NUM             # do not ignore header lines (NUM=1 by default)
  --no-lines          | -L                 # do not ignore horizontal lines
  --no-blanklines     | -B                 # do not ignore blank lines
  --csv               # parse input as CSV format (sets --in=csv)
  --tsv               # parse input as TSV format (sets --in=tsv)
  --tbl               # parse input as table format (sets --in=table)
  --table             # output as table format (sets --out=table with pipe separator)
  --plain             # parse input as plain format (sets --in=plain)
  --LANGUAGE                                # set comments pattern according to the LANGUAGE

CHARS="\s"              # default is whitespace, same as " \t\n\r"
CHARS=":"               # separate fields with ':'
CHARS=","               # separate fields with ','

Input Formats (--in=FORMAT):
    --in=csv    # Comma-separated values, fields can be quoted
    --in=tsv    # Tab-separated values
    --in=table  # ASCII table format with header, separator line, and data
    --in=tbl    # Alias for table
    --in=plain  # Whitespace-separated values
    --in=auto   # Auto-detect format (default)

Output Formats (--out=FORMAT):
    --out=csv    # Output as CSV (comma-separated, properly quoted)
    --out=tsv    # Output as TSV (tab-separated)
    --out=table  # Output as ASCII table (with column widths and separator lines)
    --out=tbl    # Alias for table
    --out=plain  # Output as whitespace-separated (aligned columns)
    --out=same   # Use same format as input (default)

Format Conversion Examples:
    ec --in=csv --out=table data.csv   # Convert CSV to table format
    ec --in=table --out=csv data.txt   # Convert table to CSV format
    ec --out=table data.csv            # Auto-detect input, convert to table
    ec --in=tsv --out=csv data.tsv     # Convert TSV to CSV

The comments pattern can be given explicitly, or can be inferred by the input
file type (if given), or by --LANGUAGE option, where LANGUAGE is one of: ruby,
c, go, elixir, python, java, scala, etc.  Each language has a different style
for doing block comments, and this tool can be used to extract columns from
blocks of comment text anywhere in file, given the --start and --stop patterns,
along with the

Examples:
  --ruby    # => --comments="^\\s*# "
  --js      # => --comments="^\\s*//"
  --python  # => --comments="^\\s*# "

