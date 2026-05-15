import Foundation
import MapKit
import Combine

class LocationSearchManager: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    
    private let completer: MKLocalSearchCompleter
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = .address // Or .pointOfInterest if needed, but address is better for cities
    }
    
    func updateSearch(query: String) {
        completer.queryFragment = query
    }
    
    // MARK: - Completer Delegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter for results that seem like cities
        self.suggestions = completer.results.filter { result in
            // Basic filtering: avoid specific street addresses if we only want cities
            !result.title.containsAnyNumber() 
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search error: \(error.localizedDescription)")
    }
    
    func getCityAndCountry(from completion: MKLocalSearchCompletion, completionHandler: @escaping (String?, String?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)

        search.start { (response, error) in
            guard let mapItem = response?.mapItems.first else {
                completionHandler(nil, nil)
                return
            }

            let placemark = mapItem.placemark
            let cityName = placemark.locality ?? placemark.name ?? mapItem.name

            var countryName: String? = placemark.country
            if countryName == nil {
                let comps = completion.subtitle
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                countryName = comps.last
            }

            completionHandler(cityName, countryName)
        }
    }
}

extension String {
    func containsAnyNumber() -> Bool {
        let numberRegEx  = ".*[0-9]+.*"
        let testCase = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        return testCase.evaluate(with: self)
    }
}
