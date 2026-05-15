import AppIntents

@available(iOS 17.0, *)
struct PlantEntity: AppEntity {
    let id: String
    let nickname: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Plant" }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(nickname)") }

    static var defaultQuery = PlantEntityQuery()
}

@available(iOS 17.0, *)
struct PlantEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PlantEntity] {
        let jungle = await DataLoader.shared.userProfile?.myJungle ?? []
        return jungle
            .filter { identifiers.contains($0.plantId) }
            .map { PlantEntity(id: $0.plantId, nickname: $0.nickname) }
    }

    func suggestedEntities() async throws -> [PlantEntity] {
        let jungle = await DataLoader.shared.userProfile?.myJungle ?? []
        return jungle.map { PlantEntity(id: $0.plantId, nickname: $0.nickname) }
    }
}
