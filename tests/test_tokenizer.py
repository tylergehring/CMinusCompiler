#!/usr/bin/env python3
"""Regression tests for the CMinus assignment 1 tokenizer.

Run from the repository root with:
    python3 tests/test_tokenizer.py

The tests intentionally run each case in a separate process so malformed input
cannot shift the line numbers or hide failures in later cases.
"""

from __future__ import annotations

import re
import tarfile
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "CMinusCompiler"
EXECUTABLE = PROJECT / "c-"


class TestFailure(Exception):
    pass


def build() -> None:
    result = subprocess.run(
        ["make", "-C", str(PROJECT)],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise TestFailure(
            "build failed\nstdout:\n{}\nstderr:\n{}".format(
                result.stdout, result.stderr
            )
        )


def run_case(name: str, source: str) -> str:
    result = subprocess.run(
        [str(EXECUTABLE)],
        cwd=ROOT,
        input=source,
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise TestFailure(
            f"{name}: executable returned {result.returncode}\n{result.stderr}"
        )
    return result.stdout


def run_executable(executable: Path, source: str) -> str:
    result = subprocess.run(
        [str(executable)],
        cwd=executable.parent,
        input=source,
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise TestFailure(
            f"{executable}: executable returned {result.returncode}\n{result.stderr}"
        )
    return result.stdout


def require(name: str, condition: bool, detail: str) -> None:
    if not condition:
        raise TestFailure(f"{name}: {detail}")


def token_lines(output: str) -> list[str]:
    return [line for line in output.splitlines() if line.startswith("Line ")]


def assert_token_sequence(name: str, output: str, expected: list[str]) -> None:
    actual = token_lines(output)
    require(
        name,
        actual == expected,
        "token sequence differs\nexpected:\n{}\nactual:\n{}".format(
            "\n".join(expected), "\n".join(actual)
        ),
    )


def test_keywords_and_identifiers() -> None:
    name = "keywords and identifiers"
    source = (
        "int bool char static if then else while do for to by return break "
        "and or not true false\n"
        "intx Int INT truefalse falsehood A a0 z999 _bad\n"
    )
    output = run_case(name, source)
    expected = [
        "Line 1 Token: INT",
        "Line 1 Token: BOOL",
        "Line 1 Token: CHAR",
        "Line 1 Token: STATIC",
        "Line 1 Token: IF",
        "Line 1 Token: THEN",
        "Line 1 Token: ELSE",
        "Line 1 Token: WHILE",
        "Line 1 Token: DO",
        "Line 1 Token: FOR",
        "Line 1 Token: TO",
        "Line 1 Token: BY",
        "Line 1 Token: RETURN",
        "Line 1 Token: BREAK",
        "Line 1 Token: AND",
        "Line 1 Token: OR",
        "Line 1 Token: NOT",
        "Line 1 Token: BOOLCONST Value: 1 Input: true",
        "Line 1 Token: BOOLCONST Value: 0 Input: false",
        "Line 2 Token: ID Value: intx",
        "Line 2 Token: ID Value: Int",
        "Line 2 Token: ID Value: INT",
        "Line 2 Token: ID Value: truefalse",
        "Line 2 Token: ID Value: falsehood",
        "Line 2 Token: ID Value: A",
        "Line 2 Token: ID Value: a0",
        "Line 2 Token: ID Value: z999",
        "Line 2 Token: ID Value: bad",
    ]
    assert_token_sequence(name, output, expected)
    require(name, output.count("ERROR(") == 1, "underscore should be rejected once")


def test_numbers() -> None:
    name = "numbers"
    output = run_case(name, "0 7 007 0000089 700 999999999999999999\n")
    expected = [
        "Line 1 Token: NUMCONST Value: 0 Input: 0",
        "Line 1 Token: NUMCONST Value: 7 Input: 7",
        "Line 1 Token: NUMCONST Value: 7 Input: 007",
        "Line 1 Token: NUMCONST Value: 89 Input: 0000089",
        "Line 1 Token: NUMCONST Value: 700 Input: 700",
        "Line 1 Token: NUMCONST Value: 999999999999999999 Input: 999999999999999999",
    ]
    assert_token_sequence(name, output, expected)
    require(name, "ERROR(" not in output, "valid integers produced an error")


def test_characters() -> None:
    name = "character constants"
    source = r"'a' ' ' '" + '"' + r"' '\'' '\\' '\n' '\t' '\0' '\x' '\@'" + "\n"
    output = run_case(name, source)
    expected_values = ["'a'", "' '", "'\"'", "'\''", "'\\'", "'", "'", "'", "'x'", "'@'"]
    require(name, output.count("Token: CHARCONST") == len(expected_values), "wrong CHARCONST count")
    require(name, "Input: '\\n'" in output, "newline escape was not preserved in input")
    require(name, "Input: '\\t'" in output, "tab escape was not preserved in input")
    require(name, "Input: '\\0'" in output, "null escape was not preserved in input")
    require(name, "ERROR(" not in output, "valid character escape produced an error")


def test_strings() -> None:
    name = "string constants"
    source = (
        '"" "x" "dogs cats" "\\\'" "\\\\" "\\n" "\\t" "\\0" '
        '"\\x" "dogs\\\'cats" "dogs\\\"cats"\n'
    )
    output = run_case(name, source)
    require(name, output.count("Token: STRINGCONST") == 11, "wrong STRINGCONST count")
    require(name, 'Value: "" Len: 0 Input: ""' in output, "empty string failed")
    require(name, 'Value: "x" Len: 1 Input: "x"' in output, "plain string failed")
    require(name, 'Value: "dogs cats" Len: 9' in output, "space failed")
    require(name, 'Value: "x" Len: 1 Input: "\\x"' in output, "unknown escape failed")
    require(name, 'Input: "\\n"' in output, "newline escape input failed")
    require(name, 'Input: "\\t"' in output, "tab escape input failed")
    require(name, "ERROR(" not in output, "valid string produced an error")


def test_operators_and_punctuation() -> None:
    name = "operators and punctuation"
    source = (
        "<= >= == != += -= *= /= ++ -- << >> "
        "+ - * / % < > = ? ; , ( ) [ ] { } :\n"
    )
    output = run_case(name, source)
    expected = [
        "Line 1 Token: LEQ",
        "Line 1 Token: GEQ",
        "Line 1 Token: EQ",
        "Line 1 Token: NEQ",
        "Line 1 Token: ADDASS",
        "Line 1 Token: SUBASS",
        "Line 1 Token: MULASS",
        "Line 1 Token: DIVASS",
        "Line 1 Token: INC",
        "Line 1 Token: DEC",
        "Line 1 Token: MIN",
        "Line 1 Token: MAX",
        "Line 1 Token: +",
        "Line 1 Token: -",
        "Line 1 Token: *",
        "Line 1 Token: /",
        "Line 1 Token: %",
        "Line 1 Token: <",
        "Line 1 Token: >",
        "Line 1 Token: =",
        "Line 1 Token: ?",
        "Line 1 Token: ;",
        "Line 1 Token: ,",
        "Line 1 Token: (",
        "Line 1 Token: )",
        "Line 1 Token: [",
        "Line 1 Token: ]",
        "Line 1 Token: {",
        "Line 1 Token: }",
        "Line 1 Token: :",
    ]
    assert_token_sequence(name, output, expected)


def test_logical_operator_spellings() -> None:
    name = "logical operator spellings"
    output = run_case(name, "and or not && ||\n")
    assert_token_sequence(
        name,
        output,
        [
            "Line 1 Token: AND",
            "Line 1 Token: OR",
            "Line 1 Token: NOT",
            "Line 1 Token: AND",
            "Line 1 Token: OR",
        ],
    )


def test_whitespace_and_comments() -> None:
    name = "whitespace and comments"
    source = "\t  int\r\n// ignored int 123 @\n  x // ignored\n +\n"
    output = run_case(name, source)
    expected = [
        "Line 1 Token: INT",
        "Line 3 Token: ID Value: x",
        "Line 4 Token: +",
    ]
    assert_token_sequence(name, output, expected)
    require(name, "ignored" not in output, "comment text leaked into output")
    require(name, "ERROR(" not in output, "whitespace/comment case produced an error")


def test_invalid_characters() -> None:
    name = "invalid characters"
    output = run_case(name, "# ^ & _ @ ~ . | !\n")
    for character in ["#", "^", "&", "_", "@", "~", ".", "|", "!"]:
        require(
            name,
            f"input character: '{character}'" in output,
            f"missing diagnostic for {character!r}",
        )
    require(name, not token_lines(output), "invalid characters returned tokens")


def test_malformed_characters() -> None:
    name = "malformed character constants"
    cases = {
        "empty": ("''\n", 0, []),
        "two characters": ("'ab'\n", 2, ["ID Value: ab"]),
        "three characters": ("'abc'\n", 2, ["ID Value: abc"]),
        "dangling escape": ("'" + "\\" + "\n", 2, []),
    }
    for case, (source, error_count, expected_tokens) in cases.items():
        output = run_case(f"{name} / {case}", source)
        invalid_count = output.count("Invalid or misplaced input character")
        require(
            f"{name} / {case}",
            invalid_count == error_count,
            f"expected {error_count} invalid-character diagnostics, got:\n{output}",
        )
        for expected_token in expected_tokens:
            require(
                f"{name} / {case}",
                expected_token in output,
                f"missing recovery token {expected_token!r}",
            )
    require(
        "empty character diagnostic",
        "ERROR(1): Empty character ''. Characters ignored." in run_case("empty character diagnostic", "''\n"),
        "empty character constant did not use the expected diagnostic",
    )


def test_string_line_boundaries() -> None:
    name = "string line boundaries"
    source = '"unterminated\nnext"\n"closed"\n'
    output = run_case(name, source)
    require(name, output.count("Token: STRINGCONST") == 2, "newline-spanning string was rejected")
    require(name, 'Line 1 Token: STRINGCONST Value: "unterminated\nnext" Len: 17 Input: "unterminated\nnext"' in output, "multiline string was decoded incorrectly")
    require(name, 'Line 2 Token: STRINGCONST Value: "closed" Len: 6 Input: "closed"' in output, "line count should not advance for newlines embedded in a multi-line string")
    require(name, "ERROR(" not in output, "valid multiline string produced an error")


def test_grammar_sample_tokens() -> None:
    name = "grammar sample"
    source = """char bark[10]:\"corgis\";
bool fate:true;
int x:42, y:666;
int ant(int bat, cat[]; bool dog, elk; int fox; char gnu)
{
  gnu = 'W';
  if dog and elk or bat > cat[3] then dog = not dog;
  else fox++;
  while dog do break;
  for i = 1 to 1000 by 17 do break;
  return (fox+bat*cat[bat])/-fox;
}
main() { return; }
"""
    output = run_case(name, source)
    require(name, "ERROR(" not in output, "valid grammar sample produced an error")
    for expected in [
        "Token: CHAR",
        "Token: STRINGCONST Value: \"corgis\"",
        "Token: BOOLCONST Value: 1 Input: true",
        "Token: ID Value: ant",
        "Token: AND",
        "Token: OR",
        "Token: NOT",
        "Token: INC",
        "Token: TO",
        "Token: BY",
        "Token: RETURN",
    ]:
        require(name, expected in output, f"missing {expected}")


def test_submission_archive() -> None:
    name = "submission archive"
    archive = ROOT / "assignment1.tar"
    require(name, archive.exists(), "assignment1.tar is missing")

    expected_members = {"parser.l", "parser.y", "parser.scantype.h", "makefile"}
    with tarfile.open(archive) as tar:
        members = {member.name for member in tar.getmembers()}
        require(name, members == expected_members, f"unexpected archive members: {members}")
        archived_scanner = tar.extractfile("parser.l")
        require(name, archived_scanner is not None, "parser.l is missing from archive")
        assert archived_scanner is not None
        archived_bytes = archived_scanner.read()

    require(
        name,
        archived_bytes == (PROJECT / "parser.l").read_bytes(),
        "archive parser.l differs from workspace parser.l; rebuild the tar",
    )

    with tempfile.TemporaryDirectory(prefix="cminus-assignment1-") as directory:
        extracted = Path(directory)
        with tarfile.open(archive) as tar:
            tar.extractall(extracted)
        result = subprocess.run(
            ["make", "-C", str(extracted)],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        require(name, result.returncode == 0, f"archive build failed:\n{result.stderr}")
        output = run_executable(extracted / "c-", '"unterminated\nnext"\n"closed"\n')
        require(name, output.count("Token: STRINGCONST") == 2, "archive rejects multiline strings")
        require(name, "ERROR(" not in output, "archive rejects valid multiline strings")
        require(name, "Empty character" not in output, "archive contains obsolete empty-character rule")


def main() -> int:
    tests = [
        test_keywords_and_identifiers,
        test_numbers,
        test_characters,
        test_strings,
        test_operators_and_punctuation,
        test_logical_operator_spellings,
        test_whitespace_and_comments,
        test_invalid_characters,
        test_malformed_characters,
        test_string_line_boundaries,
        test_grammar_sample_tokens,
        test_submission_archive,
    ]
    try:
        build()
        for test in tests:
            test()
            print(f"PASS {test.__name__}")
    except (TestFailure, OSError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"All {len(tests)} tokenizer test groups passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
