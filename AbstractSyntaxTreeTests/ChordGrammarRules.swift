//
//  ChordSyntaxRules.swift
//  AbstractSyntaxTreeTests
//
//  Created by Sihao Lu on 12/29/18.
//

// swiftformat:disable all
/*
 SYMBOLIC REPRESENTATION OF MUSICAL CHORDS: A PROPOSED SYNTAX FOR TEXT ANNOTATIONS
 Reference: http://ismir2005.ismir.net/proceedings/1080.pdf
 With slight modifications.

 Syntax of Chord Notation in Backus-Naur Form:
 <chord>        ::= <note> ":" <shorthand> ["("<degree-list>")"]["/"<degree>] |
                    <note> ":" "("<degree-list>")" ["/"<degree>] |
                    <note> ["/"<degree>] |
                    "N"
 <note>         ::= <natural> [<modifier>]
 <natural>      ::= A|B|C|D|E|F|G
 <modifier>     ::= bb|##|b|#|x
 <degree-list>  ::= ["*"] <degree> ["," <degree-list>]
 <degree>       ::= [<modifier>] <interval>
 <interval>     ::= 1|2|3|4|5|6|7|8|9|10|11|12|13
 <shorthand>    ::= maj|min|dim|aug|maj7|min7|7|dim7|hdim7|minmaj7|maj6|min6|9|maj9|min9|sus2|sus4
 */
// swiftformat:enable all

import AbstractSyntaxTree
import Foundation

struct NaturalNode: LeafNode, Equatable {
    static let regex = "[A-Ga-g]"

    let token: String
    let extraCaptureGroups: [String]
}

struct ModifierNode: LeafNode, Equatable {
    static let regex = "(?:bb|b|♭♭|♭|##|#|♯♯|♯)|x"

    let token: String
    let extraCaptureGroups: [String]
}

struct IntervalNode: LeafNode, Equatable {
    static let regex = "1[0-3]|[1-9]"

    let token: String
    let extraCaptureGroups: [String]
}

struct ShorthandNode: LeafNode, Equatable {
    static let regex = "maj7|min7|7|dim7|hdim7|minmaj7|maj6|min6|9|maj9|min9|sus2|sus4|maj|min|dim|aug"

    let token: String
    let extraCaptureGroups: [String]
}

struct StarNode: LeafNode, Equatable {
    static let regex = "\\*"

    let token: String
    let extraCaptureGroups: [String]
}

struct DegreeNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.nonLeaf(OptionalLeafNode<ModifierNode>.self), .leaf(IntervalNode.self)],
        ]
    }

    let modifier: OptionalLeafNode<ModifierNode>
    let interval: IntervalNode

    var length: Int {
        return modifier.length + interval.token.count
    }

    init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        if parsedNodes.count == 2, let modifier = parsedNodes[0] as? OptionalLeafNode<ModifierNode>, let interval = parsedNodes[1] as? IntervalNode {
            self.modifier = modifier
            self.interval = interval
        } else {
            fatalError()
        }
    }

    init(modifier: OptionalLeafNode<ModifierNode>, interval: IntervalNode) {
        self.modifier = modifier
        self.interval = interval
    }
}

struct SlashDegreeNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.token("/"), .nonLeaf(DegreeNode.self)],
        ]
    }

    let node: DegreeNode

    var length: Int {
        return node.length + 1
    }

    init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        node = parsedNodes[0] as! DegreeNode
    }

    init(node: DegreeNode) {
        self.node = node
    }
}

struct DegreeListNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.nonLeaf(OptionalLeafNode<StarNode>.self), .nonLeaf(DegreeNode.self), .nonLeaf(OptionalNonLeafNode<ConcatenatedDegreeListNode>.self)],
        ]
    }

    let star: OptionalLeafNode<StarNode>
    let degree: DegreeNode
    let concatenatedDegreeList: OptionalNonLeafNode<ConcatenatedDegreeListNode>

    var length: Int {
        return star.length + degree.length + concatenatedDegreeList.length
    }

    init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        star = parsedNodes[0] as! OptionalLeafNode<StarNode>
        degree = parsedNodes[1] as! DegreeNode
        concatenatedDegreeList = parsedNodes[2] as! OptionalNonLeafNode<ConcatenatedDegreeListNode>
    }

    init(star: OptionalLeafNode<StarNode> = .none, degree: DegreeNode, concatenatedDegreeList: OptionalNonLeafNode<ConcatenatedDegreeListNode> = .none) {
        self.star = star
        self.degree = degree
        self.concatenatedDegreeList = concatenatedDegreeList
    }
}

struct ConcatenatedDegreeListNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.token(","), .nonLeaf(DegreeListNode.self)],
        ]
    }

    let node: DegreeListNode

    var length: Int {
        return 1 + node.length
    }

    init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        node = parsedNodes[0] as! DegreeListNode
    }

    init(node: DegreeListNode) {
        self.node = node
    }
}

struct ParenthesizedDegreeListNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.token("("), .nonLeaf(DegreeListNode.self), .token(")")],
        ]
    }

    let node: DegreeListNode

    var length: Int {
        return node.length + 2
    }

    init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        node = parsedNodes[0] as! DegreeListNode
    }

    init(node: DegreeListNode) {
        self.node = node
    }
}

struct NoteNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.leaf(NaturalNode.self), .nonLeaf(OptionalLeafNode<ModifierNode>.self)],
        ]
    }

    let natural: NaturalNode
    let modifier: OptionalLeafNode<ModifierNode>

    var length: Int {
        return natural.token.count + modifier.length
    }

    init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        if parsedNodes.count == 2, let naturalNode = parsedNodes[0] as? NaturalNode, let modifierNode = parsedNodes[1] as? OptionalLeafNode<ModifierNode> {
            natural = naturalNode
            modifier = modifierNode
        } else {
            fatalError()
        }
    }

    init(natural: NaturalNode, modifier: OptionalLeafNode<ModifierNode>) {
        self.natural = natural
        self.modifier = modifier
    }
}

enum ChordNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [.nonLeaf(NoteNode.self), .token(":"), .leaf(ShorthandNode.self), .nonLeaf(OptionalNonLeafNode<ParenthesizedDegreeListNode>.self), .nonLeaf(OptionalNonLeafNode<SlashDegreeNode>.self)],
            [.nonLeaf(NoteNode.self), .token(":"), .nonLeaf(OptionalNonLeafNode<ParenthesizedDegreeListNode>.self), .nonLeaf(OptionalNonLeafNode<SlashDegreeNode>.self)],
            [.nonLeaf(NoteNode.self), .nonLeaf(OptionalNonLeafNode<SlashDegreeNode>.self)],
            [.token("N")],
        ]
    }

    indirect case withShorthand(NoteNode, ShorthandNode, OptionalNonLeafNode<ParenthesizedDegreeListNode>, OptionalNonLeafNode<SlashDegreeNode>)
    indirect case noShorthand(NoteNode, OptionalNonLeafNode<ParenthesizedDegreeListNode>, OptionalNonLeafNode<SlashDegreeNode>)
    indirect case withoutDegrees(NoteNode, OptionalNonLeafNode<SlashDegreeNode>)
    case neopolitan

    var length: Int {
        switch self {
        case let .withShorthand(noteNode, shorthandNode, parensDegreeListNode, slashDegreeNode):
            return noteNode.length + 1 + shorthandNode.token.count + parensDegreeListNode.length + slashDegreeNode.length
        case let .noShorthand(noteNode, parensDegreeListNode, slashDegreeNode):
            return noteNode.length + 1 + parensDegreeListNode.length + slashDegreeNode.length
        case let .withoutDegrees(noteNode, slashDegreeNode):
            return noteNode.length + slashDegreeNode.length
        case .neopolitan:
            return 1
        }
    }

    init(parsedNodes: [Node], productionRule _: [ProductionRuleComponent]) {
        if parsedNodes.count == 4, let noteNode = parsedNodes[0] as? NoteNode, let shorthandNode = parsedNodes[1] as? ShorthandNode, let parensDegreeListNode = parsedNodes[2] as? OptionalNonLeafNode<ParenthesizedDegreeListNode>, let slashDegreeNode = parsedNodes[3] as? OptionalNonLeafNode<SlashDegreeNode> {
            self = .withShorthand(noteNode, shorthandNode, parensDegreeListNode, slashDegreeNode)
        } else if parsedNodes.count == 3, let noteNode = parsedNodes[0] as? NoteNode, let parensDegreeListNode = parsedNodes[1] as? OptionalNonLeafNode<ParenthesizedDegreeListNode>, let slashDegreeNode = parsedNodes[2]
            as? OptionalNonLeafNode<SlashDegreeNode> {
            self = .noShorthand(noteNode, parensDegreeListNode, slashDegreeNode)
        } else if parsedNodes.count == 2, let noteNode = parsedNodes[0] as? NoteNode, let slashDegreeNode = parsedNodes[1]
            as? OptionalNonLeafNode<SlashDegreeNode> {
            self = .withoutDegrees(noteNode, slashDegreeNode)
        } else if parsedNodes.count == 1, parsedNodes[0] is String {
            self = .neopolitan
        } else {
            fatalError()
        }
    }
}
