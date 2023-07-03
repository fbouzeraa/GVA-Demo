global class Batch07_Reinstallation implements Database.Batchable<sObject>, Database.AllowsCallouts {
    /**
     * Start Method to filter Batch records
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //get all suivis of 'changing Address' subscription
        string moveCodeAction = 'ACT007';
        string suiviStatus = 'STA002';
        string suspendedStatus = 'Suspended';

        return Database.getQueryLocator('SELECT Id, ownerId,SV_Id_Souscription__c,SV_Reference_Externe__c, SV_Id_Souscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,SV_Id_Souscription__r.Name, SV_Id_Souscription__r.BoxNumber__c, ' +
                                        'SV_Id_Souscription__r.Zuora__Account__c,SV_Id_Souscription__r.ExpectedRenewalDate__c, SV_Id_Souscription__r.Zuora__Account__r.ACC_BuildingID__c,SV_Id_Souscription__r.Zuora__SubscriptionNumber__c,' +
                                        'SV_Id_Souscription__r.Zuora__Account__r.ACC_Escalier__c,SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroDEtage__c,SV_Id_Souscription__r.Zuora__Account__r.ACC_Porte__c,SV_Id_Souscription__r.SUB_T_Credit_Memo_Id__c , ' +
                                        'SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroPTO_cc__c,SV_Id_Souscription__r.Zuora__Account__r.BillingPostalCode,createdDate,SV_Id_Souscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c ' +
                                        ' FROM Suivi_de_Souscription__c' +
                                        ' WHERE SV_Id_Souscription__c != null AND SV_Reference_Externe__c != null AND ' +
                                        ' SV_Code_Action__c = \'' + String.escapeSingleQuotes(moveCodeAction) + '\' AND SV_Id_Souscription__r.Zuora__Status__c = \'' + String.escapeSingleQuotes(suspendedStatus) + '\' AND SV_Tech_Installation_Termine__c = false AND SV_Statut__c =  \'' + String.escapeSingleQuotes(suiviStatus) + '\'');
    }
/**
 * steps to do in this batch
 * update BCD on account the the day of suspension
 * resume subscription on installation date
 * add custom fields to the generated bill
 * apply credit memo to the generated bill
 */
    global void execute(Database.BatchableContext bc, List<Suivi_de_Souscription__c> listSuivi){
        //set of zuora Logs
        Set<Log__c> setLog = new set<Log__c>();
        list<Log__c> listLog = new list<Log__c>();
        //list of reactivation follow up
        list<Suivi_de_Souscription__c> listReactivationFollowUp = new list<Suivi_de_Souscription__c>();
        for(Suivi_de_Souscription__c suivi : listSuivi) {

            CanalBoxObjects.Orders order = new CanalBoxObjects.Orders();
            order.order_ref = suivi.SV_Reference_Externe__c;

            // call installation API to check if the box is installed or not
            HttpResponse installationResponse = CanalBoxManager.boxInstallation(order);

            system.debug('Installation ' + installationResponse.getBody());

            // successed order
            // if(installationResponse.getStatusCode() == 200) {
            //  CanalBoxObjects.OrderResponse orderResponse = new CanalBoxObjects.OrderResponse();
            //  orderResponse = (CanalBoxObjects.OrderResponse)JSON.deserialize(installationResponse.getBody(), CanalBoxObjects.OrderResponse.class);
            // if(orderResponse.services != null && orderResponse.services.size() > 0) {
            //   for(CanalBoxObjects.OrderServiceItemResponse service : orderResponse.services) {
            //    if(service.reactivation_date != null && !string.isBlank(service.reactivation_date)) {

            //actually resume date service.reactivation_date but for testing purpose is set as static value
            date resumeDate = date.today().addDays(6);

            //get number of prepaid period till now
            //integer prepaidperiod = Date.today().monthsBetween(suivi.SV_Id_Souscription__r.ExpectedRenewalDate__c);

            // expected renewal date become old one + number of suspended days
            date newRenewalDate = suivi.SV_Id_Souscription__r.ExpectedRenewalDate__c.addDays(date.valueOf(suivi.createdDate).daysBetween(resumeDate));
            date billingTargetDate = suivi.SV_Id_Souscription__r.ExpectedRenewalDate__c;//newRenewalDate.addMonths(prepaidperiod - 1);

            //adjust the bcd on the account to be = new renewal date
            ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(newRenewalDate.day());
            HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, suivi.SV_Id_Souscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
            ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBDCResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(
                updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), suivi.SV_Id_Souscription__r.Zuora__Account__c, suivi.SV_Id_Souscription__c, suivi.SV_Id_Souscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.updateAccountAPIUrl, updateAccount.getBody(),
                                                               adjustBDCResponse.success, adjustBDCResponse.reasons == null?null : adjustBDCResponse.reasons[0].message, ZuoraObjects.put, false));
            if(adjustBDCResponse.success) {
                // resume the subscription on the installation date and update the expected renewal date and generate invoice
                // ?returnIds = true ==> return the Id of each record created in the order
                ZuoraObjects.ZuoraOrder resumeOrder = ZuoraMapper.fillResumeSubscription(suivi.SV_Id_Souscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, suivi.SV_Id_Souscription__r.Name, billingTargetDate, string.valueOf(resumeDate), newRenewalDate);
                HttpResponse resumeResponse = ZuoraManager.doCallout(zuoraObjects.ordersAPIUrl + '?returnIds=true', zuoraObjects.post, json.serialize(resumeOrder, true));
                ZuoraResponseObjects.ZuoraCreateOrderResponse resumeOrderResponse =  (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                    resumeResponse.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(resumeOrder, true), null, suivi.SV_Id_Souscription__c, suivi.SV_Id_Souscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, resumeResponse.getBody(),
                                                                   resumeOrderResponse.success, resumeOrderResponse.reasons == null?null : resumeOrderResponse.reasons[0].message, ZuoraObjects.post, false));
                if(resumeOrderResponse.success) {
                    //create follow up for reactivation
                    listReactivationFollowUp.add(ZuoraSubscriptionActions.createSuivi(
                                                     suivi.SV_Id_Souscription__r.BoxNumber__c, 'ACT003', Datetime.now(),
                                                     'DST001', suivi.SV_Id_Souscription__c, null, suivi.SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroPTO_cc__c, 'STA001', null, null, null, null, null, null));
                    //update custom fields on the generated Invoice
                    ZuoraObjects.ZuoraBilling zBill = zuoraMapper.fillResumeInvoiceCustomFields(suivi.ownerId);
                    HttpResponse billResponse = ZuoraManager.updateInvoice(resumeOrderResponse.invoiceIds == null?null : resumeOrderResponse.invoiceIds[0], zBill);
                    ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse = new ZuoraResponseObjects.ZuoraBill();
                    invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(billResponse.getBody(), ZuoraResponseObjects.ZuoraBill.class);

                    setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zBill, true), null, suivi.SV_Id_Souscription__c, suivi.SV_Id_Souscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.invoiceAPIUrl + resumeOrderResponse.invoiceIds[0], billResponse.getBody(),
                                                                       invoiceUpdateResponse.success, invoiceUpdateResponse.reasons == null?null : invoiceUpdateResponse.reasons[0].message, ZuoraObjects.put, true));
                    if(invoiceUpdateResponse.success) {
                        //get credit memo amount
                        HttpResponse CMResponse = ZuoraManager.doCallout(zuoraObjects.creditMemoAPIURL + suivi.SV_Id_Souscription__r.SUB_T_Credit_Memo_Id__c, zuoraObjects.get, '');
                        ZuoraResponseObjects.ZuoraInvoices getCM = (ZuoraResponseObjects.ZuoraInvoices) JSON.deserialize(CMResponse.getBody(), ZuoraResponseObjects.ZuoraInvoices.class);

                        // apply credit memo to the invoice
                        ZuoraObjects.ZuoraPayment applyCM =  ZuoraMapper.fillApplyPayment(resumeOrderResponse.invoiceIds[0], integer.valueOf(getCM.amount));

                        HttpResponse response = ZuoraManager.doCallout(ZuoraObjects.creditMemoAPIURL + suivi.SV_Id_Souscription__r.SUB_T_Credit_Memo_Id__c + '/apply', ZUoraObjects.put, JSON.serialize(applyCM, true));
                        system.debug(response.getBody());
                        ZuoraResponseObjects.ZuoraPayment applyCMResponse = new ZuoraResponseObjects.ZuoraPayment();
                        applyCMResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                            response.getBody(), ZuoraResponseObjects.ZuoraPayment.class);

                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(applyCM, true), null, null, null, ZuoraObjects.creditMemoAPIURL + suivi.SV_Id_Souscription__r.SUB_T_Credit_Memo_Id__c + '/apply', response.getBody(),
                                                                           applyCMResponse.success, applyCMResponse.reasons == null?null : applyCMResponse.reasons[0].message, ZUoraObjects.put, true));

                    }

                }
            }

            //     }
            //    }
            // }
            //}
        }
        if(setLog.size() > 0 && setLog != null) {
            listLog.addALL(setLog);
            insert listLog;
        }
        if(listReactivationFollowUp.size() > 0 && listReactivationFollowUp != null) {
            insert listReactivationFollowUp;
        }
    }

    global void finish(Database.BatchableContext bc){}
}