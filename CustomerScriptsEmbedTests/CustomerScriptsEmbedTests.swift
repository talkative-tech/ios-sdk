//
//  CustomerScriptsEmbedTests.swift
//  CustomerScriptsEmbedTests
//
//  Created by mert on 02/09/2021.
//

import XCTest
import Combine
@testable import CustomerScriptsEmbed

class CustomerScriptsEmbedTests: XCTestCase {
    
    private var cancellable = Set<AnyCancellable>()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TalkativeManager.shared.config = TalkativeConfig.defaultConfig(companyId: "bfc1d038-680e-45e0-ab57-79373c852560",
                                                                       queueId: "b0a99b74-f914-4154-88d8-d8ac5aa16d4b",
                                                                       region: "eu")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCreateOnlineCheckRequest() throws {
        let req = TalkativeManager.shared.createRequestForOnlineCheck()
        
        XCTAssertTrue(((req?.url?.absoluteString.hasSuffix(".engage.app/api/v1/controls/online")) != nil), "Creates online check request with proper url and body")
    }

    func testOnlineCheck() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expectation = XCTestExpectation(description: "sends request to online and receives stat")

        let subject = PassthroughSubject<AvailabilityStatus, Never>()

        TalkativeManager.shared.onlineCheck { status in
            subject.send(status)
        }

        subject.sink { status in
            print("Status \(status)")
            switch status {
            case .error(let desc): XCTAssert(true, desc)
            default:
                break;
            }
            
            expectation.fulfill()
        }.store(in: &cancellable)
        
        wait(for: [expectation], timeout: 30.0)
    }
        
    func testStartInteractionImmediately() throws {
        let vc = TalkativeManager.shared.startInteractionImmediately(type: .chat)
        
        XCTAssertNotNil(vc, "Talkative VC is not set")
        XCTAssertNotNil(vc?.delegate, "Talkative VC delegate is not set")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
