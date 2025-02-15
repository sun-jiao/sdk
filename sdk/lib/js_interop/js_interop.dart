// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for JS interop. Includes a JS type hierarchy to facilitate sound
/// interop with JS. The JS type hierarchy is modeled after the actual type
/// hierarchy in JS, and not the Dart type hierarchy.
///
/// Note: The JS types that are exposed through this library are currently
/// wrapper types that are erased to their runtime types. The runtime types will
/// differ based on the backend. In general, stick to using conversion functions
/// that are exposed as extension methods e.g. 'toJS'.
///
/// **WARNING**:
/// This library is still a work in progress. As such, JS types, allowed syntax,
/// semantics, and functionality may all change, so avoid using this library in
/// production.
///
/// {@category Web}
library dart.js_interop;

import 'dart:_js_types' as js_types;
import 'dart:typed_data';

/// Allow use of `@staticInterop` classes with JS types as well as export
/// functionality.
export 'dart:_js_annotations' show staticInterop, anonymous, JSExport;

/// The annotation for JS interop members.
///
/// This is meant to signify that a given library, top-level external member, or
/// inline class is a JS interop declaration.
///
/// Specifying [name] customizes the JavaScript name to use. This can be used in
/// the following scenarios:
///
/// - Namespacing all the external top-level members, static members, and
/// constructors of a library by annotating the library with a custom name.
/// - Namespacing all the external static members and constructors of an inline
/// class by annotating the inline class with a custom name.
/// - Renaming external members by annotating the member with a custom name.
///
/// In the case where [name] is not specified, we default to the Dart name for
/// inline classes and external members.
///
/// Note: `package:js` exports an `@JS` annotation as well. Unlike that
/// annotation, this is meant for inline classes, and will result in more
/// type-checking for external top-level members.
class JS {
  final String? name;
  const JS([this.name]);
}

/// The JS types users should use to write their external APIs.
///
/// These are meant to separate the Dart and JS type hierarchies statically.
///
/// **WARNING**:
/// For now, the runtime semantics between backends may differ and may not be
/// intuitive e.g. casting to [JSString] may give you inconsistent and
/// surprising results depending on the value. It is preferred to always use the
/// conversion functions e.g. `toJS` and `toDart`. The only runtime semantics
/// stability we can guarantee is if a value actually is the JS type you are
/// type-checking with/casting to e.g. `obj as JSString` will continue to work
/// if `obj` actually is a JavaScript string.

/// The overall top type in the JS types hierarchy.
typedef JSAny = js_types.JSAny;

/// The representation type of all JavaScript objects for inline classes,
/// [JSObject] <: [JSAny].
///
/// This is the supertype of all JS objects, but not other JS types, like
/// primitives. This is the only allowed `on` type for inline classes written by
/// users to model JS interop objects. See https://dart.dev/web/js-interop for
/// more details on how to use JS interop.
// TODO(srujzs): This class _must_ be sealed before we can make this library
// public. Either use the CFE mechanisms that exist today, or use the Dart 3
// sealed classes feature.
// TODO(joshualitt): Do we need to seal any other JS types on JS backends? We
// probably want to seal all JS types on Wasm backends.
// TODO(joshualitt): Add a [JSObject] constructor.
typedef JSObject = js_types.JSObject;

/// The type of all JS functions, [JSFunction] <: [JSObject].
typedef JSFunction = js_types.JSFunction;

/// The type of all Dart functions adapted to be callable from JS. We only allow
/// a subset of Dart functions to be callable from JS, [JSExportedDartFunction]
/// <: [JSFunction].
// TODO(joshualitt): Detail exactly what are the requirements.
typedef JSExportedDartFunction = js_types.JSExportedDartFunction;

/// The type of JS promises and promise-like objects, [JSPromise] <: [JSObject].
typedef JSPromise = js_types.JSPromise;

/// The type of all JS arrays, [JSArray] <: [JSObject].
typedef JSArray = js_types.JSArray;

/// The type of the boxed Dart object that can be passed to JS safely. There is
/// no interface specified of this boxed object, and you may get a new box each
/// time you box the same Dart object.
/// [JSBoxedDartObject] <: [JSObject].
typedef JSBoxedDartObject = js_types.JSBoxedDartObject;

/// The type of JS array buffers, [JSArrayBuffer] <: [JSObject].
typedef JSArrayBuffer = js_types.JSArrayBuffer;

