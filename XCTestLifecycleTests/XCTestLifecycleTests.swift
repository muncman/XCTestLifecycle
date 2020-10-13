//
//  XCTestLifecycleTests.swift
//  XCTestLifecycleTests
//
//  Created by Kevin Munc on 10/09/2020.
//

// See also: https://github.com/apple/swift-corelibs-xctest/blob/main/Sources/XCTest/Public/XCTestCase.swift

// `XCTestCase` extends `XCTest`.
import XCTest
@testable import XCTestLifecycle

enum DemoError: Error {
    case somethingToThrow
}

// A simple example of making a custom assertion.
// But this is really just here for Steve Madsen. ;)
extension XCTestCase {
    func expect<T>(_ actual: T,
                   toEq expected: T,
                   message: String = "",
                   file: StaticString = #file,
                   method: StaticString = #function,
                   line: UInt = #line) where T: Equatable {
        XCTAssertEqual(actual, expected, "\(message) Method: \(method)", file: file, line: line)
    }
}

/// This is my test case.
/// There are many like it, but this one is mine.
class XCTestLifecycleTests: XCTestCase {

    /* Abandoned way to control which-tests-run-when for presentation purposes.
     private let DEMO_STEP = 12
     try XCTSkipIf(DEMO_STEP < 20)
     try XCTSkipUnless(DEMO_STEP > 15)
     Another approach considered was to use MARK comments for each step...
     */

    // This is the designated initializer of XCTestCase.
    // Cannot use without Objective-C, since `NSInvocation` is not available in Swift.
    // Other initializers are unavailable as a result.
    /*override init(invocation: NSInvocation?) {
        super.init(invocation: invocation)
        print("init with invocation: \(invocation)")
    }*/

    // Use `setUp` and `tearDown` even if you think "everything will go away when the test is over."
    // Behind the scenes, objects will stay around for the duration of the entire test suite
    // since the test cases are not individually deinitialized.
    deinit {
        print("deinit: you'll never see me in the output; so use setUp and tearDown to avoid memory build up")
    }

    // MARK: From XCTest

    override func run() {
        print("ℹ️ ==> run")
        super.run()
    }

    override func perform(_ run: XCTestRun) {
        print("ℹ️ ==> perform with: \(run)")
        super.perform(run)
    }

    // MARK: From XCTestCase

    override class var defaultTestSuite: XCTestSuite {
        print("ℹ️ ==> defaultTestSuite")
        return super.defaultTestSuite
    }

    override func invokeTest() {
        print("ℹ️ ==> invokeTest")
        super.invokeTest()
    }

    override func record(_ issue: XCTIssue) {
        print("ℹ️ ==> record issue: \(issue)")
        super.record(issue)
    }

    // MARK: - Lifecycle Methods

    // You cannot have assertions here, as they require a test class instance.
    override class func setUp() {
        super.setUp()
        print("✳️ \t==> class-level setUp")
    }

    // You cannot have assertions here, as that requires a test class instance.
    override class func tearDown() {
        print("✳️ \t==> class-level tearDown")
        super.tearDown()
    }

    // Note that the `super` calls for the set up and tear down methods invoke empty template method implementations.
    // But they are still recommended, as for all overridden methods.
    override func setUp() {
        super.setUp()
        print("✳️ \t\t\t==> setUp")
        XCTAssertTrue(true)
    }

    override func tearDown() {
        print("✳️ \t\t\t==> tearDown")
        super.tearDown()
    }

    // Showed up in Xcode 11.4, which also added `throws` to example test methods.
    // If an error is thrown here, the wrapped test method is skipped.
    override func setUpWithError() throws {
        try super.setUpWithError()
        print("✳️ \t\t==> setUpWithError")
    }

    // Clean up or undo instantiated objects, injected dependencies, data stores,
    // user defaults, keychain, files, swizzled methods, etc.
    override func tearDownWithError() throws {
        print("✳️ \t\t==> tearDownWithError")
        try super.tearDownWithError()
    }

    // MARK: - Test Methods

    // Note that this _does_ declare that it throws...
    func testAddition() throws {
        print("More info you can access withing test methods:")
        print("Test Name: \(name)")
        print("Test Case Count: \(testCaseCount)")
        print("Test Run: \(String(describing: testRun))")
        print("Test Run Class: \(String(describing: testRunClass))")
        print("✳️ \t\t\t\t----> TEST: testAddition")
        expect(1 + 1, toEq: 2)
    }

    // Note that this does _not_ declare that it throws...
    func testSubtraction() throws {
        print("Test Name: \(name)")
        print("✳️ \t\t\t\t----> TEST: testSubtraction")
        expect(3 - 1, toEq: 2)
    }

    // Teardown blocks cannot (re)throw errors that arise within their execution,
    // even if the test method they are in declares that it throws.
    func testWithSingleTeardownBlock() throws {
        print("✳️ \t\t\t\t----> TEST: testWithSingleTeardownBlock")
        XCTAssertTrue(true)
        addTeardownBlock {
            print("✳️ \t\t\t\t----> TEST: testWithSingleTeardownBlock's teardown block")
        }
    }

}

