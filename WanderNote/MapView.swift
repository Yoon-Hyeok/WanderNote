import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Query private var records: [TravelRecord]
    
    @State private var selectedRecord: TravelRecord?
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.5, longitude: 127.5),
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    )
    
    var body: some View {
        NavigationStack {
            Map(position: $position, selection: $selectedRecord) {
                ForEach(records) { record in
                    Annotation(record.placeName, coordinate: CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)) {
                        ZStack {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 32, height: 32)
                                .shadow(radius: 3)
                            
                            Image(systemName: "airplane")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .tag(record)
                }
            }
            .navigationTitle("여행 지도")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if let record = selectedRecord {
                    MapBottomCard(record: record) {
                        selectedRecord = nil
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut, value: selectedRecord)
        }
    }
}

struct MapBottomCard: View {
    var record: TravelRecord
    var onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            NavigationLink(destination: DetailView(record: record)) {
                HStack(spacing: 15) {
                    if let photoData = record.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.placeName)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(record.visitDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // 별점 표시
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < record.rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            VStack {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -2)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}
