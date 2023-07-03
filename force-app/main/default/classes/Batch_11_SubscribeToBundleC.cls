/**
 * Classe Test Batch_11_SubscribeToBundleC_Test
 * @author Jackie abi nassif
 * @date 22 Decembre 2022
 */
global class Batch_11_SubscribeToBundleC  implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // get all subscription marked to be activated 
        return Database.getQueryLocator('SELECT Id, Zuora__Status__c, SUB_Status__c, Create_Bundle_C_subscription__c, '
                                                +'SUB_Options__c, SUB_Offer__c, SUB_Tech_Material__c, CBundle_Periode__c, Zuora__Subscription__c.Quote__r.QUO_Periodes_Prepayees__c  '
                                                +'FROM Zuora__Subscription__c '
                                                +'WHERE Create_Bundle_C_subscription__c = true AND (Prior_expedted_renewal_Date__c = TODAY OR Prior_expedted_renewal_Date__c = YESTERDAY)');
    }

    global void execute(Database.BatchableContext bc, List<Zuora__Subscription__c> subscriptions){

        // get all subscriptions that are supposed to be activated in CBundle Today or yesterday
        if(subscriptions != null && subscriptions.size() > 0){

            try {
                // Send 1 by 1 record to the method to send the subscribe request to C + Bundle (The number of record is handled in the batch to not exceed the governor limit) (waiting an update in the CGA web service)
                for(Zuora__Subscription__c sub : subscriptions){

                    list<string> listOptions = new list<string>();
                    if(sub.SUB_Options__c != null && !String.isBlank(sub.SUB_Options__c)){
                        listOptions = sub.SUB_Options__c.split(';');
                    }
                    // si c'est une nouvelle souscription la periode est sauvegarder sur le quote
                    String prePaidPeriod = sub.CBundle_Periode__c == null? sub.Quote__r.QUO_Periodes_Prepayees__c : String.valueof(sub.CBundle_Periode__c);
                    String subscriptionResponse = BundleCSubscription.subscribeToC (sub.Id, sub.SUB_Offer__c, listOptions, sub.SUB_Tech_Material__c, prePaidPeriod, false);
                }
            } catch (Exception e) {
                system.debug('in batch11 error '+e.getLineNumber()+': '+e.getMessage());
            }

        }


        integer myDMLLimit = Limits.getDMLStatements();
        system.debug(' dml number '+myDMLLimit);
    }
    // to get the failed request search for subscriptions with Checkbox Create_Bundle_C_subscription__c true and Prior_expedted_renewal_Date__c < Today
    // solution to trigger the batch again update the proior date of the subscription to today and execute the batch in the anonymous

    global void finish(Database.BatchableContext bc){}

}