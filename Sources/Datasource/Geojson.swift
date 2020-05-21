import Foundation
import AnyCodable

public struct GeoJson: Decodable {
    public let type: String
    public let features: [Feature]

    @dynamicMemberLookup
    public struct Feature: Decodable {
        public let type: String
        public let geometry: Geometry

        public struct Geometry: Decodable {
            public let type: String
            public let coordinates: [Double]
        }

        public let properties: [String: AnyDecodable]

        public var name: String {
            properties["name"]!.value as! String
        }

        public var coordinates: Coordinates? {
            guard geometry.coordinates.count == 2 else { return nil }
            return Coordinates(lat: geometry.coordinates[0], lng: geometry.coordinates[1])
        }

        public subscript<T>(_ key: String) -> T? {
            get {
                properties[key]?.value as? T
            }
        }

        public subscript(_ key: String) -> URL? {
            get {
                guard let str = properties[key]?.value as? String else {
                    return nil
                }
                return URL(string: str)
            }
        }

        public subscript<T>(dynamicMember dynamicMember: String) -> T? {
            self[dynamicMember]
        }
    }

    public func lot(withName name: String) -> Feature? {
        assert(features.allSatisfy { $0.properties["name"] != nil }, "Every lot feature should have a name property.")
        return features.first { $0.name == name }
    }
}
