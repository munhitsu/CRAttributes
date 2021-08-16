// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: ProtoModel.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct ProtoOperationID {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var lamport: Int64 = 0

  ///UUID to 16 bytes
  var peerID: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct ProtoObjectOperation {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var version: Int32 = 0

  var lamport: Int64 = 0

  var peerID: Data = Data()

  var rawType: Int32 = 0

  var deleteOperations: [ProtoDeleteOperation] = []

  var attributeOperations: [ProtoAttributeOperation] = []

  var objectOperations: [ProtoObjectOperation] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct ProtoAttributeOperation {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var version: Int32 = 0

  var lamport: Int64 = 0

  var peerID: Data = Data()

  var name: String = String()

  var rawType: Int32 = 0

  var deleteOperations: [ProtoDeleteOperation] = []

  var lwwOperations: [ProtoLWWOperation] = []

  var stringInsertOperations: [ProtoStringInsertOperation] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct ProtoDeleteOperation {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var version: Int32 = 0

  var lamport: Int64 = 0

  var peerID: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct ProtoLWWOperation {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var version: Int32 = 0

  var lamport: Int64 = 0

  var peerID: Data = Data()

  var value: ProtoLWWOperation.OneOf_Value? = nil

  var int: Int64 {
    get {
      if case .int(let v)? = value {return v}
      return 0
    }
    set {value = .int(newValue)}
  }

  var float: Float {
    get {
      if case .float(let v)? = value {return v}
      return 0
    }
    set {value = .float(newValue)}
  }

  var date: Double {
    get {
      if case .date(let v)? = value {return v}
      return 0
    }
    set {value = .date(newValue)}
  }

  var boolean: Bool {
    get {
      if case .boolean(let v)? = value {return v}
      return false
    }
    set {value = .boolean(newValue)}
  }

  var string: String {
    get {
      if case .string(let v)? = value {return v}
      return String()
    }
    set {value = .string(newValue)}
  }

  var deleteOperations: [ProtoDeleteOperation] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum OneOf_Value: Equatable {
    case int(Int64)
    case float(Float)
    case date(Double)
    case boolean(Bool)
    case string(String)

  #if !swift(>=4.1)
    static func ==(lhs: ProtoLWWOperation.OneOf_Value, rhs: ProtoLWWOperation.OneOf_Value) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.int, .int): return {
        guard case .int(let l) = lhs, case .int(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.float, .float): return {
        guard case .float(let l) = lhs, case .float(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.date, .date): return {
        guard case .date(let l) = lhs, case .date(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.boolean, .boolean): return {
        guard case .boolean(let l) = lhs, case .boolean(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.string, .string): return {
        guard case .string(let l) = lhs, case .string(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  init() {}
}

struct ProtoStringInsertOperation {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var version: Int32 = 0

  var lamport: Int64 = 0

  var peerID: Data = Data()

  var contribution: String = String()

  var deleteOperations: [ProtoDeleteOperation] = []

  var stringInsertOperations: [ProtoStringInsertOperation] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct ProtoOperationsTree {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var containerID: ProtoOperationID {
    get {return _containerID ?? ProtoOperationID()}
    set {_containerID = newValue}
  }
  /// Returns true if `containerID` has been explicitly set.
  var hasContainerID: Bool {return self._containerID != nil}
  /// Clears the value of `containerID`. Subsequent reads from it will return its default value.
  mutating func clearContainerID() {self._containerID = nil}

  var value: ProtoOperationsTree.OneOf_Value? = nil

  var objectOperation: ProtoObjectOperation {
    get {
      if case .objectOperation(let v)? = value {return v}
      return ProtoObjectOperation()
    }
    set {value = .objectOperation(newValue)}
  }

  var attributeOperation: ProtoAttributeOperation {
    get {
      if case .attributeOperation(let v)? = value {return v}
      return ProtoAttributeOperation()
    }
    set {value = .attributeOperation(newValue)}
  }

  var deleteOperation: ProtoDeleteOperation {
    get {
      if case .deleteOperation(let v)? = value {return v}
      return ProtoDeleteOperation()
    }
    set {value = .deleteOperation(newValue)}
  }

  var lwwOperation: ProtoLWWOperation {
    get {
      if case .lwwOperation(let v)? = value {return v}
      return ProtoLWWOperation()
    }
    set {value = .lwwOperation(newValue)}
  }

  var stringInsertOperation: ProtoStringInsertOperation {
    get {
      if case .stringInsertOperation(let v)? = value {return v}
      return ProtoStringInsertOperation()
    }
    set {value = .stringInsertOperation(newValue)}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum OneOf_Value: Equatable {
    case objectOperation(ProtoObjectOperation)
    case attributeOperation(ProtoAttributeOperation)
    case deleteOperation(ProtoDeleteOperation)
    case lwwOperation(ProtoLWWOperation)
    case stringInsertOperation(ProtoStringInsertOperation)

  #if !swift(>=4.1)
    static func ==(lhs: ProtoOperationsTree.OneOf_Value, rhs: ProtoOperationsTree.OneOf_Value) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.objectOperation, .objectOperation): return {
        guard case .objectOperation(let l) = lhs, case .objectOperation(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.attributeOperation, .attributeOperation): return {
        guard case .attributeOperation(let l) = lhs, case .attributeOperation(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.deleteOperation, .deleteOperation): return {
        guard case .deleteOperation(let l) = lhs, case .deleteOperation(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.lwwOperation, .lwwOperation): return {
        guard case .lwwOperation(let l) = lhs, case .lwwOperation(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.stringInsertOperation, .stringInsertOperation): return {
        guard case .stringInsertOperation(let l) = lhs, case .stringInsertOperation(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  init() {}

  fileprivate var _containerID: ProtoOperationID? = nil
}

/// tree of operations
/// a tree will contain all operations in the upstream queue, if device change the peerID or repllicated through backup then it may contain a mix
struct ProtoOperationsForest {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var version: Int32 = 0

  ///it's a sender device ID
  var peerID: Data = Data()

  var trees: [ProtoOperationsTree] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension ProtoOperationID: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "OperationID"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "lamport"),
    2: .same(proto: "peerID"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.lamport) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.peerID) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.lamport != 0 {
      try visitor.visitSingularInt64Field(value: self.lamport, fieldNumber: 1)
    }
    if !self.peerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.peerID, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoOperationID, rhs: ProtoOperationID) -> Bool {
    if lhs.lamport != rhs.lamport {return false}
    if lhs.peerID != rhs.peerID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProtoObjectOperation: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "ObjectOperation"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "version"),
    2: .same(proto: "lamport"),
    3: .same(proto: "peerID"),
    4: .same(proto: "rawType"),
    5: .same(proto: "deleteOperations"),
    6: .same(proto: "attributeOperations"),
    7: .same(proto: "objectOperations"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.version) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.lamport) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.peerID) }()
      case 4: try { try decoder.decodeSingularInt32Field(value: &self.rawType) }()
      case 5: try { try decoder.decodeRepeatedMessageField(value: &self.deleteOperations) }()
      case 6: try { try decoder.decodeRepeatedMessageField(value: &self.attributeOperations) }()
      case 7: try { try decoder.decodeRepeatedMessageField(value: &self.objectOperations) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.version != 0 {
      try visitor.visitSingularInt32Field(value: self.version, fieldNumber: 1)
    }
    if self.lamport != 0 {
      try visitor.visitSingularInt64Field(value: self.lamport, fieldNumber: 2)
    }
    if !self.peerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.peerID, fieldNumber: 3)
    }
    if self.rawType != 0 {
      try visitor.visitSingularInt32Field(value: self.rawType, fieldNumber: 4)
    }
    if !self.deleteOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.deleteOperations, fieldNumber: 5)
    }
    if !self.attributeOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.attributeOperations, fieldNumber: 6)
    }
    if !self.objectOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.objectOperations, fieldNumber: 7)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoObjectOperation, rhs: ProtoObjectOperation) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.lamport != rhs.lamport {return false}
    if lhs.peerID != rhs.peerID {return false}
    if lhs.rawType != rhs.rawType {return false}
    if lhs.deleteOperations != rhs.deleteOperations {return false}
    if lhs.attributeOperations != rhs.attributeOperations {return false}
    if lhs.objectOperations != rhs.objectOperations {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProtoAttributeOperation: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "AttributeOperation"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "version"),
    2: .same(proto: "lamport"),
    3: .same(proto: "peerID"),
    4: .same(proto: "name"),
    5: .same(proto: "rawType"),
    6: .same(proto: "deleteOperations"),
    7: .same(proto: "lwwOperations"),
    8: .same(proto: "stringInsertOperations"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.version) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.lamport) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.peerID) }()
      case 4: try { try decoder.decodeSingularStringField(value: &self.name) }()
      case 5: try { try decoder.decodeSingularInt32Field(value: &self.rawType) }()
      case 6: try { try decoder.decodeRepeatedMessageField(value: &self.deleteOperations) }()
      case 7: try { try decoder.decodeRepeatedMessageField(value: &self.lwwOperations) }()
      case 8: try { try decoder.decodeRepeatedMessageField(value: &self.stringInsertOperations) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.version != 0 {
      try visitor.visitSingularInt32Field(value: self.version, fieldNumber: 1)
    }
    if self.lamport != 0 {
      try visitor.visitSingularInt64Field(value: self.lamport, fieldNumber: 2)
    }
    if !self.peerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.peerID, fieldNumber: 3)
    }
    if !self.name.isEmpty {
      try visitor.visitSingularStringField(value: self.name, fieldNumber: 4)
    }
    if self.rawType != 0 {
      try visitor.visitSingularInt32Field(value: self.rawType, fieldNumber: 5)
    }
    if !self.deleteOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.deleteOperations, fieldNumber: 6)
    }
    if !self.lwwOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.lwwOperations, fieldNumber: 7)
    }
    if !self.stringInsertOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.stringInsertOperations, fieldNumber: 8)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoAttributeOperation, rhs: ProtoAttributeOperation) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.lamport != rhs.lamport {return false}
    if lhs.peerID != rhs.peerID {return false}
    if lhs.name != rhs.name {return false}
    if lhs.rawType != rhs.rawType {return false}
    if lhs.deleteOperations != rhs.deleteOperations {return false}
    if lhs.lwwOperations != rhs.lwwOperations {return false}
    if lhs.stringInsertOperations != rhs.stringInsertOperations {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProtoDeleteOperation: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "DeleteOperation"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "version"),
    2: .same(proto: "lamport"),
    3: .same(proto: "peerID"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.version) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.lamport) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.peerID) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.version != 0 {
      try visitor.visitSingularInt32Field(value: self.version, fieldNumber: 1)
    }
    if self.lamport != 0 {
      try visitor.visitSingularInt64Field(value: self.lamport, fieldNumber: 2)
    }
    if !self.peerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.peerID, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoDeleteOperation, rhs: ProtoDeleteOperation) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.lamport != rhs.lamport {return false}
    if lhs.peerID != rhs.peerID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProtoLWWOperation: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "LWWOperation"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "version"),
    2: .same(proto: "lamport"),
    3: .same(proto: "peerID"),
    4: .same(proto: "int"),
    5: .same(proto: "float"),
    6: .same(proto: "date"),
    7: .same(proto: "boolean"),
    8: .same(proto: "string"),
    9: .same(proto: "deleteOperations"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.version) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.lamport) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.peerID) }()
      case 4: try {
        var v: Int64?
        try decoder.decodeSingularInt64Field(value: &v)
        if let v = v {
          if self.value != nil {try decoder.handleConflictingOneOf()}
          self.value = .int(v)
        }
      }()
      case 5: try {
        var v: Float?
        try decoder.decodeSingularFloatField(value: &v)
        if let v = v {
          if self.value != nil {try decoder.handleConflictingOneOf()}
          self.value = .float(v)
        }
      }()
      case 6: try {
        var v: Double?
        try decoder.decodeSingularDoubleField(value: &v)
        if let v = v {
          if self.value != nil {try decoder.handleConflictingOneOf()}
          self.value = .date(v)
        }
      }()
      case 7: try {
        var v: Bool?
        try decoder.decodeSingularBoolField(value: &v)
        if let v = v {
          if self.value != nil {try decoder.handleConflictingOneOf()}
          self.value = .boolean(v)
        }
      }()
      case 8: try {
        var v: String?
        try decoder.decodeSingularStringField(value: &v)
        if let v = v {
          if self.value != nil {try decoder.handleConflictingOneOf()}
          self.value = .string(v)
        }
      }()
      case 9: try { try decoder.decodeRepeatedMessageField(value: &self.deleteOperations) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.version != 0 {
      try visitor.visitSingularInt32Field(value: self.version, fieldNumber: 1)
    }
    if self.lamport != 0 {
      try visitor.visitSingularInt64Field(value: self.lamport, fieldNumber: 2)
    }
    if !self.peerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.peerID, fieldNumber: 3)
    }
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every case branch when no optimizations are
    // enabled. https://github.com/apple/swift-protobuf/issues/1034
    switch self.value {
    case .int?: try {
      guard case .int(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularInt64Field(value: v, fieldNumber: 4)
    }()
    case .float?: try {
      guard case .float(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularFloatField(value: v, fieldNumber: 5)
    }()
    case .date?: try {
      guard case .date(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularDoubleField(value: v, fieldNumber: 6)
    }()
    case .boolean?: try {
      guard case .boolean(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularBoolField(value: v, fieldNumber: 7)
    }()
    case .string?: try {
      guard case .string(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularStringField(value: v, fieldNumber: 8)
    }()
    case nil: break
    }
    if !self.deleteOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.deleteOperations, fieldNumber: 9)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoLWWOperation, rhs: ProtoLWWOperation) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.lamport != rhs.lamport {return false}
    if lhs.peerID != rhs.peerID {return false}
    if lhs.value != rhs.value {return false}
    if lhs.deleteOperations != rhs.deleteOperations {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProtoStringInsertOperation: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "StringInsertOperation"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "version"),
    2: .same(proto: "lamport"),
    3: .same(proto: "peerID"),
    4: .same(proto: "contribution"),
    5: .same(proto: "deleteOperations"),
    6: .same(proto: "stringInsertOperations"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.version) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.lamport) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.peerID) }()
      case 4: try { try decoder.decodeSingularStringField(value: &self.contribution) }()
      case 5: try { try decoder.decodeRepeatedMessageField(value: &self.deleteOperations) }()
      case 6: try { try decoder.decodeRepeatedMessageField(value: &self.stringInsertOperations) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.version != 0 {
      try visitor.visitSingularInt32Field(value: self.version, fieldNumber: 1)
    }
    if self.lamport != 0 {
      try visitor.visitSingularInt64Field(value: self.lamport, fieldNumber: 2)
    }
    if !self.peerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.peerID, fieldNumber: 3)
    }
    if !self.contribution.isEmpty {
      try visitor.visitSingularStringField(value: self.contribution, fieldNumber: 4)
    }
    if !self.deleteOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.deleteOperations, fieldNumber: 5)
    }
    if !self.stringInsertOperations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.stringInsertOperations, fieldNumber: 6)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoStringInsertOperation, rhs: ProtoStringInsertOperation) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.lamport != rhs.lamport {return false}
    if lhs.peerID != rhs.peerID {return false}
    if lhs.contribution != rhs.contribution {return false}
    if lhs.deleteOperations != rhs.deleteOperations {return false}
    if lhs.stringInsertOperations != rhs.stringInsertOperations {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProtoOperationsTree: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "OperationsTree"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "containerID"),
    2: .same(proto: "objectOperation"),
    3: .same(proto: "attributeOperation"),
    4: .same(proto: "deleteOperation"),
    5: .same(proto: "lwwOperation"),
    6: .same(proto: "stringInsertOperation"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._containerID) }()
      case 2: try {
        var v: ProtoObjectOperation?
        var hadOneofValue = false
        if let current = self.value {
          hadOneofValue = true
          if case .objectOperation(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.value = .objectOperation(v)
        }
      }()
      case 3: try {
        var v: ProtoAttributeOperation?
        var hadOneofValue = false
        if let current = self.value {
          hadOneofValue = true
          if case .attributeOperation(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.value = .attributeOperation(v)
        }
      }()
      case 4: try {
        var v: ProtoDeleteOperation?
        var hadOneofValue = false
        if let current = self.value {
          hadOneofValue = true
          if case .deleteOperation(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.value = .deleteOperation(v)
        }
      }()
      case 5: try {
        var v: ProtoLWWOperation?
        var hadOneofValue = false
        if let current = self.value {
          hadOneofValue = true
          if case .lwwOperation(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.value = .lwwOperation(v)
        }
      }()
      case 6: try {
        var v: ProtoStringInsertOperation?
        var hadOneofValue = false
        if let current = self.value {
          hadOneofValue = true
          if case .stringInsertOperation(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.value = .stringInsertOperation(v)
        }
      }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._containerID {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    }
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every case branch when no optimizations are
    // enabled. https://github.com/apple/swift-protobuf/issues/1034
    switch self.value {
    case .objectOperation?: try {
      guard case .objectOperation(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case .attributeOperation?: try {
      guard case .attributeOperation(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }()
    case .deleteOperation?: try {
      guard case .deleteOperation(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    }()
    case .lwwOperation?: try {
      guard case .lwwOperation(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    }()
    case .stringInsertOperation?: try {
      guard case .stringInsertOperation(let v)? = self.value else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoOperationsTree, rhs: ProtoOperationsTree) -> Bool {
    if lhs._containerID != rhs._containerID {return false}
    if lhs.value != rhs.value {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension ProtoOperationsForest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "OperationsForest"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "version"),
    2: .same(proto: "peerID"),
    3: .same(proto: "trees"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.version) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.peerID) }()
      case 3: try { try decoder.decodeRepeatedMessageField(value: &self.trees) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.version != 0 {
      try visitor.visitSingularInt32Field(value: self.version, fieldNumber: 1)
    }
    if !self.peerID.isEmpty {
      try visitor.visitSingularBytesField(value: self.peerID, fieldNumber: 2)
    }
    if !self.trees.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.trees, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: ProtoOperationsForest, rhs: ProtoOperationsForest) -> Bool {
    if lhs.version != rhs.version {return false}
    if lhs.peerID != rhs.peerID {return false}
    if lhs.trees != rhs.trees {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
