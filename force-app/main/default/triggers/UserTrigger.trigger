trigger UserTrigger on User (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            if(PAD.canTrigger('AP01_User')) {
                AP01_User.addUsersToGroup(null, Trigger.newMap);
            }
            if(PAD.canTrigger('UserTriggerHandler')) {
                System.debug('Is Batch ?    '+ System.IsBatch());
                System.debug('Is Future ?    '+ System.isFuture());
                if(System.IsBatch() == false && System.isFuture() == false) {
                    UserTriggerHandler.sendWelcomeSmsToClientPortalUsers(Trigger.new);
                }
            }

        }
        when AFTER_Update {
            if(PAD.canTrigger('AP01_User')) {
                AP01_User.addUsersToGroup(Trigger.oldMap, Trigger.newMap);
            }
        }

    }
}