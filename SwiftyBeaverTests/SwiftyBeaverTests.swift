//
//  SwiftyBeaverTests.swift
//  SwiftyBeaverTests
//
//  Created by Sebastian Kreutzberger (Twitter @skreutzb) on 28.11.15.
//  Copyright © 2015 Sebastian Kreutzberger
//  Some rights reserved: http://opensource.org/licenses/MIT
//

import XCTest
@testable import SwiftyBeaver

class SwiftyBeaverTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        SwiftyBeaver.removeAllDestinations()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddDestination() {
        let log = SwiftyBeaver.self
        
        // add invalid destination
        XCTAssertFalse(log.addDestination(["foo": "bar"]))
        XCTAssertEqual(log.countDestinations(), 0)
        
        // add valid destinations
        let console = ConsoleDestination()
        let console2 = ConsoleDestination()
        let file = FileDestination()

        XCTAssertEqual(log.countDestinations(), 0)
        XCTAssertTrue(log.addDestination(console))
        XCTAssertEqual(log.countDestinations(), 1)
        XCTAssertTrue(log.addDestination(console))
        XCTAssertTrue(log.addDestination(console))
        XCTAssertEqual(log.countDestinations(), 1)
        XCTAssertTrue(log.addDestination(console2))
        XCTAssertTrue(log.addDestination(console2))
        XCTAssertEqual(log.countDestinations(), 2)
        XCTAssertTrue(log.addDestination(file))
        XCTAssertEqual(log.countDestinations(), 3)
    }
    
    func testRemoveDestination() {
        let log = SwiftyBeaver.self
        
        // remove invalid destination
        XCTAssertFalse(log.removeDestination(["foo": "bar"]))
        XCTAssertEqual(log.countDestinations(), 0)
        
        // remove valid destinations
        let console = ConsoleDestination()
        let console2 = ConsoleDestination()
        let file = FileDestination()
        
        // add destinations
        log.addDestination(console)
        log.addDestination(console2)
        log.addDestination(file)
        XCTAssertEqual(log.countDestinations(), 3)
        // remove destinations
        XCTAssertTrue(log.removeDestination(console))
        XCTAssertEqual(log.countDestinations(), 2)
        XCTAssertTrue(log.removeDestination(console))
        XCTAssertTrue(log.removeDestination(console))
        XCTAssertEqual(log.countDestinations(), 2)
        XCTAssertTrue(log.removeDestination(console2))
        XCTAssertTrue(log.removeDestination(console2))
        XCTAssertEqual(log.countDestinations(), 1)
        XCTAssertTrue(log.removeDestination(file))
        XCTAssertEqual(log.countDestinations(), 0)
    }
    
    func testLoggingWithoutDestination() {
        let log = SwiftyBeaver.self
        // no destination was set, yet
        log.verbose("Where do I log to?")
    }

    func testDestinationIntegration() {
        let log = SwiftyBeaver.self
        log.verbose("that should lead to nowhere")
        
        // add console
        let console = ConsoleDestination()
        log.addDestination(console)
        log.verbose("the default console destination")
        // add another console and set it to be less chatty
        let console2 = ConsoleDestination()
        log.addDestination(console2)
        XCTAssertEqual(log.countDestinations(), 2)
        console2.detailOutput = false
        console2.dateFormat = "HH:mm:ss.SSS"
        console2.minLevel = SwiftyBeaver.Level.Debug
        log.verbose("a verbose hello from hopefully just 1 console!")
        log.debug("a debug hello from 2 different consoles!")
        
        // add file
        let file = FileDestination()
        file.logFileURL = NSURL(string: "file:///tmp/testSwiftyBeaver.log")!
        log.addDestination(file)
        XCTAssertEqual(log.countDestinations(), 3)
        log.verbose("default file msg 1")
        log.verbose("default file msg 2")
        log.verbose("default file msg 3")
        
        // log to another file
        let file2 = FileDestination()
        file2.logFileURL = NSURL(string: "file:///tmp/testSwiftyBeaver2.log")!
        file2.detailOutput = false
        file2.dateFormat = "HH:mm:ss.SSS"
        file2.minLevel = SwiftyBeaver.Level.Debug
        log.addDestination(file2)
        XCTAssertEqual(log.countDestinations(), 4)
        log.verbose("this should be in file 1")
        log.debug("this should be in both files, msg 1")
        log.info("this should be in both files, msg 2")
    }

    
    func testColors() {
        let log = SwiftyBeaver.self
        log.verbose("that should lead to nowhere")
        
        // add console
        let console = ConsoleDestination()
        log.addDestination(console)
        let file = FileDestination()
        file.logFileURL = NSURL(string: "file:///tmp/testSwiftyBeaver.log")!
        file.detailOutput = false
        file.dateFormat = "HH:mm:ss.SSS"
        log.addDestination(file)
        
        XCTAssertTrue(console.colored)
        XCTAssertTrue(file.colored)
        
        log.verbose("not so important")
        log.debug("something to debug")
        log.info("a nice information")
        log.warning("oh no, that won’t be good")
        log.error("ouch, an error did occur!")
        XCTAssertEqual(log.countDestinations(), 2)
    }
    
    func testDifferentMessageTypes() {
        let log = SwiftyBeaver.self
        
        // add console
        let console = ConsoleDestination()
        console.detailOutput = false
        console.dateFormat = "HH:mm:ss.SSS"
        console.levelString.Info = "interesting number"
        log.addDestination(console)
        
        log.verbose("My name is üÄölèå")
        log.verbose(123)
        log.info(-123.45678)
        log.warning(NSDate())
        log.error(["I", "like", "logs!"])
        log.error(["beaver": "yeah", "age": 12])

        XCTAssertEqual(log.countDestinations(), 1)
    }
    
    func testMinLevelFilters() {
        let log = SwiftyBeaver.self
        
        // add console
        let console = ConsoleDestination()
        console.dateFormat = "HH:mm:ss.SSS"
        // set info level on default
        console.minLevel = .Info
        // do verbose logging for current unit tests file
        console.addMinLevelFilter(.Debug, path: "Test")
        log.addDestination(console)
    
        log.verbose("This should NOT BE VISIBLE!")
        log.debug("This should be visible due to minLevelFilter")
        log.info("This should be visible due to console minLevel")
        
        XCTAssertEqual(log.countDestinations(), 1)
    }
    
    func testLongRunningTaskIsNotExecutedWhenLoggingUnderMinLevel() {
        
        let log = SwiftyBeaver.self
        
        // add console
        let console = ConsoleDestination()
        console.dateFormat = "HH:mm:ss.SSS"
        // set info level on default
        console.minLevel = .Info
        
        log.addDestination(console)

        func longRunningTask() -> String {
            XCTAssert(false, "A block passed should not be executed if the log should not be logged.")
            return "This should NOT BE VISIBLE!"
        }
        
        log.verbose(longRunningTask())
    }
    
}
