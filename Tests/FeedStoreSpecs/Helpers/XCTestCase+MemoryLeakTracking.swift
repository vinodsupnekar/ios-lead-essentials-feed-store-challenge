//
//  XCTestCase+MemoryLeakTracking.swift
//  Tests
//
//  Created by vinod supnekar on 27/02/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

extension XCTestCase {
  
   func trackMemoryLeaks (_ instance: AnyObject,file: StaticString = #file, line: UInt = #line) {
	
		addTeardownBlock { [weak instance] in
		
			XCTAssertNil(instance,"instance should have been deallocated.Potential memory leak.",file: file,line: line)
	
	}
  }
  
}
