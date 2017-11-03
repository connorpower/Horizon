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
     
     - parameter file: (form) This endpoint expects a file in the body of the request as ‘multipart/form-data’.  (optional)
     - parameter recursive: (query) Add directory paths recursively. Defaults to false.  (optional)
     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func add(file: URL? = nil, recursive: Bool? = nil, completion: @escaping ((_ data: InlineResponse200?,_ error: Error?) -> Void)) {
        addWithRequestBuilder(file: file, recursive: recursive).execute { (response, error) -> Void in
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
     
     - parameter file: (form) This endpoint expects a file in the body of the request as ‘multipart/form-data’.  (optional)
     - parameter recursive: (query) Add directory paths recursively. Defaults to false.  (optional)

     - returns: RequestBuilder<InlineResponse200> 
     */
    open class func addWithRequestBuilder(file: URL? = nil, recursive: Bool? = nil) -> RequestBuilder<InlineResponse200> {
        let path = "/add"
        let URLString = SwaggerClientAPI.basePath + path
        let formParams: [String:Any?] = [
            "file": file
        ]

        let nonNullParameters = APIHelper.rejectNil(formParams)
        let parameters = APIHelper.convertBoolToString(nonNullParameters)

        let url = NSURLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems(values:[
            "recursive": recursive
        ])
        

        let requestBuilder: RequestBuilder<InlineResponse200>.Type = SwaggerClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

}
