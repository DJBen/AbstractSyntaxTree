[![Build Status](https://travis-ci.com/DJBen/AbstractSyntaxTree.svg?branch=master)](https://travis-ci.com/DJBen/AbstractSyntaxTree)
[![Swift 4.2](https://img.shields.io/badge/swift-4.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)


## What is this?
AbstractSyntaxTree provides strongly typed AST modeling in Swift.

It provides the building blocks for grammar rules in [Backus-Naur form (BNF)](https://en.wikipedia.org/wiki/Backus–Naur_form) and a [recursive descent parser](https://en.wikipedia.org/wiki/Recursive_descent_parser) as an extension to each node.

We can then utilize the advantages of Swift struct and enum types to model complex grammar rules.

## How does it work?

### Terminology
- **Terminal symbols** are literal symbols which may appear in the outputs of the production rules of a formal grammar and which cannot be changed using the rules of the grammar.
- **Nonterminal symbols** are those symbols which can be replaced.
- A grammar is defined by **production rules** that specify which symbols may replace which other symbols.

Read more in [Terminal and Nonterminal symbols wiki](https://en.wikipedia.org/wiki/Terminal_and_nonterminal_symbols).

In this project, we introduce another two concepts:

- **Leaf** nodes are nodes whose yields are entirely terminal nodes. For example, `<grade> = A|B|C|F` yields terminal `A`, `B`, `C` or `F`.
- **Non-leaf** nodes are nodes that yields leaf nodes, non-leaf nodes or both with optional terminals. For example, `<grade-plus> = <grade> +` includes leaf node `grade` and a terminal `+`, thus it is a non-leaf node.

### AST Modeling

#### Leaf Nodes

To model the leaf nodes, create a struct that conforms to `LeafNode` and provide a regex pattern that captures the terminal symbols. The regex pattern can have as many capture groups as you wish; the first capture group (group 0) is always the full string, which is propagated to `token` property. Extra capture groups (starting from group 1) are sent into `extraCaptureGroups` property for more flexible use case.

Consider the following grammar rule in Backus-Naur form:

 ```
 <alpha-numeric> ::= \w+
```
This rule captures alphanumeric tokens, which can be represented in the following Swift struct.

```swift
struct AlphaNumericNode: LeafNode, Equatable {
    static let regex = "(\\w+)"

    let token: String
    let extraCaptureGroups: [String]
}
```
Note that to make the regex pattern has one capture group, we surround the token with parentheses.

#### Non-leaf Nodes

To model a non-leaf node, you need to provide

- Production rules
- The length of the tokens
- Initializer method from parsed nodes

##### Production Rules
```swift
public enum ProductionRuleComponent {
    case token(String)
    case nonLeaf(NonLeafNode.Type)
    case leaf(LeafNode.Type)
}

// Inside NonLeafNode protocol
static var productionRules: [[ProductionRuleComponent]]
```

Production rules are arrays of individual production rule, within which each element is either a string literal token, a leaf node type or a non-leaf node type.

If there are alternations `"|"` in the rule, write each subrule in a separate production rule array.

```
<something> ::= "xy" <alpha-numeric> <something> | <alpha-numeric>
```
For example, the above grammar rule can be modeled as

```swift
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [ .token("xy"), .leaf(AlphaNumericNode.self), .nonLeaf(Something.self)],
            [.leaf(AlphaNumericNode.self)]
        ]
    }
```
##### Optional Wrapping

This project provides convenient wrappers for optional leaf and non-leaf nodes, corresponding to the `[]` notation in extended Backus-Naur form.

```
<shining> ::= "All work and no play makes Jack a dull boy\n" [<shining>]
```
This grammar generates the proverb with the option to recursively generate another one concatenated to it.

Its production rule is thus
```swift
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [ .token("All work and no play makes Jack a dull boy\n"), .nonLeaf(OptionalNonLeafNode<ShiningNode>.self)]
        ]
    }
```

### Pitfalls

#### Left Recursion

Due to the nature of recursive descent parser, [left recursion](https://en.wikipedia.org/wiki/Left_recursion) will lead to infinite recursion.

Basically, any form of `<A> ::= <A> a1 a2 | a3` that the first symbol on the right is the symbol of the rule that is being defined is prohibited.

To eliminate left recursion, you can rewrite the above rule into an equivalent right recursion form.
```
<A>  ::= a3 <A'>
<A'> ::= a1 a2 | ε
```

Follow the wiki to read more.

### Another Example

Consider the following grammar rule in Backus-Naur form:
 ```
 <names> ::= "(" <alpha-numeric> ["," <names>] ")" | "Empty"  
```
where `alpha-numeric` is a defined as `AlphaNumericNode` in previous example.

Here it matches `(name)`, `(name,name2,nameblahblah3)` and `Empty` but not `noparens`, `(extracomma,)` or `(invlid-hyphen)`.

It can be represented in the following Swift code.

```swift
struct ConcatNamesNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [ .token(","), .leaf(NamesNode.self)]
        ]
    }

    let names: NamesNode

    var length: Int { 
        return names.length 
    }

    init(parsedNodes: [Node], productionRule: [ProductionRuleComponent]) {
        precondition(parsedNodes.count == 1)
        self.names = parsedNodes[0] as! NamesNode
    }
}

enum NamesNode: NonLeafNode, Equatable {
    static var productionRules: [[ProductionRuleComponent]] {
        return [
            [ .token("("), .leaf(AlphaNumericNode.self), .nonLeaf(OptionalNonLeafNode<ConcatNamesNode>.self), .token(")")],
            ["Empty"]
        ]
    }

    case nameAndConcatNames(name: AlphaNumericNode, concatNames: OptionalNonLeafNode<ConcatNamesNode>)
    case empty

    var length: Int {
        return name.token.count + concatNames.length
    }

    init(parsedNodes: [Node], productionRule: [ProductionRuleComponent]) {
        if parsedNodes.count == 2, let name = parsedNodes[0] as? AlphaNumericNode, let concatNames = parsedNodes[1] as? OptionalNonLeafNode<ConcatNamesNode> {
            self = .nameAndConcatNames(name, concatNames)
        } else if parsedNodes.isEmpty {
            self = .empty
        } else {
            fatalError()
        }
    }
}
```

To parse the string as abstract syntax tree, simply call `<NodeClass>.init(fromString:)`. You can call this method on any leaf or non-leaf nodes, giving you immense flexibility.
