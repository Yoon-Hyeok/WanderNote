import SwiftUI
import SwiftData
import PhotosUI
import MapKit
import Photos
import CoreLocation

struct AddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var placeName = ""
    @State private var visitDate = Date()
    @State private var memo = ""
    @State private var rating = 3
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    
    @State private var latitude: Double = 37.5665
    @State private var longitude: Double = 126.9780
    @State private var cityName: String = "서울특별시"
    
    @State private var isShowingLocationPicker = false
    @State private var showingSaveAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("사진 추가")) {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text("갤러리에서 사진 선택")
                            }
                            .foregroundColor(.purple)
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    self.selectedPhotoData = data
                                }
                            }
                            
                            if let localID = newItem?.itemIdentifier {
                                let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                                
                                if status == .authorized || status == .limited {
                                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                                    
                                    if let asset = fetchResult.firstObject {
                                        await MainActor.run {
                                            if let creationDate = asset.creationDate {
                                                self.visitDate = creationDate
                                            }
                                            
                                            if let location = asset.location {
                                                self.latitude = location.coordinate.latitude
                                                self.longitude = location.coordinate.longitude
                                                extractCityName(from: location)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("기본 정보")) {
                    TextField("장소명", text: $placeName)
                    DatePicker("방문 날짜", selection: $visitDate, displayedComponents: .date)
                }
                
                Section(header: Text("위치 설정")) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.purple)
                        
                        Text(cityName)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("위치 선택") {
                            isShowingLocationPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                }
                
                Section(header: Text("여행 메모")) {
                    TextEditor(text: $memo)
                        .frame(height: 100)
                }
                
                Section(header: Text("별점")) {
                    HStack(spacing: 15) {
                        Spacer()
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .foregroundColor(index <= rating ? .yellow : .gray)
                                .font(.title)
                                .onTapGesture {
                                    withAnimation { rating = index }
                                }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("새 여행 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { resetForm() }
                        .tint(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장하기") {
                        let newRecord = TravelRecord(
                            placeName: placeName,
                            visitDate: visitDate,
                            memo: memo,
                            photoData: selectedPhotoData,
                            rating: rating,
                            latitude: latitude,
                            longitude: longitude,
                            cityName: cityName
                        )
                        modelContext.insert(newRecord)
                        showingSaveAlert = true
                    }
                    .bold()
                    .tint(.purple)
                    .disabled(placeName.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingLocationPicker) {
                LocationPickerView(latitude: $latitude, longitude: $longitude, cityName: $cityName)
            }
            .alert("저장 완료", isPresented: $showingSaveAlert) {
                Button("확인") { resetForm() }
            } message: {
                Text("여행 기록이 성공적으로 저장되었습니다.")
            }
        }
    }
    
    private func resetForm() {
        placeName = ""
        visitDate = Date()
        memo = ""
        rating = 3
        selectedItem = nil
        selectedPhotoData = nil
        latitude = 37.5665
        longitude = 126.9780
        cityName = "서울특별시"
    }
    
    private func extractCityName(from location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                self.cityName = placemark.locality ?? placemark.administrativeArea ?? placemark.country ?? "알 수 없는 도시"
            }
        }
    }
}

struct LocationPickerView: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var cityName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MapReader { proxy in
                    Map(position: $position) {
                        if let coordinate = selectedCoordinate {
                            Annotation("선택한 위치", coordinate: coordinate) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.largeTitle)
                            }
                        }
                    }
                    .onTapGesture { tapPosition in
                        if let coordinate = proxy.convert(tapPosition, from: .local) {
                            updateLocation(coordinate)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
                
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        Button(action: {
                            if let coord = item.placemark.location?.coordinate {
                                updateLocation(coord)
                                searchText = ""
                                searchResults = []
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "알 수 없는 장소")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(item.placemark.title ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(UIColor.systemBackground))
                }
            }
            .navigationTitle("장소 선택")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "장소명이나 주소를 입력하세요")
            .onChange(of: searchText) { _, newValue in searchLocation(query: newValue) }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .tint(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        if let coord = selectedCoordinate {
                            latitude = coord.latitude
                            longitude = coord.longitude
                        }
                        dismiss()
                    }
                    .bold()
                    .tint(.purple)
                }
            }
            .onAppear {
                let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                updateLocation(coord)
            }
        }
    }
    
    private func searchLocation(query: String) {
        guard !query.isEmpty else { searchResults = []; return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        MKLocalSearch(request: request).start { response, _ in
            if let response = response { self.searchResults = response.mapItems }
        }
    }
    
    private func updateLocation(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            if let placemark = placemarks?.first {
                self.cityName = placemark.locality ?? placemark.administrativeArea ?? placemark.country ?? "알 수 없는 도시"
            }
        }
    }
}
