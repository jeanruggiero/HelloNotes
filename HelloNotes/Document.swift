//
//  Document.swift
//  HelloNotes
//
//  Created by Jean Ruggiero on 1/8/20.
//  Copyright © 2020 Jean Ruggiero. All rights reserved.
//

enum NoteDocumentFileNames: String {
    case TextFile = "Text.rft"
    
    case AttachmentsDirectory = "Attachments"
}

enum ErrorCode : Int {
    
    /// We couldn't find the document.
    case cannotAccessDocument
    
    /// We couldn't access any filr wrappers inside this document.
    case cannotLoadFileWrappers
    
    /// We couldn'tload the text.rtf file.
    case cannotLoadText
    
    /// We couldn't access the Attachments folder.
    case cannotAccessAttachments
    
    /// We couldn't save the Text.rtf file.
    case cannotSaveText
    
    /// We couldn't save an attachment.
    case cannotSaveAttachment
}

let ErrorDomain = "NotesErrorDomain"

func err(_ code: ErrorCode, _ userInfo: [String: Any]? = nil) -> NSError {
    return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
}

import Cocoa
import SwiftUI

class Document: NSDocument {
    
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    
    var documentFileWrapper = FileWrapper(directoryWithFileWrappers: [:])

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
    }

    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        let textRTFData = try self.text.data(
            from: NSRange(0..<self.text.length),
            documentAttributes: [
                NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf])
        
        // If the current document file wrapper already contains a text file, remove it - we'll replace it with a new one
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }
        
        // Save the text data into the file
        self.documentFileWrapper.addRegularFile(withContents: textRTFData, preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
        
        // Return the main document's file wrapper - this is what will be saved on disk
        return self.documentFileWrapper
    }
    
    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        
        // Ensure that we have additional file wrappers in this file wrapper
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(.cannotLoadFileWrappers)
        }
        
        // Ensure that we can access the document text
        guard let documentTextData = fileWrappers[NoteDocumentFileNames.TextFile.rawValue]?.regularFileContents else {
            throw err(.cannotLoadText)
        }
        
        // Load the text data as RTF
        guard let documentText = NSAttributedString(rtf: documentTextData, documentAttributes: nil) else {
            throw err(.cannotLoadText)
        }
        
        // Keep the text in memory
        self.documentFileWrapper = fileWrapper
        self.text = documentText
    }


}

