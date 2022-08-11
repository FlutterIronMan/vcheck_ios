//
//  DemoStartViewModel.swift
//  VcheckSDKDemoIOS
//
//  Created by Kirill Kaun on 28.04.2022.
//

import Foundation

class VCheckStartViewModel {
    
    private var dataService: VCheckSDKRemoteDatasource = VCheckSDKRemoteDatasource.shared
    
    // MARK: - Constructor
    init() {}
    
    
    // MARK: - Properties
    private var timestamp: String?
    
    var currentStageResponse: StageResponse?
    
    var countries: [Country]?

    var error: VCheckApiError? {
        didSet { self.showAlertClosure?() }
    }
    var isLoading: Bool = false {
        didSet { self.updateLoadingStatus?() }
    }
    
    // MARK: - Closures for callback, since we are not using the ViewModel to the View.
    var showAlertClosure: (() -> ())?
    var updateLoadingStatus: (() -> ())?
    
    var didCreateVerif: (() -> ())?
    
    var didInitVerif: (() -> ())?
    
    var didFinishFetch: (() -> ())?
    var gotCountries: (() -> ())?
    
    var didReceivedCurrentStage: (() -> ())?
    
    
    // MARK: - Data calls
    
    func startVerifFlow() {
        self.isLoading = true
        
        self.dataService.requestServerTimestamp(completion: { (timestamp, error) in
            if let error = error {
                self.error = error
                self.isLoading = false
                return
            }
            self.timestamp = timestamp
            self.createVerifAttempt()
        })
    }
    
    func createVerifAttempt() {
        let languagePrefix = VCheckSDK.shared.getSDKLangCode()
        
        if (VCheckSDK.shared.verificationClientCreationModel == nil) {
            self.error = VCheckApiError(errorText: "Client error: Verification was not created properly",
                                        errorCode: VCheckApiError.DEFAULT_CODE)
            self.isLoading = false
            return
        }
        
        //print("VERIF MODEL TYPE: \(String(describing: VCheckSDK.shared.verificationClientCreationModel?.verificationType))")
        
        if let timestamp = self.timestamp {
            self.dataService.createVerificationRequest(timestamp: timestamp,
                                                       locale: languagePrefix,
                                                       verificationClientCreationModel:
                                                            VCheckSDK.shared.verificationClientCreationModel!,
                                                       completion: { (data, error) in
                if let error = error {
                    self.error = error
                    self.isLoading = false
                    return
                }
                
                //VCheckSDKLocalDatasource.shared.saveAccessToken(accessToken: data!.token!)
                VCheckSDK.shared.setVerificationToken(token: data!.token!)
                
                print("VERIF ::: CREATE ATTEMPT SUCCESS! DATA: \(String(describing: data))")
                
                self.initVerif()
            })
        } else {
            print("Error: server timestamp not set!")
        }
    }
    
    
    func initVerif() {
        
        self.dataService.initVerification(completion: { (data, error) in
            if let error = error {
                self.error = error
                self.isLoading = false
                return
            }
            
            print("VERIF ::: INIT SUCCESS! DATA: \(String(describing: data))")
            
            VCheckSDK.shared.setVerificationId(verifId: data!.id!)
            
            self.getCurrentStage()
        })
    }
    
    func getCurrentStage() {
        
        self.dataService.getCurrentStage(completion: { (data, error) in
            if let error = error {
                self.error = error
                self.isLoading = false
                return
            }
            
            print("VERIF ::: GOT CURRENT STAGE! DATA: \(String(describing: data))")
            
            if (data!.data != nil || data!.errorCode != nil) {
                self.currentStageResponse = data
                self.didReceivedCurrentStage!()
            }
        })
    }
    
    func getCountries() {
        
        self.dataService.getCountries(completion: { (data, error) in
            if let error = error {
                self.error = error
                self.isLoading = false
                return
            }
            
            //print("VERIF ::: GOT COUNTRIES! DATA: \(String(describing: data))")
                        
            if (data!.count > 0) {
                self.isLoading = false
                self.countries = data
                self.gotCountries!()
            }
        })
    }
    
}