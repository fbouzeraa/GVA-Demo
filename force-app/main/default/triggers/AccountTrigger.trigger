trigger AccountTrigger on Account (before insert, before update, after update, after insert, before delete, after delete, after undelete){
    switch on Trigger.operationType {

        when BEFORE_INSERT {
            if(PAD.canTrigger('DFG152Package')) {
                AP01_AccountTriggerHandler.AP01_AccountTriggerHandler(null, null, 'beforeInsert', trigger.new);
            }
        }
        when AFTER_INSERT {
            if(PAD.canTrigger('AP01_AccountEligibility') || PAD.canTrigger('DFG152Package')) {
                AP01_AccountTriggerHandler.AP01_AccountTriggerHandler(trigger.newmap, null, 'afterInsert', null);
            }
        }
        when BEFORE_UPDATE {
            if(PAD.canTrigger('UpdateUserHandler')) {
                UpdateUserHandler.updateCommunityUser(trigger.new, trigger.oldmap);
            }
            if(PAD.canTrigger('DFG152Package')){
                AP01_AccountTriggerHandler.AP01_AccountTriggerHandler(trigger.newmap, trigger.oldmap, 'beforeUpdate', null);
            }
        }
        when AFTER_UPDATE {
            if(PAD.canTrigger('BundleCSubscription') || PAD.canTrigger('ZuoraSubscriptionActions') || PAD.canTrigger('AP01_AccountEligibility') || PAD.canTrigger('DFG152Package'))
            {
                AP01_AccountTriggerHandler.AP01_AccountTriggerHandler(trigger.newmap, trigger.oldmap, 'afterUpdate', null);
            }
        }
        when BEFORE_DELETE {
            if(PAD.canTrigger('DFG152Package')){
                AP01_AccountTriggerHandler.AP01_AccountTriggerHandler(null, trigger.oldmap, 'beforeDelete', null);
            }
        }
        when AFTER_DELETE {
            if(PAD.canTrigger('DFG152Package')){
                AP01_AccountTriggerHandler.AP01_AccountTriggerHandler(null, trigger.oldmap, 'afterDelete', null);
            }
        }
        when AFTER_UNDELETE {
            if(PAD.canTrigger('DFG152Package')){
                AP01_AccountTriggerHandler.AP01_AccountTriggerHandler(trigger.newmap, null, 'afterUndelete', null);
            }
        }
    }
}