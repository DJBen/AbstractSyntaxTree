//
//  swift
//  AbstractSyntaxTreeTests
//
//  Created by Sihao Lu on 12/19/18.
//

import AbstractSyntaxTree
import XCTest

class AbstractSyntaxTreeTests: XCTestCase {
    func testChordSyntaxTree() {
        let cNode = ChordNode(fromString: "C")!
        XCTAssertEqual(cNode, ChordNode.withoutDegrees(NoteNode(natural: NaturalNode(token: "C", extraCaptureGroups: []), modifier: OptionalLeafNode<ModifierNode>.none), OptionalNonLeafNode<SlashDegreeNode>.none))
        let gbmin7 = ChordNode(fromString: "Gb:min7")!
        XCTAssertEqual(gbmin7, ChordNode.withShorthand(NoteNode(natural: NaturalNode(token: "G", extraCaptureGroups: []), modifier: OptionalLeafNode<ModifierNode>.some(ModifierNode(token: "b", extraCaptureGroups: []))), ShorthandNode(token: "min7", extraCaptureGroups: []), OptionalNonLeafNode<ParenthesizedDegreeListNode>.none, OptionalNonLeafNode<SlashDegreeNode>.none))
        let fbmaj7 = ChordNode(fromString: "F#:maj7")!
        XCTAssertEqual(fbmaj7, ChordNode.withShorthand(NoteNode(natural: NaturalNode(token: "F", extraCaptureGroups: []), modifier: OptionalLeafNode<ModifierNode>.some(ModifierNode(token: "#", extraCaptureGroups: []))), ShorthandNode(token: "maj7", extraCaptureGroups: []), OptionalNonLeafNode<ParenthesizedDegreeListNode>.none, OptionalNonLeafNode<SlashDegreeNode>.none))
        let dsus4b9 = ChordNode(fromString: "D:sus4(b9)")!
        XCTAssertEqual(dsus4b9, ChordNode.withShorthand(
            NoteNode(natural: NaturalNode(token: "D", extraCaptureGroups: []),
                     modifier: OptionalLeafNode<ModifierNode>.none),
            ShorthandNode(token: "sus4", extraCaptureGroups: []),
            OptionalNonLeafNode<ParenthesizedDegreeListNode>.some(
                ParenthesizedDegreeListNode(node:
                    DegreeListNode(degree:
                        DegreeNode(
                            modifier: OptionalLeafNode<ModifierNode>.some(ModifierNode(token: "b", extraCaptureGroups: [])),
                            interval: IntervalNode(token: "9", extraCaptureGroups: [])
                )))
            ),
            OptionalNonLeafNode<SlashDegreeNode>.none
        ))
        let cFlat3Flat7Flat11 = ChordNode(fromString: "C:(b3,b7,11)")
        let innerDegreeListNode = DegreeListNode(
            star: OptionalLeafNode<StarNode>.none,
            degree: DegreeNode(
                modifier: OptionalLeafNode<ModifierNode>.some(ModifierNode(token: "b", extraCaptureGroups: [])),
                interval: IntervalNode(token: "3", extraCaptureGroups: [])
            ),
            concatenatedDegreeList: OptionalNonLeafNode<ConcatenatedDegreeListNode>.some(
                ConcatenatedDegreeListNode(node: DegreeListNode(
                    star: OptionalLeafNode<StarNode>.none,
                    degree: DegreeNode(
                        modifier: OptionalLeafNode<ModifierNode>.some(ModifierNode(token: "b", extraCaptureGroups: [])),
                        interval: IntervalNode(token: "7", extraCaptureGroups: [])
                    ),
                    concatenatedDegreeList: OptionalNonLeafNode<ConcatenatedDegreeListNode>.some(
                        ConcatenatedDegreeListNode(node: DegreeListNode(
                            star: OptionalLeafNode<StarNode>.none,
                            degree: DegreeNode(modifier: OptionalLeafNode<ModifierNode>.none, interval: IntervalNode(token: "11", extraCaptureGroups: [])),
                            concatenatedDegreeList: OptionalNonLeafNode<ConcatenatedDegreeListNode>.none
                        ))
                    )
                ))
            )
        )
        XCTAssertEqual(cFlat3Flat7Flat11, ChordNode.noShorthand(
            NoteNode(natural: NaturalNode(token: "C", extraCaptureGroups: []), modifier: OptionalLeafNode<ModifierNode>.none),
            OptionalNonLeafNode<ParenthesizedDegreeListNode>.some(
                ParenthesizedDegreeListNode(node: innerDegreeListNode)
            ),
            OptionalNonLeafNode<SlashDegreeNode>.none
        ))
        let ebWithSlashDegree = ChordNode(fromString: "Eb:7/3")
        XCTAssertEqual(ebWithSlashDegree, ChordNode.withShorthand(
            NoteNode(natural: NaturalNode(token: "E", extraCaptureGroups: []),
                     modifier: OptionalLeafNode<ModifierNode>.some(ModifierNode(token: "b", extraCaptureGroups: []))),
            ShorthandNode(token: "7", extraCaptureGroups: []), OptionalNonLeafNode<ParenthesizedDegreeListNode>.none, OptionalNonLeafNode<SlashDegreeNode>.some(
                SlashDegreeNode(node:
                    DegreeNode(modifier: OptionalLeafNode<ModifierNode>.none,
                               interval: IntervalNode(token: "3", extraCaptureGroups: [])))
            )
        ))
    }

    func testTokenLength() {
        let rule: [ProductionRuleComponent] = [.token("(xx"), .nonLeaf(ChordNode.self), .leaf(ModifierNode.self), .token("xm")]
        XCTAssertEqual(rule.tokenLength, 5)
    }
}
