# frozen_string_literal: true

require_relative 'easy_cols/version'
require_relative 'easy_cols/parser'
require_relative 'easy_cols/formatter'
require_relative 'easy_cols/column_selector'
require_relative 'easy_cols/cli'

module EasyCols
  class Error < StandardError; end
  class ParseError < Error; end
  class FormatError < Error; end
  class SelectionError < Error; end
end

