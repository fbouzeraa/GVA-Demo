/**
 * Test Class : WS09_USSDMTNPayment_test
 * @date 2023-03-10
 * Classe utiliser pour recuperer le callBack de l'appel Request to pay (WS10_MTNRequestToPay)
 */
@RestResource(urlMapping = '/v1/MTNPayment/*')
global class WS09_USSDMTNPayment {
    
    @HttpPost
    global static string postTransaction() {

        RestRequest req = RestContext.request;

        MTNObjects.MobileMoneyResponse response = new MTNObjects.MobileMoneyResponse();
        response.success = false;

        if(RestContext.request.requestBody == null){
            response.message = 'No request body received';
            return json.serialize(response, true);
        }
        
        System.debug('get the callback body >> '+RestContext.request.requestBody.toString());
        MTNObjects.MobileMoneyRequest transactionRequest = (MTNObjects.MobileMoneyRequest) JSON.deserialize(RestContext.request.requestBody.toString(), MTNObjects.MobileMoneyRequest.class);
        
        String externalId = transactionRequest.externalId;
        String transactionId = transactionRequest.financialTransactionId;
        String amount =  transactionRequest.amount;
        String status =  transactionRequest.status;
        String payerMessage = transactionRequest.payerMessage;
        String payeeNote = transactionRequest.payeeNote;

        if(externalId != null && transactionId != null && amount != null && integer.valueOf(amount) > 0){

            List<requestToPayDemand__c> listRequestToPay = [SELECT Id, CreatedDate, externalId__c, financialTransactionId__c, Request_Status__c, Currency__c, Subscription__c,
                                                                Amount__c, numTel__c, baseProductToAdd__c, prepaidPeriod__c, Error_message__c, Source_operator__c,
                                                                Current_Expected_Renewal_Date__c, Current_Base_Product__c, Request_Stage__c, Success__c, CurrencyIsoCode
                                                            FROM requestToPayDemand__c 
                                                            WHERE externalId__c=: externalId AND Request_Stage__c = 'Successful_RequestToPay' 
                                                            AND financialTransactionId__c =: transactionId AND Amount__c =: integer.valueOf(amount)];
        
            if(listRequestToPay != null && listRequestToPay.size() > 0 && status != null && status == 'SUCCESSFUL'){

                String curency = listRequestToPay[0].Currency__c;
                String modeDePaiement = System.Label.ModePaiement_MobileMoney;
                String baseProductToAdd = listRequestToPay[0].baseProductToAdd__c;
                Integer prepaidPeriod = Integer.valueOf(listRequestToPay[0].prepaidPeriod__c);
                String operator = listRequestToPay[0].Source_operator__c;


                list<zuora__subscriptionProductCharge__c> subPrCharge = [SELECT Name, Zuora__Subscription__r.BoxNumber__c, Zuora__Subscription__r.Zuora__Account__r.Name,
                                                                     Zuora__Subscription__r.Name, Zuora__Subscription__r.SUB_T_Produit_De_Base__c, Zuora__Subscription__r.SUB_T_Account_Country__c,
                                                                     Zuora__Subscription__r.Zuora__Status__c, Zuora__Subscription__r.Zuora__Account__c,
                                                                     IsDeleted, Zuora__ListPriceBase__c, Zuora__Product__c, Zuora__Product__r.Name, Zuora__Subscription__c,
                                                                     Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                                                     Zuora__Subscription__r.Zuora__SubscriptionNumber__c, Zuora__RatePlanId__c,
                                                                     Zuora__Subscription__r.ExpectedRenewalDate__c, Zuora__Subscription__r.isCollaborator__c,
                                                                     Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode
                                                                     FROM zuora__subscriptionProductCharge__c
                                                                     WHERE Zuora__Subscription__r.BoxNumber__c =: externalId AND Zuora__Subscription__r.SuspensionReason__c != 'Move-Requested'
                                                                     AND (Zuora__Subscription__r.Zuora__Status__c = :System.Label.Sub_Status_Active OR Zuora__Subscription__r.Zuora__Status__c = :System.Label.Sub_Status_Suspended)];
                // check if a current active or suspended subscription was found
                if(subPrCharge == null || subPrCharge.Size() < 1 || subPrCharge.isEmpty() /* || subPrCharge[0].Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode != 'CG' */){ 
                    response.Message = System.Label.WS_Message_NoSub; // return this error in these case: client doesn't exist, client in move proccess, client in country USSD not supported
                    return json.serialize(response, true); 
                }

                // check the current base product
                String baseProduct = subPrCharge[0].Zuora__Subscription__r.SUB_T_Produit_De_Base__c;
                Date currentRenewalDate = subPrCharge[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                String renewResponse;

                try {
                    // check if its a simple renewal or renewal with upgrade or downgrade
                    if(baseProductToAdd == baseProduct) {

                        renewResponse = SubscriptionRenewalActions.renewSubscription(subPrCharge[0].Zuora__Subscription__c,
                                                                                     prepaidPeriod, modeDePaiement, transactionId, operator, null, null, null, null, null, null, null, null);
                    } else if(baseProduct == System.Label.Start_BaseProduct) {

                        renewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(subPrCharge[0].Zuora__Subscription__c,
                                                                                              prepaidPeriod, false, true, false, modeDePaiement, transactionId, operator, null, null, null, null, null, null, null, null);
                    } else if(baseProduct == System.Label.Premium_BaseProduct){

                        renewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(subPrCharge[0].Zuora__Subscription__c,
                                                                                                null, prepaidPeriod, false, modeDePaiement, transactionId, operator, null, null, null, null, null, null, null, null);
                    }
                } catch(Exception e) {
                    listRequestToPay[0].Error_message__c = e.getLineNumber() + ' >>> '+ e.getMessage();
                    updateTheRequestToPayDemand(listRequestToPay[0], true, subPrCharge[0].Zuora__Subscription__c);
                    response.success = false;
                    response.message = e.getLineNumber() + ' >> ' + e.getMessage();
    
                    return json.serialize(response, true);
                }

                ZuoraResponseObjects.ZuoraPayment responseObject = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(renewResponse, ZuoraResponseObjects.ZuoraPayment.class);

                Boolean failed;
                if(responseObject.success) {

                    response.success = true;
                    response.requestDate = string.valueOf(Datetime.now());

                    failed = false;
                }else {
                    response.message = 'Renew Action will be launched automatically after 30 minutes, ' + responseObject.reasons[0].message;

                    listRequestToPay[0].Error_message__c = responseObject.reasons[0].message;

                    failed = true;
                }

                updateTheRequestToPayDemand(listRequestToPay[0], failed, subPrCharge[0].Zuora__Subscription__c);
            } else if(status != 'SUCCESSFUL') {
                response.message = 'UnSuccessful payment';
                listRequestToPay[0].Request_Stage__c  = 'Unsuccessful_Payment';
                listRequestToPay[0].Request_Status__c += '\n' + Datetime.now() + ' End of transaction';

                update listRequestToPay[0]; 
            } else{
                response.message = 'No matching request was found';
            }
        }
        else if(string.isBlank(externalId)) {
            response.message = System.Label.Box_Number_Required;
        } else if(string.isBlank(transactionId)) {
            response.message = System.Label.Transaction_Number_Required;
        } else if(amount == null || integer.valueOf(amount) < 1) {
            response.message = 'Null amount';
        } else {
            response.message = System.Label.required_fields_are_empty;
        }

        return json.serialize(response, true);
	}

    // if a suivi is not created we create requestToPayDemand__c with the transaction info else there is a way to reTrigger the transaction based on the suivi record
    public static void updateTheRequestToPayDemand(requestToPayDemand__c requestToPayDemand, Boolean failed, String subId){

        if(failed){
            requestToPayDemand.Request_Stage__c  = 'Failed_renewal';
            requestToPayDemand.Request_Status__c += '\n' + Datetime.now() + ' unSuccessful transaction';
        }else{
            requestToPayDemand.Request_Status__c += '\n' + Datetime.now() + ' Renewed, End of transaction';
            requestToPayDemand.Request_Stage__c = 'Successful_renewal';
            requestToPayDemand.Success__c = true;
        }


        update requestToPayDemand;    
    }
}