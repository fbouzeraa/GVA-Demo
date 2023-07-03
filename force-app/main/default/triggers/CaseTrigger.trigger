trigger CaseTrigger on Case (before update) {
    switch on Trigger.operationType {

        when BEFORE_UPDATE {
            if(PAD.canTrigger('AP01_Case')) {
                AP01_Case.categUpdateTriggerHandler(trigger.newmap, trigger.oldmap);
            }
        }
    }
}