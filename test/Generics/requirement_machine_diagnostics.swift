// RUN: %target-typecheck-verify-swift -requirement-machine-protocol-signatures=on -requirement-machine-inferred-signatures=on

func testInvalidConformance() {
  // expected-error@+1 {{type 'T' constrained to non-protocol, non-class type 'Int'}}
  func invalidIntConformance<T>(_: T) where T: Int {}

  // expected-error@+1 {{type 'T' constrained to non-protocol, non-class type 'Int'}}
  struct InvalidIntConformance<T: Int> {}

  struct S<T> {
    // expected-error@+2 {{type 'T' constrained to non-protocol, non-class type 'Int'}}
    // expected-note@+1 {{use 'T == Int' to require 'T' to be 'Int'}}
    func method() where T: Int {}
  }
}

// Check directly-concrete same-type constraints
typealias NotAnInt = Double

protocol X {}

// expected-error@+1{{generic signature requires types 'NotAnInt' (aka 'Double') and 'Int' to be the same}}
extension X where NotAnInt == Int {}

protocol EqualComparable {
  func isEqual(_ other: Self) -> Bool
}

func badTypeConformance1<T>(_: T) where Int : EqualComparable {} // expected-error{{type 'Int' in conformance requirement does not refer to a generic parameter or associated type}}

func badTypeConformance2<T>(_: T) where T.Blarg : EqualComparable { } // expected-error{{'Blarg' is not a member type of type 'T'}}

func badTypeConformance3<T>(_: T) where (T) -> () : EqualComparable { }
// expected-error@-1{{type '(T) -> ()' in conformance requirement does not refer to a generic parameter or associated type}}

func badTypeConformance4<T>(_: T) where (inout T) throws -> () : EqualComparable { }
// expected-error@-1{{type '(inout T) throws -> ()' in conformance requirement does not refer to a generic parameter or associated type}}

func badTypeConformance5<T>(_: T) where T & Sequence : EqualComparable { }
// expected-error@-1 {{non-protocol, non-class type 'T' cannot be used within a protocol-constrained type}}

func badTypeConformance6<T>(_: T) where [T] : Collection { }
// expected-warning@-1{{redundant conformance constraint '[T]' : 'Collection'}}

func concreteSameTypeRedundancy<T>(_: T) where Int == Int {}
// expected-warning@-1{{redundant same-type constraint 'Int' == 'Int'}}

func concreteSameTypeRedundancy<T>(_: T) where Array<Int> == Array<T> {}
// expected-warning@-1{{redundant same-type constraint 'Array<Int>' == 'Array<T>'}}

protocol P {}
struct S: P {}
func concreteConformanceRedundancy<T>(_: T) where S : P {}
// expected-warning@-1{{redundant conformance constraint 'S' : 'P'}}

class C {}
func concreteLayoutRedundancy<T>(_: T) where C : AnyObject {}
// expected-warning@-1{{redundant constraint 'C' : 'AnyObject'}}

func concreteLayoutConflict<T>(_: T) where Int : AnyObject {}
// expected-error@-1{{type 'Int' in conformance requirement does not refer to a generic parameter or associated type}}

class C2: C {}
func concreteSubclassRedundancy<T>(_: T) where C2 : C {}
// expected-warning@-1{{redundant superclass constraint 'C2' : 'C'}}

class D {}
func concreteSubclassConflict<T>(_: T) where D : C {}
// expected-error@-1{{type 'D' in conformance requirement does not refer to a generic parameter or associated type}}

protocol UselessProtocolWhereClause where Int == Int {}
// expected-warning@-1 {{redundant same-type constraint 'Int' == 'Int'}}

protocol InvalidProtocolWhereClause where Self: Int {}
// expected-error@-1 {{type 'Self' constrained to non-protocol, non-class type 'Int'}}

typealias Alias<T> = T where Int == Int
// expected-warning@-1 {{redundant same-type constraint 'Int' == 'Int'}}

func cascadingConflictingRequirement<T>(_: T) where DoesNotExist : EqualComparable { }
// expected-error@-1 {{cannot find type 'DoesNotExist' in scope}}

func cascadingInvalidConformance<T>(_: T) where T : DoesNotExist { }
// expected-error@-1 {{cannot find type 'DoesNotExist' in scope}}

func trivialRedundant1<T>(_: T) where T: P, T: P {}
// expected-warning@-1 {{redundant conformance constraint 'T' : 'P'}}

