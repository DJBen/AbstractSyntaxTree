Pod::Spec.new do |s|
  s.name         = "AbstractSyntaxTree"
  s.version      = "0.1.0"
  s.summary      = "AbstractSyntaxTree provides strongly typed AST modeling in Swift."

  s.description  = <<-DESC
    It provides the building blocks for grammar rules in Backus-Naur form (BNF) and a recursive descent parser as an extension to each node.
    We can then utilize the advantages of Swift struct and enum types to model complex grammar rules.
  DESC

  s.homepage     = "https://github.com/DJBen/AbstractSyntaxTree"
  s.license      = "MIT"
  s.author       = { "Ben Lu" => "lsh32768@gmail.com" }

  s.swift_version = '4.2'
  
  s.ios.deployment_target = "12.0"
  s.osx.deployment_target = "10.13"
  s.watchos.deployment_target = "5.0"
  s.tvos.deployment_target = "12.0"

  s.source       = { :git => "https://github.com/DJBen/AbstractSyntaxTree.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/*.swift"

  s.framework  = "Foundation"

  s.requires_arc = true
end
