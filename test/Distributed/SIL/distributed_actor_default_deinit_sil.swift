// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend-emit-module -emit-module-path %t/FakeDistributedActorSystems.swiftmodule -module-name FakeDistributedActorSystems -disable-availability-checking %S/../Inputs/FakeDistributedActorSystems.swift
// RUN: %target-swift-frontend -module-name default_deinit -primary-file %s -emit-sil -disable-availability-checking -I %t | %FileCheck %s --enable-var-scope --color
// REQUIRES: concurrency
// REQUIRES: distributed

import Distributed
import FakeDistributedActorSystems

typealias DefaultDistributedActorSystem = FakeActorSystem

final class SomeClass: Sendable {}

distributed actor MyDistActor {
  let localOnlyField: SomeClass

  init(system: FakeActorSystem) {
    self.actorSystem = system
    self.localOnlyField = SomeClass()
  }
}

// MARK: distributed actor check

// This test checks that we resign the identity for local deallocations,
// destroy only the correct stored properties whether remote or local, and also
// destroy the executor.

// CHECK-LABEL: sil hidden{{.*}} @$s14default_deinit11MyDistActorCfd : $@convention(method) (@guaranteed MyDistActor) -> @owned Builtin.NativeObject {
// CHECK: bb0([[SELF:%[0-9]+]] : $MyDistActor):
// CHECK:   [[EXI_SELF:%[0-9]+]] = init_existential_ref [[SELF]] : $MyDistActor
// CHECK:   [[IS_REMOTE_FN:%[0-9]+]] = function_ref @swift_distributed_actor_is_remote
// CHECK:   [[IS_REMOTE:%[0-9]+]] = apply [[IS_REMOTE_FN]]([[EXI_SELF]])
// CHECK:   [[RAW_BOOL:%[0-9]+]] = struct_extract [[IS_REMOTE]] : $Bool, #Bool._value
// CHECK:   cond_br [[RAW_BOOL]], [[REMOTE_BB:bb[0-9]+]], [[LOCAL_BB:bb[0-9]+]]

// *** If local... invoke system.resignID()
// CHECK: [[LOCAL_BB]]:
// CHECK:   [[ID_REF:%[0-9]+]] = ref_element_addr [[SELF]] : $MyDistActor, #MyDistActor.id
// CHECK:   [[SYS_REF:%[0-9]+]] = ref_element_addr [[SELF]] : $MyDistActor, #MyDistActor.actorSystem
// CHECK:   [[ID_LOAD:%[0-9]+]] = load [[ID_REF]] : $*ActorAddress
// CHECK:   [[SYS_LOAD:%[0-9]+]] = load [[SYS_REF]] : $*FakeActorSystem
// CHECK:   [[RESIGN:%[0-9]+]] = function_ref @$s27FakeDistributedActorSystems0aC6SystemV8resignIDyyAA0C7AddressVF : $@convention(method) (@guaranteed ActorAddress, @guaranteed FakeActorSystem) -> ()
// CHECK:   apply [[RESIGN]]([[ID_LOAD]], [[SYS_LOAD]])
// CHECK:   br [[CONTINUE:bb[0-9]+]]

// *** If remote...
// CHECK: [[REMOTE_BB]]:
// CHECK:  br [[CONTINUE]]

// Now we deallocate stored properties, and how we do that depends again on
// being remote or local. Default code emission does another is_remote test,
// so we check for that here and leave tail-merging to the optimizer, for now.
// CHECK: [[CONTINUE]]:
            // *** this is entirely copy-pasted from the first check in bb0 ***
// CHECK:   [[EXI_SELF:%[0-9]+]] = init_existential_ref [[SELF]] : $MyDistActor
// CHECK:   [[IS_REMOTE_FN:%[0-9]+]] = function_ref @swift_distributed_actor_is_remote
// CHECK:   [[IS_REMOTE:%[0-9]+]] = apply [[IS_REMOTE_FN]]([[EXI_SELF]])
// CHECK:   [[RAW_BOOL:%[0-9]+]] = struct_extract [[IS_REMOTE]] : $Bool, #Bool._value
// CHECK:   cond_br [[RAW_BOOL]], [[REMOTE_BB_DEALLOC:bb[0-9]+]], [[LOCAL_BB_DEALLOC:bb[0-9]+]]

