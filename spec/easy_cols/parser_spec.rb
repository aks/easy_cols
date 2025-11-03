# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyCols::Parser do
  let(:csv_data) { "Name,Age,City\nJohn,25,NYC\nJane,30,LA" }
  let(:tsv_data) { "Name\tAge\tCity\nJohn\t25\tNYC\nJane\t30\tLA" }
  let(:table_data) { "Name | Age | City\n-----|-----|----\nJohn | 25  | NYC\nJane | 30  | LA" }

  describe '#parse' do
    context 'with CSV format' do
      it 'parses CSV data correctly' do
        parser = EasyCols::Parser.new(format: 'csv')
        result = parser.parse(csv_data)

        expect(result.length).to eq(3) # header + 2 data rows
        expect(result.first).to eq(['Name', 'Age', 'City'])
        expect(result[1]).to eq(['John', '25', 'NYC'])
        expect(result[2]).to eq(['Jane', '30', 'LA'])
      end
    end

    context 'with TSV format' do
      it 'parses TSV data correctly' do
        parser = EasyCols::Parser.new(format: 'tsv')
        result = parser.parse(tsv_data)

        expect(result.length).to eq(3)
        expect(result.first).to eq(['Name', 'Age', 'City'])
      end
    end

    context 'with table format' do
      it 'parses table data correctly' do
        parser = EasyCols::Parser.new(format: 'table')
        result = parser.parse(table_data)

        expect(result.length).to eq(3) # header + 2 data rows
        expect(result.first).to eq(['Name', 'Age', 'City'])
      end

      it 'parses with tbl alias' do
        parser = EasyCols::Parser.new(format: 'tbl')
        result = parser.parse(table_data)

        expect(result.length).to eq(3)
        expect(result.first).to eq(['Name', 'Age', 'City'])
      end

      it 'handles table without separator line' do
        table_no_sep = "Name | Age\nJohn | 25"
        parser = EasyCols::Parser.new(format: 'table')
        result = parser.parse(table_no_sep)

        expect(result.first).to eq(['Name', 'Age'])
        expect(result[1]).to eq(['John', '25'])
      end
    end

    context 'with plain format' do
      it 'parses whitespace-delimited data' do
        plain_data = "Name Age City\nJohn 25 NYC\nJane 30 LA"
        parser = EasyCols::Parser.new(format: 'plain')
        result = parser.parse(plain_data)

        expect(result.length).to eq(3)
        expect(result.first).to eq(['Name', 'Age', 'City'])
      end

      it 'handles custom delimiter for plain format' do
        plain_data = "Name:Age:City\nJohn:25:NYC"
        parser = EasyCols::Parser.new(format: 'plain', delimiter: ':')
        result = parser.parse(plain_data)

        expect(result.first).to eq(['Name', 'Age', 'City'])
      end
    end

    context 'with custom delimiter' do
      it 'uses custom delimiter for CSV' do
        pipe_csv = "Name|Age|City\nJohn|25|NYC"
        parser = EasyCols::Parser.new(format: 'csv', delimiter: '|')
        result = parser.parse(pipe_csv)

        expect(result.first).to eq(['Name', 'Age', 'City'])
      end

      it 'overrides default delimiter for TSV' do
        semicolon_data = "Name;Age;City\nJohn;25;NYC"
        parser = EasyCols::Parser.new(format: 'tsv', delimiter: ';')
        result = parser.parse(semicolon_data)

        expect(result.first).to eq(['Name', 'Age', 'City'])
      end
    end

    context 'with auto-detection' do
      it 'auto-detects CSV format' do
        parser = EasyCols::Parser.new(format: 'auto')
        result = parser.parse(csv_data)

        expect(result.length).to eq(3)
        expect(result.first).to eq(['Name', 'Age', 'City'])
        expect(parser.detected_format).to eq('csv')
      end

      it 'auto-detects TSV format' do
        parser = EasyCols::Parser.new(format: 'auto')
        result = parser.parse(tsv_data)

        expect(result.length).to eq(3)
        expect(result.first).to eq(['Name', 'Age', 'City'])
        expect(parser.detected_format).to eq('tsv')
      end

      it 'auto-detects table format' do
        parser = EasyCols::Parser.new(format: 'auto')
        result = parser.parse(table_data)

        expect(result.length).to eq(3)
        expect(result.first).to eq(['Name', 'Age', 'City'])
        expect(parser.detected_format).to eq('table')
      end

      it 'defaults to plain format when format is unclear' do
        plain_data = "Name Age City\nJohn 25 NYC"
        parser = EasyCols::Parser.new(format: 'auto')
        result = parser.parse(plain_data)

        expect(result.length).to eq(2)
        expect(parser.detected_format).to eq('plain')
      end

      it 'defaults to csv for empty input' do
        parser = EasyCols::Parser.new(format: 'auto')
        result = parser.parse('')

        expect(parser.detected_format).to eq('csv')
      end
    end

    context 'with unsupported format' do
      it 'raises FormatError' do
        parser = EasyCols::Parser.new(format: 'invalid')
        expect { parser.parse('data') }.to raise_error(EasyCols::FormatError, /Unsupported format/)
      end
    end
  end
end

