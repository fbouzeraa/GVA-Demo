trigger SuiviTrigger on Suivi_de_Souscription__c (after insert, after update) {
    switch on Trigger.operationType {
        // when AFTER_INSERT {
        //     if(PAD.canTrigger('AP01_SuiviDeSouscription')) {
        //         AP01_SuiviDeSouscription.getNewSuivi(Trigger.new);
        //     }
        // }
        when AFTER_Update {
            if(PAD.canTrigger('ZuoraSubscriptionActions')) {
                ZuoraSubscriptionActions.changeBoxNumber(Trigger.oldMap, Trigger.newMap);
            }
        }
    }
}