import Testing
@testable import LauncherKit

@Suite struct ExpressionEvaluatorTests {
    @Test func evaluatesBasicArithmetic() {
        #expect(ExpressionEvaluator.evaluate("2+2") == 4)
        #expect(ExpressionEvaluator.evaluate("10 * 3") == 30)
        #expect(ExpressionEvaluator.evaluate("100 / 4") == 25)
        #expect(ExpressionEvaluator.evaluate("7 - 9") == -2)
    }

    @Test func respectsPrecedenceAndParentheses() {
        #expect(ExpressionEvaluator.evaluate("2+3*4") == 14)
        #expect(ExpressionEvaluator.evaluate("(2+3)*4") == 20)
        #expect(ExpressionEvaluator.evaluate("-5 + 2") == -3)
        #expect(ExpressionEvaluator.evaluate("10 % 3") == 1)
    }

    @Test func decimalsWork() {
        #expect(ExpressionEvaluator.evaluate("0.5 * 4") == 2)
    }

    @Test func rejectsNonMath() {
        #expect(ExpressionEvaluator.evaluate("safari") == nil)
        #expect(ExpressionEvaluator.evaluate("") == nil)
        #expect(ExpressionEvaluator.evaluate("42") == nil)        // no operator → not a calc
        #expect(ExpressionEvaluator.evaluate("2 +") == nil)       // malformed
        #expect(ExpressionEvaluator.evaluate("5 / 0") == nil)     // div by zero
    }
}
