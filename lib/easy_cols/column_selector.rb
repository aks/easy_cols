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
                 when Integer
                   select_by_index(selector)
                 when Range
                   select_by_range(selector)
                 when Array
                   if selector.first == :name_range && selector.size == 3
                     select_by_name_range(selector[1], selector[2])
                   else
                     select_by_array(selector)
                   end
                 when String
                   select_by_name(selector)
                 else
                   raise SelectionError, "Invalid selector type: #{selector.class}"
                 end
        indices.concat(result)
      end

      indices.uniq.sort
    end

    private

    def select_by_index(index)
      resolved = index < 0 ? @headers.length + index : index
      if resolved >= 0 && resolved < @headers.length
        [resolved]
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

    def select_by_name_range(from_name, to_name)
      from_idx = @headers.find_index(from_name)
      to_idx   = @headers.find_index(to_name)

      missing = []
      missing << from_name unless from_idx
      missing << to_name   unless to_idx

      unless missing.empty?
        raise SelectionError,
              "Column name range :#{from_name}-:#{to_name} not found. Missing: #{missing.join(', ')}. Available: #{@headers.join(', ')}"
      end

      if from_idx <= to_idx
        (from_idx..to_idx).to_a
      else
        (to_idx..from_idx).to_a
      end
    end
  end
end

