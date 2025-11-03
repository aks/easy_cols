# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'stringio'

RSpec.describe EasyCols::CLI, '#run' do
  let(:cli) { EasyCols::CLI.new }
  let(:csv_data) { "Name,Age,City\nJohn,25,NYC\nJane,30,LA" }
  let(:csv_file) { Tempfile.new(['test', '.csv']) }

  before do
    csv_file.write(csv_data)
    csv_file.close
  end

  after do
    csv_file.unlink
  end

  describe 'file input' do
    it 'processes file with column indices' do
      expect { cli.run([csv_file.path, '0', '1']) }.to output(/John.*25/).to_stdout
    end

    it 'handles column range selector' do
      expect { cli.run([csv_file.path, '0-1']) }.to output(/Name.*Age/).to_stdout
    end

    it 'handles column name selector' do
      expect { cli.run([csv_file.path, 'Name', 'City']) }.to output(/John.*NYC/).to_stdout
    end

    it 'handles comma-separated column selectors' do
      expect { cli.run([csv_file.path, '0,2']) }.to output(/Name.*City/).to_stdout
    end

    it 'defaults to all columns when no selectors provided' do
      output = capture_stdout do
        cli.run([csv_file.path])
      end
      expect(output).to include('Name')
      expect(output).to include('Age')
      expect(output).to include('City')
      expect(output).to include('John')
      expect(output).to include('25')
      expect(output).to include('NYC')
    end
  end

  describe 'stdin input (pipe filter)' do
    it 'handles stdin input with -' do
      allow($stdin).to receive(:read).and_return(csv_data)
      expect { cli.run(['-', '0', '1']) }.to output(/John.*25/).to_stdout
    end

    it 'defaults to all columns when using stdin with no selectors' do
      output = capture_stdout do
        allow($stdin).to receive(:read).and_return(csv_data)
        cli.run(['-'])
      end
      expect(output).to include('Name')
      expect(output).to include('Age')
      expect(output).to include('City')
      expect(output).to include('John')
      expect(output).to include('25')
      expect(output).to include('NYC')
    end

    it 'produces identical output when used as pipe filter vs direct file input' do
      # Test with file input
      file_output = capture_stdout do
        cli.run([csv_file.path, '0', '1'])
      end

      # Test with stdin (pipe filter) - using '-' explicitly
      stdin_output = capture_stdout do
        allow($stdin).to receive(:read).and_return(csv_data)
        cli.run(['-', '0', '1'])
      end

      # Both should produce identical output
      expect(stdin_output).to eq(file_output)
    end

    it 'produces identical output when used as pipe filter (no file arg) vs direct file input' do
      # Test with file input
      file_output = capture_stdout do
        cli.run([csv_file.path, 'Name', 'City'])
      end

      # Test with stdin (pipe filter) - simulate when no file path is provided
      cli2 = EasyCols::CLI.new
      stdin_output = capture_stdout do
        allow($stdin).to receive(:read).and_return(csv_data)
        cli2.instance_variable_set(:@file_path, nil)
        cli2.instance_variable_set(:@column_selectors, ['Name', 'City'])
        cli2.send(:process_input)
      end

      # Both should produce identical output
      expect(stdin_output).to eq(file_output)
    end

    it 'works as a pipe filter with multiple column selectors' do
      file_output = capture_stdout do
        cli.run([csv_file.path, '0', '1', '2'])
      end

      stdin_output = capture_stdout do
        allow($stdin).to receive(:read).and_return(csv_data)
        cli.run(['-', '0', '1', '2'])
      end

      expect(stdin_output).to eq(file_output)
    end

    it 'works as a pipe filter with options and column selectors' do
      file_output = capture_stdout do
        cli.run(['--format', 'csv', csv_file.path, 'Name', 'City'])
      end

      stdin_output = capture_stdout do
        allow($stdin).to receive(:read).and_return(csv_data)
        cli.run(['--format', 'csv', '-', 'Name', 'City'])
      end

      expect(stdin_output).to eq(file_output)
    end
  end

  describe 'format options' do
    it 'handles --format option (legacy)' do
      tsv_data = "Name\tAge\tCity\nJohn\t25\tNYC"
      tsv_file = Tempfile.new(['test', '.tsv'])
      tsv_file.write(tsv_data)
      tsv_file.close

      expect { cli.run(['--format', 'tsv', tsv_file.path, '0', '1']) }.to output(/John.*25/).to_stdout
      tsv_file.unlink
    end

    it 'handles --in option for input format' do
      tsv_data = "Name\tAge\tCity\nJohn\t25\tNYC"
      tsv_file = Tempfile.new(['test', '.tsv'])
      tsv_file.write(tsv_data)
      tsv_file.close

      expect { cli.run(['--in=tsv', tsv_file.path, '0', '1']) }.to output(/John.*25/).to_stdout
      tsv_file.unlink
    end

    it 'auto-detects input format when --in=auto (default)' do
      tsv_data = "Name\tAge\tCity\nJohn\t25\tNYC"
      tsv_file = Tempfile.new(['test', '.tsv'])
      tsv_file.write(tsv_data)
      tsv_file.close

      expect { cli.run([tsv_file.path, '0', '1']) }.to output(/John.*25/).to_stdout
      tsv_file.unlink
    end

    it 'handles --table option (legacy)' do
      table_data = "Name | Age\n----|----\nJohn | 25"
      table_file = Tempfile.new(['test', '.txt'])
      table_file.write(table_data)
      table_file.close

      expect { cli.run(['--table', table_file.path, '0', '1']) }.to output(/John.*\|.*25/).to_stdout
      table_file.unlink
    end

    it 'handles --delimiter for input parsing' do
      pipe_data = "Name|Age|City\nJohn|25|NYC"
      pipe_file = Tempfile.new(['test', '.txt'])
      pipe_file.write(pipe_data)
      pipe_file.close

      expect { cli.run(['-f', 'csv', '-d', '|', pipe_file.path, '0', '1']) }.to output(/John.*25/).to_stdout
      pipe_file.unlink
    end
  end

  describe 'output format options' do
    it 'converts CSV to table format' do
      output = capture_stdout do
        cli.run(['--out=table', csv_file.path, '0', '1'])
      end

      expect(output).to include('Name | Age')
      expect(output).to include('-+-')  # Separator line uses -+- at intersections
      expect(output).to include('John | 25')
    end

    it 'converts CSV to TSV format' do
      output = capture_stdout do
        cli.run(['--out=tsv', csv_file.path, '0', '1'])
      end

      expect(output).to include("Name\tAge\n")
      expect(output).to include("John\t25\n")
    end

    it 'converts CSV to plain format' do
      output = capture_stdout do
        cli.run(['--out=plain', csv_file.path, '0', '1'])
      end

      expect(output).to include("Name")
      expect(output).to include("Age")
      expect(output).to include("John")
      expect(output).to include("25")
      # Plain format now aligns columns with padding
      expect(output).to match(/John\s+25/)
    end

    it 'converts table to CSV format' do
      table_data = "Name | Age | City\n-----|-----|----\nJohn | 25  | NYC"
      table_file = Tempfile.new(['test', '.txt'])
      table_file.write(table_data)
      table_file.close

      output = capture_stdout do
        cli.run(['--in=table', '--out=csv', table_file.path, '0', '1'])
      end

      expect(output).to include("Name,Age\n")
      expect(output).to include("John,25\n")
      table_file.unlink
    end

    it 'uses same format as input when --out=same (default)' do
      tsv_data = "Name\tAge\tCity\nJohn\t25\tNYC"
      tsv_file = Tempfile.new(['test', '.tsv'])
      tsv_file.write(tsv_data)
      tsv_file.close

      output = capture_stdout do
        cli.run(['--in=tsv', tsv_file.path, '0', '1'])
      end

      expect(output).to include("Name\tAge\n")
      expect(output).to include("John\t25\n")
      tsv_file.unlink
    end

    it 'converts with auto-detected input format' do
      tsv_data = "Name\tAge\tCity\nJohn\t25\tNYC"
      tsv_file = Tempfile.new(['test', '.tsv'])
      tsv_file.write(tsv_data)
      tsv_file.close

      output = capture_stdout do
        cli.run(['--out=table', tsv_file.path, '0', '1'])
      end

      expect(output).to include('Name | Age')
      expect(output).to include('John | 25')
      tsv_file.unlink
    end
  end

  describe 'output formatting options' do
    it 'handles --output-delimiter option' do
      expect { cli.run(['-D', ';', csv_file.path, '0', '1']) }.to output(/Name;Age/).to_stdout
    end

    it 'handles --no-header option' do
      output = StringIO.new
      allow($stdout).to receive(:puts) { |arg| output.puts(arg) }
      cli.run(['-H', csv_file.path, '0', '1'])
      result = output.string
      expect(result).to include('John')
      expect(result).not_to include('Name')
    end

    it 'handles --pipe option' do
      expect { cli.run(['--pipe', csv_file.path, '0', '1']) }.to output(/Name.*\|.*Age/).to_stdout
    end

    it 'handles --tab option' do
      expect { cli.run(['--tab', csv_file.path, '0', '1']) }.to output(/\t/).to_stdout
    end

    it 'handles --comma option' do
      expect { cli.run(['--comma', csv_file.path, '0', '1']) }.to output(/Name,Age/).to_stdout
    end
  end

  describe 'count mode' do
    it 'handles --count mode' do
      expect { cli.run(['-c', csv_file.path]) }.to output(/Total columns: 3/).to_stdout
    end

    it 'handles --count with --quiet' do
      output = StringIO.new
      allow($stdout).to receive(:puts) { |arg| output.puts(arg) }
      cli.run(['-c', '-q', csv_file.path])
      result = output.string
      expect(result).to include('Total columns: 3')
      expect(result).not_to include('Headers:')
    end
  end

  describe 'error handling' do
    it 'exits with error on invalid file' do
      suppress_output do
        expect { cli.run(['nonexistent.csv', '0']) }.to raise_error(SystemExit)
      end
    end

    it 'exits with error on invalid column selector' do
      suppress_output do
        expect { cli.run([csv_file.path, 'InvalidColumn']) }.to raise_error(SystemExit)
      end
    end
  end
end