func trivialRedundant2<T>(_: T) where T: AnyObject, T: AnyObject {}
// expected-warning@-1 {{redundant constraint 'T' : 'AnyObject'}}

func trivialRedundant3<T>(_: T) where T: C, T: C {}
// expected-warning@-1 {{redundant superclass constraint 'T' : 'C'}}

func trivialRedundant4<T>(_: T) where T == T {}
// expected-warning@-1 {{redundant same-type constraint 'T' == 'T'}}

protocol TrivialRedundantConformance: P, P {}
// expected-warning@-1 {{redundant conformance constraint 'Self' : 'P'}}

protocol TrivialRedundantLayout: AnyObject, AnyObject {}
// expected-warning@-1 {{redundant constraint 'Self' : 'AnyObject'}}
// expected-error@-2 {{duplicate inheritance from 'AnyObject'}}

protocol TrivialRedundantSuperclass: C, C {}
// expected-warning@-1 {{redundant superclass constraint 'Self' : 'C'}}
// expected-error@-2 {{duplicate inheritance from 'C'}}

protocol TrivialRedundantSameType where Self == Self {
// expected-warning@-1 {{redundant same-type constraint 'Self' == 'Self'}}
  associatedtype T where T == T
  // expected-warning@-1 {{redundant same-type constraint 'Self.T' == 'Self.T'}}
}

struct G<T> { }

protocol Pair {
  associatedtype A
  associatedtype B
}

func test1<T: Pair>(_: T) where T.A == G<Int>, T.A == G<T.B>, T.B == Int { }
// expected-warning@-1 {{redundant same-type constraint 'T.A' == 'G<T.B>'}}


protocol P1 {
  func p1()
}

protocol P2 : P1 { }

protocol P3 {
  associatedtype P3Assoc : P2
}

protocol P4 {
  associatedtype P4Assoc : P1
}

func inferSameType2<T : P3, U : P4>(_: T, _: U) where U.P4Assoc : P2, T.P3Assoc == U.P4Assoc {}
// expected-warning@-1{{redundant conformance constraint 'U.P4Assoc' : 'P2'}}

protocol P5 {
  associatedtype Element
}

protocol P6 {
  associatedtype AssocP6 : P5
}

protocol P7 : P6 {
  associatedtype AssocP7: P6
}

// expected-warning@+1{{redundant conformance constraint 'Self.AssocP6.Element' : 'P6'}}
extension P7 where AssocP6.Element : P6,
        AssocP7.AssocP6.Element : P6,
        AssocP6.Element == AssocP7.AssocP6.Element {
  func nestedSameType1() { }
}

protocol P8 {
  associatedtype A
  associatedtype B
}

protocol P9 : P8 {
  associatedtype A
  associatedtype B
}

protocol P10 {
  associatedtype A
  associatedtype C
}

class X3 { }

func sameTypeConcrete2<T : P9 & P10>(_: T) where T.B : X3, T.C == T.B, T.C == X3 { }
// expected-warning@-1{{redundant superclass constraint 'T.B' : 'X3'}}


// Redundant requirement warnings are suppressed for inferred requirements.

protocol P11 {
 associatedtype X
 associatedtype Y
 associatedtype Z
}

func inferred1<T : Hashable>(_: Set<T>) {}
func inferred2<T>(_: Set<T>) where T: Hashable {}
func inferred3<T : P11>(_: T) where T.X : Hashable, T.Z == Set<T.Y>, T.X == T.Y {}
func inferred4<T : P11>(_: T) where T.Z == Set<T.Y>, T.X : Hashable, T.X == T.Y {}
func inferred5<T : P11>(_: T) where T.Z == Set<T.X>, T.Y : Hashable, T.X == T.Y {}
func inferred6<T : P11>(_: T) where T.Y : Hashable, T.Z == Set<T.X>, T.X == T.Y {}

func typeMatcherSugar<T>(_: T) where Array<Int> == Array<T>, Array<Int> == Array<T> {}
// expected-warning@-1 2{{redundant same-type constraint 'Array<Int>' == 'Array<T>'}}
// expected-warning@-2{{redundant same-type constraint 'T' == 'Int'}}

// MARK: - Conflict diagnostics

protocol ProtoAlias1 {
  typealias A1 = Int
}

protocol ProtoAlias2 {
  typealias A2 = String
}

