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
import UIKit
//#endif

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
    
    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return storage!.attributes(at: location, effectiveRange: range)
    }

    public override func replaceCharacters(in range: NSRange, with str: String) {
        storage!.replaceCharacters(in: range, with: str)
        let changeInLength = str.count - range.length
        self.edited(NSTextStorage.EditActions.editedCharacters, range: range, changeInLength: changeInLength)
    }
    
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        storage!.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }
    
}
