# frozen_string_literal: true

module EasyCols
  class ColumnSelector
    def initialize(headers)
      @headers = headers
    end

    def select(selectors)
      indices = []

      selectors.each do |selector|
        result = case selector
                 when Integer then select_by_index(selector)
                 when Range   then select_by_range(selector)
                 when Array   then select_by_array(selector)
                 when String  then select_by_name(selector)
                 else
                   raise SelectionError, "Invalid selector type: #{selector.class}"
                 end
        indices.concat(result)
      end

      indices.uniq.sort
    end

    private

    def select_by_index(index)
      if index >= 0 && index < @headers.length
        [index]
      else
        raise SelectionError, "Column index #{index} is out of range (0-#{@headers.length - 1})"
      end
    end

    def select_by_range(range)
      range.to_a.select { |idx| in_range?(idx) }
    end

    def select_by_array(array)
      array.select { |idx| in_range?(idx) }
    end

    def in_range?(index)
      in_range = index >= 0 && index < @headers.length
      warn "Warning: Column index #{index} is out of range (0-#{@headers.length - 1})" unless in_range
      in_range
    end

    def select_by_name(name)
      header_idx = @headers.find_index(name)
      if header_idx
        [header_idx]
      else
        raise SelectionError, "Column '#{name}' not found. Available: #{@headers.join(', ')}"
      end
    end
  end
end

