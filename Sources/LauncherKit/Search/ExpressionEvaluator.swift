import Foundation

/// A small, crash-safe arithmetic evaluator for the search-field calculator. Supports `+ - * /`,
/// parentheses, unary minus, decimals, and `%` (modulo). Pure recursive-descent — no NSExpression
/// (which can raise uncatchable ObjC exceptions on malformed input).
public enum ExpressionEvaluator {
    /// Returns the numeric result of a math expression, or nil if the input isn't one.
    public static func evaluate(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        // Must look like math: only allowed characters, at least one digit and one operator.
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/()% ")
        guard trimmed.unicodeScalars.allSatisfy(allowed.contains) else { return nil }
        guard trimmed.rangeOfCharacter(from: .decimalDigits) != nil,
              trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: "+-*/%")) != nil
        else { return nil }

        var parser = Parser(trimmed)
        guard let value = parser.parseExpression(), parser.isAtEnd, value.isFinite else { return nil }
        return value
    }

    /// Recursive-descent parser over the characters of the expression.
    private struct Parser {
        private let chars: [Character]
        private var index = 0

        init(_ string: String) { chars = Array(string) }

        var isAtEnd: Bool { peek() == nil }

        // expression := term (('+' | '-') term)*
        mutating func parseExpression() -> Double? {
            guard var value = parseTerm() else { return nil }
            while let op = peek(), op == "+" || op == "-" {
                advance()
                guard let rhs = parseTerm() else { return nil }
                value = (op == "+") ? value + rhs : value - rhs
            }
            return value
        }

        // term := factor (('*' | '/' | '%') factor)*
        private mutating func parseTerm() -> Double? {
            guard var value = parseFactor() else { return nil }
            while let op = peek(), op == "*" || op == "/" || op == "%" {
                advance()
                guard let rhs = parseFactor() else { return nil }
                switch op {
                case "*": value *= rhs
                case "/": guard rhs != 0 else { return nil }; value /= rhs
                default:  guard rhs != 0 else { return nil }; value = value.truncatingRemainder(dividingBy: rhs)
                }
            }
            return value
        }

        // factor := '-' factor | '(' expression ')' | number
        private mutating func parseFactor() -> Double? {
            skipSpaces()
            if peek() == "-" { advance(); guard let v = parseFactor() else { return nil }; return -v }
            if peek() == "(" {
                advance()
                guard let v = parseExpression() else { return nil }
                skipSpaces()
                guard peek() == ")" else { return nil }
                advance()
                return v
            }
            return parseNumber()
        }

        private mutating func parseNumber() -> Double? {
            skipSpaces()
            var digits = ""
            while let ch = peek(), ch.isNumber || ch == "." { digits.append(ch); advance() }
            return Double(digits)
        }

        private func peek() -> Character? {
            var i = index
            while i < chars.count, chars[i] == " " { i += 1 }
            return i < chars.count ? chars[i] : nil
        }

        private mutating func advance() {
            while index < chars.count, chars[index] == " " { index += 1 }
            if index < chars.count { index += 1 }
        }

        private mutating func skipSpaces() {
            while index < chars.count, chars[index] == " " { index += 1 }
        }
    }
}
