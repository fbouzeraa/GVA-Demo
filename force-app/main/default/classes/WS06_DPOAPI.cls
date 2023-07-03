/**
 * Test Classe : WS06_DPOAPI_Test
 * @author Yara Bourdoukan
 * @date 2021-10-21
 */
@RestResource(urlMapping = '/v1/getPayment/*')
global class WS06_DPOAPI {
    /* Methode permettant DPO de faire un appel à Salesforce via API
     * pour envoyer les info d'un paiement
     * @return string
     * */
    @HttpPost
    global static string doGet()
    {
        RestRequest req = RestContext.request;

        string results;
        DPObjects.Response response = new DPObjects.Response();
        list<string> listErrors = new list<String>();

        if(req != null){

            DPObjects.PushPaymentResponse subscriptionRequest = (DPObjects.PushPaymentResponse) JSON.deserialize(RestContext.request.requestBody.toString(), DPObjects.PushPaymentResponse.class);

            system.debug('the request '+subscriptionRequest);

            // list of required status
            list<string> listSubStatus = new list<string> {System.Label.Sub_Status_Active, System.Label.Sub_Status_Suspended};

            // Subscription base product type
            string productType = System.Label.Recurring_Product_Type;

            String companyToken;
            integer prepaidPeriod;
            double totalAmount;
            String productName;
            String boxNumber;
            String notTreated = System.Label.NotTreated_Value;

            //set of available base product
            set<string> setAvailableProduct = new set<string>();

            // Check if Object is accessible by calling user.
            try {

                string aggregatorQuery = 'SELECT Id, AT_Prepaid_Period__c, AT_Transaction_Reference__c, AT_Renew_Type__c, AT_Company_Reference__c, AT_Subscription__c, AT_Transaction_Token__c, AT_Status__c';
                       aggregatorQuery += ' FROM Agregator_Transaction__c ';
                       aggregatorQuery += ' WHERE AT_Status__c =:  notTreated';

                String query = 'SELECT Zuora__RatePlanName__c,Zuora__Subscription__c ';
                       query += ' FROM Zuora__SubscriptionProductCharge__c';
                       query += ' WHERE Zuora__Subscription__r.Zuora__Status__c IN :listSubStatus  AND Zuora__Type__c = :productType ';

                // Add country filter required
                if(subscriptionRequest.CustomerCountry != null && !string.isBlank(subscriptionRequest.CustomerCountry))
                {
                    String country = subscriptionRequest.CustomerCountry;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.BillingCountry = :country';

                    string product = '%' + country;
                    list<zqu__ProductRatePlan__c> baseProducts = [SELECT Name
                                                                FROM zqu__ProductRatePlan__c
                                                               WHERE type__c =: System.Label.Base_Product_Type AND zqu__Product__r.Name like :product];
                    
                    // Check if base product exist for the current country
                    if(baseProducts != null && baseProducts.size() > 0){
                        for(zqu__ProductRatePlan__c prod : baseProducts) {
                            setAvailableProduct.add(prod.Name);
                        }
                        query += ' AND Zuora__RatePlanName__c IN :setAvailableProduct';
                    }else{
                        listErrors.add(System.label.Country_Required);
                    }
                } 
                else{
                    listErrors.add(System.label.Country_Required);
                }

                // Add city filter NOT required
                if(subscriptionRequest.CustomerCity != null && !string.isBlank(subscriptionRequest.CustomerCity)) {
                    String city = subscriptionRequest.CustomerCity;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.BillingCity = :city';
                }

                // Add box number filter required
                if(subscriptionRequest.TransactionRef != null && !string.isBlank(subscriptionRequest.TransactionRef)) {
                    boxNumber = subscriptionRequest.TransactionRef;
                    query += ' AND Zuora__Subscription__r.BoxNumber__c = :boxNumber';
                    aggregatorQuery += ' AND AT_Transaction_Token__c = :boxNumber ';
                } else {
                    listErrors.add(System.label.Box_Number_Required);
                }

                // check total amount required
                if(subscriptionRequest.TransactionAmount != null && !string.isBlank(string.valueOf(subscriptionRequest.TransactionAmount))) {
                    totalAmount = subscriptionRequest.TransactionAmount;
                } else {
                    listErrors.add(System.label.Amount_Required);
                }

                // check company token required
                if(subscriptionRequest.CompanyToken != null && !string.isBlank(string.valueOf(subscriptionRequest.CompanyToken))) {
                    companyToken = subscriptionRequest.CompanyToken;
                } else {
                    listErrors.add(System.label.Company_Token_required);
                }

                system.debug('companyToken ==> '+companyToken);

                // if a required value is missing return an error
                if(listErrors.size() > 0 && listErrors != null) {
                    response.Erreurs = listErrors;
                    response.Success = false;
                    results = JSON.serialize(response, true);

                    return results;
                } 
                else
                {
                    // get the results
                    List<Zuora__SubscriptionProductCharge__c> listSub =  Database.query(query);
                    list<Agregator_Transaction__c> listPayment = Database.query(aggregatorQuery);

                    if((listSub != null && listSub.size() > 0) || (listPayment != null && listPayment.size() > 0))
                    {
                        // call get transaction by ref to get renew info
                        DPObjects.getTransactionByRef getTransaction = new DPObjects.getTransactionByRef();
                        DPObjects.API3G obj = new DPObjects.API3G();

                        obj.CompanyToken = companyToken;
                        obj.CompanyRef = boxNumber;
                        obj.Request = System.Label.DPO_getTransactionByRef_request;
                        if(subscriptionRequest.TransactionToken != null)
                        {
                            obj.TransactionToken = subscriptionRequest.TransactionToken;
                        }

                        getTransaction.API3G = obj;
                        //convert apex obj to json and json to xml
                        string jsonRequest =  JSON.serialize(getTransaction, true);
                        string xmlRequest = new XMLSerializer().jsonToXML(jsonRequest);

                        //Send request then convert XML response to json
                        HttpResponse getTransactionResponse = DPOManager.doCallout(DPObjects.getTransactionAPIUrl, DPObjects.post, xmlRequest);

                        if(getTransactionResponse != null)
                        {
                            system.debug('getTransactionResponse ==> '+getTransactionResponse.getBody());
                            string body = getTransactionResponse.getBody();  //'<API3G><Code>000</Code><Explanation>ResultsFound</Explanation><Transactions><Transaction><TransactionBookRef>ALCL:B18A9982</TransactionBookRef><TransactionToken>59744796-D317-49CD-BBE9-0FCE82B2F8FA</TransactionToken><TransactionCreatedDate>2022-05-3017:02:57</TransactionCreatedDate><TransactionAmount>25,000.00</TransactionAmount><TransactionCurrency>RWF</TransactionCurrency><TransactionFinalAmount>25,000.00</TransactionFinalAmount><TransactionFinalCurrency>RWF</TransactionFinalCurrency><TransactionCardLastFour>1111</TransactionCardLastFour><TransactionCardFirstSix>41111111</TransactionCardFirstSix><TransactionPartPayment>0</TransactionPartPayment><TransactionCityId>0</TransactionCityId><TransactionPhone>0503725378</TransactionPhone><TransactionPhonePrefix>250</TransactionPhonePrefix><TransactionRef>R4962742</TransactionRef><TransactionStatus>Paid</TransactionStatus><TransactionPaymentDate>2022-05-3017:03:34</TransactionPaymentDate><TransactionCardType>Visa</TransactionCardType><TransactionUserName>System</TransactionUserName><TransactionApprovalNumber>4444444403</TransactionApprovalNumber><TransactionServiceDescription><ServiceDescription>Pay My Bills Start (50 Mbps) 1 month</ServiceDescription></TransactionServiceDescription><TransactionCustomerPhone>2500503725378</TransactionCustomerPhone><TransactionCustomerEmail>nathanc@dpogroup.com</TransactionCustomerEmail><TransactionCustomerName>nathanchemla</TransactionCustomerName><TransactionFraudAlert>004</TransactionFraudAlert><TransactionFraudExplanation>HighRisk(Merchantchecked)</TransactionFraudExplanation><TransactionExpiryDate>2022-05-3014:17:57</TransactionExpiryDate><TransactionAdditionalFields></TransactionAdditionalFields><TransactionAdditionalAirlineFields></TransactionAdditionalAirlineFields><TransactionAuthCode></TransactionAuthCode><TransactionCompanyAccRef></TransactionCompanyAccRef><MetaData></MetaData><Additional><BlockPayment/></Additional><RedirectUrl>http://nathan-shop.dev.directpay.online/paymybills/gvarwanda?billAction=done&amp;order=1653919377</RedirectUrl><BackUrl>http://nathan-shop.dev.directpay.online//paymybills/gvarwanda?billAction=cancel&amp;order=1653919377</BackUrl><DeclinedUrl></DeclinedUrl></Transaction></Transactions></API3G>';
                            string xmlResponse = body.replaceAll('<Transaction>', '<Transaction_toReplace>');
                            xmlResponse = xmlResponse.replaceAll('</Transaction>', '</Transaction_toReplace>');
                            string jsonResponse =  new XMLSerializer().XMLToJSON(xmlResponse);
                            system.debug('jsonResponse ==> '+jsonResponse);
                            // deserialize the request
                            DPObjects.transactionByRefResponse transactionResponse = (DPObjects.transactionByRefResponse) JSON.deserialize(jsonResponse, DPObjects.transactionByRefResponse.class);
                            
                            if(transactionResponse.API3G.Code == '000') {
                                if(transactionResponse.API3G.Transactions.Transaction_toReplace.TransactionStatus == 'Paid')
                                {
                                    // get renew info,
                                    // string format --> Pay My Bills PREMIUM (200 Mbps) 1 month
                                    string renewInfo = transactionResponse.API3G.Transactions.Transaction_toReplace.TransactionServiceDescription == null?null : transactionResponse.API3G.Transactions.Transaction_toReplace.TransactionServiceDescription.ServiceDescription;
                                    renewInfo = renewInfo.toUpperCase();
                                    System.debug('renewInfo >>> '+renewInfo);

                                    if(renewInfo.contains('PAY MY BILLS ')) {
                                        //remove pay my bills --> PREMIUM (200 MBPS) 1 MONTH
                                        renewInfo = renewInfo.substringAfter('BILLS ');

                                        productName = renewInfo.substringBefore(' (');

                                        // prepaid = 1 month
                                        string prepaid = renewInfo.substringAfter(') ');
                                        prepaidPeriod = integer.valueOf(prepaid.substringBefore(' '));

                                        string renewSub;               
                                        string renewResponse;
                                        // for simple renew product name should be the same of the existing Prod
                                        if(listSub.size() > 0?listSub[0].Zuora__RatePlanName__c.toUpperCase() == productName : listPayment[0].AT_Renew_Type__c == System.Label.LWC_Simple_Renew_Type)
                                        {
                                            renewResponse = 
                                                SubscriptionRenewalActions.renewSubscription(listPayment.size() > 0?listPayment[0].AT_Subscription__c : listSub[0].Zuora__Subscription__c, prepaidPeriod,
                                                System.Label.ModePaiement_MobileMoney, transactionResponse.API3G.Transactions.Transaction_toReplace.TransactionToken, 'DPO', null, null, null, null, null, null, null, null);
                                        }// case to upgrade
                                        else if(productName == 'PREMIUM' && (listSub.size() > 0?listSub[0].Zuora__RatePlanName__c == system.label.Start_BaseProduct : listPayment[0].AT_Renew_Type__c == System.Label.LWC_Renew_With_Upgrade_Type))
                                        {
                                            renewResponse = 
                                                SubscriptionRenewalActions.upgradeSubscriptionProduct(listPayment.size() > 0?listPayment[0].AT_Subscription__c : listSub[0].Zuora__Subscription__c, prepaidPeriod, 
                                                false, true, false, System.Label.ModePaiement_MobileMoney, transactionResponse.API3G.Transactions.Transaction_toReplace.TransactionToken, 'DPO', null, null, null, null, null, null, null, null);
                                        }// case of downgrade
                                        else if(productName == 'START')
                                        {
                                            renewResponse = 
                                                SubscriptionRenewalActions.downgradeSubscriptionProduct(listSub.size() > 0?listSub[0].Zuora__Subscription__c : listPayment[0].AT_Subscription__c, null, 
                                                prepaidPeriod, true, System.Label.ModePaiement_MobileMoney, transactionResponse.API3G.Transactions.Transaction_toReplace.TransactionToken, 'DPO', null, null, null, null, null, null, null, null);
                                        }

                                        system.debug('renewResponse >><< '+renewResponse);
                                        if(renewResponse != null)
                                        {
                                            string responseAdjustment = renewResponse.replaceAll('number', 'number_toReplace');
                                            ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                                            
                                            if(paymentResponse.success) {
                                                response.Success = true;
                                                response.Message = System.label.Successful_Response;
                                                results = JSON.serialize(response, true);

                                                if(listPayment.size() > 0 && listPayment != null) {
                                                    listPayment[0].AT_Status__c = System.label.Treated_Value;
                                                    update listPayment[0];
                                                }
                                            }
                                            else
                                            {
                                                string subId = listPayment.size() > 0?listPayment[0].AT_Subscription__c : listSub[0].Zuora__Subscription__c;
                                                list<Suivi_de_Souscription__c> listSuivi = [SELECT Id FROM Suivi_de_Souscription__c
                                                                                            WHERE createdDate = :date.today() AND SV_Code_Action__c IN ('ACT003', 'ACT004')
                                                                                            AND SV_Id_Souscription__c = :subId];
                                                if(listSuivi.size() > 0)
                                                {
                                                    response.Success = true;
                                                    response.Message = System.label.Successful_Response;
                                                    results = JSON.serialize(response, true);
                                                }
                                                else{
                                                    listErrors.add(paymentResponse.reasons[0].message);
                                                    response.Erreurs = listErrors;
                                                    response.Success = false;
                                                    results = JSON.serialize(response, true);
                                                }
                                            }
                                        }
                                        else{
                                            response.Success = false;
                                            response.Message = System.label.DPO_ErrorMessage_2;
                                            results = JSON.serialize(response, true);
                                        }
                                    }
                                    else{
                                        response.Success = false;
                                        response.Message = System.label.DPO_ErrorMessage_1;
                                        results = JSON.serialize(response, true);
                                    }
                                }
                                else{
                                    response.Success = false;
                                    response.Message = System.label.Successful_Response; //transaction not paid
                                    results = JSON.serialize(response, true);
                                }
                            } 
                            else{
                                response.Success = false;
                                response.Message = transactionResponse.API3G.Explanation;
                                results = JSON.serialize(response, true);
                            }
                        }
                    } 
                    else {
                        response.Success = false;
                        response.Message = System.label.Subscription_Not_Found;
                        results = JSON.serialize(response, true);
                    }
                    system.debug(results);

                    return results;
                }
            }
            catch(Exception e) {
                system.debug('catch error '+e.getMessage() + ' ' + e.getLineNumber());
                response.Erreurs = new list<string> {e.getMessage() + ' ' + e.getLineNumber()};
                response.Success = false;
                results = JSON.serialize(response, true);

                return results;
            }
        }
        else{
            listErrors.add('Null request');
            response.Erreurs = listErrors;
            response.Success = false;
            results = JSON.serialize(response, true);

            return results;
        }
    }
}