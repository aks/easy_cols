# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyCols::CLI, '#parse_column_selectors' do
  let(:cli) { EasyCols::CLI.new }

  describe '#parse_column_selectors' do
    it 'parses single integer' do
      result = cli.send(:parse_column_selectors, ['0'])
      expect(result).to eq([0])
    end

    it 'parses range' do
      result = cli.send(:parse_column_selectors, ['0-2'])
      expect(result).to eq([[0, 1, 2]])
    end

    it 'parses comma-separated indices' do
      result = cli.send(:parse_column_selectors, ['0,2,5'])
      expect(result).to eq([[0, 2, 5]])
    end

    it 'parses header name with :NAME syntax' do
      result = cli.send(:parse_column_selectors, [':Name'])
      expect(result).to eq(['Name'])
    end

    it 'parses header name range with :NAME1-:NAME2 syntax' do
      result = cli.send(:parse_column_selectors, [':Name-:City'])
      expect(result).to eq([[:name_range, 'Name', 'City']])
    end

    it 'parses relative-from-end selector _1' do
      result = cli.send(:parse_column_selectors, ['_1'])
      expect(result).to eq([-1])
    end

    it 'parses relative-from-end selector _3' do
      result = cli.send(:parse_column_selectors, ['_3'])
      expect(result).to eq([-3])
    end

    it 'does not treat _0 as a relative selector' do
      # _0 is not valid; numeric_selector? must reject it so it falls
      # through as a file argument, not a silent alias for column 0
      cli_instance = EasyCols::CLI.new
      expect(cli_instance.send(:numeric_selector?, '_0')).to be false
    end

  end
end

