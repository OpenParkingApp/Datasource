import XCTest
import OpenParking

public func validate(datasource: Datasource,
                     ignoreExceededCapacity: Bool = false,
                     ignoreDataAge: Bool = false,
                     file: StaticString = #filePath,
                     line: UInt = #line) {
    do {
        let data = try datasource.data()
        XCTAssert(!data.lots.isEmpty, file: file, line: line)

        for lot in data.lots {
            validate(lot: lot,
                     ignoreExceededCapacity: ignoreExceededCapacity,
                     ignoreDataAge: ignoreDataAge,
                     file: file,
                     line: line)
        }
    } catch {
        XCTFail("Fetching data from \(datasource.name) failed with: \(error)", file: file, line: line)
    }
}

public func validate(lot: LotResult,
                     ignoreExceededCapacity: Bool = false,
                     ignoreDataAge: Bool = false,
                     file: StaticString = #filePath,
                     line: UInt = #line) {
    switch lot {
    case .failure(let error):
        switch error {
        case .missingMetadata(lot: let lot):
            XCTFail("Missing metadata for \(lot)", file: file, line: line)
        case .missingMetadataField(let field, lot: let lot):
            XCTFail("\(lot) metadata missing expected field \(field)", file: file, line: line)
        case .other(reason: let reason):
            XCTFail("\(lot) failed because of: \(reason)", file: file, line: line)
        }
    case .success(let lot):
        if let dataAge = lot.dataAge, !ignoreDataAge {
            XCTAssert(dataAge < Date(), "\(lot) data age should be in the past.", file: file, line: line)
        }
        XCTAssert(!lot.name.isEmpty, "Lot name should not be empty", file: file, line: line)
        XCTAssert(!lot.city.isEmpty, "Lot '\(lot.name)' city should not be empty", file: file, line: line)
        if let region = lot.region {
            XCTAssert(!region.isEmpty, "Lot '\(lot.name)' region should not be empty if set", file: file, line: line)
        }
        if let address = lot.address {
            XCTAssert(!address.isEmpty, "Lot '\(lot.name)' address should not be empty if set", file: file, line: line)
        }
        if let position = lot.position {
            XCTAssertNotEqual(position.longitude, 0.0, "Lot '\(lot.name)' position should not contain placeholder values", file: file, line: line)
            XCTAssertNotEqual(position.longitude, 1.0, "Lot '\(lot.name)' position should not contain placeholder values", file: file, line: line)
            XCTAssertNotEqual(position.latitude, 0.0, "Lot '\(lot.name)' position should not contain placeholder values", file: file, line: line)
            XCTAssertNotEqual(position.latitude, 1.0, "Lot '\(lot.name)' position should not contain placeholder values", file: file, line: line)
        }
        if lot.geometry != nil {
            XCTAssertNotNil(lot.position, "Lot '\(lot.name)' position should not be nil if geometry is set.")
        }
        if let pricing = lot.pricing {
            switch (pricing.url, pricing.description) {
            case (nil, nil):
                XCTFail("Lot '\(lot.name)' either Pricing.url or Pricing.description should be set if pricing information is supplied.")
            default:
                break
            }
        }
        if let openingHours = lot.openingHours {
            switch (openingHours.url, openingHours.times) {
            case (nil, nil):
                XCTFail("Lot '\(lot.name)' either OpeningHours.url or OpeningHours.times should be set if opening hours information is supplied.")
            default:
                break
            }
        }
        if !ignoreExceededCapacity {
            switch lot.available {
            case .discrete(let available):
                XCTAssert(available >= 0, "Lot '\(lot.name)' should have a positive amount of available spots", file: file, line: line)
                if let capacity = lot.capacity {
                    XCTAssert(available <= capacity, "Lot '\(lot.name)' available spots should not exceed the capacity", file: file, line: line)
                }
            case .range(let range):
                XCTAssert(range.lowerBound >= 0, "Lot '\(lot.name)' availability range should start at a positive value", file: file, line: line)
                if let capacity = lot.capacity {
                    XCTAssert(range.upperBound <= capacity, "Lot '\(lot.name)' availability range upper bound should not exceed the capacity", file: file, line: line)
                }
            }
        }
    }

    _ = Warning.flush()
}
