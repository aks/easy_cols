# TODO

## Future Enhancements

### Streaming Pipeline Support
Implement a pure streaming pipeline to handle arbitrarily large files without loading the entire input into memory. This would enable processing files of any size by:

- Reading input line-by-line instead of loading everything into memory
- Detecting headers and separator lines incrementally (especially for table format)
- Outputting rows incrementally as they're processed
- Handling column selection with header-based selectors in a streaming context

This would trade some parsing flexibility (look-ahead/backtrack) for memory efficiency, which could be valuable for very large inputs.

