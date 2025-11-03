# EasyCols

[![Build Status](https://github.com/aks/easy_cols/workflows/CI/badge.svg)](https://github.com/aks/easy_cols/actions)
[![Gem Version](https://badge.fury.io/rb/easy_cols.svg)](https://badge.fury.io/rb/easy_cols)
[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.2.0-blue.svg)](https://www.ruby-lang.org/)

A powerful command-line tool for extracting and processing columns from structured text data in various formats.

## Features

- **Multiple Input Formats**: CSV, TSV, table, and plain text with auto-detection
- **Flexible Column Selection**: By index, range, or header name
- **Format Conversion**: Convert between CSV, TSV, table, and plain formats
- **Sophisticated Parsing**: Quote handling, comment stripping, header processing
- **Multiple Output Formats**: CSV, TSV, table, plain, or customizable separators
- **STDIN Support**: Process data from pipes and streams
- **Language-Specific Comment Patterns**: Ruby, C, Go, Python, and more

## Installation

### As a Gem

```bash
gem install easy_cols
```

After installation, the `easy_cols` and `ec` commands will be available.

### From Source

```bash
git clone https://github.com/aks/easy_cols.git
cd easy_cols
bundle install
rake install
```

## Usage

### Basic Column Selection

```bash
# If no column selectors are provided, all columns are output by default
ec data.csv

# Select columns by index
ec data.csv 0 1 2

# Select columns by name
ec data.csv 'Name' 'Email'

# Select column ranges
ec data.csv 0-5

# Mix different selector types
ec data.csv 0,2,'Name','Email'
```

### Input and Output Formats

```bash
# Auto-detect input format (default)
ec data.csv 0 1 2

# Explicit input format
ec --in=csv data.csv 0 1 2
ec --in=tsv data.tsv 0 1 2
ec --in=table data.txt 0 1 2
ec --in=plain data.txt 0 1 2

# Format conversion (CSV to table)
ec --in=csv --out=table data.csv 0 1 2

# Format conversion (table to CSV)
ec --in=table --out=csv data.txt 0 1 2

# Auto-detect input, convert to table
ec --out=table data.csv 0 1 2

# Legacy format option (still supported)
ec --format tsv data.tsv 0 1 2
```

### Output Formatting Options

```bash
# Output as table format (with column widths and separator lines)
ec --out=table data.csv 0 1 2

# Output as CSV
ec --out=csv data.csv 0 1 2

# Output as TSV
ec --out=tsv data.csv 0 1 2

# Output as plain (whitespace-separated, aligned columns)
ec --out=plain data.csv 0 1 2

# Legacy separator options (still supported)
ec --tab data.csv 0 1 2
ec --comma data.csv 0 1 2
ec --output-delimiter ' | ' data.csv 0 1 2
```

### Advanced Options

```bash
# No header output
ec --no-header data.csv 0 1 2

# Count columns instead of selecting
ec --count data.csv

# Read from STDIN
cat data.csv | ec - 0 1 2

# Verbose output
ec --verbose data.csv 0 1 2
```

## Examples

### CSV Processing

```bash
$ cat data.csv
Name,Age,City,Country
John,25,NYC,USA
Jane,30,LA,USA
Bob,35,London,UK

$ ec data.csv 0 1
Name , Age
John , 25
Jane , 30
Bob , 35

$ ec --table data.csv 0 1
Name | Age
-----+----
John | 25
Jane | 30
Bob  | 35
```

### TSV Processing

```bash
$ ec --in=tsv data.tsv 'Name' 'City'
Name , City
John , NYC
Jane , LA
Bob  , London
```

### Format Conversion

```bash
# Convert CSV to table format
$ ec --out=table data.csv 0 1
Name | Age
-----+----
John | 25
Jane | 30
Bob  | 35

# Convert table to CSV
$ cat table.txt
Name | Age | City
-----+-----+-----
John | 25  | NYC
Jane | 30  | LA

$ ec --in=table --out=csv table.txt 0 2
Name,City
John,NYC
Jane,LA

# Auto-detect input format, convert to TSV
$ ec --out=tsv data.csv 0 1
Name	Age
John	25
Jane	30
```

## Development

### Setup

```bash
git clone https://github.com/aks/easy_cols.git
cd easy_cols
bundle install
```

### Running Tests

```bash
bundle exec rspec
```

### Building the Gem

```bash
bundle exec rake build
```

### Version Management and Releases

This project uses [Semantic Versioning](https://semver.org/) and includes Rake tasks for version bumping and releases.

#### Version Bumping

Use the Rake tasks to bump the version:

```bash
# Show current version
rake version:current

# Bump patch version (0.0.x)
rake version:patch

# Bump minor version (0.x.0)
rake version:minor

# Bump major version (x.0.0)
rake version:major
```

These tasks update `lib/easy_cols/version.rb`. After bumping, commit the change:

```bash
git add lib/easy_cols/version.rb
git commit -m "Bump version to X.Y.Z"
git push
```

#### Creating a Release

After bumping the version and merging to main:

1. **Ensure you're on main branch**:
   ```bash
   git checkout main
   git pull
   ```

2. **Verify everything is committed and synced**:
   The `rake release` task will check this for you.

3. **Create the release**:
   ```bash
   rake release
   ```

This will:
- Verify you're on the main branch
- Check for uncommitted changes
- Verify the tag doesn't already exist
- Ensure you're synced with remote
- Create an annotated git tag (`vX.Y.Z`)
- Push the tag to origin

4. **CI automatically handles**:
   - Running all tests
   - Creating a GitHub Release (with `.tar.gz` and `.zip` source archives)
   - Publishing the gem to RubyGems

**Note**: You'll need to set the `RUBYGEMS_API_KEY` secret in your GitHub repository settings for automatic publishing to work.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Roadmap

- [ ] Language-specific comment pattern support
- [ ] Advanced filtering options (start/stop patterns)
- [ ] Quote handling improvements
- [ ] Performance optimizations for large files
- [ ] Additional output formats (JSON, XML)
- [ ] Configuration file support

## Acknowledgments

- Inspired by Unix text processing tools
- Built with Ruby's excellent CSV library
- Thanks to the Ruby community for inspiration and tools