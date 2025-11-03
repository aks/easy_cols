# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyCols::Formatter do
  let(:data) { [['Name', 'Age'], ['John', '25'], ['Jane', '30']] }
  let(:indices) { [0, 1] }

  describe '#format' do
    it 'formats with default separator' do
      formatter = EasyCols::Formatter.new
      result = formatter.format(data, indices)

      expect(result).to include('Name , Age')
      expect(result).to include('John , 25')
    end

    it 'formats without header' do
      formatter = EasyCols::Formatter.new(show_header: false)
      result = formatter.format(data, indices)

      expect(result).not_to include('Name , Age')
      expect(result).to include('John , 25')
    end

    it 'formats in table mode' do
      formatter = EasyCols::Formatter.new(table_mode: true)
      result = formatter.format(data, indices)

      expect(result).to include('Name | Age')
      expect(result).to include('-+-')  # Separator line uses -+- at intersections
    end

    it 'handles empty data' do
      formatter = EasyCols::Formatter.new
      expect(formatter.format([], indices)).to eq('')
    end

    it 'handles empty indices' do
      formatter = EasyCols::Formatter.new
      expect(formatter.format(data, [])).to eq('')
    end

    it 'uses custom separator' do
      formatter = EasyCols::Formatter.new(separator: ';')
      result = formatter.format(data, indices)

      expect(result).to include('Name;Age')
      expect(result).to include('John;25')
    end

    it 'respects separator even in table mode when provided' do
      formatter = EasyCols::Formatter.new(table_mode: true, separator: '::')
      result = formatter.format(data, indices)

      expect(result).to include('Name::Age')
      expect(result).to include('-+-')  # Separator line uses -+- at intersections
    end

    it 'calculates separator width from all rows' do
      wide_data = [['Name', 'Age'], ['John', '25'], ['VeryLongName', '30']]
      formatter = EasyCols::Formatter.new(table_mode: true)
      result = formatter.format(wide_data, indices)

      # Separator should match longest column (12 for "VeryLongName")
      expect(result).to include('-' * 12)
    end

    context 'with output format options' do
      it 'formats as CSV' do
        formatter = EasyCols::Formatter.new(format: 'csv')
        result = formatter.format(data, indices)

        expect(result).to include("Name,Age\n")
        expect(result).to include("John,25\n")
        expect(result).to include("Jane,30")
      end

      it 'formats as TSV' do
        formatter = EasyCols::Formatter.new(format: 'tsv')
        result = formatter.format(data, indices)

        expect(result).to include("Name\tAge\n")
        expect(result).to include("John\t25\n")
        expect(result).to include("Jane\t30")
      end

      it 'formats as table format' do
        formatter = EasyCols::Formatter.new(format: 'table')
        result = formatter.format(data, indices)

        expect(result).to include('Name | Age')
        expect(result).to include('-+-')  # Separator line uses -+- at intersections
        expect(result).to include('John | 25')
      end

      it 'formats as plain (whitespace-separated)' do
        formatter = EasyCols::Formatter.new(format: 'plain')
        result = formatter.format(data, indices)

        expect(result).to include("Name")
        expect(result).to include("Age")
        expect(result).to include("John")
        expect(result).to include("25")
        expect(result).to include("Jane")
        expect(result).to include("30")
        # Plain format now aligns columns with padding
        expect(result).to match(/Name\s+Age/)
        expect(result).to match(/John\s+25/)
      end

      it 'formats as same (default format) when format is same' do
        formatter = EasyCols::Formatter.new(format: 'same')
        result = formatter.format(data, indices)

        expect(result).to include('Name , Age')
        expect(result).to include('John , 25')
      end

      it 'formats without header when show_header is false' do
        formatter = EasyCols::Formatter.new(format: 'csv', show_header: false)
        result = formatter.format(data, indices)

        expect(result).not_to include('Name')
        expect(result).to include("John,25\n")
        expect(result).to include("Jane,30")
      end
    end
  end
end

