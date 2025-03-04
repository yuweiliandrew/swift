// RUN: %target-typecheck-verify-swift -requirement-machine-inferred-signatures=on
// RUN: %target-swift-frontend -typecheck -debug-generic-signatures %s -requirement-machine-inferred-signatures=on 2>&1 | %FileCheck %s

protocol P1 {
  associatedtype A : P2
}

protocol P2 {
  associatedtype A
}

// CHECK: Generic signature: <T, U where T : P2, T == U.[P2]A.[P1]A, U == T.[P2]A.[P1]A, T.[P2]A : P1, U.[P2]A : P1>
func testTU<T : P2, U : P2>(_: T, _: U) where T.A : P1, T.A.A == U, U.A : P1, U.A.A == T {}
// expected-warning@-1 {{redundant conformance constraint 'U' : 'P2'}}

// CHECK: Generic signature: <T, U where T == U.[P2]A.[P1]A, U : P2, U == T.[P2]A.[P1]A, T.[P2]A : P1, U.[P2]A : P1>
func testU<T, U : P2>(_: T, _: U) where T.A : P1, T.A.A == U, U.A : P1, U.A.A == T {}

// CHECK: Generic signature: <T, U where T : P2, T == U.[P2]A.[P1]A, U == T.[P2]A.[P1]A, T.[P2]A : P1, U.[P2]A : P1>
func testT<T : P2, U>(_: T, _: U) where T.A : P1, T.A.A == U, U.A : P1, U.A.A == T {}
