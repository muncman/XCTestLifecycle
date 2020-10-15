Theme: notes
Palette: Green
Size: Wide

---
Layout: SectionTitle
# < This slide left intentionally blank />

---
Layout: SectionTitle
# ColdFusion + VBScript

## Leveraging our favorite tools for cross✻-platform development

_Coming soon:_ COBOL and Fortran connectors, dBase integration, and Rexx scripting!

_✻ Cross:
(adjective) annoyed: they seemed to be very cross about something._

---
Layout: SectionTitle
# ~~ColdFusion + VBScript~~

## ~~Leveraging our favorite tools for cross✻-platform development~~

~~_Coming soon:_ COBOL and Fortran connectors, dBase integration, and Rexx scripting!~~

### No offense to these technologies!

---
Layout: SectionTitle
# Getting to Know the XCTest Lifecycle

---
You write tests, right? 

_Right...?_ 

😅

^ In this talk, we'll take a look at some of the nooks and crannies of XCTest, so that next time we write a test we'll be more familiar with what's happening around our assertions.
^ A couple dozen slides, fewer than ten test methods, and a code demo!

---
Layout: SectionTitle
# What happens _around_ our test methods and assertions?

^ Let's look at an XCTestCase.

---
Layout: SectionTitle

The Bare Essentials of an XCTestCase

```
class XCTestLifecycleTests: XCTestCase {

    // What happens before this runs? 
    // After? 
    func testAddition() throws {
        XCTAssertEqual(1 + 1, 2)
    }

}
```

---
# The Workhorses

```
    override func setUp() {
        super.setUp()
        // Prepare test harness here...
    }

    override func tearDown() {
        // Clean up test harness / environment here...
        super.tearDown()
    }
```

- `setUp` runs before **each** test method
- `tearDown` runs after **each** test method
- You _can_ make assertions in these, too

^ Everyone knows these... 
^ This is where you instantiate, prepare, and clean up your test harness.
^ TODO: more notes here! 

---
# The New(er/ish) Kids

```
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Prepare test harness here...
    }

    override func tearDownWithError() throws {
        // Clean up test harness / environment here...
        try super.tearDownWithError()
    }
```

- Since Xcode 11.4
- These do the same, but allow for actions that might throw an Error
- This results in cleaner Swift code when you need to work with errors here
- Xcode's template also shows the example test methods with `throws`

^ ...since you can skip having to catch any errors and explicitly fail the test yourself
^ instead of blowing up or not compiling

---
Layout: SectionTitle
# These look similar, but...

```
    override class func setUp() {
        super.setUp()
        // Prepare test harness here...
    }
    override class func tearDown() {
    	// Clean up test harness / environment here...
        super.tearDown()
    }
```

- These run _once_ for the **entire** test case
- You cannot have assertions in these

^ ...at the very start, and the very end
^ as that requires a test class instance
^ Use for building up and breaking down test harness aspects that don't change between test methods

---
# Per-Test Method Clean Up

```
    func testWithTeardownBlock() throws {
        XCTAssertTrue(true)
        addTeardownBlock {
            // ... clean up ... 
        }
    }
```

- Teardown blocks are executed even when errors are thrown
- You cannot throw/rethrow errors that arise within their execution

^ So you must handle any errors thrown
^ Why use these instead of defer? I dunno. 

---
# More Teardown Blocks

```
    func testWithMultipleTeardownBlocks() throws {
        XCTAssertTrue(true)
        addTeardownBlock { /* ... */ }
        XCTAssertFalse(false)
        addTeardownBlock { /* ... */ }
        XCTAssertTrue(true)
        addTeardownBlock { /* ... */ }
        XCTAssertFalse(false)
    }
```

- When there are multiple, they are executed LIFO
- You can make assertions within these blocks

^ Other blocks will still execute even on failure of assertions within one

---
Layout: SectionTitle
# Other Hooks (via Inheritance)

```
    override class var defaultTestSuite: XCTestSuite {
        return super.defaultTestSuite
    }
    override func invokeTest() {
        super.invokeTest()
    }
    override func record(_ issue: XCTIssue) {
        super.record(issue)
    }
```

- `init(invocation: NSInvocation?)` is the designated initializer, but is unavailable for Swift
- Also, `deinit` does not get executed

^ NSInvocation is not available in Swift
^ deinit never triggers through the etire suite run
^ so use setUp and tearDown to avoid memory build up
^ run and perform are from XCTest, the others from XCTestCase

---
Is that all?

---
Layout: SectionTitle
# Another Set of Hooks
## XCTestObservation

For monitoring the overall test execution process

Can be used for reporting or logging

^ I'm still not super sure how helpful this really is...

---
# Getting Started

- Write a new class conforming to `XCTestObservation`
- Add an entry in the test target's `Info.plist` under key `NSPrincipalClass`/`Principal class` with a value of `$(PRODUCT_NAME).TheNameOfYourTestObserverType`
- Then have it add itself during initialization:

