import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    // DB에서 여행 기록 가져오기
    @Query private var records: [TravelRecord]
    
    // 지도에서 선택한 핀의 데이터를 담을 상태 변수
    @State private var selectedRecord: TravelRecord?
    
    // 초기 카메라 위치 (대한민국 중심부 설정)
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.5, longitude: 127.5),
            span: MKCoordinateSpan(latitudeDelta: 4.0, longitudeDelta: 4.0)
        )
    )
    
    var body: some View {
        NavigationStack {
            Map(position: $position, selection: $selectedRecord) {
                // DB에 있는 기록들을 반복문으로 지도 위에 뿌려줌
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
                    .tag(record) // 핀을 선택했을 때 selectedRecord에 값이 들어가도록 태그 설정
                }
            }
            .navigationTitle("여행 지도")
            .navigationBarTitleDisplayMode(.inline)
            // 핀을 눌렀을 때 하단에 정보 카드가 올라오도록 safeAreaInset 사용
            .safeAreaInset(edge: .bottom) {
                if let record = selectedRecord {
                    MapBottomCard(record: record) {
                        // X 버튼을 누르면 선택 해제하여 카드 숨김
                        selectedRecord = nil
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut, value: selectedRecord)
        }
    }
}

// 지도 하단에 띄울 정보 카드 UI 컴포넌트
struct MapBottomCard: View {
    var record: TravelRecord
    var onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            // 💡 1. 카드의 사진과 텍스트 영역을 NavigationLink로 감싸 상세 화면으로 연결
            NavigationLink(destination: DetailView(record: record)) {
                HStack(spacing: 15) {
                    // 사진 영역
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
                    
                    // 텍스트 정보 영역
                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.placeName)
                            .font(.headline)
                            .foregroundColor(.primary) // 링크 기본색(파란색) 방지
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
            .buttonStyle(PlainButtonStyle()) // 💡 2. 네비게이션 링크 클릭 시 전체가 파란색으로 변하는 것 방지
            
            Spacer()
            
            // 💡 3. 닫기 버튼은 NavigationLink 밖에 두어 독립적으로 동작하게 유지
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
