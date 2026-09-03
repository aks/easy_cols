# frozen_string_literal: true

require 'csv'
require 'stringio'

module EasyCols
  class Parser
    SUPPORTED_FORMATS = %w[csv tsv table tbl plain auto].freeze

    attr_reader :leading_comments, :inline_comments

    def initialize(**options)
      @options = {
        format:     'auto',
        delimiter:  nil,
        pattern:    nil,
        quotes:     true,
        headers:    1,
        lines:      true,
        blanklines: true,
        comments:   nil,
        start:      nil,
        stop:       nil,
      }.merge(options)

      @leading_comments = []
      @inline_comments = []
      @seen_first_non_comment = false
    end

    def parse(input)
      # Reset per-parse state
      @leading_comments = []
      @inline_comments = []
      @seen_first_non_comment = false

      format = detect_format(input) if @options[:format] == 'auto' || @options[:format].nil?
      format ||= @options[:format] || 'csv'

      # Store the actual format used for reference
      @detected_format = format

      case format
      when 'csv'          then parse_csv(input)
      when 'tsv'          then parse_tsv(input)
      when 'table', 'tbl' then parse_table(input)
      when 'plain'        then parse_plain(input)
      else
        raise FormatError, "Unsupported format: #{format}"
      end
    end

    def detected_format
      @detected_format
    end

    def detect_format(input)
      return 'csv' if input.strip.empty?

      first_line = input.lines.first&.strip || ''

      # Check for table format (has pipe separators and separator line)
      if first_line.include?('|') && input.match?(/^[-_|+]+$/m)
        return 'table'
      end

      # Check for TSV (tabs in first line)
      if first_line.include?("\t")
        return 'tsv'
      end

      # Check for CSV (commas)
      if first_line.include?(',')
        return 'csv'
      end

      # Default to plain if no clear indicators
      'plain'
    end

    private

    def parse_csv(input)
      options = { headers: true }
      options[:col_sep] = @options[:delimiter] if @options[:delimiter]

      filtered_input = filter_comment_lines(input)

      # Parse and convert to array format
      csv_data = CSV.parse(filtered_input, **options)
      [csv_data.headers] + csv_data.map(&:fields)
    end

    def parse_tsv(input)
      options = { headers: true, col_sep: "\t" }
      options[:col_sep] = @options[:delimiter] if @options[:delimiter]

      filtered_input = filter_comment_lines(input)

      # Parse and convert to array format
      csv_data = CSV.parse(filtered_input, **options)
      [csv_data.headers] + csv_data.map(&:fields)
    end

    def parse_table(input)
      # Table format: header line, separator line, data lines
      lines = input.lines.map(&:chomp)

      # Find header and separator lines
      header_line = nil
      separator_line = nil
      data_start = 0

      lines.each_with_index do |line, index|
        stripped = line.strip
        next if stripped.empty? && @options[:blanklines]
        next if comment_line?(line)

        if header_line.nil? && !stripped.empty?
          header_line = line
          data_start = index + 1  # Default to starting after header
          next
        end

        if separator_line.nil? && header_line && stripped.match?(/^[-_|+]+$/)
          separator_line = line
          data_start = index + 1
          break
        end
      end

      # Parse header
      headers = parse_table_line(header_line) if header_line

      # Parse data rows
      data_rows = []
      lines[data_start..]&.each do |line|
        stripped = line.strip
        next if stripped.empty? && @options[:blanklines]
        next if stripped.match?(/^[-_|+]+$/) && @options[:lines]
        next if comment_line?(line)

        @seen_first_non_comment = true unless @seen_first_non_comment
        data_rows << parse_table_line(line)
      end

      # Convert to CSV-like structure
      [headers] + data_rows
    end

    def parse_plain(input)
      lines = input.lines.map(&:chomp)
      delimiter = @options[:delimiter] || /\s+/

      rows = []
      row_index = 0 # index into rows (0 = header row)

      lines.each do |line|
        stripped = line.strip
        next if stripped.empty? && @options[:blanklines]

        if comment_line?(line)
          # After we've seen the first non-comment row, treat further
          # comments as inline and remember their position relative to
          # the structured rows (by row index in the parsed data).
          @inline_comments << [row_index, line.chomp] if @seen_first_non_comment
          next
        end

        @seen_first_non_comment = true unless @seen_first_non_comment
        rows << line.split(delimiter)
        row_index += 1
      end

      rows
    end

    def parse_table_line(line)
      # Split by " | " pattern for table format
      line.split(/\s*\|\s*/).map(&:strip)
    end

    def filter_comment_lines(input)
      filtered_lines = []

      input.lines.each do |line|
        if comment_line?(line)
          next
        else
          @seen_first_non_comment = true unless @seen_first_non_comment
          filtered_lines << line
        end
      end

      filtered_lines.join
    end

    def comment_line?(line)
      return false unless line

      raw = line.to_s.chomp
      content = raw.lstrip

      # Explicit comments pattern, if provided (future CLI options)
      pattern = @options[:comments]
      is_comment =
        if pattern.is_a?(Regexp)
          content.match?(pattern)
        elsif pattern.is_a?(String)
          content.match?(Regexp.new(pattern))
        else
          # Default heuristic: treat lines starting with '#' (including shebang '#!') as comments
          content.start_with?('#')
        end

      if is_comment && !@seen_first_non_comment
        @leading_comments << raw
      end

      is_comment
    end
  end
end