// *** only destroy the id and system if remote ***
// CHECK: [[REMOTE_BB_DEALLOC]]:
            // *** destroy system ***
// SKIP:   [[REF:%[0-9]+]] = ref_element_addr [[SELF]] : $MyDistActor, #MyDistActor.actorSystem
// SKIP:   [[ACCESS:%[0-9]+]] = begin_access [deinit] [static] [[REF]]
// SKIP:   destroy_addr [[ACCESS]] : $*FakeActorSystem
// SKIP:   end_access [[ACCESS]]
            // *** destroy identity ***
// CHECK:   [[REF:%[0-9]+]] = ref_element_addr [[SELF]] : $MyDistActor, #MyDistActor.id
// CHECK:   [[ACCESS:%[0-9]+]] = begin_access [deinit] [static] [[REF]]
// CHECK:   destroy_addr [[ACCESS]] : $*ActorAddress
// CHECK:   end_access [[ACCESS]]
// CHECK:   br [[AFTER_DEALLOC:bb[0-9]+]]

// *** destroy everything if local ***
// CHECK: [[LOCAL_BB_DEALLOC]]:
            // *** destroy the user-defined field ***
// CHECK:   [[REF:%[0-9]+]] = ref_element_addr [[SELF]] : $MyDistActor, #MyDistActor.localOnlyField
// CHECK:   [[ACCESS:%[0-9]+]] = begin_access [deinit] [static] [[REF]]
// CHECK:   destroy_addr [[ACCESS]] : $*SomeClass
// CHECK:   end_access [[ACCESS]]
            // *** the rest of this part is identical to the remote case ***
// SKIP:   [[REF:%[0-9]+]] = ref_element_addr [[SELF]] : $MyDistActor, #MyDistActor.actorSystem
// SKIP:   [[ACCESS:%[0-9]+]] = begin_access [deinit] [static] [[REF]]
// SKIP:   destroy_addr [[ACCESS]] : $*FakeActorSystem
// SKIP:   end_access [[ACCESS]]
// CHECK:   [[REF:%[0-9]+]] = ref_element_addr [[SELF]] : $MyDistActor, #MyDistActor.id
// CHECK:   [[ACCESS:%[0-9]+]] = begin_access [deinit] [static] [[REF]]
// CHECK:   destroy_addr [[ACCESS]] : $*ActorAddress
// CHECK:   end_access [[ACCESS]]
// CHECK:   br [[AFTER_DEALLOC]]

// CHECK: [[AFTER_DEALLOC]]:
// CHECK:   builtin "destroyDefaultActor"([[SELF]] : $MyDistActor)
// CHECK:   [[CAST:%[0-9]+]] = unchecked_ref_cast [[SELF]]
// CHECK:   return [[CAST]] : $Builtin.NativeObject
// CHECK: } // end sil function '$s14default_deinit11MyDistActorCfd'


// MARK: local actor check

@available(macOS 12, *)
actor SimpleActor {
  let someField: SomeClass
  init() {
    self.someField = SomeClass()
  }
}

// additionally, we add basic coverage for a non-distributed actor's deinit


// CHECK-LABEL: sil hidden{{.*}} @$s14default_deinit11SimpleActorCfd : $@convention(method) (@guaranteed SimpleActor) -> @owned Builtin.NativeObject {
// CHECK: bb0([[SELF:%[0-9]+]] : $SimpleActor):
// CHECK:   [[REF:%[0-9]+]] = ref_element_addr [[SELF]] : $SimpleActor, #SimpleActor.someField
// CHECK:   [[ACCESS:%[0-9]+]] = begin_access [deinit] [static] [[REF]]
// CHECK:   destroy_addr [[ACCESS]] : $*SomeClass
// CHECK:   end_access [[ACCESS]]
// CHECK:   builtin "destroyDefaultActor"([[SELF]] : $SimpleActor)
// CHECK:   [[CAST:%[0-9]+]] = unchecked_ref_cast [[SELF]]
// CHECK:   return [[CAST]] : $Builtin.NativeObject
// CHECK: } // end sil function '$s14default_deinit11SimpleActorCfd'


