# frozen_string_literal: true

require 'csv'
require 'stringio'

module EasyCols
  class Parser
    SUPPORTED_FORMATS = %w[csv tsv table tbl plain auto].freeze

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
    end

    def parse(input)
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

      # Parse and convert to array format
      csv_data = CSV.parse(input, **options)
      [csv_data.headers] + csv_data.map(&:fields)
    end

    def parse_tsv(input)
      options = { headers: true, col_sep: "\t" }
      options[:col_sep] = @options[:delimiter] if @options[:delimiter]

      # Parse and convert to array format
      csv_data = CSV.parse(input, **options)
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
        next if line.strip.empty? && @options[:blanklines]

        if header_line.nil? && !line.strip.empty?
          header_line = line
          data_start = index + 1  # Default to starting after header
          next
        end

        if separator_line.nil? && header_line && line.match?(/^[-_|+]+$/)
          separator_line = line
          data_start = index + 1
          break
        end
      end

      # Parse header
      headers = parse_table_line(header_line) if header_line

      # Parse data rows
      data_rows = []
      lines[data_start..].each do |line|
        next if line.strip.empty? && @options[:blanklines]
        next if line.match?(/^[-_|+]+$/) && @options[:lines]

        data_rows << parse_table_line(line)
      end

      # Convert to CSV-like structure
      [headers] + data_rows
    end

    def parse_plain(input)
      lines = input.lines.map(&:chomp)
      delimiter = @options[:delimiter] || /\s+/

      lines.map do |line|
        next if line.strip.empty? && @options[:blanklines]
        line.split(delimiter)
      end.compact
    end

    def parse_table_line(line)
      # Split by " | " pattern for table format
      line.split(/\s*\|\s*/).map(&:strip)
    end
  end
end
