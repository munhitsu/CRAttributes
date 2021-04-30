//
//  CoOpTextStorage.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 08/03/2021.
//

import Foundation
//#if os(macOS)
//import AppKit
//#else
#if os(iOS)
import UIKit
#endif
//#endif


// proxy over CoOpMutableStringAttribute
// that takes care of beginEditing, edited and endEditing
// and exposes NSTextStorage
public class CoOpTextStorage: NSTextStorage {
    
    var storage: CoOpMutableStringAttribute?
    
    init(_ storage: CoOpMutableStringAttribute) {
        self.storage = storage
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalNotImplemented()
        self.storage = nil
        super.init(coder: aDecoder)
    }

    
    //TODO: how to properly extend String https://forums.swift.org/t/subclassing-nsstring-in-swift/33143
    
    public override var string: String {
        get {
            return storage!.string
        }
    }

    //TODO: subclasses should implement it to execute in O(1) time. (source https://developer.apple.com/documentation/foundation/nsattributedstring/1412616-string)
    
    
    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return storage!.attributes(at: location, effectiveRange: range)
    }

    public override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        storage!.replaceCharacters(in: range, with: str)
        edited(.editedCharacters,
               range: range,
               changeInLength: (str as NSString).length - range.length)
        endEditing()
    }
    
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        storage!.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
}
