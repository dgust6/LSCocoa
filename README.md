LSCocoa provides concrete implementations to __[LSData framework](https://github.com/dinogustinn/LSData)__ for `CoreData`, `UserDefaults`, `Keychain` and networking layer.

# Step by step tutorials
Assume we are using following simple Domain Model classes for GitHub repositories and their owners
Owner:

    struct  Owner {
        let id: String
        let name: String
    }

    struct Repository {
        let id: String
        let name: String
        let watchers: Int
        let stars: Int
        let owner: Owner
    }

Simple tutorials for following implementations are available:
+ __[Networking](https://github.com/dinogustinn/LSCocoa#1-networking)__
+ __[CoreData](https://github.com/dinogustinn/LSCocoa#2-coredata)__
+ __[UserDefaults](https://github.com/dinogustinn/LSCocoa#3-userdefaults)__
+ __[KeyChain](https://github.com/dinogustinn/LSCocoa#4-keychain)__

## 1. Networking
Creating a networking layer conforming to `LSData` is extremely simple.
Let's create a data source of `Repositories` proving queriable search functionality using GitHub's search endpoint:
https://docs.github.com/en/rest/reference/search#search-repositories

#### 1. Create an API endpoint:
Create a concrete endpoint implementing the `ApiEndpoint` protocol:

    struct SearchRepositoriesEndpoint: ApiEndpoint {
        var baseUrl = URL(string: "https://api.github.com")!
        var path: String? = "/search/repositories"   
        var headers = ["Accept" : "application/vnd.github.v3+json"]
    }

And thats it, we're done! You can now create a `DataSource` like this:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
    //erased type would be: AnyDataSource<Data, [ApiEndpointAttribute], NetworkError> 

This `DataSource` is useful, but it has two things which can be imporved (for general usage):
+ Output type is `Data`, and we want to use our domain model `Repository` instead
+ Parameter type is `[ApiEndpointAttribute]`, which enables us to add any request parameter, such as adding headers, chainging http method, etc. We want this parameter to be query `String` to prohibit adding anything else

#### 2. Create a network model (Optional):
In most cases you wish to create a network model to serve as __[ACL pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer)__. This enables us to have our domain model separate from our external models (such as these networking and CoreData modles) making our domain model and our app logic immune to changes in backend and it's response which can contain various metadata (such as paging or analytics).

Looking at the endpoint above we can create a model like this

    struct RepositoryNetworkModel: Codable {
        let id: Int
        let node_id: String
        let name: String
        let stargazers_count: Int
        let watchers_count: Int
        let owner: OwnerNetworkModel
    }
    struct OwnerNetworkModel: Codable {
        let login: String
        let id: Int
    }
#### 3. Creating an endpoint response Decodable
Looking at GitHub's documentation above we can create a response like this:

    extension SearchRepositoriesEndpoint {
        struct Response: Decodable {
            let total_count: Int
            let items: [RepositoryNetworkModel]
        }
    }

Now we can map the output like this:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
        .jsonDecodeMap(to: SearchRepositoriesEndpoint.Response.self)
    //erased type would be: AnyDataSource<SearchRepositoriesEndpoint.Response, [ApiEndpointAttribute], NetworkError>
#### 4. Map response to our domain model
There are two ways to map, one using `Mapper` and one using a simple completion handler. Here we will create a more complex `Mapper`

    class SearchRepositoriesOutputMapper: Mapper {

        typealias Input = SearchRepositoriesEndpoint.Response?
        typealias Output = [Repository]
        
        func map(_ input: SearchRepositoriesEndpoint.Response?) -> [Repository] {
            guard let input = input else { return [] }
            return input.items.map { item in
                Repository(id: String(item.id), name: item.name, watchers: item.watchers_count, stars: item.stargazers_count, owner: Owner(id: String(item.owner.id), name: item.owner.login))
            }
        }
    }

Now our `DataSource` will look something like this:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
        .jsonDecodeMap(to: SearchRepositoriesEndpoint.Response.self)
        .outMap(with: SearchRepositoriesOutputMapper())
    //erased type would be: AnyDataSource<Repository, [ApiEndpointAttribute], NetworkError>

Almost there! We are now outputting our domain model `Repository` instead of initial `Data`, now we just need to map there parameter.

#### 5. Map the parameter
When mapping `Input` above we used `Mapper` class but for showcase purposes we will use `paramMap` method here:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
        .jsonDecodeMap(to: SearchRepositoriesEndpoint.Response.self)
        .outMap(with: SearchRepositoriesOutputMapper())
        .paramMap { (queryString: String) -> [ApiEndpointAttribute] in
            return [.addUrlParameter(key: "q", value: queryString)]
        }
    //erased type would be: AnyDataSource<Repository, String, NetworkError>

#### 6. All done!
Now we have a `DataSource` which publishes our domain model object `Repository` and supports `String` argument to query the search.

What can we do with it? Since it's completely abstracted generic we can do many things, mostly interacting with other `DataSource` or `DataStorage`  with same output of `Repository`, such as caching, syncing and refreshing (or many other complex behaviours you can implement yourself!).

For showcase purposes let's create refresh functionality.

#### 7. (Optional) Refresh functionality

Let's say we have a text field or a search bar where user can input a query to search repositories. We would like to refresh our data source every time this text is inputted (i.e. user presses done, or on each text change, up to you).

Using the above code we can call `refreshable` method to create `LSRefreshableDataSource`:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
        .jsonDecodeMap(to: SearchRepositoriesEndpoint.Response.self)
        .outMap(with: SearchRepositoriesOutputMapper())
        .paramMap { (queryString: String) -> [ApiEndpointAttribute] in
            return [.addUrlParameter(key: "q", value: queryString)]
        }
        .refreshable(parameter: "")

That's it, just one line! Now each time our query changes we can call something like this:

    queryRepositoriesDataSource.refresh(with: "repositoryQueryText")

And all subscribers will be automatically notified on each change.



## 2. CoreData
To add `CoreData` functionality to our domain model we need to implement following things:
+ create `CoreData` Data Model
+ create `NSManagedObject` of our domain model
+ Implement `LSManagedObject` protocol and it's mapping methods.

There is no escaping first two points when dealing with `CoreData`, you will need to do those however you use `CoreData`, so only additional work is the third point, which you should be doing anyway (since `NSManagedObject` is "old", business layer shouldn't use it, but use domain model instead).

There are numerous tutorials for first two points on internet, so you can skip them if you are familiar with them.
### 1. Create `CoreData` Data Model (skip if you are familiar)
In Xcode right click desired project folder and create a *New File>Data Model>Name it "Model"*

*You can name it however you want, and even have multiple models but in this tutorial we will use "Model" as a name*

Now fill in the model like this, with no optional field values:

We will use __[codegen](https://developer.apple.com/documentation/coredata/modeling_data/generating_code)__ feature set to *Manual/None*.

### 2. Create `NSManagedObject` of our domain model

Now manually create NSManagedObject classes to look something like this. Ideally, you will separated them in each their own files :)

    import Foundation
    import LSCocoa
    import LSData
    import CoreData
    
    @objc(RepositoryManagedObject)
    public class RepositoryManagedObject: NSManagedObject {
        @NSManaged public var id: String
        @NSManaged public var name: String
        @NSManaged public var stars: NSNumber
        @NSManaged public var watchers: NSNumber
        @NSManaged public var owner: OwnerManagedObject
    }
    
    @objc(OwnerManagedObject)
    public class OwnerManagedObject: NSManagedObject {
        @NSManaged public var id: String
        @NSManaged public var name: String
    }

### 3. Implement `LSManagedObject` protocol and it's mapping methods

Lastly we need to implement `LSManagedObject` protocol:

    extension OwnerManagedObject: LSManagedObject {
        func populate(with model: Owner, in context: NSManagedObjectContext?) {
            name = model.name
            id = model.id
        }
        
        func toModel() -> Owner {
            Owner(id: id, name: name)
        }
        
        typealias T = OwnerManagedObject
        
        typealias AppModel = Owner
    }

    extension Owner: LSManagedObjectConvertible {
        typealias ManagedObject = OwnerManagedObject
    }

And

    extension RepositoryManagedObject: LSManagedObject {
        func populate(with model: Repository, in context: NSManagedObjectContext?) {
            name = model.name
            id = model.id
        }
        
        func toModel() -> Repository {
            Repository(id: id, name: name, watchers: watchers.intValue, stars: stars.intValue, owner: owner.toModel())
        }
        
        typealias T = RepositoryManagedObject
        
        typealias AppModel = Repository
    }

    extension Repository: LSManagedObjectConvertible {
        typealias ManagedObject = RepositoryManagedObject
    }

Thats it!

### 4. Use it!

We can create helper methods to easily initialise our repositories:

    extension LSCoreDataStack {
        static let shared: LSCoreDataStack = {
            do {
                return try LSCoreDataStack(modelName: "Model")
            } catch let error {
                fatalError("Unable to create CoreData stack")
            }
        }()
    }
    extension LSCoreDataRepository {
        convenience init() {
            self.init(stack: LSCoreDataStack.shared)
        }
    }

You can now create `LSCoreDataRepository` with for both `owners` and `repositories`.

        let ownerRepo = LSCoreDataRepository<Owner.ManagedObject>()
        let repositoryRepo = LSCoreDataRepository<Repository.ManagedObject>()
You get all `LSCoreDataRepository` functionality out of the box! This includes:
+ Since it's a `DataSource` you get reactive updates every time the DB changes. If you wish to observe only the current DB table, supply `reactOnChildUpdates=false` on init (This uses  optimised `NSFetchedResultsController` internally).
+ Insert, Overwrite, Upsert, Update, Delete methods all included and ran on background context
+ Since it's generic, you can add various things to it, such as analytics and it will work for al your repos, and use existing functionality such as `sync` where you can store data from a `DataSource` (such as network one explained above) into it.

## 3. UserDefaults
These are the easy parts!

    let ownerUserDefaultsRepository = UserDefaultsItemRepository<[Owner]>()

Aaaaand you are done!

If you wish to use custom key you can do it like this:

    let userRegisteredUserDefaults = UserDefaultsItemRepository<Bool>(itemKey: "didRegister")
## 4. Keychain
`Keychain` is similar to `UserDefaults` explained above

    let authTokenRepo = LSKeychainItemRepository<String>(itemKey: "authToken")
