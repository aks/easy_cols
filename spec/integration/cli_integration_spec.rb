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

    it 'handles column name selection' do
      output, status = Open3.capture2(
        'bundle', 'exec', 'bin/easy_cols', csv_file.path, 'Name', 'City'
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
  end
end

