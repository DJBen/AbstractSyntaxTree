//
//  AbstractSyntaxTree.swift
//  AbstractSyntaxTree
//
//  Created by Sihao Lu on 12/19/18.
//

import Foundation

public protocol Node {}

public protocol NonLeafNode: Node {
    static var productionRules: [[ProductionRuleComponent]] { get }
    var length: Int { get }
    init(parsedNodes: [Node], productionRule: [ProductionRuleComponent])
}

public protocol LeafNode: Node {
    /**
     * A regex to capture the leaf node.
     *
     * The regex can have any number of capture groups. The capture group 0 (the full string) is always propagated to the `token` property.
     * Extra capture groups (starting from index 1) are propagated to `extraCaptureGroups` property.
     */
    static var regex: String { get }
    var token: String { get }
    var extraCaptureGroups: [String] { get }
    init(token: String, extraCaptureGroups: [String])
}

public enum ProductionRuleComponent {
    case token(String)
    case nonLeaf(NonLeafNode.Type)
    case leaf(LeafNode.Type)
}

extension LeafNode {
    public init?(fromString string: String) {
        let regex = try! NSRegularExpression(pattern: "^(?:\(Self.regex))", options: [])
        guard let match = regex.firstMatch(in: string, options: [], range: NSRange(0 ..< string.count)),
            let range = Range(match.range(at: 0), in: string) else {
            return nil
        }
        self.init(token: String(string[range]), extraCaptureGroups: (1 ..< match.numberOfRanges).map { (rangeIndex) -> String in
            String(string[Range(match.range(at: rangeIndex), in: string)!])
        })
    }
}

extension NonLeafNode {
    public init?(fromString string: String) {
        for productionRule in Self.productionRules {
            var parsedNodes = [Node]()
            var unmatchedString = string
            var satisfyRule = true
            productionRuleChecks: for element in productionRule {
                switch element {
                case let .token(token):
                    let tokenLength = token.count
                    guard tokenLength <= unmatchedString.count,
                        unmatchedString[..<unmatchedString.index(unmatchedString.startIndex, offsetBy: tokenLength)] == token else {
                        satisfyRule = false
                        break productionRuleChecks
                    }
                    unmatchedString = String(unmatchedString[unmatchedString.index(unmatchedString.startIndex, offsetBy: tokenLength)...])
                case let .leaf(terminalClass):
                    if let terminalNode = terminalClass.init(fromString: unmatchedString) {
                        unmatchedString = String(unmatchedString[unmatchedString.index(unmatchedString.startIndex, offsetBy: terminalNode.token.count)...])
                        parsedNodes.append(terminalNode)
                    } else {
                        satisfyRule = false
                        break productionRuleChecks
                    }
                case let .nonLeaf(nonTerminalClass):
                    if let nonTerminalNode = nonTerminalClass.init(fromString: unmatchedString) {
                        unmatchedString = String(unmatchedString[unmatchedString.index(unmatchedString.startIndex, offsetBy: nonTerminalNode.length)...])
                        parsedNodes.append(nonTerminalNode)
                    } else {
                        satisfyRule = false
                        break productionRuleChecks
                    }
                }
            }
            if satisfyRule {
                self.init(parsedNodes: parsedNodes, productionRule: productionRule)
                return
            }
        }
        return nil
    }
}

public enum OptionalLeafNode<InnerNode: LeafNode & Equatable>: NonLeafNode, Equatable {
    public static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.leaf(InnerNode.self)],
            [.token("")],
        ]
    }

    case none
    indirect case some(InnerNode)

    public var length: Int {
        switch self {
        case let .some(node):
            return node.token.count
        case .none:
            return 0
        }
    }

    public init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        if parsedNodes.count == 1, let node = parsedNodes.first as? InnerNode {
            self = .some(node)
        } else if parsedNodes.isEmpty {
            self = .none
        } else {
            fatalError("Type or number of parsed notes do not match production rules")
        }
    }
}

public enum OptionalNonLeafNode<InnerNode: NonLeafNode & Equatable>: NonLeafNode, Equatable {
    public static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.nonLeaf(InnerNode.self)],
            [.token("")],
        ]
    }

    case none
    indirect case some(InnerNode)

    public var length: Int {
        switch self {
        case let .some(node):
            return node.length
        case .none:
            return 0
        }
    }

    public init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        if parsedNodes.count == 1, let node = parsedNodes.first as? InnerNode {
            self = .some(node)
        } else if parsedNodes.isEmpty {
            self = .none
        } else {
            fatalError("Type or number of parsed notes do not match production rules")
        }
    }
}

extension Array where Element == ProductionRuleComponent {
    public var tokenLength: Int {
        return map { (component) -> Int in
            if case let .token(token) = component {
                return token.count
            } else {
                return 0
            }
        }.reduce(0, +)
    }
}