// MARK: - Tests that *intentionally* fail

extension XCTestLifecycleTests {

    func testWhichDoesNOTDeclareThatItThrows_butDoes() {
        print("✳️ \t\t\t\t----> TEST: testWhichDoesNOTDeclareThatItThrows")
        XCTAssertTrue(true)
        // This method does not declare that it throws, so we need to do more work here.
        do {
            throw DemoError.somethingToThrow
        } catch {
            XCTFail("Got an 'unexpected' expected error: \(error)")
        }
    }

    // Teardown blocks are executed even when errors are thrown.
    func testWithSingleTeardownBlockAndException() throws {
        print("✳️ \t\t\t\t----> TEST: testWithSingleTeardownBlockAndException")
        XCTAssertTrue(false, "Supposed to fail.")
        addTeardownBlock {
            print("✳️ \t\t\t\t----> TEST: testWithSingleTeardownBlockAndException's teardown block")
        }
        throw DemoError.somethingToThrow
    }

    // Teardown blocks are executed LIFO (like `defer`)
    func testWithMultipleTeardownBlocks() throws {
        print("✳️ \t\t\t\t----> TEST: testWithMultipleTeardownBlocks")
        XCTAssertTrue(true)
        addTeardownBlock {
            XCTAssertFalse(false)
            print("✳️ \t\t\t\t----> TEST: testWithMultipleTeardownBlocks FIRST teardown block")
        }
        XCTAssertFalse(false)
        addTeardownBlock {
            XCTAssertTrue(false, "Supposed to fail.")
            print("✳️ \t\t\t\t----> TEST: testWithMultipleTeardownBlocks SECOND teardown block")
        }
        XCTAssertTrue(true)
        addTeardownBlock {
            print("✳️ \t\t\t\t----> TEST: testWithMultipleTeardownBlocks THIRD teardown block")
            // Nope: throw DemoError.somethingToThrow
        }
        XCTAssertFalse(false)
    }

}

// For monitoring the overall test execution process.
// Can be used for reporting or logging.
// All methods are optional on this protocol.
public class DemoTestObserver: NSObject, XCTestObservation {

    // Add entry in test target's Info.plist under key `NSPrincipalClass`/`Principal class`
    // with value `$(PRODUCT_NAME).DemoTestObserver`.
    override init() {
        super.init()
        print("⚛️  Observer: init")
        XCTestObservationCenter.shared.addTestObserver(self)
        // You can add multiple observers: XCTestObservationCenter.shared.addTestObserver(self)
        // `removeTestObserver` also exists to remove the observer mid-session.
    }

    // MARK: Bundle-Level

    public func testBundleWillStart(_ testBundle: Bundle) {
        print("⚛️  Observer: testBundleWillStart with bundle: \(testBundle)")
    }

    public func testBundleDidFinish(_ testBundle: Bundle) {
        print("⚛️  Observer: testBundleDidFinish with bundle: \(testBundle)")
    }

    // MARK: TestSuite-Level

    // Notice that this is invoked multiple times for a single suite.
    public func testSuiteWillStart(_ testSuite: XCTestSuite) {
        print("⚛️  Observer: testSuiteWillStart with suite: \(testSuite)")
    }

    // Notice that this is invoked multiple times for a single suite.
    public func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        print("⚛️  Observer: testSuiteDidFinish with suite: \(testSuite)")
    }

    // Why not seeing this one?
    public func testSuite(_ testSuite: XCTestSuite, didRecord issue: XCTIssue) {
        print("⚛️  Observer: test suite did record issue with suite: \(testSuite)")
    }

    public func testSuite(_ testSuite: XCTestSuite,
                          didFailWithDescription description: String,
                          inFile filePath: String?,
                          atLine lineNumber: Int) {
        print("⚛️  Observer: didFailWithDescription with test suite: \(testSuite), " +
                "description: \(description), at line: \(lineNumber)")
    }

    // MARK: TestCase-Level

    // This is called for every test method.
    public func testCaseWillStart(_ testCase: XCTestCase) {
        print("⚛️  Observer: testCaseWillStart with case: \(testCase)")
    }

    // This is called for every test method.
    public func testCaseDidFinish(_ testCase: XCTestCase) {
        print("⚛️  Observer: testCaseDidFinish with case: \(testCase)")
    }

    public func testCase(_ testCase: XCTestCase, didRecord issue: XCTIssue) {
        print("⚛️  Observer: test case did record issue with case: \(testCase)")
    }

    public func testCase(_ testCase: XCTestCase,
                         didFailWithDescription description: String,
                         inFile filePath: String?,
                         atLine lineNumber: Int) {
        print("⚛️  Observer: didFailWithDescription with test case: \(testCase), " +
                "description: \(description), at line: \(lineNumber)")
    }

}
