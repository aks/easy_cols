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
            - Relative from end: _1 (last), _2 (second-to-last), etc.
            - Column range: 0-5, 2-10, etc.
            - Comma-separated indices: 0,2,5
            - Header name: :Name, :Email, etc. (colon-prefixed)
            - Header name range: :Name-:City

          Examples:
            #{$PROG} data.csv 0 1 2                  # Show columns 0, 1, 2
            #{$PROG} data.csv _1                     # Show last column
            #{$PROG} data.csv :Name :Email           # Show Name and Email columns
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

      # After option parsing, `argv` contains only non-option arguments.
      # We classify them into:
      #   - selectors: numeric indices/ranges/lists, or name selectors
      #                using the :NAME / :NAME1-:NAME2 syntax
      #   - at most one file argument, or '-' for stdin
      args = argv.dup

      selectors  = []
      file_arg   = nil
      stdin_file = false

      args.each do |arg|
        case
        when arg == '-'
          raise SelectionError, 'Only one input file may be specified' if stdin_file || file_arg
          stdin_file = true

        when numeric_selector?(arg)
          selectors << arg

        when name_selector?(arg)
          selectors << arg

        else
          # Anything that is not a selector or '-' is treated as a file
          # argument. This removes ambiguity around bare names: if you
          # want a named column, use :name / :name-:status explicitly.
          if file_arg
            raise SelectionError,
                  "Only one input file may be specified (got #{file_arg.inspect} and #{arg.inspect})"
          end
          file_arg = arg
        end
      end

      @file_path =
        if stdin_file
          '-'
        else
          file_arg # may be nil => read from stdin
        end

      @column_selectors = selectors.empty? ? [] : parse_column_selectors(selectors)
    end

    def parse_column_selectors(selectors)
      selectors.map do |selector|
        case selector
        when /^_([1-9]\d*)$/     # Relative from end: _1 => last, _2 => 2nd-to-last
          -Regexp.last_match(1).to_i
        when /^\d+$/            # Single integer index
          selector.to_i
        when /^\d+-\d+$/        # Numeric range
          start_idx, end_idx = selector.split('-').map(&:to_i)
          (start_idx..end_idx).to_a
        when /,/                # Comma-separated numeric indices
          selector.split(',').map(&:strip).map(&:to_i)
        when /^:([^:]+)-:([^:]+)$/ # Name range :NAME1-:NAME2
          [:name_range, Regexp.last_match(1), Regexp.last_match(2)]
        when /^:([^:]+)$/         # Single name :NAME
          Regexp.last_match(1)    # bare name; ColumnSelector resolves it
        else                      # Fallback / legacy header name
          selector
        end
      end
    end

    # Helpers for classifying non-option arguments
    def numeric_selector?(token)
      return false unless token.is_a?(String)

      return true if token.match?(/^\d+$/)     # single integer
      return true if token.match?(/^\d+-\d+$/) # range
      return true if token.match?(/^_[1-9]\d*$/) # relative from end (_1, _2, …)

      if token.include?(',')
        parts = token.split(',').map(&:strip)
        return parts.all? { |p| p.match?(/^\d+$/) }
      end

      false
    end

    def name_selector?(token)
      return false unless token.is_a?(String)

      token.match?(/^:[^:]+$/) || token.match?(/^:[^:]+-:[^:]+$/)
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

      # Insert inline comments (for plain-style inputs) without affecting
      # column widths/alignment. Comments are not part of the parsed table
      # data and therefore never influence column counts.
      if parser.respond_to?(:inline_comments) &&
         parser.inline_comments.any? &&
         formatter_options[:show_header]

        # We only support structured reinsertion for line-oriented formats
        # (plain/default and ASCII table). CSV/TSV keep current behavior.
        unless %w[csv tsv].include?(output_format)
          lines = output.split("\n")
          offset = 0

          parser.inline_comments.each do |before_row_index, comment_text|
            # before_row_index is indexed into the parsed `data` rows,
            # where 0 is the header row, 1 is the first data row, etc.
            insert_at = nil

            if output_format == 'plain'
              # Mapping for plain output with header shown:
              #   data row 0 (header) => lines[0]
              #   data row i (>=1)    => lines[i]
              insert_at = before_row_index
            elsif output_format == 'table' || output_format == 'tbl' || formatter_options[:table_mode]
              # Mapping for table output with header and separator:
              #   header row (0)      => lines[0]
              #   separator line      => lines[1]
              #   data row i (>=1)    => lines[i + 1]
              next if before_row_index <= 0 # treated as leading already
              insert_at = before_row_index + 1
            else
              # Other text formats fall back to inserting based on row index
              insert_at = before_row_index
            end

            next unless insert_at

            idx = [[insert_at + offset, 0].max, lines.length].min
            lines.insert(idx, comment_text)
            offset += 1
          end

          output = lines.join("\n")
        end
      end

      # Prepend any leading comment lines preserved by the parser
      if parser.respond_to?(:leading_comments) && parser.leading_comments.any?
        comment_block = parser.leading_comments.join("\n")
        output = if output.nil? || output.empty?
                   comment_block
                 else
                   [comment_block, output].join("\n")
                 end
      end

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
