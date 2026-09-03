# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'open3'

RSpec.describe 'CLI Integration Tests' do
  describe 'end-to-end CLI execution' do
    let(:csv_data) { "Name,Age,City\nJohn,25,NYC\nJane,30,LA" }
    let(:csv_file) { Tempfile.new(['test', '.csv']) }

    before do
      csv_file.write(csv_data)
      csv_file.close
    end

    after do
      csv_file.unlink
    end

    it 'processes CSV files correctly' do
      output, status = Open3.capture2('bundle', 'exec', 'bin/easy_cols', csv_file.path, '0', '1')

      expect(status.exitstatus).to eq(0)
      expect(output).to include('Name')
      expect(output).to include('Age')
      expect(output).to include('John')
      expect(output).to include('25')
    end

    it 'handles pipe input correctly' do
      output, status = Open3.capture2(
        "echo '#{csv_data}' | bundle exec bin/easy_cols - 0 1"
      )

      expect(status.exitstatus).to eq(0)
      expect(output).to include('Name')
      expect(output).to include('Age')
    end

    it 'handles column name selection with :NAME syntax' do
      output, status = Open3.capture2(
        'bundle', 'exec', 'bin/easy_cols', csv_file.path, ':Name', ':City'
      )

      expect(status.exitstatus).to eq(0)
      expect(output).to include('Name')
      expect(output).to include('City')
      expect(output).to include('John')
      expect(output).to include('NYC')
    end

    it 'handles table format output' do
      output, status = Open3.capture2(
        'bundle', 'exec', 'bin/easy_cols', '--table', csv_file.path, '0', '1'
      )

      expect(status.exitstatus).to eq(0)
      expect(output).to include('|')
      expect(output).to include('Name')
      expect(output).to include('Age')
    end

    it 'handles count mode' do
      output, status = Open3.capture2(
        'bundle', 'exec', 'bin/easy_cols', '--count', csv_file.path
      )

      expect(status.exitstatus).to eq(0)
      expect(output).to include('Total columns: 3')
      expect(output).to include('Row')
    end

    it 'preserves inline comments without affecting table alignment' do
      data_with_comments = <<~DATA
        ## header comment
        Name:Age:City
        John:25:NYC
        # middle comment
        Jane:30:LA
      DATA

      tmp = Tempfile.new(['inline_comments', '.txt'])
      tmp.write(data_with_comments)
      tmp.close

      begin
        output, status = Open3.capture2(
          'bundle', 'exec', 'bin/easy_cols', '--plain', '--out=table', '-d:', tmp.path
        )

        expect(status.exitstatus).to eq(0)

        lines = output.lines.map(&:chomp)

        # First line should be the leading comment
        expect(lines[0]).to eq('## header comment')

        # Next comes the table header and separator
        expect(lines[1]).to match(/Name\s*\|\s*Age\s*\|\s*City/)
        expect(lines[2]).to match(/^-+\+-+\+-+/)

        # Then the first data row
        expect(lines[3]).to match(/John\s*\|\s*25\s*\|\s*NYC/)

        # Inline comment should appear next
        expect(lines[4]).to eq('# middle comment')

        # And the final data row should still be column-aligned
        expect(lines[5]).to match(/Jane\s*\|\s*30\s*\|\s*LA/)
      ensure
        tmp.unlink
      end
    end
  end
end

