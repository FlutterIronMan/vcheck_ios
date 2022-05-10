//
//  CheckDocPhotoViewModel.swift
//  VcheckSDKDemoIOS
//
//  Created by Kirill Kaun on 04.05.2022.
//

import Foundation
import UIKit

class CheckDocPhotoViewModel {
    
    private var dataService: RemoteDatasource = RemoteDatasource.shared
    
    // MARK: - Constructor
    init() {}
    
    
    // MARK: - Properties
    var uploadResponse: DocumentUploadResponseData? = nil

    var error: ApiError? {
        didSet { self.showAlertClosure?() }
    }
    var isLoading: Bool = false {
        didSet { self.updateLoadingStatus?() }
    }
    
    // MARK: - Closures for callback, since we are not using the ViewModel to the View.
    var showAlertClosure: (() -> ())?
    var updateLoadingStatus: (() -> ())?
    
    var didReceiveDocUploadResponse: (() -> ())?
    
    
    func sendDocForVerifUpload(photo1: UIImage, photo2: UIImage?) {
        
        self.isLoading = true
        
        let countryCode: String = LocalDatasource.shared.readSelectedCountryCode()
        
        let docType: Int = LocalDatasource.shared.getSelectedDocTypeWithData()!.category!
        
        let docTpeStr: String = "\(docType)"
        
        print("DOC TYPE: \(docTpeStr)")
    
        dataService.uploadVerificationDocuments(photo1: photo1,
                                                photo2: photo2,
                                                countryCode: countryCode,
                                                documentType: docTpeStr,
                                                completion: { (data, error) in
            if let error = error {
                self.isLoading = false
                self.error = error
                return
            }
                        
            self.isLoading = false
            self.uploadResponse = data
            self.didReceiveDocUploadResponse!()
        })
    }
}