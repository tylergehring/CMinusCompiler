# Tokenizer Test Suite

Run the complete assignment 1 tokenizer regression suite from the repository root:

```sh
python3 tests/test_tokenizer.py
```

The runner builds `CMinusCompiler/c-` first and executes isolated stdin cases for:

- all CMinus keywords and boolean constants
- identifier boundaries and invalid underscores
- decimal integer constants, leading zeroes, and large values
- plain and escaped character constants, including `\\n`, `\\t`, and `\\0`
- empty, escaped, and arbitrary escaped string constants
- every multi-character and single-character operator in `grammarC-.md`
- punctuation used by declarations, calls, arrays, blocks, and statements
- whitespace, line tracking, and `//` comments
- invalid characters and malformed character constants
- unterminated strings and recovery at line boundaries
- a complete token stream based on the grammar's example CMinus program

Malformed-input cases are isolated so one greedy lexer recovery cannot shift the
line numbers or hide a later failure. The tests check scanner diagnostics separately
from parser end-of-input diagnostics.
