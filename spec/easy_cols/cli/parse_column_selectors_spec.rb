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

    it 'parses header name' do
      result = cli.send(:parse_column_selectors, ['Name'])
      expect(result).to eq(['Name'])
    end

    it 'handles multiple selectors' do
      result = cli.send(:parse_column_selectors, ['0', '1-2', 'Name'])
      expect(result).to eq([0, [1, 2], 'Name'])
    end
  end
end

