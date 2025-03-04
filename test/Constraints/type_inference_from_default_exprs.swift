// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend-emit-module -emit-module-path %t/InferViaDefaults.swiftmodule -enable-experimental-type-inference-from-defaults -module-name InferViaDefaults %S/Inputs/type_inference_via_defaults_other_module.swift
// RUN: %target-swift-frontend -enable-experimental-type-inference-from-defaults -module-name main -typecheck -verify -I %t %s %S/Inputs/type_inference_via_defaults_other_module.swift

func testInferFromResult<T>(_: T = 42) -> T { fatalError() } // Ok

enum ETest<T> {
  case test(_: T = 42) // expected-note {{default value declared here}}
}

func testInferFromOtherPos1<T>(_: T = 42, _: [T]) {}
// expected-error@-1 {{cannot use default expression for inference of 'T' because it is inferrable from parameters #0, #1}}

func testInferFromOtherPos2<T>(_: T = 42, _: T = 0.0) {}
// expected-error@-1 2 {{cannot use default expression for inference of 'T' because it is inferrable from parameters #0, #1}}

protocol P {
  associatedtype X
}

func testInferFromSameType<T, U: P>(_: T = 42, _: [U]) where T == U.X {}
// expected-error@-1 {{cannot use default expression for inference of 'T' because requirement 'T == U.X' refers to other generic parameters}}

func test1<T>(_: T = 42) {} // Ok

struct S : P {
  typealias X = Int
}

func test2<T: P>(_: T = S()) {} // Ok

struct A : P {
  typealias X = Double
}

class B : P {
  typealias X = String

  init() {}
}

func test2<T: P & AnyObject>(_: T = B()) {} // Ok

func test2NonClassDefault<T: P & AnyObject>(_: T = S()) {}
// expected-error@-1 {{global function 'test2NonClassDefault' requires that 'S' be a class type}}
// expected-note@-2 {{where 'T' = 'S'}}

func test2NonConformingDefault<T: P>(_: T = 42.0) {}
// expected-error@-1 {{global function 'test2NonConformingDefault' requires that 'Double' conform to 'P'}}
// expected-note@-2 {{where 'T' = 'Double'}}

func testMultiple<T, U>(a: T = 42.0, b: U = "") {} // Ok

// Subscripts

extension S {
  subscript<T: P>(a: T = S()) -> Int {
    get { return 42 }
  }

  subscript<T: P, U: AnyObject>(a: T = S(), b: U = B()) -> Int {
    get { return 42 }
  }
}

// In nested positions
func testNested1<T>(_: [T] = [0, 1.0]) {} // Ok (T == Double)
func testNested2<T>(_: T? = 42.0) {} // Ok
func testNested2NoInference<T>(_: T? = nil) {} // Ok (old semantics)
// expected-note@-1 {{in call to function 'testNested2NoInference'}}

struct D : P {
  typealias X = B
}

func testNested3<T: P>(_: T = B()) where T.X == String {}
func testNested4<T: P>(_: T = B()) where T.X == Int {}
// expected-error@-1 {{global function 'testNested4' requires the types 'B.X' (aka 'String') and 'Int' be equivalent}}
// expected-note@-2 {{where 'T.X' = 'B.X' (aka 'String')}}

func testNested5<T: P>(_: [T]? = [D()]) where T.X: P, T.X: AnyObject {}

func testNested5Invalid<T: P>(_: [T]? = [B()]) where T.X: P, T.X: AnyObject {}
// expected-error@-1 {{global function 'testNested5Invalid' requires that 'B.X' (aka 'String') conform to 'P'}}
// expected-error@-2 {{global function 'testNested5Invalid' requires that 'B.X' (aka 'String') be a class type}}
// expected-note@-3 2 {{where 'T.X' = 'B.X' (aka 'String')}}
// expected-note@-4 {{in call to function 'testNested5Invalid'}}

func testNested6<T: P, U>(_: (a: [T?], b: U) = (a: [D()], b: B())) where T.X == U, T.X: P, U: AnyObject { // Ok
}

