/**
 * Classe Utiliser pour recuperer la demande de paiement relier a MTN USSD Congo et declencher l'appel Request to pay (https://momodeveloper.mtn.com/api-documentation)
 * @date 2023-02-28
 */
@RestResource(urlMapping = '/v1/MTNRequestToPay/*')
global class WS10_MTNRequestToPay {
    
	@HttpPost
    global static string postRequestToPay() {

        RestRequest req = RestContext.request;

        MTNObjects.RequestToPayPreviewResponse response = new MTNObjects.RequestToPayPreviewResponse();
        MTNObjects.Argument  arg = new MTNObjects.Argument();
        MTNObjects.Key  key = new MTNObjects.Key();
        MTNObjects.Value  value = new MTNObjects.Value();
        list<MTNObjects.Argument> listArgument = new list<MTNObjects.Argument>();

        response.success = false; // succes false until we get the amount

        if(RestContext.request.requestBody == null){
            response.message = 'No request body received';
            return json.serialize(response, true);
        }
        
        MTNObjects.RequestToPayReq transactionRequest = (MTNObjects.RequestToPayReq) JSON.deserialize(RestContext.request.requestBody.toString(), MTNObjects.RequestToPayReq.class);
        
        String requestToPayStatus = '';
        String boxNumber = '';
        String baseProductToAdd = '';
        String prepaidPeriod = '';
        String numTel = '';

        for(Integer i=0; i<transactionRequest.arguments.size();i++){

            switch on transactionRequest.arguments[i].key.value {
                when 'boxNumber' {
                    boxNumber = transactionRequest.arguments[i].value.value;
                }
                when 'subsName' {
                    baseProductToAdd = transactionRequest.arguments[i].value.value;     
                }
                when 'Period' {
                    prepaidPeriod = transactionRequest.arguments[i].value.value;
                    prepaidPeriod = prepaidPeriod == '' ? '0' : prepaidPeriod;
                }
                when 'ACCOUNT_HOLDER_MSISDN' {
                    numTel = transactionRequest.arguments[i].value.value;
                }
            }
        }
        

        if(!string.isBlank(boxNumber) && !string.isBlank(baseProductToAdd) && prepaidPeriod != null && integer.valueOf(prepaidPeriod) > 0){

            // see with MTN if i can send the transactionID in the preview and get it back in this request
            String transactionId = boxNumber +'-'+string.valueOf(date.today())+'-'+baseProductToAdd+'-'+prepaidPeriod;

            List<requestToPayDemand__c> listRequestToPay = [SELECT Id,externalId__c,numTel__c,Currency__c,financialTransactionId__c,Amount__c, Request_Status__c,
                                                            Subscription__c, Subscription__r.Zuora__Account__r.BillingCountryCode, Subscription__r.Zuora__Account__c
                                                            FROM requestToPayDemand__c 
                                                            WHERE externalId__c=: boxNumber /* AND financialTransactionId__c =: transactionId */ AND createdDate = TODAY
                                                            AND Request_Stage__c = 'Preview' AND Subscription__r.SuspensionReason__c != 'Move-Requested'];
            
            if(listRequestToPay != null && listRequestToPay.size()>0 /* &&  listRequestToPay[0].Subscription__r.Zuora__Account__r.BillingCountryCode == 'CG' */){

                // create the request body
                MTNObjects.MobileMoneyRequest bodyJson = new MTNObjects.MobileMoneyRequest();
                bodyJson.amount =  String.valueOf(listRequestToPay[0].Amount__c);
                bodyJson.curency = listRequestToPay[0].Currency__c;
                bodyJson.externalId = listRequestToPay[0].externalId__c.replaceAll(':', '_');
                bodyJson.payerMessage = '';
                bodyJson.payeeNote = 'Payment request';
                bodyJson.payer = new MTNObjects.Payer('MSISDN',listRequestToPay[0].numTel__c);

                // send request and get the status code
                requestToPayStatus = apiManagerMTN.callout(listRequestToPay[0].financialTransactionId__c, JSON.serialize(bodyJson).replace('curency','currency'), MTNObjects.post, MTNObjects.requesttopayAPIUrl);

                if(requestToPayStatus == '202'){
                    response.message = 'ACCEPTED';
                    response.success = true;

                    listRequestToPay[0].Request_Stage__c = 'Successful_RequestToPay';
                }
                else if(requestToPayStatus == '400'){
                    response.message = 'Bad request!';
                }
                else if(requestToPayStatus == '409'){
                    response.message = 'Duplicated reference id. Creation of resource failed!';
                }
                else if(requestToPayStatus == '500'){
                    response.message = 'An internal error occurred while processing!';
                }
                else{
                    response.message = requestToPayStatus;
                }

                key.value = 'confirmationCode';
                value.value = requestToPayStatus;
                arg.key = key;
                arg.value = value;
                listArgument.add(arg);
                response.arguments = listArgument;


                listRequestToPay[0].Request_Status__c += '\n' + Datetime.now() + ' Request to pay Status: '+ requestToPayStatus;
                update listRequestToPay[0];

                Log__c lg = new log__c();
                lg.LG_Body__c = JSON.serialize(bodyJson);
                lg.LG_Account__c = listRequestToPay[0].Subscription__r.Zuora__Account__c;
                lg.LG_Subscription__c = listRequestToPay[0].Subscription__c;
                lg.LG_Method_URL__c = MTNObjects.requesttopayAPIUrl;
                lg.LG_Response__c = requestToPayStatus;
                lg.LG_Interface__c = 'MTN Congo';
                lg.LG_Success__c = requestToPayStatus == '202' ? true : false;
                lg.LG_Error_Message__c = response.message;
                lg.LG_Method_Type__c = MTNObjects.post;
                insert lg;
            }
            else{
                response.message = 'No Preview object is found';
            }
        }  
        else if(string.isBlank(boxNumber)) {
            response.message = System.Label.Box_Number_Required;
        } else if(string.isBlank(baseProductToAdd)) {
            response.message  = System.Label.referenceNumber_is_required;
        } else if(prepaidPeriod == null || integer.valueOf(prepaidPeriod) < 1) {
            response.message  = System.Label.Prepaid_Period_Required;
        } else {
            response.message  = System.Label.required_fields_are_empty;
        }
        
        return json.serialize(response, true);
    }
}