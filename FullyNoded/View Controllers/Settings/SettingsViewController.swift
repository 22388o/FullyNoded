//
//  SettingsViewController.swift
//  BitSense
//
//  Created by Peter on 08/10/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import UIKit
import AuthenticationServices

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    let ud = UserDefaults.standard
    let spinner = ConnectingView()
    private var authenticated = false
    @IBOutlet var settingsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTable.delegate = self
                        
        if UserDefaults.standard.object(forKey: "useEsplora") == nil && UserDefaults.standard.object(forKey: "useEsploraWarning") == nil {            
            UserDefaults.standard.setValue(true, forKey: "useEsploraWarning")
        }
        
        if UserDefaults.standard.object(forKey: "useBlockchainInfo") == nil {
            UserDefaults.standard.set(true, forKey: "useBlockchainInfo")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        settingsTable.reloadData()
    }
    
    private func show2fa() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    private func configureCell(_ cell: UITableViewCell) {
        cell.selectionStyle = .none
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.borderWidth = 0.5
        cell.backgroundColor = #colorLiteral(red: 0.05172085258, green: 0.05855310153, blue: 0.06978280196, alpha: 1)
    }
    
    private func settingsCell(_ indexPath: IndexPath) -> UITableViewCell {
        let settingsCell = settingsTable.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        configureCell(settingsCell)
        
        let label = settingsCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        label.adjustsFontSizeToFitWidth = true
        
        let background = settingsCell.viewWithTag(2)!
        background.clipsToBounds = true
        background.layer.cornerRadius = 8
        
        let icon = settingsCell.viewWithTag(3) as! UIImageView
        icon.tintColor = .white
        
        switch indexPath.section {
        case 0:
            label.text = "Node Manager"
            icon.image = UIImage(systemName: "desktopcomputer")
            background.backgroundColor = .systemBlue
            
        case 1:
            switch indexPath.row {
            case 0:
                label.text = "Wallet Backup"
                icon.image = UIImage(systemName: "square.grid.3x1.folder.badge.plus")
                background.backgroundColor = .systemGreen
            case 1:
                label.text = "Wallet Recovery"
                icon.image = UIImage(systemName: "square.grid.3x1.folder.badge.plus")
                background.backgroundColor = .systemPurple
            default:
                break
            }
            
        case 2:
            label.text = "Security Center"
            icon.image = UIImage(systemName: "lock.shield")
            background.backgroundColor = .systemOrange
            
        
            
        default:
            break
        }
        
        return settingsCell
    }
    
    func esploraCell(_ indexPath: IndexPath) -> UITableViewCell {
        let esploraCell = settingsTable.dequeueReusableCell(withIdentifier: "toggleCell", for: indexPath)
        configureCell(esploraCell)
        
        let label = esploraCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        label.adjustsFontSizeToFitWidth = true
        
        let background = esploraCell.viewWithTag(2)!
        background.clipsToBounds = true
        background.layer.cornerRadius = 8
        
        let icon = esploraCell.viewWithTag(3) as! UIImageView
        icon.tintColor = .white
        
        let toggle = esploraCell.viewWithTag(4) as! UISwitch
        toggle.addTarget(self, action: #selector(toggleEsplora(_:)), for: .valueChanged)
        
        guard let useEsplora = UserDefaults.standard.object(forKey: "useEsplora") as? Bool, useEsplora else {
            toggle.setOn(false, animated: true)
            label.text = "Esplora disabled"
            icon.image = UIImage(systemName: "shield.fill")
            background.backgroundColor = .systemGreen
            return esploraCell
        }
        
        toggle.setOn(true, animated: true)
        label.text = "Esplora enabled"
        icon.image = UIImage(systemName: "shield.slash.fill")
        background.backgroundColor = .systemOrange
        
        return esploraCell
    }
    
    func iCloudCell(_ indexPath: IndexPath) -> UITableViewCell {
        let iCloudCell = settingsTable.dequeueReusableCell(withIdentifier: "toggleCell", for: indexPath)
        configureCell(iCloudCell)

        let label = iCloudCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        label.adjustsFontSizeToFitWidth = true

        let background = iCloudCell.viewWithTag(2)!
        background.clipsToBounds = true
        background.layer.cornerRadius = 8

        let icon = iCloudCell.viewWithTag(3) as! UIImageView
        icon.tintColor = .white

        let toggle = iCloudCell.viewWithTag(4) as! UISwitch
        toggle.addTarget(self, action: #selector(toggleiCloud(_:)), for: .valueChanged)

        guard let enabled = UserDefaults.standard.object(forKey: "iCloudBackup") as? Bool, enabled else {
            toggle.setOn(false, animated: true)
            label.text = "iCloud backup disabled"
            icon.image = UIImage(systemName: "xmark.shield")
            background.backgroundColor = .systemRed
            return iCloudCell
        }

        toggle.setOn(enabled, animated: true)
        label.text = "iCloud backup enabled"
        icon.image = UIImage(systemName: "checkmark.shield.fill")
        background.backgroundColor = .systemGreen

        return iCloudCell
    }
    
    func blockchainInfoCell(_ indexPath: IndexPath) -> UITableViewCell {
        let blockchainInfoCell = settingsTable.dequeueReusableCell(withIdentifier: "toggleCell", for: indexPath)
        configureCell(blockchainInfoCell)
        
        let label = blockchainInfoCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        label.adjustsFontSizeToFitWidth = true
        
        let background = blockchainInfoCell.viewWithTag(2)!
        background.clipsToBounds = true
        background.layer.cornerRadius = 8
        
        let icon = blockchainInfoCell.viewWithTag(3) as! UIImageView
        icon.tintColor = .white
        
        let toggle = blockchainInfoCell.viewWithTag(4) as! UISwitch
        toggle.addTarget(self, action: #selector(toggleBlockchainInfo(_:)), for: .valueChanged)
        
        let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
        
        toggle.setOn(useBlockchainInfo, animated: true)
        label.text = "Blockchain.info"
        icon.image = UIImage(systemName: "dollarsign.circle")
        
        if useBlockchainInfo {
            background.backgroundColor = .systemBlue
        } else {
            background.backgroundColor = .systemGray
        }
        
        return blockchainInfoCell
    }
    
    func coinDeskCell(_ indexPath: IndexPath) -> UITableViewCell {
        let coinDeskCell = settingsTable.dequeueReusableCell(withIdentifier: "toggleCell", for: indexPath)
        configureCell(coinDeskCell)
        
        let label = coinDeskCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        label.adjustsFontSizeToFitWidth = true
        
        let background = coinDeskCell.viewWithTag(2)!
        background.clipsToBounds = true
        background.layer.cornerRadius = 8
        
        let icon = coinDeskCell.viewWithTag(3) as! UIImageView
        icon.tintColor = .white
        
        let toggle = coinDeskCell.viewWithTag(4) as! UISwitch
        toggle.addTarget(self, action: #selector(toggleCoindesk(_:)), for: .valueChanged)
        
        let useBlockchainInfo = UserDefaults.standard.object(forKey: "useBlockchainInfo") as? Bool ?? true
        
        toggle.setOn(!useBlockchainInfo, animated: true)
        label.text = "Coindesk"
        icon.image = UIImage(systemName: "dollarsign.circle")
        
        if useBlockchainInfo {
            background.backgroundColor = .systemGray
        } else {
            background.backgroundColor = .systemBlue
        }
        
        return coinDeskCell
    }
    
    func currencyCell(_ indexPath: IndexPath, _ currency: String) -> UITableViewCell {
        let currencyCell = settingsTable.dequeueReusableCell(withIdentifier: "toggleCell", for: indexPath)
        configureCell(currencyCell)
        
        let label = currencyCell.viewWithTag(1) as! UILabel
        label.textColor = .lightGray
        label.adjustsFontSizeToFitWidth = true
        
        let background = currencyCell.viewWithTag(2)!
        background.clipsToBounds = true
        background.layer.cornerRadius = 8
        
        label.text = currency
        
        let icon = currencyCell.viewWithTag(3) as! UIImageView
        icon.tintColor = .white
        
        let toggle = currencyCell.viewWithTag(4) as! UISwitch
        toggle.restorationIdentifier = currency
        toggle.addTarget(self, action: #selector(toggleCurrency(_:)), for: .valueChanged)
        
        let currencyToUse = UserDefaults.standard.object(forKey: "currency") as? String ?? "USD"
        
        if currencyToUse == currency {
            background.backgroundColor = .systemGreen
        } else {
            background.backgroundColor = .systemGray
        }
        
        toggle.setOn(currencyToUse == currency, animated: true)
        
        switch currency {
        case "USD":
            icon.image = UIImage(systemName: "dollarsign.circle")
        case "GBP":
            icon.image = UIImage(systemName: "sterlingsign.circle")
        case "EUR":
            icon.image = UIImage(systemName: "eurosign.circle")
        default:
            break
        }
        
        return currencyCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0, 2:
            return settingsCell(indexPath)
            
        case 1:
            switch indexPath.row {
            case 0, 1: return settingsCell(indexPath)
            case 2: return iCloudCell(indexPath)
            default:
                return UITableViewCell()
            }
            
        case 3:
            switch indexPath.row {
            case 0: return esploraCell(indexPath)
            default:
                return UITableViewCell()
            }
                        
        case 4:
            if indexPath.row == 0 {
                return blockchainInfoCell(indexPath)
            } else {
                return coinDeskCell(indexPath)
            }
            
        case 5:
            switch indexPath.row {
            case 0:
                return currencyCell(indexPath, "USD")
            case 1:
                return currencyCell(indexPath, "GBP")
            case 2:
                return currencyCell(indexPath, "EUR")
            default:
                return UITableViewCell()
            }
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        header.frame = CGRect(x: 0, y: 0, width: view.frame.size.width - 32, height: 50)
        let textLabel = UILabel()
        textLabel.textAlignment = .left
        textLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        textLabel.textColor = .white
        textLabel.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        switch section {
        case 0:
            textLabel.text = "Nodes"
            
        case 1:
            textLabel.text = "Backup/Recovery"
            
        case 2:
            textLabel.text = "Security"
            
        case 3:
            textLabel.text = "Privacy"
            
        case 4:
            textLabel.text = "Exchange Rate API"
            
        case 5:
            textLabel.text = "Fiat Currency"
            
        default:
            break
        }
        
        header.addSubview(textLabel)
        return header
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 4 {
            return 2
        } else if section == 5 || section == 1 {
            return 3
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        impact()
        
        switch indexPath.section {
        case 0:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.performSegue(withIdentifier: "goToNodes", sender: self)
            }
            
        case 1:
            if KeyChain.getData("userIdentifier") != nil && !authenticated {
                show2fa()
            } else {
                if indexPath.row == 0 {
                    warnToBackup()
                } else {
                    alertToRecover()
                }
            }
        case 2:
            if KeyChain.getData("userIdentifier") != nil && !authenticated {
                show2fa()
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.performSegue(withIdentifier: "goToSecurity", sender: self)
                }
            }
            
        default:
            break
            
        }
    }
    
    @objc func toggleCurrency(_ sender: UISwitch) {
        let currency = sender.restorationIdentifier!
        
        if sender.isOn {
            UserDefaults.standard.setValue(currency, forKey: "currency")
        } else {
            UserDefaults.standard.setValue("USD", forKey: "currency")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.settingsTable.reloadData()
        }
    }
    
    @objc func toggleiCloud(_ sender: UISwitch) {
        
        if sender.isOn {
            guard let usersPassword = KeyChain.getData("UnlockPassword") else { return }
                        
            promptToEnableiCloud(usersPassword)
        } else {
            promptToDisableiCloud()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.settingsTable.reloadData()
        }
    }
    
    private func promptToEnableiCloud(_ existingPasswordHash: Data) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let tit = "Enable iCloud sync?"
            
            let mess = "This will create an independent, iCloud database which stores your encrypted data using the unlock password you created for Fully Noded.\n\nIf you forget your password this backup will be completely useless! You MUST USE THE SAME UNLOCK PASSWORD to recover this data!\n\nThis backs up *everything* (signers, nodes, wallets, transactions, utxos and Tor auth keys) to make recovery seamless."
            
            let alert = UIAlertController(title: tit, message: mess, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Enable iCloud backup", style: .default, handler: { action in
                self.confirmiCloudEnable(existingPasswordHash)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func promptToDisableiCloud() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let tit = "Disable iCloud sync?"
            
            let mess = "This will delete and disable your iCloud backup."
            
            let alert = UIAlertController(title: tit, message: mess, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Disable iCloud backup", style: .destructive, handler: { action in
                self.spinner.addConnectingView(vc: self, description: "deleting iCloud data...")
                
                BackupiCloud.destroy { destroyed in
                    UserDefaults.standard.setValue(false, forKey: "iCloudBackup")
                    self.spinner.removeConnectingView()
                    
                    if destroyed {
                        showAlert(vc: self, title: "", message: "iCloud backup destroyed and disabled.")
                        
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            self.settingsTable.reloadSections(IndexSet(arrayLiteral: 1), with: .none)
                        }
                    } else {
                        showAlert(vc: self, title: "Error", message: "iCloud backup NOT destroyed, however syncing will no longer occur.")
                    }
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func hash(_ text: String) -> Data? {
        return Data(hexString: Crypto.sha256hash(text))
    }
    
    private func confirmiCloudEnable(_ existingPasswordHash: Data) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let title = "Enable iCloud backup?"
            let message = "You need to input the apps unlock password in order to enable iCloud backup."
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let enable = UIAlertAction(title: "Enable", style: .default) { [weak self] alertAction in
                guard let self = self else { return }
                
                let text = (alert.textFields![0] as UITextField).text
                
                guard let text = text,
                      let hash = self.hash(text),
                      existingPasswordHash == hash else {
                    showAlert(vc: self, title: "", message: "Incorrect password.")
                    
                    return
                }
                
                self.createiCloudBackupNow()
            }
            
            alert.addTextField { textField in
                textField.placeholder = "app password"
                textField.isSecureTextEntry = true
                textField.keyboardAppearance = .dark
            }
            
            alert.addAction(enable)
            
            let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
            alert.addAction(cancel)
            
            self.present(alert, animated:true, completion: nil)
        }
    }
    
    
    private func createiCloudBackupNow() {
        self.spinner.addConnectingView(vc: self, description: "creating iCloud backup...")
        
        BackupiCloud.backup { backedup in
            self.spinner.removeConnectingView()
            
            guard backedup else {
                showAlert(vc: self, title: "", message: "There was an error creating your iCould backup.")
                
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                UserDefaults.standard.setValue(true, forKey: "iCloudBackup")
                self.settingsTable.reloadSections(IndexSet(arrayLiteral: 1), with: .none)
            }
        }
    }
    
    private func alertToRecover() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.performSegue(withIdentifier: "segueToRecoveryDetail", sender: self)
        }
    }
    
    private func warnToBackup() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let tit = "WARNING!"
            let mess = "THIS BACKUP DOES ***NOT*** INCLUDE ANY PRIVATE KEY MATERIAL!\n\nAlways backup your signers offline on paper or metal, ensuring you keep them safe and secure."
            
            let alert = UIAlertController(title: tit, message: mess, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.alertToBackup()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func alertToBackup() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let tit = "Master Wallet Backup"
            let mess = "Backup all of your wallets so that you can easily recover them in the future. This file will be saved unencrypted and only contains *PUBLIC* keys, you must always backup your signers seperately."
            
            let alert = UIAlertController(title: tit, message: mess, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Create backup", style: .default, handler: { action in
                self.exportJson()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func exportJson() {
        CoreDataService.retrieveEntity(entityName: .wallets) { wallets in
            guard let wallets = wallets, wallets.count > 0 else { return }
            
            CoreDataService.retrieveEntity(entityName: .transactions) { transactions in
                guard var transactions = transactions else { return }
                
                let dateFormatter = DateFormatter()
                
                for (i, tx) in transactions.enumerated() {
                    if let id = tx["id"] as? UUID {
                        transactions[i]["id"] = id.uuidString
                    }
                    
                    if let walletId = tx["walletId"] as? UUID {
                        transactions[i]["walletId"] = walletId.uuidString
                    }
                    
                    if let date = tx["date"] as? Date {
                        dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
                        let dateString = dateFormatter.string(from: date)
                        transactions[i]["date"] = dateString
                    }
                }
                
                var jsonArray = [[String:Any]]()
                
                for (i, wallet) in wallets.enumerated() {
                    let walletStruct = Wallet(dictionary: wallet)
                    let accountMapString = AccountMap.create(wallet: walletStruct) ?? ""
                    jsonArray.append(["\(walletStruct.label)":accountMapString])
                    
                    if i + 1 == wallets.count {
                        
                        CoreDataService.retrieveEntity(entityName: .utxos) { [weak self] utxos in
                            guard let self = self else { return }
                            var processedUtxoArray:[[String:Any]] = []
                            
                            if let utxos = utxos, utxos.count > 0 {
                                processedUtxoArray = utxos
                                
                                for (u, utxo) in utxos.enumerated() {
                                    let utxoStr = UtxosStruct(dictionary: utxo)
                                    processedUtxoArray[u]["id"] = utxoStr.id!.uuidString
                                    
                                    if let walletid = utxoStr.walletId {
                                        processedUtxoArray[u]["walletId"] = walletid.uuidString
                                    }
                                    
                                    
                                    if u + 1 == utxos.count {
                                        let file:[String:Any] = ["wallets": jsonArray, "transactions": transactions, "utxos": processedUtxoArray.json() ?? []]
                                        self.saveFile(file)
                                    }
                                }
                            } else {
                                let file:[String:Any] = ["wallets": jsonArray, "transactions": transactions, "utxos": processedUtxoArray.json() ?? []]
                                self.saveFile(file)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveFile(_ file: [String:Any]) {
        let fileManager = FileManager.default
        let fileURL = fileManager.temporaryDirectory.appendingPathComponent("wallets.fullynoded")
        
        guard let json = file.json() else { return }
        
        try? json.dataUsingUTF8StringEncoding.write(to: fileURL)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var controller:UIDocumentPickerViewController!
            
            if #available(iOS 14, *) {
                controller = UIDocumentPickerViewController(forExporting: [fileURL]) // 5
            } else {
                controller = UIDocumentPickerViewController(url: fileURL, in: .exportToService)
            }
            
            self.present(controller, animated: true)
        }
    }
    
    @objc func toggleEsplora(_ sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "useEsplora")
        
        if sender.isOn {
            showAlert(vc: self, title: "Esplora enabled ✓", message: "Enabling Esplora may have negative privacy implications and is discouraged.\n\n**ONLY APPLIES TO PRUNED NODES**")
        } else {
            showAlert(vc: self, title: "", message: "Esplora disabled ✓")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.settingsTable.reloadData()
        }
    }
    
    @objc func toggleBlockchainInfo(_ sender: UISwitch) {
        UserDefaults.standard.setValue(sender.isOn, forKey: "useBlockchainInfo")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.settingsTable.reloadData()
        }
    }
    
    @objc func toggleCoindesk(_ sender: UISwitch) {
        UserDefaults.standard.setValue(!sender.isOn, forKey: "useBlockchainInfo")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.settingsTable.reloadData()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let authorizationProvider = ASAuthorizationAppleIDProvider()
            if let usernameData = KeyChain.getData("userIdentifier") {
                if let username = String(data: usernameData, encoding: .utf8) {
                    if username == appleIDCredential.user {
                        authorizationProvider.getCredentialState(forUserID: username) { [weak self] (state, error) in
                            guard let self = self else { return }
                            
                            switch state {
                            case .authorized:
                                self.authenticated = true
                            case .revoked:
                                fallthrough
                            case .notFound:
                                fallthrough
                            default:
                                break
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
        
}



