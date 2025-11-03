# frozen_string_literal: true

require 'optparse'
require 'stringio'

module EasyCols
  $PROG = File.basename($0)

  class CLI
    def initialize
      @options = {}
      @column_selectors = []
    end

    def run(argv)
      parse_options(argv)
      process_input
    rescue Error => e
      warn "Error: #{e.message}"
      exit 1
    rescue StandardError => e
      warn "Unexpected error: #{e.message}"
      exit 1
    end

    private

    def parse_options(argv)
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$PROG} [options] <file> [column_selectors...]"

        opts.separator <<~HELP

          Extract and display specific columns from structured text data.

          Column selectors can be:
            - Column index: 0, 1, 2, etc. (0-based)
            - Column range: 0-5, 2-10, etc.
            - Comma-separated indices: 0,2,5
            - Header name: 'Name', 'Email', etc.

          Examples:
            #{$PROG} data.csv 0 1 2                  # Show columns 0, 1, 2
            #{$PROG} data.csv 'Name' 'Email'         # Show Name and Email columns
            #{$PROG} data.csv 0-5                    # Show columns 0 through 5
            #{$PROG} --format tsv data.tsv 0 1       # Parse as TSV
            #{$PROG} --table data.txt 0 1 2          # Parse as table format
            #{$PROG} - < data.csv                    # Read from STDIN

          Options:
        HELP

        opts.on('--in=FORMAT', Parser::SUPPORTED_FORMATS,
                "Input format (default: auto, formats: #{Parser::SUPPORTED_FORMATS.join(', ')})") do |format|
          @options[:input_format] = format
        end

        opts.on('--out=FORMAT', Formatter::SUPPORTED_OUTPUT_FORMATS,
                "Output format (default: same, formats: #{Formatter::SUPPORTED_OUTPUT_FORMATS.join(', ')})") do |format|
          @options[:output_format] = format
        end

        # Legacy options for backward compatibility
        opts.on('-f', '--format=FORMAT', Parser::SUPPORTED_FORMATS,
                "Input format (deprecated, use --in)") do |format|
          @options[:input_format] = format
        end

        opts.on('-d', '--delimiter=CHARS', 'Field delimiter') do |delim|
          @options[:delimiter] = delim
        end

        opts.on('-D', '--output-delimiter=STR', 'Output separator (default: " , ")') do |str|
          @options[:output_separator] = str
        end

        opts.on('-H', '--no-header', 'Do not output header row') do
          @options[:no_header] = true
        end

        opts.on('--table', 'Use table format for output (sets output format to table)') do
          # Only set output format, not input format
          # Input format will be auto-detected unless explicitly set
          @options[:output_format] = 'table'
          @options[:output_separator] = ' | '
          @options[:table_mode] = true
        end

        opts.on('--pipe', 'Use pipe separator (" | ")') do
          @options[:output_separator] = ' | '
        end

        opts.on('--tab', 'Use tab separator') do
          @options[:output_separator] = "\t"
        end

        opts.on('--comma', 'Use comma separator (",")') do
          @options[:output_separator] = ','
        end

        # Convenience format options for input
        opts.on('--csv', 'Parse input as CSV format') do
          @options[:input_format] = 'csv'
        end

        opts.on('--tsv', 'Parse input as TSV format') do
          @options[:input_format] = 'tsv'
        end

        opts.on('--tbl', 'Parse input as table format') do
          @options[:input_format] = 'table'
        end

        opts.on('--plain', 'Parse input as plain (whitespace-separated) format') do
          @options[:input_format] = 'plain'
        end

        opts.on('-v', '--verbose', 'Verbose output') do
          @options[:verbose] = true
        end

        opts.on('-q', '--quiet', 'Quiet output') do
          @options[:quiet] = true
        end

        opts.on('-c', '--count', 'Count columns instead of selecting') do
          @options[:count_mode] = true
        end

        opts.on('-h', '--help', 'Show this help') do
          puts opts
          exit 0
        end
      end.parse!(argv)

      @file_path = argv[0]
      @column_selectors = parse_column_selectors(argv[1..]) if argv.length > 1
    end

    def parse_column_selectors(selectors)
      selectors.map do |selector|
        case selector
        when /^\d+$/            # Single integer
          selector.to_i
        when /^\d+-\d+$/        # Range
          start_idx, end_idx = selector.split('-').map(&:to_i)
          (start_idx..end_idx).to_a
        when /,/                # Comma-separated
          selector.split(',').map(&:strip).map(&:to_i)
        else                    # Header name
          selector
        end
      end
    end

    def process_input
      input_data = read_input

      if @options[:count_mode]
        count_columns(input_data)
      else
        select_columns(input_data)
      end
    end

    def read_input
      if @file_path == '-' || @file_path.nil?
        $stdin.read
      else
        File.read(@file_path)
      end
    end

    def select_columns(input_data)
      # Determine input format
      input_format = @options[:input_format] || 'auto'

      # Parser only needs input/parsing options
      parser_options = {
        format: input_format,
        delimiter: @options[:delimiter]
      }.compact

      parser = Parser.new(**parser_options)
      data = parser.parse(input_data)

      return if data.empty?

      headers = data.first
      selector = ColumnSelector.new(headers)

      # If no selectors provided, default to all columns
      selectors = if @column_selectors.empty?
                    (0...headers.length).to_a
                  else
                    @column_selectors
                  end

      selected_indices = selector.select(selectors)

      # Determine output format
      # If 'same', use the detected/parsed input format
      # However, if output_separator is explicitly set (not default), keep as 'same'
      # to use format_default which respects the separator
      actual_input_format = parser.detected_format || 'csv'
      output_format = @options[:output_format] || 'same'

      # If separator is explicitly set, use default format (not format-specific)
      # Otherwise, convert 'same' to the actual input format
      if output_format == 'same' && !@options[:output_separator]
        output_format = actual_input_format
      end

      # Formatter needs output format and options
      formatter_options = {
        format: output_format,
        separator: @options[:output_separator] || ' , ',
        show_header: !@options[:no_header],
        table_mode: @options[:table_mode] || (output_format == 'table' || output_format == 'tbl')
      }

      formatter = Formatter.new(formatter_options)
      output = formatter.format(data, selected_indices)

      puts output
    end

    def count_columns(input_data)
      # Determine input format
      input_format = @options[:input_format] || 'auto'

      # Parser only needs input/parsing options
      parser_options = {
        format: input_format,
        delimiter: @options[:delimiter]
      }.compact

      parser = Parser.new(**parser_options)
      data = parser.parse(input_data)

      return if data.empty?

      headers = data.first
      puts "Headers: #{headers.join(', ')}" unless @options[:quiet]
      puts "Total columns: #{headers.length}"

      data[1..].each_with_index do |row, index|
        puts "Row #{index + 1}: #{row.length} columns" unless @options[:quiet]
      end
    end
  end
end
