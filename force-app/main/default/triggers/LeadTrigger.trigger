trigger LeadTrigger on Lead (after update, after insert) 
{
    switch on Trigger.operationType {
        when AFTER_INSERT {
            if(PAD.canTrigger('AP01_Lead')){
                AP01_Lead.triggerHandler(trigger.newmap,null);
            }
        }
        when AFTER_UPDATE {
            if(PAD.canTrigger('AP01_Lead')){
                AP01_Lead.triggerHandler(trigger.newmap,trigger.oldmap);
            }
        }
    }
}