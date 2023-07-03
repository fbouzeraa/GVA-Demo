/**
 * Classe Test Batch12_RenewBundleMigration_Test
 * @author Jackie abi nassif
 * @date 14 Juin 2022
 */
global class Batch12_RenewBundleMigration  implements Database.Batchable<sObject>, Database.AllowsCallouts {

    List<String> activeANDsuspended = new List<String>{System.Label.Sub_Status_Active, System.Label.Sub_Status_Suspended};

    // ACT007 = Migration request
    // At this moment the canal subscription will be activated automaticly in canal+ System with a Bundle contract so in SF we should activate the Fiber Offer and create a Bundle payment

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // get the list of bundle suivi waiting for migration (Il faut bloquer le demenagement dans cette date aussi)
        return Database.getQueryLocator('SELECT BC_Code_Action__c, BC_Subscription__c, BC_Contract_Id__c, BC_Contact_Id__c, Old_Equipment__c, New_Equipment__c, Payment_Amount__c, '+
                                                ' Fiber_Offer__c, Canal_Offer__c, Prepaid_Period__c, Options__c, Migration_Date__c, Canal_Category__c, BC_Subscription__r.Zuora__Status__c, Status__c,  '+
                                                ' BC_Subscription__r.SUB_T_Produit_De_Base__c, Payment_Method__c, Transaction_Id__c, BC_Subscription__r.Name, Operator__c, Dollar_Payment__c, CDF_Payment__c, '+
                                                ' Dollars_Refund__c, CDF_Refund__c,BC_Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Notes__c  '+
                                                'FROM Bundle_C_Follow_up__c  '+
                                                'WHERE BC_Code_Action__c = \'ACT007\' AND Migration_Date__c = TODAY '+
                                                ' AND BC_Subscription__r.Zuora__Status__c IN: activeANDsuspended ' +
                                                ' AND BC_Subscription__r.SuspensionReason__c != \'Move-Requested\' ' +
                                                ' AND Status__c != \'Cancelled\' ');
    }

    global void execute(Database.BatchableContext bc, List<Bundle_C_Follow_up__c> BundleSuiviList){

        if(BundleSuiviList != null && BundleSuiviList.size() > 0){

            list<Bundle_C_Follow_up__c> listSuiviBundle = new list<Bundle_C_Follow_up__c>();
            list<Zuora__Subscription__c> listsubscriptions = new list<Zuora__Subscription__c>();

            for(Bundle_C_Follow_up__c suiviBundle : BundleSuiviList){

                String renewResponse;
                String equipmentType;
                string transactionNumber = suiviBundle.Transaction_Id__c == null ? 'mig-' + suiviBundle.BC_Subscription__r.Name + '-' + String.valueOf(Datetime.now()).replaceAll('[^a-zA-Z0-9]','') : suiviBundle.Transaction_Id__c;
                String options = suiviBundle.Options__c?.replaceAll('[\"\\[\\]]', '');
                List<String> listOfOptions = options?.split(','); 

                double dolarpayment = suiviBundle.Dollar_Payment__c != null ? double.valueOf(suiviBundle.Dollar_Payment__c) : null;
                integer cdfPayment = suiviBundle.CDF_Payment__c != null ? integer.valueOf(suiviBundle.CDF_Payment__c) : null;
                integer dollarRefund = suiviBundle.Dollars_Refund__c != null ? integer.valueOf(suiviBundle.Dollars_Refund__c) : null;
                integer cdfRefund = suiviBundle.CDF_Refund__c != null ? integer.valueOf(suiviBundle.CDF_Refund__c) : null;

                if(suiviBundle.Fiber_Offer__c == suiviBundle.BC_Subscription__r.SUB_T_Produit_De_Base__c){

                    renewResponse = SubscriptionRenewalActions.renewSubscription(suiviBundle.BC_Subscription__c, integer.valueOf(suiviBundle.Prepaid_Period__c), suiviBundle.Payment_Method__c, transactionNumber,
                                                                                suiviBundle.Operator__c, dolarpayment, cdfPayment, dollarRefund, cdfRefund, null, suiviBundle.Canal_Offer__c, 
                                                                                listOfOptions, suiviBundle.Canal_Category__c);

                }
                else if(suiviBundle.BC_Subscription__r.SUB_T_Produit_De_Base__c == System.Label.Start_BaseProduct){

                    renewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(suiviBundle.BC_Subscription__c, integer.valueOf(suiviBundle.Prepaid_Period__c), false, true, false, suiviBundle.Payment_Method__c,
                                                                                            transactionNumber, suiviBundle.Operator__c, dolarpayment, cdfPayment, dollarRefund, cdfRefund, null, suiviBundle.Canal_Offer__c, 
                                                                                            listOfOptions, suiviBundle.Canal_Category__c);

                }
                else if(suiviBundle.BC_Subscription__r.SUB_T_Produit_De_Base__c == System.Label.Premium_BaseProduct){

                    renewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(suiviBundle.BC_Subscription__c, null, integer.valueOf(suiviBundle.Prepaid_Period__c), false, suiviBundle.Payment_Method__c,
                                                                                            transactionNumber, suiviBundle.Operator__c, dolarpayment, cdfPayment, dollarRefund, cdfRefund, null, suiviBundle.Canal_Offer__c, 
                                                                                            listOfOptions, suiviBundle.Canal_Category__c);
                }

                system.debug('222 > '+renewResponse);
                ZuoraResponseObjects.ZuoraPayment responseObject = new ZuoraResponseObjects.ZuoraPayment();
                try {
                    responseObject = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(renewResponse, ZuoraResponseObjects.ZuoraPayment.class);
                } catch (Exception e) {
                    system.debug(e.getMessage()+' : '+e.getLineNumber());
                }

                if(responseObject.success != null && responseObject.success) {
                    Bundle_C_Follow_up__c followUp = new Bundle_C_Follow_up__c();
                    followUp.BC_Code_Action__c = 'ACT001';
                    followUp.BC_Subscription__c = suiviBundle.BC_Subscription__c;
                    followUp.BC_Contract_Id__c = suiviBundle.BC_Subscription__r.Name;
                    followUp.BC_Contact_Id__c = suiviBundle.BC_Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
                    followUp.Old_Equipment__c = suiviBundle.Old_Equipment__c;
                    followUp.New_Equipment__c = suiviBundle.New_Equipment__c;
                    followUp.Canal_Offer__c = suiviBundle.Canal_Offer__c;
                    followUp.Options__c = suiviBundle.Options__c;
                    listSuiviBundle.add(followUp);
    
                    Zuora__Subscription__c currentSub = new Zuora__Subscription__c();
                    currentSub.Id = suiviBundle.BC_Subscription__c;
                    currentSub.SUB_Status__c = 'Active';
                    currentSub.SUB_End_Date__c = date.today().addMonths(integer.valueOf(suiviBundle.Prepaid_Period__c));
                    currentSub.SUB_Offer__c = suiviBundle.Canal_Offer__c;
                    currentSub.SUB_Options__c = options == null || options == '' ? null : options;
                    currentSub.SUB_EquipmentType_CBundle__c = equipmentType;
                    currentSub.SUB_EquipmenId_CBundle__c = suiviBundle.New_Equipment__c;
                    currentSub.SUB_Bundle_Contract_Id__c = suiviBundle.BC_Subscription__r.Name;
                    currentSub.SUB_Activation_Date__c = Date.Today();
                    listsubscriptions.add(currentSub);

                    suiviBundle.Status__c = 'Treated';
                    listSuiviBundle.add(suiviBundle);
                }else{
                    suiviBundle.Status__c = 'Failed';
                    suiviBundle.Notes__c = renewResponse;
                    listSuiviBundle.add(suiviBundle);
                }
            }
            
            if(listSuiviBundle != null && listSuiviBundle.size() > 0){ upsert listSuiviBundle;}
            if(listsubscriptions != null && listsubscriptions.size() > 0){ update listsubscriptions;}
        }
    }

    global void finish(Database.BatchableContext bc){}

}