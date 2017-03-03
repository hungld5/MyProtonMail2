//
//  LabelCreatingViewModelImple.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

// label creating
public class LabelCreatingViewModelImple : LabelEditViewModel {

    public override func getTitle() -> String {
        return "Add New Label"
    }
    
    public override func getPlaceHolder() -> String {
        return "Label Name"
    }
    
    public override func getRightButtonText() -> String {
        return "Create"
    }
    
//    private var labelMessages : Dictionary<String, LabelMessageModel>!
//    public override init() {
//        super.init()
//        self.labelMessages = Dictionary<String, LabelMessageModel>()
//    }
//    
//    override public func showArchiveOption() -> Bool {
//        return false
//    }
//    
//    override public func getLabelMessage( label : Label!) -> LabelMessageModel! {
//        if let outVar = self.labelMessages[label.labelID] {
//            return outVar
//        } else {
//            let lmm = LabelMessageModel();
//            lmm.label = label
//            lmm.status = 0
//            self.labelMessages[label.labelID] = lmm;
//            return lmm
//        }
//    }
//    
//    override public func getTitle() -> String {
//        return NSLocalizedString("Manage Labels/Folders")
//    }
//    
//    public override func getApplyButtonText() -> String {
//        return NSLocalizedString("Delete")
//    }
//    
//    public override func getCancelButtonText() -> String {
//        return NSLocalizedString("Close")
//    }
//    
//    override public func apply(archiveMessage : Bool) {
//        if let context = sharedCoreDataService.mainManagedObjectContext {
//            for (key, value) in self.labelMessages {
//                if value.status == 2 { //delete
//                    if value.label.managedObjectContext != nil && key == value.label.labelID {
//                        let api = DeleteLabelRequest(lable_id: key)
//                        api.call(nil)
//                        context.performBlockAndWait { () -> Void in
//                            context.deleteObject(value.label)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    override public func cancel() {
//        
//    }
//    
//    override public func createLabel(name: String, color: String, error:ErrorBlock,  complete: OkBlock) {
//        let api = CreateLabelRequest<CreateLabelRequestResponse>(name: name, color: color, exclusive: false)
//        api.call { (task, response, hasError) -> Void in
//            if hasError {
//                error(code: response?.code ?? 1000, errorMessage: response?.errorMessage ?? "");
//            } else {
//                sharedLabelsDataService.addNewLabel(response?.label);
//                complete()
//            }
//        }
//    }
//    
//    public override func fetchController() -> NSFetchedResultsController? {
//        return sharedLabelsDataService.fetchedResultsController(.all)
//    }
    
    
}
