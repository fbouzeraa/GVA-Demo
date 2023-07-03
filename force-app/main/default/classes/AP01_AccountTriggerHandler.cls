/**
 * Classe pour regroupper les methodes qui sera declencher par l'account trigger.
 * 
 * DFG package handler is add in this class on 6/4/2023 to handle it trigger just on Rwanda Accounts and when needed
 * This change is made to bypass a cpu limit error after a synchronization action with Zuora
 * I suggested that there was no need to call the before and after actions for each step, but DFG did not accept the removal of the "before" action
 *
 * @author jackie Abi Nassif
 * @date 20 janvier 2023
 */
public without sharing class AP01_AccountTriggerHandler {

    // Methode utiliser pour verifier le changement sur l'account avant declenchement des methodes
    public static void AP01_AccountTriggerHandler(Map<Id, Account> mapOfNewAccount, Map<Id, Account> mapOfOldAccount, String triggerType, list<Account> listOfNewAccount) {

        // relier a AP01_AccountEligibility
        Set<Id> accountIds = new Set<Id>();

        // relier a ZuoraSubscriptionAction
        list<Id> listUpdatedAccounts = new List<Id>();
        Map<Id, String> mapUpdatedAccountsTIN  = new Map<Id, String>();

        // relier a bundleCSubscription
        Map<Id, Account> accountToUpdate = new Map<Id, Account>();
        Map<Id, Zuora__Subscription__c> mapOfAcctIdSub = new Map<Id, Zuora__Subscription__c>();

        // relier a DFG-152
        Map<Id, Account> newMapOfAccountRwanda = new Map<Id, Account>();
        Map<Id, Account> oldMapOfAccountRwanda = new Map<Id, Account>();
        
        // on before insert
        if(listOfNewAccount != null){

            for(Account acc : listOfNewAccount){

                if(acc.BillingCountryCode == 'RW'){
                    newMapOfAccountRwanda.put(acc.Id, acc);
                }
            }
        }// on after insert && after undelete
        else if(mapOfOldAccount == null) 
        {
            for(Account acc : mapOfNewAccount.values()) 
            {
                if((acc.ACC_BuildingID__c != null && !string.IsBlank(acc.ACC_BuildingID__c)) && triggerType == 'afterInsert') {
                    accountIds.add(acc.Id);
                }

                if(acc.BillingCountryCode == 'RW'){ // DFG Package only for rwanda
                    newMapOfAccountRwanda.put(acc.Id, acc);
                }
            }
        } // on before/after Delete
        else if(mapOfNewAccount == null){
            for(Account acc : mapOfOldAccount.values()){

                if(acc.BillingCountryCode == 'RW'){ // DFG Package only for rwanda
                    oldMapOfAccountRwanda.put(acc.Id, acc);
                }
            }
        } // on before/after update
        else {
            // if update related to the Bundle subsciption
            if(PAD.canTrigger('BundleCSubscription') && triggerType == 'afterUpdate')
            {
                list<Zuora__Subscription__c> listOfSubscription = [SELECT Name, SUB_Status__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__Account__c, SUB_Bundle_Contract_Id__c
                                                                FROM Zuora__Subscription__c
                                                                WHERE Zuora__Account__c IN : mapOfNewAccount.KeySet() AND SUB_Status__c != null];
            
                if(listOfSubscription != null && listOfSubscription.Size() > 0) 
                {
                    for(Zuora__Subscription__c sub : listOfSubscription)
                    {
                        mapOfAcctIdSub.put(sub.Zuora__Account__c, sub);
                    }
                }
            }

            for(Account acc : mapOfNewAccount.values())
            {
                // on update, check if Buildng Id is changed or not. 
                if(acc.ACC_BuildingID__c != mapOfOldAccount.get(acc.Id).ACC_BuildingID__c && acc.ACC_BuildingID__c != null && triggerType == 'afterUpdate') 
                {
                    //mapAccountsToCheck.put(acc.ACC_BuildingID__c, acc.Id);
                    //list<zuora__Subscription__c> subs =mapOfOldAccount.get(acc.Id).Zuora__Subscriptions__r;
                    /*System.debug('mapOfOldAccount.get(acc.Id).Zuora__Subscriptions__r'+mapOfOldAccount.get(acc.Id).Zuora__Subscriptions__r);
                    System.debug('sub.Zuora__Status__c'+sub.Zuora__Status__c);*/
                    listUpdatedAccounts.add(acc.Id);
                    
                    accountIds.add(acc.Id);
                    

                    //
                }

                // if Tin changed
                if(acc.ACC_TIN__c != mapOfOldAccount.get(acc.Id).ACC_TIN__c && acc.ACC_TIN__c != null && triggerType == 'afterUpdate')
                {
                    mapUpdatedAccountsTIN.put(acc.Id, acc.ACC_TIN__c);
                }

                // if one of these info changed
                String accId = acc.Id;
                if( acc.IsPersonAccount &&
                    (acc.Salutation != mapOfOldAccount.get(accId).Salutation 
                    || acc.FirstName != mapOfOldAccount.get(accId).FirstName 
                    || acc.LastName != mapOfOldAccount.get(accId).LastName 
                    || acc.personMobilePhone != mapOfOldAccount.get(accId).personMobilePhone 
                    || acc.phone != mapOfOldAccount.get(accId).phone
                    || acc.BillingCity != mapOfOldAccount.get(accId).BillingCity 
                    || acc.BillingCountryCode != mapOfOldAccount.get(accId).BillingCountryCode 
                    || acc.BillingStreet != mapOfOldAccount.get(accId).BillingStreet 
                    || acc.personEmail != mapOfOldAccount.get(accId).personEmail))
                {
                    if(mapOfAcctIdSub != null && mapOfAcctIdSub.containsKey(acc.id) && triggerType == 'afterUpdate'){
                        accountToUpdate.put(accId, acc);
                    }

                    if(acc.BillingCountryCode == 'RW'){ // DFG Package only for rwanda
                        newMapOfAccountRwanda.put(acc.Id, acc);
                        oldMapOfAccountRwanda.put(acc.Id, mapOfOldAccount.get(accId));
                    }
                }
            } 
        }


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        //Methode utilisée pour verifier si le compte est eligible apres la modification du building id
        if(accountIds.size() > 0 && accountIds != null && PAD.canTrigger('AP01_AccountEligibility')) 
        {
            AP01_AccountEligibility.checkEligibility(accountIds);
            AP01_AccountEligibility.enrichAccountData(accountIds);
        }

        if(PAD.canTrigger('ZuoraSubscriptionActions'))
        {
            // methode pour valider si l'addresse du compte est change et puis update account address in zuora
            if(listUpdatedAccounts.size() != 0 && listUpdatedAccounts != null) 
            {
                ZuoraSubscriptionActions.updateAccountAndSubscription(listUpdatedAccounts);
            }

            // update account TIN in zuora
            if(mapUpdatedAccountsTIN != null  &&  mapUpdatedAccountsTIN.size() != 0 ) 
            {
                ZuoraSubscriptionActions.updateAccountTIN(mapUpdatedAccountsTIN);
            }
        }

        // integration with canal +
        if(accountToUpdate != null && accountToUpdate.size() > 0 && PAD.canTrigger('BundleCSubscription'))
        {
            BundleCSubscription.modifyContactBundleC(JSON.serialize(accountToUpdate), JSON.serialize(mapOfAcctIdSub));
        }

        //this code DFG
        if(PAD.canTrigger('DFG152Package')){
            System.Type handler = Type.forName('DFG' + '.TriggerHandlerImpl');
            DFG.TriggerHandler triggerHandler = (DFG.TriggerHandler) handler.newInstance();

            if (newMapOfAccountRwanda != null && triggerType == 'afterUndelete') 
            {
                triggerHandler.afterUndelete(newMapOfAccountRwanda);
            } 
            else if (oldMapOfAccountRwanda != null && triggerType == 'beforeDelete') 
            {
                triggerHandler.beforeDelete(oldMapOfAccountRwanda);
            } 
            else if (oldMapOfAccountRwanda != null && triggerType == 'afterDelete') 
            {
                triggerHandler.afterDelete(oldMapOfAccountRwanda);
            } 
            else if (newMapOfAccountRwanda != null && triggerType == 'beforeInsert') 
            {
                triggerHandler.beforeInsert(newMapOfAccountRwanda.values());
            } 
            else if (newMapOfAccountRwanda != null && triggerType == 'afterInsert') 
            {
                triggerHandler.afterInsert(newMapOfAccountRwanda);
            } 
            else if (newMapOfAccountRwanda != null && oldMapOfAccountRwanda != null && triggerType == 'beforeUpdate') 
            {
                triggerHandler.beforeUpdate(newMapOfAccountRwanda, oldMapOfAccountRwanda);
            } 
            else if (newMapOfAccountRwanda != null && oldMapOfAccountRwanda != null && triggerType == 'afterUpdate') 
            {
                triggerHandler.afterUpdate(newMapOfAccountRwanda, oldMapOfAccountRwanda);
            }
        }
        //this code DFG
    }
}