// Generic requirements

class GenClass<T> {}

func testReq1<T, U>(_: T = B(), _: U) where T: GenClass<U> {}
// expected-error@-1 {{cannot use default expression for inference of 'T' because requirement 'T : GenClass<U>' refers to other generic parameters}}

class E : GenClass<B> {
}

func testReq2<T, U>(_: (T, U) = (E(), B())) where T: GenClass<U>, U: AnyObject {} // Ok

func testReq3<T: P, U>(_: [T?] = [B()], _: U) where T.X == U {}
// expected-error@-1 {{cannot use default expression for inference of '[T?]' because requirement 'U == T.X' refers to other generic parameters}}

protocol Shape {
}

struct Circle : Shape {
}

struct Rectangle : Shape {
}

struct Figure<S: Shape> {
  init(_: S = Circle()) {} // expected-note 2 {{default value declared here}}
}

func main() {
  _ = testInferFromResult() // Ok T == Int
  let _: Float = testInferFromResult() // expected-error {{cannot convert value of type 'Int' to specified type 'Float'}}

  _ = ETest.test() // Ok

  let _: ETest<String> = .test() // expected-error {{cannot convert default value of type 'String' to expected argument type 'Int' for parameter #0}}

  test1() // Ok

  test2() // Ok
  test2(A()) // Ok as well

  testMultiple()                // Ok (T = Double, U = String)
  testMultiple(a: 0)            // Ok (T = Int, U = String)
  testMultiple(b: S())          // Ok (T = Double, U = S)
  testMultiple(a: 0.0, b: "a")  // Ok

  // From a different module
  with_defaults() // Ok
  with_defaults("") // Ok

  _ = S()[] // Ok
  _ = S()[B()] // Ok

  testNested1() // Ok
  testNested2() // Ok
  testNested2NoInference() // expected-error {{generic parameter 'T' could not be inferred}}

  testNested3() // Ok
  testNested5() // Ok
  testNested5Invalid() // expected-error {{generic parameter 'T' could not be inferred}}
  testNested6() // Ok

  testReq2() // Ok

  func takesFigure<T>(_: Figure<T>) {}
  func takesCircle(_: Figure<Circle>) {}
  func takesRectangle(_: Figure<Rectangle>) {}

  _ = Figure.init() // Ok S == Circle
  let _: Figure<Circle> = .init() // Ok (S == Circle)
  let _: Figure<Rectangle> = .init()
  // expected-error@-1 {{cannot convert default value of type 'Rectangle' to expected argument type 'Circle' for parameter #0}}

  takesFigure(.init()) // Ok
  takesCircle(.init()) // Ok
  takesRectangle(.init())
  // expected-error@-1 {{cannot convert default value of type 'Rectangle' to expected argument type 'Circle' for parameter #0}}
}

func test_magic_defaults() {
  func with_magic(_: Int = #function) {} // expected-error {{default argument value of type 'String' cannot be converted to type 'Int'}}
  func generic_with_magic<T>(_: T = #line) -> T {} // expected-error {{default argument value of type 'Int' cannot be converted to type 'T'}}

  let _ = with_magic()
  let _: String = generic_with_magic()
}

// SR-16069
func test_allow_same_type_between_dependent_types() {
  struct Default : P {
    typealias X = Int
  }

  struct Other : P {
    typealias X = Int
  }

  struct S<T: P> {
    func test<U: P>(_: U = Default()) where U.X == T.X { // expected-note {{where 'T.X' = 'String', 'U.X' = 'Default.X' (aka 'Int')}}
    }
  }

  func test_ok<T: P>(s: S<T>) where T.X == Int {
    s.test() // Ok: U == Default
  }

  func test_bad<T: P>(s: S<T>) where T.X == String {
    s.test() // expected-error {{instance method 'test' requires the types 'String' and 'Default.X' (aka 'Int') be equivalent}}
  }
}
