trigger CustomerAccountTrigger on Zuora__CustomerAccount__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            if(PAD.canTrigger('AP02_DistributorAccount')) {
                //   AP02_DistributorAccount.updateAccountBalance(null, Trigger.newMap);
            }
        }
        when AFTER_Update {
            if(PAD.canTrigger('AP02_DistributorAccount')) {
                AP02_DistributorAccount.updateAccountBalance(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}