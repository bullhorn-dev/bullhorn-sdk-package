
import Foundation

protocol BHCategoriesManagerListener: ObserverProtocol {
    func categoriesManagerDidFetch(_ manager: BHCategoriesManager)
    func categoriesManagerDidUpdateUsers(_ manager: BHCategoriesManager)
}

class BHCategoriesManager {

    static let shared = BHCategoriesManager()

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHCategoriesManagerListener>
    private let workingQueue = DispatchQueue.init(label: "BHCategoriesManager.Working", target: .global())

    private var dispatchQueue = DispatchQueue.global()
    
    fileprivate var authToken: String {
        BHAccountManager.shared.authToken
    }
    
    fileprivate lazy var api = BHServerApiCategories.init(withApiType: .regular)
    
    // MARK: - Categories

    var categories: [BHCategory] = []

    // MARK: - Users
    
    var users: [BHUser] = []

    // MARK: - Posts
    
    var posts: [BHPost] = []
    
    var hasMore: Bool {
        return page < pages
    }
    
    fileprivate var page: Int = 0
    fileprivate var pages: Int = 0
    fileprivate var searchText: String = ""

    fileprivate var nextPage: Int {
        return min(page + 1, pages)
    }
            
    // MARK: - Initialization
    
    init() {
        observersContainer = .init(notifyQueue: workingQueue)
    }
        
    // MARK: - Public listener

    func addListener(_ listener: BHCategoriesManagerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHCategoriesManagerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - Public
    
    func getCategory(with alias: String) -> BHCategory? {
        return categories.first(where: { $0.alias == alias })
    }

    func getCategories(_ networkId: String, completion: @escaping (BHServerApiCategories.CategoriesResult) -> Void) {
        
        api.getCategories(authToken: authToken, networkId: networkId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(categories: let categories):
                    self.categories = categories
                case .failure(error: let error):
                    BHLog.w("Categories load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getCategoryUsers(_ networkId: String, categoryId: Int, completion: @escaping (BHServerApiBase.UsersResult) -> Void) {
                
        api.getCategoryUsers(authToken: authToken, networkId: networkId, categoryId: categoryId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: let users):
                    self.users = users
                case .failure(error: let error):
                    BHLog.w("Category podcasts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func updateCategoryUser(_ user: BHUser) {
        if let row = users.firstIndex(where: {$0.id == user.id}) {
            self.users[row] = user
            
            self.observersContainer.notifyObserversAsync {
                $0.categoriesManagerDidUpdateUsers(self)
            }
        }
    }
    
    func getCategoryPosts(categoryId: Int, text: String?, completion: @escaping (BHServerApiBase.PaginatedPostsResult) -> Void) {

        if let validText = text, validText != searchText {
            page = 0
            pages = 0
        }
        
        searchText = text ?? ""

        api.getCategoryPosts(authToken: authToken, networkId: BHAppConfiguration.shared.networkId, categoryId: categoryId, text: searchText, page: nextPage) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: let posts, page: let page, pages: let pages):
                    if page > 1 {
                        self.posts.append(contentsOf: posts)
                    } else {
                        self.posts = posts
                    }
                    self.page = page
                    self.pages = pages
                case .failure(error: let error):
                    BHLog.w("Category recent posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func removeCategoryData() {
        users.removeAll()
        posts.removeAll()
        page = 0
        pages = 0
        searchText = ""
    }

        
    // MARK: - Initial fetch for screen
    
    func fetch(_ networkId: String, categoryId: Int, completion: @escaping (CommonResult) -> Void) {
        
        page = 0
        pages = 0
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?

        fetchGroup.enter()
        
        getCategoryUsers(networkId, categoryId: categoryId) { response in
            switch response {
            case .success(users: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getCategoryPosts(categoryId: categoryId, text: "") { response in
            switch response {
            case .success(posts: _, page: _, pages: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
                    
        fetchGroup.notify(queue: .main) {
            
            self.observersContainer.notifyObserversAsync {
                $0.categoriesManagerDidFetch(self)
            }

            if let error = responseError {
                completion(.failure(error: error))
            } else {
                completion(.success)
            }
        }
    }
    
    // MARK: - Storage Providers
    
    func fetchStorageCategories(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchCategories(with: networkId) { response in
            switch response {
            case .success(categories: let categories):
                self.categories = categories
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }

    func fetchStorageCategoryPodcasts(_ categoryId: Int, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchCategoryUsers(with: categoryId) { response in
            switch response {
            case .success(users: let users):
                self.users = users
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
}