func basicConflict<T: ProtoAlias1 & ProtoAlias2>(_:T) where T.A1 == T.A2 {}
// expected-error@-1{{no type for 'T.A1' can satisfy both 'T.A1 == String' and 'T.A1 == Int'}}

protocol RequiresAnyObject {
  associatedtype A: AnyObject
}

protocol RequiresConformance {
  associatedtype A: P
}

class Super {}
protocol RequiresSuperclass {
  associatedtype A: Super
}

func testMissingRequirements() {
  struct S {}
  func conflict1<T: RequiresAnyObject>(_: T) where T.A == S {}
  // expected-error@-1{{no type for 'T.A' can satisfy both 'T.A == S' and 'T.A : AnyObject'}}

  func conflict2<T: RequiresConformance>(_: T) where T.A == C {}
  // expected-error@-1{{no type for 'T.A' can satisfy both 'T.A == C' and 'T.A : P'}}

  class C {}
  func conflict3<T: RequiresSuperclass>(_: T) where T.A == C {}
  // expected-error@-1{{no type for 'T.A' can satisfy both 'T.A : C' and 'T.A : Super'}}

  func conflict4<T: RequiresSuperclass>(_: T) where T.A: C {}
  // expected-error@-1{{no type for 'T.A' can satisfy both 'T.A : C' and 'T.A : Super'}}
}

protocol Fooable {
  associatedtype Foo
  var foo: Foo { get }
}

protocol Barrable {
  associatedtype Bar: Fooable
  var bar: Bar { get }
}

protocol Concrete { associatedtype X where X == Int }

func sameTypeConflicts() {

  struct X {}
  struct Y: Fooable {
    typealias Foo = X
    var foo: X { return X() }
  }
  struct Z: Barrable {
    typealias Bar = Y
    var bar: Y { return Y() }
  }

  // expected-error@+1{{no type for 'T.Foo' can satisfy both 'T.Foo == X' and 'T.Foo == Y'}}
  func fail1<
    T: Fooable, U: Fooable
  >(_ t: T, u: U) -> (X, Y)
    where T.Foo == X, U.Foo == Y, T.Foo == U.Foo {
    fatalError()
  }

  // expected-error@+1{{no type for 'T.Foo' can satisfy both 'T.Foo == Y' and 'T.Foo == X'}}
  func fail2<
    T: Fooable, U: Fooable
  >(_ t: T, u: U) -> (X, Y)
    where T.Foo == U.Foo, T.Foo == X, U.Foo == Y {
    fatalError()
  }

  // expected-error@+1{{no type for 'T.Bar' can satisfy both 'T.Bar == X' and 'T.Bar : Fooable'}}
  func fail3<T: Barrable>(_ t: T) -> X
    where T.Bar == X {
    fatalError()
  }

  // expected-error@+1{{no type for 'T.Bar.Foo' can satisfy both 'T.Bar.Foo == X' and 'T.Bar.Foo == Z'}}
  func fail4<T: Barrable>(_ t: T) -> (Y, Z)
    where
    T.Bar == Y,
    T.Bar.Foo == Z {
    fatalError()
  }

  // expected-error@+1{{no type for 'T.Bar.Foo' can satisfy both 'T.Bar.Foo == X' and 'T.Bar.Foo == Z'}}
  func fail5<T: Barrable>(_ t: T) -> (Y, Z)
    where
    T.Bar.Foo == Z,
    T.Bar == Y {
    fatalError()
  }

  // expected-error@+1{{no type for 'T.X' can satisfy both 'T.X == String' and 'T.X == Int'}}
  func fail6<U, T: Concrete>(_: U, _: T) where T.X == String {}

  struct G<T> {}

  // expected-error@+1{{no type for 'T.X' can satisfy both 'T.X == G<U.Foo>' and 'T.X == Int'}}
  func fail7<U: Fooable, T: Concrete>(_: U, _: T) where T.X == G<U.Foo> {}

  // expected-error@+1{{no type for 'T' can satisfy both 'T == G<U.Foo>' and 'T == Int'}}
  func fail8<T, U: Fooable>(_: U, _: T) where T == G<U.Foo>, T == Int {}

  // expected-error@+1{{no type for 'T' can satisfy both 'T == G<U.Foo>' and 'T == Int'}}
  func fail9<T, U: Fooable>(_: U, _: T) where T == Int, T == G<U.Foo> {}
}
