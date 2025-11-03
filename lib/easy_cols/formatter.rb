# frozen_string_literal: true

require 'csv'

module EasyCols
  class Formatter
    SUPPORTED_OUTPUT_FORMATS = %w[csv tsv table tbl plain same].freeze

    def initialize(options = {})
      @options = {
        format: 'same',
        separator: ' , ',
        show_header: true,
        table_mode: false
      }.merge(options)

      # Use pipe separator in table mode if separator wasn't explicitly provided
      if (@options[:table_mode] || @options[:format] == 'table' || @options[:format] == 'tbl') && !options.key?(:separator)
        @options[:separator] = ' | '
      end
    end

    def format(data, selected_indices)
      return '' if data.empty? || selected_indices.empty?

      output_format = @options[:format]

      case output_format
      when 'csv' then format_csv(data, selected_indices)
      when 'tsv' then format_tsv(data, selected_indices)
      when 'table', 'tbl' then format_table(data, selected_indices)
      when 'plain' then format_plain(data, selected_indices)
      when 'same', nil then format_default(data, selected_indices)
      else
        raise FormatError, "Unsupported output format: #{output_format}"
      end
    end

    private

    def format_default(data, selected_indices)
      output = []

      # Add header if requested
      if @options[:show_header] && data.first
        header_row = selected_indices.map { |i| data.first[i] }
        output << header_row.join(@options[:separator])

        # Add separator line in table mode
        if @options[:table_mode]
          separator_line = calculate_separator_line(data, selected_indices)
          output << separator_line if separator_line
        end
      end

      # Add data rows (always skip header row since it's row 0)
      data[1..].each do |row|
        selected_row = selected_indices.map { |i| row[i] }
        output << selected_row.join(@options[:separator])
      end

      output.join("\n")
    end

    def format_csv(data, selected_indices)
      output = []

      if @options[:show_header] && data.first
        header_row = selected_indices.map { |i| data.first[i] }
        output << CSV.generate_line(header_row)
      end

      data[1..].each do |row|
        selected_row = selected_indices.map { |i| row[i] }
        output << CSV.generate_line(selected_row)
      end

      output.join
    end

    def format_tsv(data, selected_indices)
      output = []

      if @options[:show_header] && data.first
        header_row = selected_indices.map { |i| data.first[i] }
        output << header_row.join("\t")
      end

      data[1..].each do |row|
        selected_row = selected_indices.map { |i| row[i] }
        output << selected_row.join("\t")
      end

      output.join("\n")
    end

    def format_table(data, selected_indices)
      output = []
      column_widths = calculate_column_widths(data, selected_indices)

      if @options[:show_header] && data.first
        header_row = selected_indices.map.with_index do |col_idx, i|
          format_cell(data.first[col_idx], column_widths[i])
        end
        output << header_row.join(' | ')
        # Separator line uses "-+-" at intersections and "-" for horizontal lines
        separator_line = column_widths.map { |w| '-' * w }.join('-+-')
        output << separator_line
      end

      # Filter out empty rows (from trailing newlines in CSV)
      data_rows = data[1..].reject { |row| row.nil? || row.all?(&:nil?) || row.all?(&:empty?) }

      data_rows.each do |row|
        selected_row = selected_indices.map.with_index do |col_idx, i|
          format_cell(row[col_idx], column_widths[i])
        end
        output << selected_row.join(' | ')
      end

      output.join("\n")
    end

    def format_plain(data, selected_indices)
      output = []
      column_widths = calculate_column_widths(data, selected_indices)

      if @options[:show_header] && data.first
        header_row = selected_indices.map.with_index do |col_idx, i|
          format_cell(data.first[col_idx], column_widths[i])
        end
        output << header_row.join(' ')
      end

      # Filter out empty rows (from trailing newlines in CSV)
      data_rows = data[1..].reject { |row| row.nil? || row.all?(&:nil?) || row.all?(&:empty?) }

      data_rows.each do |row|
        selected_row = selected_indices.map.with_index do |col_idx, i|
          format_cell(row[col_idx], column_widths[i])
        end
        output << selected_row.join(' ')
      end

      output.join("\n")
    end

    def calculate_column_widths(data, selected_indices)
      selected_indices.map do |col_idx|
        data.map { |row| (row[col_idx] || '').length }.max
      end
    end

    def format_cell(value, width)
      (value || '').ljust(width)
    end

    def calculate_separator_line(data, selected_indices)
      column_widths = calculate_column_widths(data, selected_indices)
      # Use -+- at intersections for proper ASCII table formatting
      column_widths.map { |width| '-' * width }.join('-+-')
    end
  end
end
