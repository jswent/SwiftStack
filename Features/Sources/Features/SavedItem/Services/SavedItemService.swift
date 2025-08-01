//
//  SavedItemService.swift
//  Features
//
//  Created by James Swent on 7/30/25.
//

import SwiftData
import Foundation

public final class SavedItemService {
    private let savedItemRepository: SavedItemRepositoryProtocol
    private let taskRepository: TaskRepositoryProtocol
    private let projectRepository: ProjectRepositoryProtocol
    private let searchService: SearchServiceProtocol
    private let taskService: TaskServiceProtocol
    private let projectService: ProjectServiceProtocol
    
    public init(
        savedItemRepository: SavedItemRepositoryProtocol,
        taskRepository: TaskRepositoryProtocol,
        projectRepository: ProjectRepositoryProtocol,
        searchService: SearchServiceProtocol,
        taskService: TaskServiceProtocol,
        projectService: ProjectServiceProtocol
    ) {
        self.savedItemRepository = savedItemRepository
        self.taskRepository = taskRepository
        self.projectRepository = projectRepository
        self.searchService = searchService
        self.taskService = taskService
        self.projectService = projectService
    }
    
    // MARK: - Convenience Factory
    
    public static func create(with modelContext: ModelContext) -> SavedItemService {
        let savedItemRepository = SavedItemRepository(modelContext: modelContext)
        let taskRepository = TaskRepository(modelContext: modelContext)
        let projectRepository = ProjectRepository(modelContext: modelContext)
        let searchService = SearchService(modelContext: modelContext)
        let taskService = TaskService(
            taskRepository: taskRepository,
            projectRepository: projectRepository
        )
        let projectService = ProjectService(projectRepository: projectRepository)
        
        return SavedItemService(
            savedItemRepository: savedItemRepository,
            taskRepository: taskRepository,
            projectRepository: projectRepository,
            searchService: searchService,
            taskService: taskService,
            projectService: projectService
        )
    }
    
    // MARK: - SavedItem Operations
    
    public func getAllItems() throws -> [SavedItem] {
        return try savedItemRepository.fetchAll()
    }
    
    public func getBaseSavedItemsOnly() throws -> [SavedItem] {
        return try savedItemRepository.fetchBaseSavedItemsOnly()
    }
    
    public func getRecentItems(limit: Int = 10) throws -> [SavedItem] {
        return try savedItemRepository.fetchRecent(limit: limit)
    }
    
    public func getItemsWithPhotos() throws -> [SavedItem] {
        return try savedItemRepository.fetchWithPhotos()
    }
    
    public func getItemsWithUrls() throws -> [SavedItem] {
        return try savedItemRepository.fetchWithUrls()
    }
    
    // MARK: - Task Operations
    
    public func getAllTasks() throws -> [TaskItem] {
        return try taskRepository.fetchAll()
    }
    
    public func getTasks(withStatus status: TaskStatus) throws -> [TaskItem] {
        return try taskRepository.fetch(withStatus: status)
    }
    
    public func getActiveTasks() throws -> [TaskItem] {
        return try taskRepository.fetchActive()
    }
    
    public func getOverdueTasks() throws -> [TaskItem] {
        return try taskRepository.fetchOverdue()
    }
    
    // MARK: - Project Operations
    
    public func getAllProjects() throws -> [ProjectItem] {
        return try projectRepository.fetchAll()
    }
    
    public func getActiveProjects() throws -> [ProjectItem] {
        return try projectRepository.fetchActive()
    }
    
    // MARK: - Search Operations
    
    public func searchItems(containing searchText: String) throws -> [SavedItem] {
        return try searchService.searchItems(containing: searchText)
    }
    
    public func searchItemsGroupedByType(containing searchText: String) throws -> [String: [SavedItem]] {
        return try searchService.searchItemsGroupedByType(containing: searchText)
    }
    
    // MARK: - Business Logic Operations
    
    public func completeTask(_ task: TaskItem) throws {
        try taskService.completeTask(task)
    }
    
    public func cancelTask(_ task: TaskItem) throws {
        try taskService.cancelTask(task)
    }
    
    public func addTaskToProject(_ task: TaskItem, project: ProjectItem) throws {
        try taskService.addTaskToProject(task, project: project)
    }
    
    public func updateProjectStatus(_ project: ProjectItem, status: ProjectStatus) throws {
        try projectService.updateProjectStatus(project, status: status)
    }
    
    public func getProjectSummary(_ project: ProjectItem) -> ProjectSummary {
        return projectService.getProjectSummary(project)
    }
    
    // MARK: - Legacy Compatibility Methods
    
    @available(*, deprecated, message: "Use searchItems(containing:) instead")
    public func searchAllItems(containing searchText: String) throws -> [SavedItem] {
        return try searchItems(containing: searchText)
    }
    
    @available(*, deprecated, message: "Use getAllItems() instead")
    public func getAllItemsWithTypes() throws -> (items: [SavedItem], tasks: [TaskItem]) {
        let allItems = try getAllItems()
        let tasks = allItems.compactMap { $0 as? TaskItem }
        return (allItems, tasks)
    }
    
    @available(*, deprecated, message: "Use searchItemsGroupedByType(containing:) instead")
    public func getAllItemsGroupedByType() throws -> [String: [SavedItem]] {
        let allItems = try getAllItems()
        return Dictionary(grouping: allItems) { item in
            switch item {
            case is TaskItem: return "Tasks"
            case is ProjectItem: return "Projects"
            default: return "Items"
            }
        }
    }
}
