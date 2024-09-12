//
//  DexViewModel.swift
//  PokemonDex-MVVM
//
//  Created by Jeong Deokho on 9/10/24.
//

import Foundation
import SwiftUI

@Observable
final class DexViewModel {
    
    // MARK: - Constants
    
    private enum Constants {
        enum String {
            static let all = "All"
        }
    }
    
    // MARK: - Properties
    
    private let coordinator: CoordinatorDependency
    private let netWorkService: NetworkServiceDependecny
    private var cellViewModels: [DexCellViewModel] = []
    
    // MARK: - LifeCycle
    
    init(netWorkService: NetworkServiceDependecny = NetworkService(),
         coordinator: CoordinatorDependency) {
        self.netWorkService = netWorkService
        self.coordinator = coordinator
    }
    
    // MARK: - Output
    
    var filterModels: [(title: String, color: Color)] = []
    var isShowAlert = false
    var alertMessage = ""
    var selectedFilterWords = Constants.String.all
    var filteredCellViewModels: [DexCellViewModel] {
        return selectedFilter()
    }
    
    // MARK: - Function
    
    /// Asynchronously fetches Dex data from the network, updates `cellViewModels`, and sets filter models.
    func fetchCellViewModels() async {
        do {
            let models: [PokemonModel?] = try await netWorkService.requestData(
                endPoint: PokemonEndPoint.getDex
            )
            Log.debug("Successfully retrieved Pokémon Dex List entries.", "List Count: \(models.count)")
            setCellViewModels(models: models)
            setUniqueTypeFilterModels(viewModels: self.cellViewModels)
        } catch {
            alertMessage = error.localizedDescription
            isShowAlert = true
        }
    }
    
    func pushDetailView(cellViewModel: DexCellViewModel) {
        coordinator.push(destination: .pokemonDexDetail(cellViewModel))
    }
    
    /// Filters the `cellViewModels` based on the selected filter condition.
    private func selectedFilter() -> [DexCellViewModel] {
        guard selectedFilterWords != Constants.String.all else {
            return self.cellViewModels
        }
        return cellViewModels.filter {
            $0.typeName == selectedFilterWords
        }
    }
    
    /// Converts the array of Pokémon models into `DexCellViewModel` and updates `cellViewModels`.
    private func setCellViewModels(models: [PokemonModel?]) {
        self.cellViewModels = models
            .compactMap { $0 }
            .map { DexCellViewModel(model: $0) }
    }
    
    /// Generates filter models from `DexCellViewModel` array and updates `filterModels`.
    private func setUniqueTypeFilterModels(viewModels: [DexCellViewModel]) {
        var seenTypes = Set<String>()
        self.filterModels = viewModels.compactMap { model in
            if seenTypes.contains(model.typeName) {
                return nil
            } else {
                seenTypes.insert(model.typeName)
                return (title: model.typeName, color: model.backgroundColor)
            }
        }
        self.filterModels.insert((title: Constants.String.all, color: .black), at: 0)
    }
}
