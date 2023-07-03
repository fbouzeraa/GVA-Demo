trigger UserChangeEventTrigger on UserChangeEvent (after insert) {

    switch on Trigger.operationType {
        when AFTER_INSERT {
            UserChangeEventTriggerHandler.updatePersonAccountEmail(Trigger.New);
        }  
    }
}