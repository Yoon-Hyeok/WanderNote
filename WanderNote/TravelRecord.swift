import Foundation
import SwiftData

@Model
final class TravelRecord {
    var placeName: String
    var visitDate: Date
    var memo: String
    var photoData: Data?
    var rating: Int
    var latitude: Double
    var longitude: Double
    var isFavorite: Bool
    var cityName: String
    
    init(placeName: String, visitDate: Date, memo: String, photoData: Data? = nil, rating: Int, latitude: Double, longitude: Double, isFavorite: Bool = false, cityName: String = "알 수 없는 도시") {
        self.placeName = placeName
        self.visitDate = visitDate
        self.memo = memo
        self.photoData = photoData
        self.rating = rating
        self.latitude = latitude
        self.longitude = longitude
        self.isFavorite = isFavorite
        self.cityName = cityName
    }
}
