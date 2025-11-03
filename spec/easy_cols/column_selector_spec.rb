# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyCols::ColumnSelector do
  let(:headers) { ['Name', 'Age', 'City', 'Country'] }
  let(:selector) { EasyCols::ColumnSelector.new(headers) }

  describe '#select' do
    it 'selects by index' do
      result = selector.select([0, 2])
      expect(result).to eq([0, 2])
    end

    it 'selects by name' do
      result = selector.select(['Name', 'City'])
      expect(result).to eq([0, 2])
    end

    it 'selects by range' do
      result = selector.select([(0..2)])
      expect(result).to eq([0, 1, 2])
    end

    it 'raises error for invalid index' do
      expect { selector.select([10]) }.to raise_error(EasyCols::SelectionError)
    end

    it 'raises error for invalid name' do
      expect { selector.select(['Invalid']) }.to raise_error(EasyCols::SelectionError)
    end

    it 'selects by array' do
      result = selector.select([[0, 1, 2]])
      expect(result).to eq([0, 1, 2])
    end

    it 'warns for out-of-range indices in range' do
      expect { selector.select([(0..10)]) }.to output(/Warning: Column index/).to_stderr
      suppress_stderr do
        result = selector.select([(0..10)])
        expect(result).to eq([0, 1, 2, 3])
      end
    end

    it 'warns for out-of-range indices in array' do
      expect { selector.select([[0, 5, 10]]) }.to output(/Warning: Column index/).to_stderr
      suppress_stderr do
        result = selector.select([[0, 5, 10]])
        expect(result).to eq([0])
      end
    end

    it 'handles multiple selector types together' do
      suppress_stderr do
        result = selector.select([0, (1..2), 'Country', [3]])
        expect(result).to eq([0, 1, 2, 3])
      end
    end

    it 'deduplicates and sorts results' do
      result = selector.select([2, 0, 2, 0, 1])
      expect(result).to eq([0, 1, 2])
    end

    it 'raises error for invalid selector type' do
      expect { selector.select([:symbol]) }.to raise_error(EasyCols::SelectionError, /Invalid selector type/)
    end
  end
end

