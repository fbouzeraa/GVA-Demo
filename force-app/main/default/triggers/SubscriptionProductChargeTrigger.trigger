trigger SubscriptionProductChargeTrigger on Zuora__SubscriptionProductCharge__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {

            if(PAD.canTrigger('ZuoraSubscriptionActions')) {
                SubscriptionRenewalActions.addProductBaseName(Trigger.new);
            }
        }
        when AFTER_UPDATE {

            if(PAD.canTrigger('ZuoraSubscriptionActions')) {
                SubscriptionRenewalActions.addProductBaseName(Trigger.new);
            }
        }
    }

}