# frozen_string_literal: true

require 'stringio'

# Helper methods to capture or suppress stderr/stdout
module OutputHelpers
  def suppress_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
  ensure
    $stderr = original_stderr
  end

  def suppress_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original_stdout
  end

  def suppress_output
    original_stderr = $stderr
    original_stdout = $stdout
    $stderr = StringIO.new
    $stdout = StringIO.new
    yield
  ensure
    $stderr = original_stderr
    $stdout = original_stdout
  end

  def capture_stderr
    original_stderr = $stderr
    captured = StringIO.new
    $stderr = captured
    yield
    captured.string
  ensure
    $stderr = original_stderr
  end

  def capture_stdout
    original_stdout = $stdout
    captured = StringIO.new
    $stdout = captured
    yield
    captured.string
  ensure
    $stdout = original_stdout
  end
end