/// The type of JS byte data, [JSDataView] <: [JSObject].
typedef JSDataView = js_types.JSDataView;

/// The abstract supertype of all JS typed arrays, [JSTypedArray] <: [JSObject].
typedef JSTypedArray = js_types.JSTypedArray;

/// The typed arrays themselves, `*Array` <: [JSTypedArray].
typedef JSInt8Array = js_types.JSInt8Array;
typedef JSUint8Array = js_types.JSUint8Array;
typedef JSUint8ClampedArray = js_types.JSUint8ClampedArray;
typedef JSInt16Array = js_types.JSInt16Array;
typedef JSUint16Array = js_types.JSUint16Array;
typedef JSInt32Array = js_types.JSInt32Array;
typedef JSUint32Array = js_types.JSUint32Array;
typedef JSFloat32Array = js_types.JSFloat32Array;
typedef JSFloat64Array = js_types.JSFloat64Array;

// The various JS primitive types. Crucially, unlike the Dart type hierarchy,
// none of these are subtypes of [JSObject], but rather they are logically
// subtypes of [JSAny].

/// The type of JS numbers, [JSNumber] <: [JSAny].
typedef JSNumber = js_types.JSNumber;

/// The type of JS booleans, [JSBoolean] <: [JSAny].
typedef JSBoolean = js_types.JSBoolean;

/// The type of JS strings, [JSString] <: [JSAny].
typedef JSString = js_types.JSString;

/// The type of JS Symbols, [JSSymbol] <: [JSAny].
typedef JSSymbol = js_types.JSSymbol;

/// The type of JS BigInts, [JSBigInt] <: [JSAny].
typedef JSBigInt = js_types.JSBigInt;

/// A getter to retrieve the global context that is used in static interop
/// lowering.
external JSObject get globalContext;

/// `JSUndefined` and `JSNull` are actual reified types on some backends, but
/// not others. Instead, users should use nullable types for any type that could
/// contain `JSUndefined` or `JSNull`. However, instead of trying to determine
/// the nullability of a JS type in Dart, i.e. using `?`, `!`, `!= null` or `==
/// null`, users should use the provided helpers below to determine if it is
/// safe to downcast a potentially `JSNullable` or `JSUndefineable` object to a
/// defined and non-null JS type.
// TODO(joshualitt): Investigate whether or not it will be possible to reify
// `JSUndefined` and `JSNull` on all backends.
extension NullableUndefineableJSAnyExtension on JSAny? {
  external bool get isUndefined;
  external bool get isNull;
  bool get isUndefinedOrNull => isUndefined || isNull;
  bool get isDefinedAndNotNull => !isUndefinedOrNull;
  external JSBoolean typeofEquals(JSString typeString);

  /// Effectively the inverse of [jsify], [dartify] Takes a JavaScript object,
  /// and converts it to a Dart based object. Only JS primitives, arrays, or
  /// 'map' like JS objects are supported.
  external Object? dartify();
}

/// Utility extensions for [Object?].
extension NullableObjectUtilExtension on Object? {
  /// Recursively converts a JSON-like collection, or Dart primitive to a
  /// JavaScript compatible representation.
  external JSAny? jsify();
}

/// Utility extensions for [JSObject].
extension JSObjectUtilExtension on JSObject {
  external JSBoolean instanceof(JSFunction constructor);
}

/// The type of `JSUndefined` when returned from functions. Unlike pure JS,
/// no actual object will be returned.
typedef JSVoid = js_types.JSVoid;

// Extension members to support conversions between Dart types and JS types.
// Not all Dart types can be converted to JS types and vice versa.
// TODO(joshualitt): We might want to investigate using inline classes instead
// of extension methods for these methods.

/// [JSExportedDartFunction] <-> [Function]
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  external Function get toDart;
}

extension FunctionToJSExportedDartFunction on Function {
  external JSExportedDartFunction get toJS;
}

/// [JSBoxedDartObject] <-> [Object]
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  external Object get toDart;
}

extension ObjectToJSBoxedDartObject on Object {
  external JSBoxedDartObject get toJSBox;
}

/// [JSPromise] -> [Future<JSAny?>].
extension JSPromiseToFuture on JSPromise {
  external Future<JSAny?> get toDart;
}

// TODO(joshualitt): On Wasm backends List / Array conversion methods will
// copy, and on JS backends they will not. We should find a path towards
// consistent semantics.
/// [JSArrayBuffer] <-> [ByteBuffer]
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  external ByteBuffer get toDart;
}

