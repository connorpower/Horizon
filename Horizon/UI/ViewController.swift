//
//  ViewController.swift
//  Horizon
//
//  Created by Jürgen on 02.11.17.
//  Copyright © 2017 Semantical GmbH & Co. KG. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSFilePromiseProviderDelegate {

    @IBOutlet weak var contactsTableView: NSTableView!
    @IBOutlet weak var filesTableView: NSTableView!

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var statusField: NSTextField!

    // Constants
    let contactsTableViewId = NSUserInterfaceItemIdentifier("Contacts")
    let filesTableViewId = NSUserInterfaceItemIdentifier("Files")

    // State
    var selectedContact: Contact?

    var observers = [NSObjectProtocol]()

    var dataModel: DataModel {
        let appDelegate = (NSApp.delegate) as? AppDelegate
        return appDelegate!.dataModel
    }

    // Life cycle and updating
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFilesTableView()
        contactsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        filesTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        filesTableView.setDraggingSourceOperationMask(NSDragOperation.copy, forLocal: false)

        let dataAvailableObserver = NotificationCenter.default.addObserver(
            forName: Notifications.newDataAvailable, object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                self?.contactsTableView.reloadData()
                self?.filesTableView.reloadData()
            }

        let syncStartedObserver = NotificationCenter.default.addObserver(
            forName: Notifications.syncStarted, object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                self?.beginProgressUpdates()
            }

        let syncEndedObserver = NotificationCenter.default.addObserver(
            forName: Notifications.syncEnded, object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                self?.endProgressUpdates()
            }

        let statusMessageObserver = NotificationCenter.default.addObserver(
            forName: Notifications.statusMessage, object: nil,
            queue: OperationQueue.main) { [weak self] notification in
                if let message = notification.userInfo?[Notifications.statusMessageKey] as? String {
                    self?.updateProgressWithStatus(status: message)
                }
            }

        observers = [dataAvailableObserver, syncStartedObserver, syncEndedObserver, statusMessageObserver]
        dataModel.sync()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func updateFilesTableView() {
        selectedContact = contact(at: contactsTableView.selectedRow)
        filesTableView.reloadData()
    }

    // ***********************
    // NSTableView data source
    // ***********************

    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let identifier = tableView.identifier else {
            print("Table view is missing an identifier.")
            return 0
        }

        switch identifier {
        case contactsTableViewId:
            return dataModel.contacts.count

        case filesTableViewId:
            if let contact = selectedContact {
                return dataModel.files(from: contact).count
            } else {
                return 0
            }

        default:
            print("No data for table view with id \(identifier.rawValue)")
            return 0
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnId = tableColumn?.identifier else {
            print("Table view column is missing.")
            return nil
        }

        switch columnId.rawValue {
        case "Contact":
            let result = tableView.makeView(withIdentifier: columnId, owner: self) as? NSTableCellView
            result?.textField?.stringValue = dataModel.contacts[row].name
            return result

        case "File":
            let fileName: String
            if let contact = selectedContact {
                let files = dataModel.files(from: contact)
                if row < files.count {
                    fileName = files[row].name
                } else {
                    print("We seem to have lost files since we last retrieved the file count.")
                    fileName = "<File is missing>"
                }
            } else {
                print("Don't retrieve files when there's no contact selected.")
                fileName = "<Error>"
            }

            let result = tableView.makeView(withIdentifier: columnId, owner: self) as? NSTableCellView
            result?.textField?.stringValue = fileName
            return result

        default:
            print("No data for column with id \(columnId.rawValue)")
            return nil
        }
    }

    // ***********************
    // NSTableView selection
    // ***********************

    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView,
            tableView.identifier == contactsTableViewId {
            updateFilesTableView()
        }
    }

    func contact(at row: Int) -> Contact? {
        if row >= 0 && row < dataModel.contacts.count {
            return dataModel.contacts[row]
        }
        return nil
    }

    // ***********************
    // NSTableView drop
    // ***********************

    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if tableView == contactsTableView && dropOperation == NSTableView.DropOperation.on {
            return NSDragOperation.copy
        }
        return NSDragOperation()
    }

    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {
        if tableView == contactsTableView {
            let pboard = info.draggingPasteboard()
            let data = pboard.readObjects(forClasses: [NSURL.self],
                                          options: [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true])
            if let fileURLs = data as? [URL] {
                if let contact = contact(at: row) {
                    dataModel.add(fileURLs: fileURLs, to: contact)
                }
                return true
            }
        }

        return false
    }

    // ***********************
    // NSTableView drag
    // ***********************

    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        if tableView == filesTableView {
            if let contact = selectedContact {
                let count = dataModel.files(from: contact).count
                for row in rowIndexes where row < count {
                    let file = dataModel.files(from: contact)[row]
                    let provider = NSFilePromiseProvider(fileType: kUTTypeData as String, delegate: self)
                    provider.userInfo = file
                    pboard.writeObjects([provider])
                }
            }

            return true
        }
        return false
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             fileNameForType fileType: String) -> String {
        if let file = filePromiseProvider.userInfo as? File {
            return file.name
        }
        return "<File missing>"
    }

    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             writePromiseTo url: URL,
                             completionHandler: @escaping (Error?) -> Void) {
        if let file = filePromiseProvider.userInfo as? File, let hash = file.hash {
            IPFSAPI().cat(arg: hash) { (data, error) in
                if let data = data {
                    try? data.write(to: url)
                    completionHandler(nil)
                } else {
                    completionHandler(error)
                }
            }
        } else {
            completionHandler(nil)
        }
    }

    // ***********************
    // Progress Updates
    // ***********************

    func beginProgressUpdates() {
        print("beginProgressUpdates")
        progressView.isHidden = false
        progressIndicator.startAnimation(nil)
    }

    func endProgressUpdates() {
        print("endProgressUpdates")
        progressIndicator.stopAnimation(nil)
        progressView.isHidden = true
    }

    func updateProgressWithStatus(status: String) {
        statusField.stringValue = status
    }

}
