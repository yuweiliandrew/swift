// REQUIRES: swift_in_compiler

// RUN: %empty-directory(%t)
// RUN: %target-swift-ide-test -enable-experimental-string-processing -batch-code-completion -source-filename %s -filecheck %raw-FileCheck -completion-output-dir %t

func testLiteral() {
    re'foo'.#^RE_LITERAL_MEMBER^#
// RE_LITERAL_MEMBER: Begin completions
// RE_LITERAL_MEMBER-DAG: Keyword[self]/CurrNominal:          self[#Regex<Substring>#];
// RE_LITERAL_MEMBER: End completions
}

