//
// DefaultAPI.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation
import Alamofire



open class DefaultAPI: APIBase {
    /**
     Add a file or directory to ipfs.
     
     - parameter file: (form) This endpoint expects a file in the body of the request as ‘multipart/form-data’.  
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func add(file: URL, completion: @escaping ((_ data: AddResponse?,_ error: Error?) -> Void)) {
        addWithRequestBuilder(file: file).execute { (response, error) -> Void in
            completion(response?.body, error);
        }
    }


    /**
     Add a file or directory to ipfs.
     - POST /add
     - examples: [{contentType=application/json, example={
  "Size" : "193960",
  "Hash" : "QmU6A9DYK4N7dvgcrmr9YRjJ4RNxAE6HnMjBBPLGedqVT7",
  "Name" : "The Cathedral and the Bazaar.pdf"
}}]
     
     - parameter file: (form) This endpoint expects a file in the body of the request as ‘multipart/form-data’.  

     - returns: RequestBuilder<AddResponse> 
     */
    open class func addWithRequestBuilder(file: URL) -> RequestBuilder<AddResponse> {
        let path = "/add"
        let URLString = SwaggerClientAPI.basePath + path
        let formParams: [String:Any?] = [
            "file": file
        ]

        let nonNullParameters = APIHelper.rejectNil(formParams)
        let parameters = APIHelper.convertBoolToString(nonNullParameters)

        let url = NSURLComponents(string: URLString)


        let requestBuilder: RequestBuilder<AddResponse>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

    /**
     Show IPFS object data.
     
     - parameter arg: (query) The path to the IPFS object(s) to be outputted.  
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func cat(arg: String, completion: @escaping ((_ data: Data?,_ error: Error?) -> Void)) {
        catWithRequestBuilder(arg: arg).execute { (response, error) -> Void in
            completion(response?.body, error);
        }
    }


    /**
     Show IPFS object data.
     - GET /cat
     - examples: [{output=none}]
     
     - parameter arg: (query) The path to the IPFS object(s) to be outputted.  

     - returns: RequestBuilder<Data> 
     */
    open class func catWithRequestBuilder(arg: String) -> RequestBuilder<Data> {
        let path = "/cat"
        let URLString = SwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil

        let url = NSURLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems(values:[
            "arg": arg
        ])
        

        let requestBuilder: RequestBuilder<Data>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

    /**
     * enum for parameter type
     */
    public enum ModelType_keygen: String { 
        case rsa = "rsa"
        case ed25519 = "ed25519"
    }

    /**
     Create a new keypair
     
     - parameter arg: (query) Name of key to create. 
     - parameter type: (query) Type of the key to create. 
     - parameter size: (query) Size of the key to generate 
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func keygen(arg: String, type: ModelType_keygen, size: Int32, completion: @escaping ((_ data: KeygenResponse?,_ error: Error?) -> Void)) {
        keygenWithRequestBuilder(arg: arg, type: type, size: size).execute { (response, error) -> Void in
            completion(response?.body, error);
        }
    }


    /**
     Create a new keypair
     - GET /key/gen
     - examples: [{contentType=application/json, example=""}]
     
     - parameter arg: (query) Name of key to create. 
     - parameter type: (query) Type of the key to create. 
     - parameter size: (query) Size of the key to generate 

     - returns: RequestBuilder<KeygenResponse> 
     */
    open class func keygenWithRequestBuilder(arg: String, type: ModelType_keygen, size: Int32) -> RequestBuilder<KeygenResponse> {
        let path = "/key/gen"
        let URLString = SwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil

        let url = NSURLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems(values:[
            "arg": arg, 
            "type": type.rawValue, 
            "size": size.encodeToJSON()
        ])
        

        let requestBuilder: RequestBuilder<KeygenResponse>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

    /**
     List all local keypairs
     
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func listKeys(completion: @escaping ((_ data: ListKeysResponse?,_ error: Error?) -> Void)) {
        listKeysWithRequestBuilder().execute { (response, error) -> Void in
            completion(response?.body, error);
        }
    }


    /**
     List all local keypairs
     - GET /key/list
     - examples: [{contentType=application/json, example=""}]

     - returns: RequestBuilder<ListKeysResponse> 
     */
    open class func listKeysWithRequestBuilder() -> RequestBuilder<ListKeysResponse> {
        let path = "/key/list"
        let URLString = SwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil

        let url = NSURLComponents(string: URLString)


        let requestBuilder: RequestBuilder<ListKeysResponse>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

