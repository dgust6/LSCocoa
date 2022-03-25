LSCocoa provides concrete implementations to __[LSData framework](https://github.com/dinogustinn/LSData)__ for `CoreData`, `UserDefaults`, `Keychain` and networking layer.

# Step by step tutorials
Assume we are using following simple Domain Model classes for GitHub repositories and their owners:

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

## 1. Networking
Creating a networking layer conforming to `LSData` is extremely simple.
Let's create a data source of `Repositories` proving queriable search functionality using GitHub's search endpoint:
https://docs.github.com/en/rest/reference/search#search-repositories

#### 1. Create an API endpoint:
Create a concrete endpoint implementing the `ApiEndpoint` protocol 

    struct SearchRepositoriesEndpoint: ApiEndpoint {
        var baseUrl = URL(string: "https://api.github.com")!
        var path: String? = "/search/repositories"   
        var headers = ["Accept" : "application/vnd.github.v3+json"]
    }

And thats it, we're done! You can now create a `DataSource` like this:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
    //erased type would be: LSAnyDataSource<Data, [LSApiEndpointAttribute], LSNetworkError> 

This `DataSource` is useful, but it has two problems which we will fix below:
+ Output type is `Data`, and we want to use our domain model `Repository` instead
+ Parameter type is `[LSApiEndpointAttribute]`, which enables us to add any request parameter, such as adding headers, chainging http method, etc. We want this parameter to be query `String`

#### 2. Create a network model (Optional):
In most cases you wish to create a network model to serve as __[ACL pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer)__. This enables us to have our domain model separate from our external models (such as this networking and CoreData), making our domain model and our app logic immune to changes in backend and it's response which can contain various metadata (such as paging or analytics).

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
    //erased type would be: LSAnyDataSource<SearchRepositoriesEndpoint.Response, [LSApiEndpointAttribute], LSNetworkError>
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
    //erased type would be: LSAnyDataSource<Repository, [LSApiEndpointAttribute], LSNetworkError>

Almost there! We are now outputting our domain model `Repository` instead of initial `Data`, now we just need to map there parameter.

#### 5. Map the parameter
When mapping `Input` above we used `Mapper` class but for showcase purposes we will use  `paramMap` method with escaping closure:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
        .jsonDecodeMap(to: SearchRepositoriesEndpoint.Response.self)
        .outMap(with: SearchRepositoriesOutputMapper())
        .paramMap { (queryString: String) -> [LSApiEndpointAttribute] in
            return [.addUrlParameter(key: "q", value: queryString)]
        }
    //erased type would be: LSAnyDataSource<Repository, String, LSNetworkError>

#### 6. All done!
Now we have a `DataSource` which publishes our domain model object `Repository` and supports `String` argument to query.

What can we do with it? Since it's completely abstracted generic we can do many things, mostly interacting with other `DataSource` or `DataStorage`  with same output of `Repository`, such as caching, syncing and refreshing (or many other complex behaviours you can implement yourself!).

For showcase purposes let's create refresh functionality.

#### 7. (Optional) Refresh functionality

Let's say we have a text field or a search bar where user can input a query to search repositories. We would like to refresh our data source every time this text is inputted (i.e. user presses done, or on each text change, up to you).

Using the above code we can call `refreshable` method to create `LSRefreshableDataSource`:

    let queryRepositoriesDataSource = SearchRepositoriesEndpoint()
        .createDataSource()
        .jsonDecodeMap(to: SearchRepositoriesEndpoint.Response.self)
        .outMap(with: SearchRepositoriesOutputMapper())
        .paramMap { (queryString: String) -> [LSApiEndpointAttribute] in
            return [.addUrlParameter(key: "q", value: queryString)]
        }
        .refreshable(parameter: "")

That's it, just one line! Now each time our query changes we can call something like this:

    queryRepositoriesDataSource.refresh(with: "repositoryQueryText")

And all subscribers will be automatically notified on each change.