```
    override init() {
        super.init()
        
        XCTestObservationCenter.shared.addTestObserver(self)
    }
```

- You can add multiple observers
- `removeTestObserver` also exists to remove an observer mid-session

^ Note XCTestObservationCenter

---
# Keep your eye on the bundle

```
    public func testBundleWillStart(_ testBundle: Bundle) { /* ... */ }

    public func testBundleDidFinish(_ testBundle: Bundle) { /* ... */ }
```


---
Layout: SectionTitle
# Taste the suite-ness

```
    public func testSuiteWillStart(_ testSuite: XCTestSuite) { /* ... */ }

    public func testSuiteDidFinish(_ testSuite: XCTestSuite) { /* ... */ }
    
    public func testSuite(_ testSuite: XCTestSuite, didRecord issue: XCTIssue) { /* ... */ }
    
    public func testSuite(_ testSuite: XCTestSuite,
                          didFailWithDescription description: String,
                          inFile filePath: String?,
                          atLine lineNumber: Int) { /* ... */ }
```

^ Not sure why, but the didStart/didFinish are invoked multiple times for a single suite
^ Not really sure what the difference in purpose is for didRecord vs didFail...

---
# Be on the case

```
    public func testCaseWillStart(_ testCase: XCTestCase) { /* ... */ }

    public func testCaseDidFinish(_ testCase: XCTestCase) { /* ... */ }

    public func testCase(_ testCase: XCTestCase, didRecord issue: XCTIssue) { /* ... */ }
    
    public func testCase(_ testCase: XCTestCase,
                         didFailWithDescription description: String,
                         inFile filePath: String?,
                         atLine lineNumber: Int) { /* ... */ }
```

^ The didStart/didFinish are called once for each test method in the TestCase

---
Layout: SectionTitle
# The Overall Sequences

---
Layout: SectionTitle

# XCTestCase Sequence
Example 1

```
ℹ️ ==> defaultTestSuite
✳️ 	==> class-level setUp
ℹ️ ==> run
ℹ️ ==> perform
ℹ️ ==> invokeTest
✳️ 		==> setUpWithError
✳️ 			==> setUp
✳️ 				----> TEST: testAddition
✳️ 			==> tearDown
✳️ 		==> tearDownWithError
ℹ️ ==> run
ℹ️ ==> perform
ℹ️ ==> invokeTest
✳️ 		==> setUpWithError
✳️ 			==> setUp
✳️ 				----> TEST: testThatFails
ℹ️ ==> record issue: Assertion Failure at XCTestLifecycleTests.swift:159: XCTAssertEqual failed: ("true") is not equal to ("false") - Supposed to fail. Method: testThatFails()
✳️ 			==> tearDown
✳️ 		==> tearDownWithError
✳️ 	==> class-level tearDown
```

^ This is a little simplified; we'll see more details in the demo
^ But notice the class-level and inherited order of events

---
Layout: SectionTitle

# XCTestCase Sequence
Example 2

```
ℹ️ ==> defaultTestSuite
✳️ 	==> class-level setUp
ℹ️ ==> run
ℹ️ ==> perform
ℹ️ ==> invokeTest
✳️ 		==> setUpWithError
✳️ 			==> setUp
✳️ 				----> TEST: testWithMultipleTeardownBlocks
✳️ 				----> testWithMultipleTeardownBlocks THIRD teardown block
✳️ 				----> testWithMultipleTeardownBlocks SECOND teardown block
✳️ 				----> testWithMultipleTeardownBlocks FIRST teardown block
✳️ 			==> tearDown
✳️ 		==> tearDownWithError
✳️ 	==> class-level tearDown
```

^ This is a little simplified; we'll see more details in the demo
^ But notice the class-level and inherited order of events

---
Layout: SectionTitle

# XCTestObservation Sequence

```
⚛️  Observer: init
⚛️  Observer: testBundleWillStart
⚛️  Observer: testSuiteWillStart
⚛️  Observer: testSuiteWillStart
⚛️  Observer: testSuiteWillStart
⚛️  Observer: testCaseWillStart
⚛️  Observer: testCaseDidFinish
⚛️  Observer: testCaseWillStart
⚛️  Observer: test case did record issue with case (when test failures)
⚛️  Observer: testCaseDidFinish
⚛️  Observer: testCaseWillStart
⚛️  Observer: testCaseDidFinish
⚛️  Observer: testSuiteDidFinish
⚛️  Observer: testSuiteDidFinish
⚛️  Observer: testSuiteDidFinish
⚛️  Observer: testBundleDidFinish
```

^ for mixed sequence, let's look at the code example

---
# Demo

# 🤞

---
Layout: SectionTitle
# Thanks!
## Questions?
### Kevin Munc ✻ @muncman