extension ByteBufferToJSArrayBuffer on ByteBuffer {
  external JSArrayBuffer get toJS;
}

/// [JSDataView] <-> [ByteData]
extension JSDataViewToByteData on JSDataView {
  external ByteData get toDart;
}

extension ByteDataToJSDataView on ByteData {
  external JSDataView get toJS;
}

/// [JSInt8Array] <-> [Int8List]
extension JSInt8ArrayToInt8List on JSInt8Array {
  external Int8List get toDart;
}

extension Int8ListToJSInt8Array on Int8List {
  external JSInt8Array get toJS;
}

/// [JSUint8Array] <-> [Uint8List]
extension JSUint8ArrayToUint8List on JSUint8Array {
  external Uint8List get toDart;
}

extension Uint8ListToJSUint8Array on Uint8List {
  external JSUint8Array get toJS;
}

/// [JSUint8ClampedArray] <-> [Uint8ClampedList]
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  external Uint8ClampedList get toDart;
}

extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  external JSUint8ClampedArray get toJS;
}

/// [JSInt16Array] <-> [Int16List]
extension JSInt16ArrayToInt16List on JSInt16Array {
  external Int16List get toDart;
}

extension Int16ListToJSInt16Array on Int16List {
  external JSInt16Array get toJS;
}

/// [JSUint16Array] <-> [Uint16List]
extension JSUint16ArrayToInt16List on JSUint16Array {
  external Uint16List get toDart;
}

extension Uint16ListToJSInt16Array on Uint16List {
  external JSUint16Array get toJS;
}

/// [JSInt32Array] <-> [Int32List]
extension JSInt32ArrayToInt32List on JSInt32Array {
  external Int32List get toDart;
}

extension Int32ListToJSInt32Array on Int32List {
  external JSInt32Array get toJS;
}

/// [JSUint32Array] <-> [Uint32List]
extension JSUint32ArrayToUint32List on JSUint32Array {
  external Uint32List get toDart;
}

extension Uint32ListToJSUint32Array on Uint32List {
  external JSUint32Array get toJS;
}

/// [JSFloat32Array] <-> [Float32List]
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  external Float32List get toDart;
}

extension Float32ListToJSFloat32Array on Float32List {
  external JSFloat32Array get toJS;
}

/// [JSFloat64Array] <-> [Float64List]
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  external Float64List get toDart;
}

extension Float64ListToJSFloat64Array on Float64List {
  external JSFloat64Array get toJS;
}

/// [JSArray] <-> [List]
extension JSArrayToList on JSArray {
  /// Returns a list wrapper of the JS array.
  external List<JSAny?> get toDart;
}

extension ListToJSArray on List<JSAny?> {
  /// Compiler-specific conversion from list to JS array.
  ///
  /// This is either a pass-by-reference, unwrap, or copy depending on the
  /// implementation of the given list, and users shouldn't rely on
  /// modifications to the list to affect the array or vice versa.
  external JSArray get toJS;

  /// Either passes by reference, unwraps, or creates a heavyweight proxy that
  /// wraps the list.
  ///
  /// Only use this member if you want modifications to the list to also affect
  /// the JS array and vice versa. In practice, dart2js and DDC will pass lists
  /// by reference and dart2wasm will add a proxy or unwrap for most lists.
  ///
  /// **WARNING**: Do not rely on this to be performant.
  external JSArray get toJSProxyOrRef;
}

/// [JSNumber] -> [double] or [int].
extension JSNumberToNumber on JSNumber {
  /// Returns a Dart [double] for the given [JSNumber].
  external double get toDartDouble;

  /// Returns a Dart [int] for the given [JSNumber].
  ///
  /// If the [JSNumber] is not an integer value, throws.
  external int get toDartInt;
}

/// [double] -> [JSNumber].
extension DoubleToJSNumber on double {
  external JSNumber get toJS;
}

/// [num] -> [JSNumber].
extension NumToJSExtension on num {
  JSNumber get toJS => DoubleToJSNumber(toDouble()).toJS;
}

/// [JSBoolean] <-> [bool]
extension JSBooleanToBool on JSBoolean {
  external bool get toDart;
}

extension BoolToJSBoolean on bool {
  external JSBoolean get toJS;
}

/// [JSString] <-> [String]
extension JSStringToString on JSString {
  external String get toDart;
}

extension StringToJSString on String {
  external JSString get toJS;
}