    /**
     IPNS is a PKI namespace, where names are the hashes of public keys, and the private key enables publishing new (signed) values. In both publish and resolve, the default name used is the node's own PeerID, which is the hash of its public key.
     
     - parameter arg: (query) ipfs path of the object to be published.  
     - parameter key: (query) Name of the key to be used, as listed by ‘ipfs key list’. Default is “self”.  (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func publish(arg: String, key: String? = nil, completion: @escaping ((_ data: PublishResponse?,_ error: Error?) -> Void)) {
        publishWithRequestBuilder(arg: arg, key: key).execute { (response, error) -> Void in
            completion(response?.body, error);
        }
    }


    /**
     IPNS is a PKI namespace, where names are the hashes of public keys, and the private key enables publishing new (signed) values. In both publish and resolve, the default name used is the node's own PeerID, which is the hash of its public key.
     - GET /name/publish
     - examples: [{contentType=application/json, example={
  "Value" : "/ipfs/QmU6A9DYK4N7dvgcrmr9YRjJ4RNxAE6HnMjBBPLGedqVT7",
  "Name" : "QmXXcnBhtXB7dFFxwEyzG1YctDU8ZpcKweQcKp1JHXktn8"
}}]
     
     - parameter arg: (query) ipfs path of the object to be published.  
     - parameter key: (query) Name of the key to be used, as listed by ‘ipfs key list’. Default is “self”.  (optional)

     - returns: RequestBuilder<PublishResponse> 
     */
    open class func publishWithRequestBuilder(arg: String, key: String? = nil) -> RequestBuilder<PublishResponse> {
        let path = "/name/publish"
        let URLString = SwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil

        let url = NSURLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems(values:[
            "arg": arg, 
            "key": key
        ])
        

        let requestBuilder: RequestBuilder<PublishResponse>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

    /**
     List all local keypairs
     
     - parameter arg: (query) Name of key to remove. 
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func removeKey(arg: String, completion: @escaping ((_ data: RemoveKeyResponse?,_ error: Error?) -> Void)) {
        removeKeyWithRequestBuilder(arg: arg).execute { (response, error) -> Void in
            completion(response?.body, error);
        }
    }


    /**
     List all local keypairs
     - GET /key/rm
     - examples: [{contentType=application/json, example=""}]
     
     - parameter arg: (query) Name of key to remove. 

     - returns: RequestBuilder<RemoveKeyResponse> 
     */
    open class func removeKeyWithRequestBuilder(arg: String) -> RequestBuilder<RemoveKeyResponse> {
        let path = "/key/rm"
        let URLString = SwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil

        let url = NSURLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems(values:[
            "arg": arg
        ])
        

        let requestBuilder: RequestBuilder<RemoveKeyResponse>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

    /**
     IPNS is a PKI namespace, where names are the hashes of public keys, and the private key enables publishing new (signed) values. In both publish and resolve, the default name used is the node's own PeerID, which is the hash of its public key.
     
     - parameter arg: (query) The IPNS name to resolve.  
     - parameter recursive: (query) Resolve until the result is not an IPNS name. Default is false.  (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func resolve(arg: String, recursive: Bool? = nil, completion: @escaping ((_ data: ResolveResponse?,_ error: Error?) -> Void)) {
        resolveWithRequestBuilder(arg: arg, recursive: recursive).execute { (response, error) -> Void in
            completion(response?.body, error);
        }
    }


    /**
     IPNS is a PKI namespace, where names are the hashes of public keys, and the private key enables publishing new (signed) values. In both publish and resolve, the default name used is the node's own PeerID, which is the hash of its public key.
     - GET /name/resolve
     - examples: [{contentType=application/json, example={
  "Path" : "/ipfs/QmU6A9DYK4N7dvgcrmr9YRjJ4RNxAE6HnMjBBPLGedqVT7"
}}]
     
     - parameter arg: (query) The IPNS name to resolve.  
     - parameter recursive: (query) Resolve until the result is not an IPNS name. Default is false.  (optional)

     - returns: RequestBuilder<ResolveResponse> 
     */
    open class func resolveWithRequestBuilder(arg: String, recursive: Bool? = nil) -> RequestBuilder<ResolveResponse> {
        let path = "/name/resolve"
        let URLString = SwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil

        let url = NSURLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems(values:[
            "arg": arg, 
            "recursive": recursive
        ])
        

        let requestBuilder: RequestBuilder<ResolveResponse>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

}
