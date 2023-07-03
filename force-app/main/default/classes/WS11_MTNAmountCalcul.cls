/**
 * Classe Utiliser pour recuperer la demande de reabo et retourner le montant de l'offre et la periode de paiement  (utiliser pour des differents operateurs)
 * @date 2023-03-24
 */
@RestResource(urlMapping = '/v1/AmountPreview/*') // MTNAmountCalcul
global class WS11_MTNAmountCalcul {
    
	@HttpPost
    global static string postAmountCalcul() {

        RestRequest req = RestContext.request;
        USSDObjects.RequestToPayPreviewResponse response = new USSDObjects.RequestToPayPreviewResponse();
        response.success = false; // succes false until we get the amount

        if(RestContext.request.requestBody == null){
            response.message = 'No request body received';
            return json.serialize(response, true);
        }
        else{
            // argument of the price
            USSDObjects.Argument  arg = new USSDObjects.Argument();
            USSDObjects.Key  key = new USSDObjects.Key();
            USSDObjects.Value  value = new USSDObjects.Value();
            // argument of the currency
            USSDObjects.Argument  arg2 = new USSDObjects.Argument();
            USSDObjects.Key  key2 = new USSDObjects.Key();
            USSDObjects.Value  value2 = new USSDObjects.Value();
            list<USSDObjects.Argument> listArgument = new list<USSDObjects.Argument>();

            USSDObjects.PreviewAmountRequest transactionRequest = (USSDObjects.PreviewAmountRequest) JSON.deserialize(RestContext.request.requestBody.toString(), USSDObjects.PreviewAmountRequest.class);

            String boxNumber = '';
            String baseProductToAdd = '';
            Integer prepaidPeriod;
            String numTel = '';
            String operatorSource;
            String renewtype;

            // MTN request case
            if(transactionRequest.arguments != null && transactionRequest.arguments.size() > 0){
                for(Integer i=0; i<transactionRequest.arguments.size();i++){

                    switch on transactionRequest.arguments[i].key.value {
                        when 'boxNumber' {
                            boxNumber = transactionRequest.arguments[i].value.value;
                        }
                        when 'subsName' {
                            baseProductToAdd = transactionRequest.arguments[i].value.value;     
                        }
                        when 'Period' {
                            prepaidPeriod = Integer.ValueOf(transactionRequest.arguments[i].value.value);
                        }
                        when 'ACCOUNT_HOLDER_MSISDN' {
                            numTel = transactionRequest.arguments[i].value.value;
                        }
                    }
                }    
            }else{ // all requests other then MTN
                boxNumber = transactionRequest.routerNumber;
                baseProductToAdd = transactionRequest.referenceNumber != null ? transactionRequest.referenceNumber : '';
                prepaidPeriod = Integer.ValueOf(transactionRequest.prepaidPeriod);
                operatorSource = transactionRequest.operator;
                renewtype = transactionRequest.renewtype != null ? transactionRequest.renewtype : null; // REABO , REABO_UPG_DWG
                if(operatorSource == null){ // only in MTN case the operator is not required
                    response.message = System.Label.Operator_is_required;
                    return json.serialize(response, true);
                }
            }
      
            // until now only the start and premium product are supported
            if(baseProductToAdd != null && baseProductToAdd != '' && baseProductToAdd != System.Label.Start_BaseProduct && baseProductToAdd != System.Label.Premium_BaseProduct) {

                response.message = System.Label.WS_Message_InvalidRefNumber;
                return json.serialize(response, true);
            }
            else{

                if(!string.isBlank(boxNumber) && (!string.isBlank(baseProductToAdd) || renewtype != null ) && prepaidPeriod != null && prepaidPeriod > 0){

                    list<Zuora__Subscription__c> listOfSub = [SELECT Id, SUB_T_Produit_De_Base__c, CurrencyIsoCode, isCollaborator__c,ExpectedRenewalDate__c, 
                                                                    Name, Zuora__Account__r.BillingCountryCode,BoxNumber__c
                                                                FROM Zuora__Subscription__c 
                                                                WHERE BoxNumber__c =: boxNumber  AND SuspensionReason__c != 'Move-Requested'
                                                                AND (Zuora__Status__c = :System.Label.Sub_Status_Active OR Zuora__Status__c = :System.Label.Sub_Status_Suspended) LIMIT 1];
                    
                    // return this error in these case: client doesn't exist, client in move proccess, client in country USSD not supported
                    if(listOfSub == null || listOfSub.Size() < 1 /* || listOfSub[0].Zuora__Account__r.BillingCountryCode != 'CG' or 'Gabon' */){
                        
                        response.Message = System.Label.WS_Message_NoSub; 
                        return json.serialize(response, true); 
                    }
                    else{
                            
                        Zuora__Subscription__c sub = listOfSub[0];
                        String curency = sub.CurrencyIsoCode;
                        String modeDePaiement = System.Label.ModePaiement_MobileMoney;
                        String operator = operatorSource != null ? operatorSource : 'MTN';
                        String transactionId = GuidUtil.NewGuid(); // boxNumber +'-'+ datetime.now(); // 1c35083b-fbe0-4714-9dfe-7a4e2c209232;
                        Double montant;
                        String previewResult;
                        string pRPChargeId = null;

                        // if baseProductToAdd is null check the renew type to get the base product to add
                        if(string.isBlank(baseProductToAdd) ||  baseProductToAdd == null){
                            if(renewtype != null && renewtype == 'REABO'){
                                baseProductToAdd = sub.SUB_T_Produit_De_Base__c;
                            }else if(renewtype != 'REABO_UPG_DWG'){
                                response.message = System.Label.WS_Message_InvalidRefNumber;
                                return json.serialize(response, true);
                            }else if(sub.SUB_T_Produit_De_Base__c == System.Label.Start_BaseProduct){
                                baseProductToAdd = System.Label.Premium_BaseProduct;
                            }else{
                                baseProductToAdd = System.Label.Start_BaseProduct;
                            }
                        }
                                                    
                        try {
                            // check if it's a collaborator get the discount product
                            if(sub.isCollaborator__c == 'Y'){
                                pRPChargeId = SubscriptionRenewalActions.getCollaboratorCharge(sub.Id);
                                pRPChargeId = pRPChargeId != null ? pRPChargeId.substring (0, pRPChargeId.indexOf(',')) : null;
                            }
    
                            if(baseProductToAdd == sub.SUB_T_Produit_De_Base__c){
                                previewResult = SubscriptionRenewalActions.renewSubPreview(sub.Id, prepaidPeriod, true, modeDePaiement, false, pRPChargeId, null, null, null);
                            } else if(baseProductToAdd == System.Label.Premium_BaseProduct){
                                previewResult = SubscriptionRenewalActions.upgradeSubscriptionProduct(sub.Id, prepaidPeriod, true, true, false, modeDePaiement, transactionId, operator,null,null,null,null,null,null,null,null);
                            } else if(baseProductToAdd == System.Label.Start_BaseProduct){
                                previewResult = SubscriptionRenewalActions.downgradeSubscriptionProduct(sub.Id, null, prepaidPeriod, true, modeDePaiement, transactionId, operator,null,null,null,null,null,null,null,null);
                            }
                        } catch (Exception e) {
                            response.success = false;
                            response.message = e.getLineNumber() + ' >> ' + e.getMessage();
    
                            return json.serialize(response, true);
                        }
    
                        ZuoraResponseObjects.ZuoraPreviewResponse firstPreview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                        montant = firstPreview.previewResult.invoices != null && firstPreview.previewResult.invoices.size() > 0 ? firstPreview.previewResult.invoices[0].amount : 0;
    
                        // create the response in case of operator MTN
                        if(operator == 'MTN'){

                            key.value = 'subsPrice';
                            value.value = String.valueOf(montant);
                            arg.key = key;
                            arg.value = value;
                            listArgument.add(arg);
                            key2.value = 'subsCurrency';
                            value2.value = curency;
                            arg2.key = key2;
                            arg2.value = value2;
                            listArgument.add(arg2);
                            response.arguments = listArgument;
                            response.success = montant != 0 && montant != null ? true : false;
        
                            try {
                                createrequestToPayDemand(sub, montant, transactionId, boxNumber, curency, numTel, baseProductToAdd, prepaidPeriod, operator, firstPreview.success != true? json.serialize(firstPreview.zuoraLogs, true) : null);
                            } catch (Exception e) {
                                response.message = e.getMessage();
                                response.success = false;
                                return json.serialize(response, true);
                            }
                        }
                        else{

                            response.success = montant != 0 && montant != null ? true : false;
                            response.amount = String.valueOf(montant);
                            response.currentCurrency = curency;
                            response.currentCountryCode = sub.Zuora__Account__r.BillingCountryCode;
                            response.currentBoxNumber = sub.BoxNumber__c;
                            response.previewDateTime = String.valueOf(datetime.now());
                            response.oldOffer = sub.SUB_T_Produit_De_Base__c;
                            response.newOffer = baseProductToAdd;
                        }
                    }
                } 
                else if(string.isBlank(boxNumber)) {
                    response.message = System.Label.Box_Number_Required;
                } else if(string.isBlank(baseProductToAdd)) {
                    response.message  = System.Label.referenceNumber_is_required;
                } else if(prepaidPeriod == null || prepaidPeriod < 1) {
                    response.message  = System.Label.Prepaid_Period_Required;
                } else {
                    response.message  = System.Label.required_fields_are_empty;
                }
            }
        }

        return json.serialize(response, true);
        // to return in JSON format remove all the return and change the method to void
        // RestContext.response.addHeader('Content-Type', 'application/json');
        // RestContext.response.responseBody = Blob.valueOf(json.serialize(response, true));
    }

    // create this technical object only for MTN requests
    public Static void createrequestToPayDemand(Zuora__Subscription__c sub, Double montant,String transactionId,String boxNumber,String curency,String numTel,String baseProductToAdd,Integer prepaidPeriod, String operator, String message){

        requestToPayDemand__c requestToPayDemand = new requestToPayDemand__c();
        requestToPayDemand.Request_Status__c = Datetime.now() + ' Preview Result: '+montant;
        requestToPayDemand.financialTransactionId__c = transactionId;
        requestToPayDemand.externalId__c = boxNumber;
        requestToPayDemand.Currency__c = curency;
        requestToPayDemand.Amount__c = montant;
        requestToPayDemand.numTel__c = numTel;
        requestToPayDemand.baseProductToAdd__c = baseProductToAdd;
        requestToPayDemand.prepaidPeriod__c = prepaidPeriod;
        requestToPayDemand.Error_message__c = message;
        requestToPayDemand.Current_Expected_Renewal_Date__c  = sub.ExpectedRenewalDate__c;
        requestToPayDemand.Current_Base_Product__c = sub.SUB_T_Produit_De_Base__c;
        requestToPayDemand.Request_Stage__c = 'Preview';
        requestToPayDemand.Subscription__c = sub.Id;
        requestToPayDemand.Source_operator__c = operator;

        insert requestToPayDemand;
    }
}