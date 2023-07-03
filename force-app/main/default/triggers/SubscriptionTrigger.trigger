trigger SubscriptionTrigger on Zuora__Subscription__c(after insert, before insert, before update, after update){
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            if(PAD.canTrigger('AP01_Quotes')) {
                AP01_Quotes.addOrderNumberToSub(Trigger.new);
            }
        }
        when AFTER_INSERT {
            if(PAD.canTrigger('AP01_Quotes')) {
                AP01_Quotes.createSuiviRecords(Trigger.new);
            }
            if(PAD.canTrigger('ZuoraSubscriptionActions')) {
                ZuoraSubscriptionActions.newProductSuivi(Trigger.new);
            }
            if(PAD.canTrigger('CreateUserHandler')) {
                CreateUserHandler.createCommunityUser(Trigger.new);
            }
        }
        when BEFORE_UPDATE{
            if(PAD.canTrigger('BundleCSubscription')) {
                BundleCSubscription.createBundleSub(Trigger.newmap, Trigger.oldmap);
            }
        }
        when AFTER_UPDATE {
            if(PAD.canTrigger('ZuoraSubscriptionActions')) {
                ZuoraSubscriptionActions.activateSubscriptionInZuora(Trigger.newmap, Trigger.oldmap);
                ZuoraSubscriptionActions.createSuspendedSuivi(Trigger.newmap, Trigger.oldmap);
                ZuoraSubscriptionActions.checkCollaboratorSub(Trigger.newmap, Trigger.oldmap);
                SubscriptionRenewalActions.checkCompensationsonSub(Trigger.newmap, Trigger.oldmap);

            }
        }
    }

}