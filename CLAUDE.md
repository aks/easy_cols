# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/easy_cols/parser_spec.rb

# Run a specific example by line number
bundle exec rspec spec/easy_cols/parser_spec.rb:42

# Lint
bundle exec rubocop

# Build the gem
bundle exec rake build

# Version management
rake version:current
rake version:patch   # or :minor / :major
rake release         # tags and pushes — CI publishes to RubyGems
```

## Architecture

The pipeline is: **CLI → Parser → ColumnSelector → Formatter → stdout**

`lib/easy_cols.rb` is the entry point; it loads the four classes and defines the error hierarchy (`Error`, `ParseError`, `FormatError`, `SelectionError`).

**`CLI`** (`lib/easy_cols/cli.rb`) — parses argv with `OptionParser`, classifies remaining tokens as file path vs. column selectors, then drives the pipeline. Column selector tokens from argv are pre-processed into integers, ranges, or name strings before being handed to `ColumnSelector`.

**`Parser`** (`lib/easy_cols/parser.rb`) — converts raw text into `Array<Array<String>>` where row 0 is always the headers. Supports `csv`, `tsv`, `table`/`tbl`, `plain`, and `auto` (auto-detects from first line). Collects leading comment lines and inline comment lines separately so the CLI can reinsert them into output without affecting column alignment.

**`ColumnSelector`** (`lib/easy_cols/column_selector.rb`) — resolves the mixed selector list (integers, arrays of integers, bare name strings, or `[:name_range, from, to]` triples) against the parsed headers and returns a sorted, deduplicated list of column indices.

**`Formatter`** (`lib/easy_cols/formatter.rb`) — takes `data` (the full parsed rows) and `selected_indices` and produces a string. Supports `csv`, `tsv`, `table`/`tbl`, `plain`, and `same` (uses the separator option directly). Table and plain formats right-pad cells to uniform column widths.

### Column selector syntax (argv)

| Token form | Meaning |
|---|---|
| `0`, `2` | Single index (0-based) |
| `0-5` | Index range |
| `0,2,5` | Comma-separated indices |
| `_1`, `_2` | Relative from end (`_1` = last, `_2` = second-to-last) |
| `:Name` | Header name |
| `:Name-:City` | Header name range |

### Binaries

`bin/easy_cols` and `bin/ec` (alias) both invoke `EasyCols::CLI.new.run(ARGV)`.
