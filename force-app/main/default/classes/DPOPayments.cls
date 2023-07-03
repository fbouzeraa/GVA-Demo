public with sharing class DPOPayments {

    @AuraEnabled
    public static string createToken(id subId, double amount, string prepaidPeriod, string productName, string renewType)
    {
        Zuora__Subscription__c sub = [SELECT Zuora__Account__r.FirstName, Zuora__Account__r.LastName, Zuora__Account__r.BillingCity,
                                      Zuora__Account__r.BillingCountryCode, Zuora__Account__r.currencyISOCode, BoxNumber__c,
                                      Zuora__Account__r.PersonMobilePhone, Zuora__Account__r.PersonEmail, SUB_Bandwidth__c
                                      FROM Zuora__Subscription__c
                                      WHERE Id = :subId];
        system.debug('productName  '+productName);
        String companyTokenOfCountry;
        Integer serviceTypeRwanda;
        switch on sub.Zuora__Account__r.BillingCountryCode {

            when 'RW'{
                companyTokenOfCountry = System.Label.DPO_CompanyToken_Rwanda;
                serviceTypeRwanda = integer.valueOf(System.Label.DPO_serviceTypeRwanda);
            }
        }

       // amount = 100;

        DPObjects.TransactionObject transactionObj = new DPObjects.TransactionObject();
        transactionObj.PaymentAmount = amount;
        transactionObj.PaymentCurrency = sub.Zuora__Account__r.currencyISOCode;
        transactionObj.customerFirstName = sub.Zuora__Account__r.FirstName;
        transactionObj.customerLastName = sub.Zuora__Account__r.LastName;
        transactionObj.customerCity = sub.Zuora__Account__r.BillingCity;
        transactionObj.customerCountry = sub.Zuora__Account__r.BillingCountryCode;
        transactionObj.customerEmail = sub.Zuora__Account__r.PersonEmail;
        transactionObj.customerPhone = sub.Zuora__Account__r.PersonMobilePhone;

        // transactionObj.RedirectURL = 'https ://grpvivendiafrica--gvaaccept.sandbox.lightning.force.com/lightning/r/Zuora__Subscription__c/'+sub.if/view?Transactionref=' + sub.BoxNumber__c;
        transactionObj.CompanyRef = sub.BoxNumber__c;
        transactionObj.CompanyAccRef = sub.BoxNumber__c;

        // info cannot be changed  // We check this message in the callBack WebService
        DPObjects.ServiceObject serviceObj = new DPObjects.ServiceObject();
        serviceObj.ServiceDescription = 'Pay My Bills ' + productName + ' (' + sub.SUB_Bandwidth__c + ') ' + prepaidPeriod + ' month';
        serviceObj.ServiceType = serviceTypeRwanda; //41076 // Rwanda ==> 41025;
        serviceObj.ServiceDate = date.today();

        DPObjects.Services services = new DPObjects.Services();
        services.Service = serviceObj;
        
        DPObjects.API3G apiInfo = new DPObjects.API3G();
        apiInfo.CompanyToken = companyTokenOfCountry; //Rwanda ==> 'C1A03A65-F728-4EB7-8BB0-6F18776509CC';//'8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';// '57466282-EBD7-4ED5-B699-8659330A6996';
        apiInfo.Request = System.Label.DPO_createToken_request;
        apiInfo.Transaction_toReplace = transactionObj;
        apiInfo.Services = services;
        system.debug('apiInfo '+apiInfo);
        DPObjects.createToken newToken = new DPObjects.createToken();
        newToken.API3G = apiInfo;

        //convert apex obj to json and json to xml
        string jsonRequest =  JSON.serialize(newToken, true);
        string xmlRequest = new XMLSerializer().jsonToXML(jsonRequest.replaceAll('Transaction_toReplace', 'Transaction'));
        HttpResponse getTransactionResponse = DPOManager.doCallout(DPObjects.newTokenAPIUrl, DPObjects.post, xmlRequest);
        string body = getTransactionResponse.getBody(); //'<API3G ><CompanyToken> 57466282 - EBD7 - 4ED 5 - B699 - 8659330A6996 </CompanyToken><Request> createToken</Request><Transaction><PaymentAmount> 450.00 </PaymentAmount><PaymentCurrency> USD</PaymentCurrency><CompanyRef> 49FKEOA </CompanyRef><RedirectURL> http://www.domain.com/payurl.php</RedirectURL><BackURL> http://www.domain.com/backurl.php </BackURL></Transaction><Services><Service><ServiceType> 45 </ServiceType><ServiceDescription> Flight from Nairobi to Diani</ServiceDescription>< ServiceDate> 2013 / 12 / 20 19 : 00 </ServiceDate></Service></Services></API3G>';

        string jsonResponse =  new XMLSerializer().XMLToJSON(body);

        DPObjects.newTokenResponse tokenResponse = (DPObjects.newTokenResponse) JSON.deserialize(jsonResponse, DPObjects.newTokenResponse.class);
        system.debug(tokenResponse.API3G);

        Agregator_Transaction__c aggTransaction = new Agregator_Transaction__c();
        aggTransaction.AT_Subscription__c = sub.Id;
        aggTransaction.AT_Transaction_Reference__c = tokenResponse.API3G.TransRef;
        aggTransaction.AT_Renew_Type__c = renewType;
        aggTransaction.AT_Status__c = System.Label.NotTreated_Value;
        aggTransaction.AT_Company_Reference__c =  companyTokenOfCountry; //Rwanda ==> 'C1A03A65-F728-4EB7-8BB0-6F18776509CC'; //'8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';
        aggTransaction.AT_Prepaid_Period__c = integer.valueof(prepaidPeriod);
        aggTransaction.AT_Transaction_Token__c = tokenResponse.API3G.TransToken;
        aggTransaction.AT_SourceOfRequest__c = 'DPO';
        insert aggTransaction;

        return System.Label.DPO_Payment_Page_URL + tokenResponse.API3G.TransToken;
    }

    @InvocableMethod(label = 'retry payment')
    public static Void retryPayment(list<id> listPaymentId){
        if(listPaymentId.size() > 0 && listPaymentId != null) {

            retryPayment(listPaymentId[0]);
        }
    }

    @future(callout = true)
    public static void retryPayment(id paymentId){
        try {
            list<Agregator_Transaction__c> listPayments = [SELECT AT_Subscription__c, AT_Transaction_Token__c, AT_Prepaid_Period__c, AT_Renew_Type__c, AT_Status__c, AT_Subscription__r.SUB_Numero_de_transaction__c
                                                           FROM Agregator_Transaction__c
                                                           WHERE Id = :paymentId AND AT_Status__c =: System.Label.NotTreated_Value AND AT_SourceOfRequest__c = 'DPO'];

            if(listPayments.size() > 0 && listPayments != null) 
            {
                if(listPayments[0].AT_Subscription__r.SUB_Numero_de_transaction__c != listPayments[0].AT_Transaction_Token__c)
                {
                    DPObjects.API3G apiInfo = new DPObjects.API3G();
                    apiInfo.CompanyToken = System.Label.DPO_CompanyToken_RW_VerifyRequest;// '57466282-EBD7-4ED5-B699-8659330A6996';
                    apiInfo.Request = System.Label.DPO_verifyToken_Request;
                    apiInfo.TransactionToken = listPayments[0].AT_Transaction_Token__c;

                    DPObjects.createToken verifyToken = new DPObjects.createToken();
                    verifyToken.API3G = apiInfo;
                    //convert apex obj to json and json to xml
                    string jsonRequest =  JSON.serialize(verifyToken, true);
                    string xmlRequest = new XMLSerializer().jsonToXML(jsonRequest.replaceAll('Transaction_toReplace', 'Transaction'));
                    HttpResponse getTransactionResponse = DPOManager.doCallout(DPObjects.newTokenAPIUrl, DPObjects.post, xmlRequest);
                    string body = getTransactionResponse.getBody(); //'<API3G ><CompanyToken> 57466282 - EBD7 - 4ED 5 - B699 - 8659330A6996 </CompanyToken><Request> createToken</Request><Transaction><PaymentAmount> 450.00 </PaymentAmount><PaymentCurrency> USD</PaymentCurrency><CompanyRef> 49FKEOA </CompanyRef><RedirectURL> http://www.domain.com/payurl.php</RedirectURL><BackURL> http://www.domain.com/backurl.php </BackURL></Transaction><Services><Service><ServiceType> 45 </ServiceType><ServiceDescription> Flight from Nairobi to Diani</ServiceDescription>< ServiceDate> 2013 / 12 / 20 19 : 00 </ServiceDate></Service></Services></API3G>';

                    string jsonResponse =  new XMLSerializer().XMLToJSON(body);

                    DPObjects.newTokenResponse tokenResponse = (DPObjects.newTokenResponse) JSON.deserialize(jsonResponse, DPObjects.newTokenResponse.class);
                    string renewResponse = null;

                    // create log of the API
                    Log__c lg = createAPILog(jsonRequest, null, listPayments[0].AT_Subscription__c, null, DPObjects.newTokenAPIUrl,
                                            jsonResponse, tokenResponse.API3G.Result == '000' ?true : false, null, CBundleObjects.post);

                    if(tokenResponse.API3G.Result == '000')
                    {
                        if(listPayments[0].AT_Renew_Type__c == System.Label.LWC_Simple_Renew_Type) {
                            renewResponse = SubscriptionRenewalActions.renewSubscription(listPayments[0].AT_Subscription__c, integer.valueOf(listPayments[0].AT_Prepaid_Period__c),
                            System.Label.ModePaiement_MobileMoney, listPayments[0].AT_Transaction_Token__c, 'DPO', null, null, null, null, null, null, null, null);
                        } 
                        else if(listPayments[0].AT_Renew_Type__c == System.Label.LWC_Renew_With_Upgrade_Type)
                        {
                            renewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(listPayments[0].AT_Subscription__c, integer.valueOf(listPayments[0].AT_Prepaid_Period__c), false, true, false, System.Label.ModePaiement_MobileMoney, listPayments[0].AT_Transaction_Token__c, 'DPO', null, null, null, null, null, null, null, null);
                        } 
                        else
                        {
                            renewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(listPayments[0].AT_Subscription__c, null, integer.valueOf(listPayments[0].AT_Prepaid_Period__c), false, System.Label.ModePaiement_MobileMoney, listPayments[0].AT_Transaction_Token__c, 'DPO', null, null, null, null, null, null, null, null);
                        }

                        if(renewResponse != null) 
                        {
                            system.debug(renewResponse);
                            string responseAdjustment = renewResponse.replaceAll('number', 'number_toReplace');

                            ZuoraResponseObjects.ZuoraPayment paymentResponse = new ZuoraResponseObjects.ZuoraPayment();
                            if(responseAdjustment != System.label.Upgrade_Product_Failure){

                                paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                                if(paymentResponse.success) {
                                    Agregator_Transaction__c payment = new Agregator_Transaction__c(id = listPayments[0].Id, AT_Status__c = System.Label.Treated_Value);
                                    update payment;
                                }
                            }

                        }
                    }
                    insert lg;
                }

            }
        } catch(Exception e) {
            system.debug(e.getMessage() + e.getLineNumber() );
            throw new CustomException(e.getMessage() +' >>> ' + e.getLineNumber() );
        }
    }

    @AuraEnabled(cacheable=true)
    public static boolean checkRWUser(){
        boolean isRW = false;
        String UserId = UserInfo.getUserId();//Returns the context user's ID.
        User user = [SELECT Id, CountryCode FROM User WHERE Id =: UserId];
        if(user.CountryCode == 'RW'){
            isRW = true;
        }
        return isRW;
    }

    public static Log__c createAPILog(string boby, id IDCompte, id IDAbonnement, string subNumber, string URL,string reponse, boolean success, string reason, string type){

        Log__c newLog = new Log__c();
        newLog.LG_Body__c = boby;
        newLog.LG_Account__c = IDCompte;
        newLog.LG_Subscription__c = IDAbonnement;
        newLog.LG_Method_URL__c = URL;
        newLog.LG_Subscription_Number__c = subNumber;
        newLog.LG_Response__c = reponse;
        newLog.LG_Interface__c = 'DPO';
        newLog.LG_Success__c = success;
        newLog.LG_Error_Message__c = reason;
        newLog.LG_Method_Type__c = type;

        return newLog;
    }

    public class CustomException extends Exception {}
}




        //if any payment found DPO Code explanation
/**
 * 000-->Transaction Paid
 * 001-->Authorized
 * 002-->Transaction overpaid / underpaid
 * 003-->Pending Bank
 * 005-->Queued Authorization
 * 007-->Pending Split Payment (Part Payment Transactions not fully paid)
 * 801-->Request missing company token
 * 802-->Company token does not exist
 * 803-->No request or error in Request type name
 * 804-->Error in XML
 * 900-->Transaction not paid yet
 * 901-->Transaction declined
 * 902-->Data mismatch in one of the fields - field (explanation)
 * 903-->The transaction passed the Payment Time Limit
 * 904-->Transaction cancelled
 * 950-->Request missing transaction level mandatory fields – field (explanation)
 */