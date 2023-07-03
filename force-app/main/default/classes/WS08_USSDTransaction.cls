/**
 * Test Class : WS08_USSDTransactiont_test
 * @author Jackie Abi Nassif
 * @date 2022-09-30
 */
@RestResource(urlMapping = '/v1/Transaction/*')
global class WS08_USSDTransaction {

    @HttpPost
    global static string postTransaction() {

        RestRequest req = RestContext.request;
        USSDObjects.TransactionAPIResponse response = new USSDObjects.TransactionAPIResponse();
        response.success = false;

        System.debug(RestContext.request.requestBody.toString());
        USSDObjects.transactionBodyRequest transactionRequest = (USSDObjects.transactionBodyRequest) JSON.deserialize(RestContext.request.requestBody.toString(), USSDObjects.transactionBodyRequest.class);

        String boxNumber = transactionRequest.routerNumber;
        String transactionId = transactionRequest.transactionNumber;
        Integer prepaidPeriod = transactionRequest.prepaidPeriod;
        String operator = transactionRequest.operator;
        String baseProductToAdd = transactionRequest.referenceNumber;
        double amount = transactionRequest.amount;
        String modeDePaiement = System.Label.ModePaiement_MobileMoney;

        // check if all the required values are received if not return an error message
        if(!string.isBlank(boxNumber) && !string.isBlank(transactionId) && !string.isBlank(operator) && !string.isBlank(baseProductToAdd) && prepaidPeriod != null && prepaidPeriod > 0) {

            list<zuora__subscriptionProductCharge__c> subPrCharge = [SELECT Name, Zuora__Subscription__r.BoxNumber__c, Zuora__Subscription__r.Zuora__Account__r.Name, Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode,
                                                                     Zuora__Subscription__r.Name, Zuora__Subscription__r.SUB_T_Produit_De_Base__c, Zuora__Subscription__r.SUB_T_Account_Country__c,
                                                                     Zuora__Subscription__r.Zuora__Status__c, Zuora__Subscription__r.Zuora__Account__c,
                                                                     IsDeleted, Zuora__ListPriceBase__c, Zuora__Product__c, Zuora__Product__r.Name, Zuora__Subscription__c,
                                                                     Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                                                     Zuora__Subscription__r.Zuora__SubscriptionNumber__c, Zuora__RatePlanId__c,
                                                                     Zuora__Subscription__r.ExpectedRenewalDate__c, Zuora__Subscription__r.isCollaborator__c
                                                                     FROM zuora__subscriptionProductCharge__c
                                                                     WHERE Zuora__Subscription__r.BoxNumber__c =: boxNumber AND Zuora__Subscription__r.SuspensionReason__c != 'Move-Requested'
                                                                     AND (Zuora__Subscription__r.Zuora__Status__c = :System.Label.Sub_Status_Active OR Zuora__Subscription__r.Zuora__Status__c = :System.Label.Sub_Status_Suspended)];
           
            List<String> countryCodefilter = System.Label.USSD_ValidCountryCode_List.split(','); // ['TG','RW']
            if(!Test.isRunningTest()) { countryCodefilter.remove(0); }

            // check if a current active or suspended subscription is found
            if(!subPrCharge.isEmpty() /* && countryCodefilter.contains(subPrCharge[0].Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode) */) {

                if(baseProductToAdd != System.Label.Start_BaseProduct && baseProductToAdd != System.Label.Premium_BaseProduct) {
                    response.message = System.Label.WS_Message_InvalidRefNumber;
                    return json.serialize(response, true);
                }
                // check the current base product
                String baseProduct = subPrCharge[0].Zuora__Subscription__r.SUB_T_Produit_De_Base__c;
                Date currentRenewalDate = subPrCharge[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                String renewResponse;
                String renewType;

                try {
                    // check if its a simple renewal or renewal with upgrade or downgrade
                    if(baseProductToAdd == baseProduct) {

                        renewType = System.Label.LWC_Simple_Renew_Type;
                        renewResponse = SubscriptionRenewalActions.renewSubscription(subPrCharge[0].Zuora__Subscription__c,
                                                                                     prepaidPeriod, modeDePaiement, transactionId, operator, null, null, null, null, null, null, null, null);

                    } else if(baseProduct == System.Label.Start_BaseProduct) {

                        renewType = System.Label.LWC_Renew_With_Upgrade_Type;
                        renewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(subPrCharge[0].Zuora__Subscription__c,
                                                                                              prepaidPeriod, false, true, false, modeDePaiement, transactionId, operator, null, null, null, null, null, null, null, null);
                    } else if(baseProduct == System.Label.Premium_BaseProduct){

                        renewType = System.Label.LWC_Renew_With_Downgrade_Type;
                        renewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(subPrCharge[0].Zuora__Subscription__c,
                                                                                                null, prepaidPeriod, false, modeDePaiement, transactionId, operator, null, null, null, null, null, null, null, null);
                    }else{
                        createAggregatorTransaction(subPrCharge[0].Zuora__Subscription__c, currentRenewalDate, prepaidPeriod, renewType, transactionId, operator, modeDePaiement, 'Invalid/NUll Base Product in SF');
                        response.message = 'ERROR: Invalid/NUll Base Product in SF';

                        return json.serialize(response, true);
                    }
                } catch(Exception e) {
                    createAggregatorTransaction(subPrCharge[0].Zuora__Subscription__c, currentRenewalDate, prepaidPeriod, renewType, transactionId, operator, modeDePaiement, 'in catch exception ===> '+e.getMessage());
                    response.message = 'Renew Action will be launched automatically after 30 minutes, ' + e.getMessage();

                    return json.serialize(response, true);
                }

                ZuoraResponseObjects.ZuoraPayment responseObject = new ZuoraResponseObjects.ZuoraPayment();
                try {
                    responseObject = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(renewResponse, ZuoraResponseObjects.ZuoraPayment.class);
                } catch (Exception e) {
                    response.message = e.getMessage()+' >>> '+renewResponse;

                    return json.serialize(response, true);
                }

                if(responseObject.success) {

                    response.success = true;
                    response.amount = responseObject.appliedAmount;
                    response.requestDate = String.valueOf(datetime.now());
                    response.name = subPrCharge[0].Zuora__Subscription__r.Zuora__Account__r.Name;
                    response.transactionId = transactionId;
                } else {
                    response.message = 'Renew Action will be launched automatically after 30 minutes, ' + 'in else of success ===> '+responseObject.reasons[0].message;
                    createAggregatorTransaction(subPrCharge[0].Zuora__Subscription__c, currentRenewalDate, prepaidPeriod, renewType, transactionId, operator, modeDePaiement, responseObject.reasons[0].message);
                }
            }
            else {
                response.Message = System.Label.WS_Message_NoSub; // return this error in these case: client doesn't exist, client in move proccess, client in country USSD not supported
            }
        } else if(string.isBlank(boxNumber)) {
            response.message = System.Label.Box_Number_Required;
        } else if(string.isBlank(transactionId)) {
            response.message = System.Label.Transaction_Number_Required;
        } else if(string.isBlank(operator)) {
            response.message = System.Label.Operator_is_required;
        } else if(string.isBlank(baseProductToAdd)) {
            response.message = System.Label.referenceNumber_is_required;
        } else if(prepaidPeriod == null || prepaidPeriod < 1) {
            response.message = System.Label.Prepaid_Period_Required;
        } else {
            response.message = System.Label.required_fields_are_empty;
        }

        return json.serialize(response, true);
    }

    // if a suivi is not created we create Agregator_Transaction__c with the transaction info else there is a way to reTrigger the transaction based on the suivi record
    public static void createAggregatorTransaction(String subId, Date currentRenewalDate, Integer prepaidPeriod, String renewType, String transactionId, String operator, String modeDePaiement, String errorMessage){

        list<Suivi_de_Souscription__c> currentSuivi =  [SELECT SV_Id_Souscription__c, SV_Statut__c, SV_T_GVAStatusKO__c
                                                        FROM Suivi_de_Souscription__c
                                                        WHERE CreatedDate = TODAY
                                                        AND ( SV_Code_Action__c = 'ACT003' OR SV_Code_Action__c = 'ACT004' )
                                                        AND SV_Id_Souscription__c = :subId];
        system.debug('list of suivi ' + currentSuivi);

        if(currentSuivi == null || currentSuivi.Size() == 0) {
            Agregator_Transaction__c reCreateTransaction = new Agregator_Transaction__c();
            reCreateTransaction.AT_Subscription__c = subId;
            reCreateTransaction.AT_Prepaid_Period__c = prepaidPeriod;
            reCreateTransaction.AT_renew_Type__c = renewType;
            reCreateTransaction.AT_Transaction_Reference__c = transactionId;
            reCreateTransaction.AT_Operator__c = operator;
            reCreateTransaction.AT_Payment_Method__c = modeDePaiement;
            reCreateTransaction.error_message__c = errorMessage;
            reCreateTransaction.AT_SourceOfRequest__c = System.Label.USSD_Value;
            reCreateTransaction.AT_Status__c  = System.Label.NotTreated_Value;
            reCreateTransaction.Number_of_retry_attempts__c = 1;
            reCreateTransaction.Current_Expected_Renewal_Date__c = currentRenewalDate;
            try {
                insert reCreateTransaction;
            } catch(Exception excep) {
                system.debug('insert Aggregator error ' + excep);
            }
        }
    }

}