//
//  CreateFullyNodedWalletViewController.swift
//  BitSense
//
//  Created by Peter on 27/06/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import UIKit

class CreateFullyNodedWalletViewController: UIViewController, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    
    @IBOutlet weak var multiSigOutlet: UIButton!
    @IBOutlet weak var singleSigOutlet: UIButton!
    
    var cosigner:Descriptor?
    var isDescriptor = false
    var onDoneBlock:(((Bool)) -> Void)?
    var spinner = ConnectingView()
    var ccXfp = ""
    var xpub = ""
    var deriv = ""
    var extendedKey = ""
    var isSegwit = false
    var isTaproot = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        singleSigOutlet.layer.cornerRadius = 8
        multiSigOutlet.layer.cornerRadius = 8
    }
    
    @IBAction func pasteAction(_ sender: Any) {
        if let data = UIPasteboard.general.data(forPasteboardType: "com.apple.traditional-mac-plain-text") {
            guard let string = String(bytes: data, encoding: .utf8) else {
                showAlert(vc: self, title: "", message: "Looks like you do not have valid text on your clipboard.")
                return
            }
            
            processPastedString(string)
        } else if let string = UIPasteboard.general.string {
           processPastedString(string)
        } else {
            showAlert(vc: self, title: "", message: "Not a supported import item. Please let us know about it so we can add it.")
        }
    }
    
    private func isExtendedKey(_ lowercased: String) -> Bool {
        if lowercased.hasPrefix("xprv") || lowercased.hasPrefix("tprv") || lowercased.hasPrefix("vprv") || lowercased.hasPrefix("yprv") || lowercased.hasPrefix("zprv") || lowercased.hasPrefix("uprv") || lowercased.hasPrefix("xpub") || lowercased.hasPrefix("tpub") || lowercased.hasPrefix("vpub") || lowercased.hasPrefix("ypub") || lowercased.hasPrefix("zpub") || lowercased.hasPrefix("upub") {
            return true
        } else {
            return false
        }
    }
    
    private func isDescriptor(_ lowercased: String) -> Bool {
        if lowercased.hasPrefix("wsh") || lowercased.hasPrefix("pkh") || lowercased.hasPrefix("sh") || lowercased.hasPrefix("combo") || lowercased.hasPrefix("wpkh") || lowercased.hasPrefix("addr") || lowercased.hasPrefix("multi") || lowercased.hasPrefix("sortedmulti") || lowercased.hasPrefix("tr(") {
            return true
        } else {
            return false
        }
    }
    
    private func processPastedString(_ string: String) {
        processImportedString(string)
    }
    
    @IBAction func fileAction(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Upload a file?", message: "Here you can upload files from your Hardware Wallets to easily create Fully Noded Wallet's", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Upload", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                var documentPicker:UIDocumentPickerViewController!
                
                if #available(iOS 14.0, *) {
                    documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
                } else {
                    documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
                }
                
                documentPicker.delegate = self
                documentPicker.modalPresentationStyle = .formSheet
                self.present(documentPicker, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func scanQrAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToScanner", sender: self)
        }
    }
    
    @IBAction func automaticAction(_ sender: Any) {
        promptForSingleSigFormat()
    }
    
    private func promptForSingleSigFormat() {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Choose an address format.", message: "", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Segwit", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.isSegwit = true
                self.segueToSingleSigCreator()
            }))
            
            alert.addAction(UIAlertAction(title: "Taproot", style: .default, handler: { [weak self] action in
                guard let self = self else { return }
                
                self.isTaproot = true
                self.segueToSingleSigCreator()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func segueToSingleSigCreator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToSeedWords", sender: self)
        }
    }
    
    @IBAction func manualAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "seguToManualCreation", sender: self)
        }
    }
    
    @IBAction func createMultiSigAction(_ sender: Any) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToCreateMultiSig", sender: self)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let data = try? Data(contentsOf: urls[0].absoluteURL) else {
            spinner.removeConnectingView()
            showAlert(vc: self, title: "", message: "That does not appear to be a recognized wallet backup/export/import file")
            return
        }
        
        guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
            
            guard let txt = String(bytes: data, encoding: .utf8) else {
                spinner.removeConnectingView()
                showAlert(vc: self, title: "", message: "That does not appear to be a recognized wallet backup/export/import file")
                return
            }
            
            self.processImportedString(txt)
            
            return
        }
        
        if let extendedPublicKeys = dict["extendedPublicKeys"] as? NSArray,
           let quorum = dict["quorum"] as? NSDictionary,
           let requiredSigners = quorum["requiredSigners"] as? Int {
            let name = dict["name"] as? String ?? "Unchained"
            var descriptor = "sh(sortedmulti(\(requiredSigners),"
            
            for (i, key) in extendedPublicKeys.enumerated() {
                if let keyDict = key as? NSDictionary {
                    if var keyPath = keyDict["bip32Path"] as? String,
                       let xfp = keyDict["xfp"] as? String,
                       let xpub = keyDict["xpub"] as? String {
                        
                        if keyPath != "Unknown" {
                            keyPath = "[\(keyPath.replacingOccurrences(of: "m", with: xfp))]\(xpub)/0/*"
                        } else {
                            keyPath = "[\(xfp)]\(xpub)/0/*"
                        }
                        
                        descriptor += keyPath
                        
                        if i + 1 == extendedPublicKeys.count {
                            descriptor += "))"
                            let accountMap = ["descriptor": descriptor, "blockheight": 0, "watching": [], "label": name] as [String : Any]
                            promptToImportUnchained(accountMap)
                        } else {
                            descriptor += ","
                        }
                    }
                }
            }
        }
        
        if let _ = dict["chain"] as? String {
            /// We think its a coldcard skeleton import
            promptToImportColdcardSingleSig(dict)
            
        } else if let deriv = dict["p2wsh_deriv"] as? String, let xfp = dict["xfp"] as? String, let p2wsh = dict["p2wsh"] as? String {
            /// It is most likely a multi-sig wallet export
            let origin = deriv.replacingOccurrences(of: "m", with: xfp)
            let descriptor = "wsh([\(origin)]\(p2wsh)/0/*)"
            promptToImportColdcardMsig(Descriptor(descriptor))
            
            
        } else if let _ = dict["wallet_type"] as? String {
            /// We think its an Electrum wallet
            promptToImportElectrumMsig(dict)
            
        } else if let _ = dict["descriptor"] as? String {
            promptToImportAccountMap(dict: dict)
            
        } else if let _ = dict["ExtPubKey"] as? String {
            promptToImportCoboSingleSig(dict)
        }
    }
    
    private func promptToImportUnchained(_ dict: [String:Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Import your Unchained Capital multi sig wallet?", message: "Looks like you selected a multi sig wallet. You can easily recreate the wallet as watchonly with Fully Noded, just tap \"import\".", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { action in
                self.importAccountMap(dict)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func promptToImportMultiSig(_ dict: [String:Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Import your multi sig wallet?", message: "Looks like you selected a multi sig wallet. You can easily recreate the wallet as watchonly with Fully Noded, just tap \"import\".", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { action in
                self.importAccountMap(dict)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func promptToImportCoboSingleSig(_ dict: [String:Any]) {
        guard let extPubKey = dict["ExtPubKey"] as? String,
            let xfp = dict["MasterFingerprint"] as? String,
            let deriv = dict["AccountKeyPath"] as? String,
            let xpub = XpubConverter.convert(extendedKey: extPubKey) else {
            showAlert(vc: self, title: "Error converting that wallet import", message: "Please let us know about this issue so we can fix it.")
                
            return
        }
        
        var desc = ""
        
        if extPubKey.hasPrefix("xpub") || extPubKey.hasPrefix("tpub") {
            desc = "pkh([\(xfp)/\(deriv)]\(xpub)/0/*)"
            
        } else if extPubKey.hasPrefix("vpub") || extPubKey.hasPrefix("zpub") {
            desc = "wpkh([\(xfp)/\(deriv)]\(xpub)/0/*)"
            
        } else if extPubKey.hasPrefix("ypub") || extPubKey.hasPrefix("upub") {
            desc = "sh(wpkh([\(xfp)/\(deriv)]\(xpub)/0/*))"
            
        }
        
        let accountMap = ["descriptor": desc, "blockheight": 0, "watching": [], "label": "Wallet import"] as [String : Any]
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Import single sig?", message: "Looks like you selected a single sig wallet. You can easily recreate the wallet as watchonly with Fully Noded, just tap \"import\".", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { action in
                self.importAccountMap(accountMap)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func promptToImportElectrumMsig(_ dict: [String:Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Import your Electrum multisig wallet?", message: "Looks like you selected an Electrum wallet backup file. You can easily recreate the wallet as watchonly with Fully Noded, just tap \"import\".", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { action in
                guard let accountMap = self.convertElectrumToAccountMap(dict) else {
                    showAlert(vc: self, title: "Uh oh", message: "We had an issue converting that backup file to a wallet... Please reach out on Telegram, Github or Twitter so we can fix it.")
                    return
                }
                
                self.importAccountMap(accountMap)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = self.view
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func convertElectrumToAccountMap(_ dict: [String:Any]) -> [String:Any]? {
        guard let descriptor = getDescriptorFromElectrumBackUp(dict) else { return nil }
        
        return ["descriptor": descriptor, "blockheight": 0, "watching": [], "label": "Electrum wallet"]
    }
    
    private func getDescriptorFromElectrumBackUp(_ dict: [String:Any]) -> String? {
        guard let walletType = dict["wallet_type"] as? String else { return nil }
        
        let processed = walletType.replacingOccurrences(of: "of", with: " ")
        let arr = processed.split(separator: " ")
        
        guard arr.count > 0 else { return nil }
        
        let m = "\(arr[0])"
        var keys = [[String:String]]()
        var derivationPathToUse = ""
        
        for (key, value) in dict {
            
            if key.hasPrefix("x") && key.hasSuffix("/") {
                
                guard let dict = value as? NSDictionary else { return nil }
                
                var keyToUse = [String:String]()
                
                if let derivation = dict["derivation"] as? String {
                    if derivation != "null" {
                        if derivation == "m/48'/0'/0'/2'" || derivation == "m/48'/1'/0'/2'" {
                            keyToUse["derivation"] = derivation
                            derivationPathToUse = derivation
                        }
                    }
                }
                
                if let root_fingerprint = dict["root_fingerprint"] as? String {
                    if root_fingerprint != "null" {
                        keyToUse["fingerprint"] = root_fingerprint
                    } else {
                        keyToUse["fingerprint"] = "00000000"
                    }
                } else {
                    keyToUse["fingerprint"] = "00000000"
                }
                
                guard let xpub = dict["xpub"] as? String, xpub.hasPrefix("Zpub") || xpub.hasPrefix("Vpub"), let convertedXpub = XpubConverter.convert(extendedKey: xpub) else {
                    showAlert(vc: self, title: "Unsupported script type", message: "Sorry but for now as this is a new feature we are only supporting the default script type p2wsh, if you would like the app to support other script types please make a request on Twitter, GitHub or Telegram.")
                    return nil
                }
                
                keyToUse["xpub"] = convertedXpub
                
                keys.append(keyToUse)
            }
        }
        
        guard derivationPathToUse == "m/48'/0'/0'/2'" || derivationPathToUse == "m/48'/1'/0'/2'" else {
            showAlert(vc: self, title: "Unsupported derivation", message: "Sorry, for now we only support m/48'/0'/0'/2' or m/48'/1'/0'/2'")
            return nil
        }
        
        for (i, key) in keys.enumerated() {
            if key["derivation"] == nil {
                keys[i]["derivation"] = derivationPathToUse
            }
        }
        
        var keysArray = [String]()
        
        for key in keys {
            guard let xpub = key["xpub"], var deriv = key["derivation"] else { return nil }
                        
            let xfp = key["fingerprint"] ?? "00000000"
            deriv = deriv.replacingOccurrences(of: "m/", with: "\(xfp)/")
            let str = "[\(deriv)]\(xpub)/0/*"
            keysArray.append(str)
        }
        
        var keysString = keysArray.description.replacingOccurrences(of: "[\"[", with: "[")
        keysString = keysString.replacingOccurrences(of: "*\"]", with: "*")
        keysString = keysString.replacingOccurrences(of: "\\", with: "")
        keysString = keysString.replacingOccurrences(of: "\"", with: "")
        keysString = keysString.replacingOccurrences(of: " ", with: "")
        
        return "wsh(sortedmulti(\(m),\(keysString)))"
    }
    
    private func promptToImportColdcardMsig(_ desc: Descriptor) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Create a multisig with your Coldcard?", message: "You have uploaded a Coldcard multisig file, this action allows you to easily create a wallet with your Coldcard and Fully Noded.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { action in
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.cosigner = desc
                    vc.performSegue(withIdentifier: "segueToCreateMultiSig", sender: vc)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func promptToImportColdcardSingleSig(_ coldcard: [String:Any]) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Create a single sig with your Coldcard?", message: "You have uploaded a Coldcard single sig file, this action will recreate your Coldcard wallet on Fully Noded using its xpubs.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { action in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .addColdCard, object: nil, userInfo: coldcard)
                    vc.navigationController?.popViewController(animated: true)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func importAccountMap(_ accountMap: [String:Any]) {
        spinner.addConnectingView(vc: self, description: "importing...")
        
        func importAccount() {
            if let _ = accountMap["descriptor"] as? String {
                if (accountMap["blockheight"] as? Int) != nil || (accountMap["blockheight"] as? Int64) != nil {
                    /// It is an Account Map.
                    ImportWallet.accountMap(accountMap) { (success, errorDescription) in
                        if success {
                            DispatchQueue.main.async {
                                self.spinner.removeConnectingView()
                                self.onDoneBlock!(true)
                                self.navigationController?.popViewController(animated: true)
                            }
                        } else {
                            self.spinner.removeConnectingView()
                            showAlert(vc: self, title: "Error", message: "There was an error importing your wallet: \(errorDescription ?? "unknown")")
                        }
                    }
                }
            } else if let _ = accountMap["ExtPubKey"] as? String {
                spinner.removeConnectingView()
                promptToImportCoboSingleSig(accountMap)
            }
        }
        
        if let url = accountMap["quickConnect"] as? String {
            QuickConnect.addNode(uncleJim: true, url: url) { (success, errorMessage) in
                guard success else {
                    self.spinner.removeConnectingView()
                    showAlert(vc: self, title: "Node connection issue:", message: errorMessage ?? "unknown error")
                    return
                }
                
                importAccount()
            }
        } else {
            importAccount()
        }
    }
    
    private func promptToImportAccountMap(dict: [String:Any]) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Import wallet?", message: "Looks like you have selected a valid wallet format ✓", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { [unowned vc = self] action in
                vc.importAccountMap(dict)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func setPrimDesc(descriptors: [String], descriptorToUseIndex: Int) {
        var accountMap:[String:Any] = ["descriptor": "", "blockheight": 0, "watching": [], "label": "Wallet Import"]
        let primDesc = descriptors[descriptorToUseIndex]
        accountMap["descriptor"] = primDesc
        
        let desc = Descriptor("\(primDesc)")
        if desc.isCosigner {
            self.ccXfp = desc.fingerprint
            self.xpub = desc.accountXpub
            self.deriv = desc.derivation
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.performSegue(withIdentifier: "segueToCreateMultiSig", sender: self)
            }
        } else {
            self.importAccountMap(accountMap)
        }
    }
    
    private func prompToChoosePrimaryDesc(descriptors: [String]) {
        DispatchQueue.main.async { [unowned vc = self] in
            let alert = UIAlertController(title: "Choose an address format.", message: "", preferredStyle: .alert)
            
            for (i, descriptor) in descriptors.enumerated() {
                let descStr = Descriptor(descriptor)
                
                alert.addAction(UIAlertAction(title: descStr.scriptType, style: .default, handler: { [weak self] action in
                    guard let self = self else { return }
                    
                    self.setPrimDesc(descriptors: descriptors, descriptorToUseIndex: i)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            alert.popoverPresentationController?.sourceView = vc.view
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    private func processImportedString(_ item: String) {
        let lowercased = item.lowercased()
        
        if self.isExtendedKey(lowercased) {
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isDescriptor = false
                self.extendedKey = item
                self.performSegue(withIdentifier: "segueToImportXpub", sender: self)
            }
            
        } else if self.isDescriptor(lowercased) {
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isDescriptor = true
                self.extendedKey = item
                self.performSegue(withIdentifier: "segueToImportXpub", sender: self)
            }
            
        } else if lowercased.hasPrefix("ur:") {
            if lowercased.hasPrefix("ur:bytes") {
                let (text, err) = URHelper.parseBlueWalletCoordinationSetup(lowercased)
                if let textFile = text {
                     if let dict = try? JSONSerialization.jsonObject(with: textFile.utf8, options: []) as? [String:Any] {
                        let importStruct = WalletImport(dict)
                        
                        var descriptors:[String] = []
                        
                        if let bip44 = importStruct.bip44 {
                            descriptors.append(bip44)
                        }
                        if let bip49 = importStruct.bip49 {
                            descriptors.append(bip49)
                        }
                        if let bip84 = importStruct.bip84 {
                            descriptors.append(bip84)
                        }
                        if let bip48 = importStruct.bip48 {
                            descriptors.append(bip48)
                        }
                        
                        self.prompToChoosePrimaryDesc(descriptors: descriptors)
                        
                     } else if let accountMap = TextFileImport.parse(textFile).accountMap {
                        self.importAccountMap(accountMap)
                            
                    } else {
                        showAlert(vc: self, title: "Error", message: err ?? "Unknown error decoding the text file into a descriptor.")
                    }
                } else {
                    showAlert(vc: self, title: "Error", message: err ?? "Unknown error decoding the QR code.")
                }
                
            } else {
                let (descriptors, error) = URHelper.parseUr(urString: item)
                
                guard error == nil, let descriptors = descriptors else {
                    showAlert(vc: self, title: "Error", message: error ?? "Unknown error decoding the QR code.")
                    return
                }
                
                var accountMap:[String:Any] = ["descriptor": "", "blockheight": 0, "watching": [], "label": "Wallet Import"]
                
                if descriptors.count > 1 {
                    self.prompToChoosePrimaryDesc(descriptors: descriptors)
                } else {
                    let desc = Descriptor("\(descriptors[0])")
                    if desc.isCosigner {
                        self.ccXfp = desc.fingerprint
                        self.xpub = desc.accountXpub
                        self.deriv = desc.derivation
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            self.performSegue(withIdentifier: "segueToCreateMultiSig", sender: self)
                        }
                    } else {
                        accountMap["descriptor"] = descriptors[0]
                        self.importAccountMap(accountMap)
                    }
                }
            }
            
        } else if Keys.validMnemonic(item) {
            let (descriptors, message) = Keys.descriptorsFromSigner(item)
            
            guard let encryptedSigner = Crypto.encrypt(item.utf8) else {
                showAlert(vc: self, title: "Unable to encrypt your signer.", message: "Please let us know about this bug.")
                return
            }
            
            let dict = ["id":UUID(), "words":encryptedSigner, "added": Date()] as [String:Any]
            CoreDataService.saveEntity(dict: dict, entityName: .signers) { success in
                guard success else {
                    return
                }
                
                guard let descriptors = descriptors else {
                    showAlert(vc: self, title: "Unable to derive descriptors...", message: "Please let us know about this issue. Error: \(message ?? "unknown.")")
                    return
                }
                
                self.prompToChoosePrimaryDesc(descriptors: descriptors)
            }
            
        } else if let accountMap = try? JSONSerialization.jsonObject(with: item.utf8, options: []) as? [String:Any] {
            self.importAccountMap(accountMap)
            
        } else if let accountMap = TextFileImport.parse(item).accountMap {
            self.importAccountMap(accountMap)
            
        } else {
            showAlert(vc: self, title: "Unsupported import.", message: item + " is not a supported import option, please let us know about this so we can add support.")
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "segueToSeedWords":
            guard let vc = segue.destination as? SeedDisplayerViewController else { fallthrough }
            
            vc.isSegwit = isSegwit
            vc.isTaproot = isTaproot
            
        case "segueToScanner":
            if #available(macCatalyst 14.0, *) {
                guard let vc = segue.destination as? QRScannerViewController else { fallthrough }
                
                vc.isImporting = true
                vc.onDoneBlock = { [weak self] item in
                    guard let self = self else { return }
                    
                    guard let item = item else {
                        return
                    }
                    
                    // needs to check AM too
                    self.processImportedString(item)
                }
            }
            
        case "segueToCreateMultiSig":
            guard let vc = segue.destination as? CreateMultisigViewController else { fallthrough }
            
            vc.cosigner = cosigner
            
        case "segueToImportDescriptor":
            guard let vc = segue.destination as? ImportXpubViewController else { fallthrough }
            
            vc.isDescriptor = true
            
        case "segueToImportXpub":
            guard let vc = segue.destination as? ImportXpubViewController else { fallthrough }
            
            vc.isDescriptor = self.isDescriptor
            vc.extKey = self.extendedKey
            
        default:
            break
        }
    }
}
