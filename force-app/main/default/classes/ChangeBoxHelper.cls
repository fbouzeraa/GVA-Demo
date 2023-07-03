public with sharing class ChangeBoxHelper {

    @AuraEnabled
    public static list<zqu__productRatePlan__c> getProducts(){

        Id pbId = ZuoraSubscriptionActions.getUserPricebookID(Id.valueOf(UserInfo.getUserId()));

        Id productId = [SELECT Product2Id
                        FROM PriceBookEntry
                        WHERE Pricebook2Id = : pbId AND isActive = true LIMIT 1].Product2Id;

        list<zqu__productRatePlan__c> productRatePlan = [SELECT Id, type__c, category__c, Name, zqu__Product__r.Name, zqu__ZuoraId__c,
                                                         zqu__EffectiveEndDate__c, SellingEffectiveEndDate__c, zqu__Deleted__c,
                                                         zqu__Product__c, SellingEffectiveStartDate__c, zqu__EffectiveStartDate__c
                                                         FROM zqu__productRatePlan__c
                                                         WHERE type__c = 'AddOn' AND category__c = 'Installation Service'
                                                         AND (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) )
                                                         AND (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY))
                                                         AND zqu__Deleted__c = FALSE AND zqu__Product__c = : productId
                                                         ORDER BY Category__c DESC];

        return productRatePlan;
    }

    @AuraEnabled
    public static list<String> getSubscriptionInfo(String subScriptionId, String zuoraProductId) {

        double currentAmount;
        String previewResult;
        list<String> listOfProductId = new list<String> {zuoraProductId};
        list<String> listOfResponse = new list<String>();

        Zuora__Subscription__c originalSub = [SELECT Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Quote__r.Account.CurrencyIsoCode, Zuora__Account__r.CurrencyIsoCode,
                                              Zuora__SubscriptionNumber__c, Quote__c, Quote__r.CreatedBy.Country, Quote__r.QUO_Mode_de_paiement__c, Zuora__Account__r.BillingCountry,
                                              Zuora__Status__c, Quote__r.Account.ACC_Entreprise__c, Quote__r.Account.billingCountry, Quote__r.AccountId
                                              FROM Zuora__Subscription__c
                                              WHERE Id = :subScriptionId ];

        listOfResponse.add(originalSub.Zuora__Account__r.CurrencyIsoCode);

        previewResult = ZuoraSubscriptionActions.createPreviewSubscription(1, originalSub.Zuora__Account__r.BillingCountry, originalSub.Zuora__Account__r.CurrencyIsoCode, listOfProductId, null, null, null, null);
        listOfResponse.add(previewResult);

        return listOfResponse;
    }

    @AuraEnabled
    public static string createTechnicalSubscription(id subId, String zuoraProductId, String paymentMethode, String transactionNumber, String operator, String aggregator, Integer paymentDollar, Integer paymentRDC, Double conversionRate, Integer returnRDC, Integer returnDollar) {
        list<Log__c> listLogs = new list<Log__c>();
        Set<Log__c> setLogs = new set<Log__c>();
        list<String> listOfProductId = new list<String> {zuoraProductId};

        // get info of the current user
        User currentUser = [SELECT Id, CountryCode, USR_DistributeurID__c
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1 ];

        // get info from the main sub
        Zuora__Subscription__c originalSub = [SELECT Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Quote__r.Account.CurrencyIsoCode, Zuora__Account__r.BillingCountry,
                                              Zuora__SubscriptionNumber__c, Quote__c, Quote__r.CreatedBy.Country, Quote__r.QUO_Mode_de_paiement__c, Zuora__Account__r.CurrencyIsoCode,
                                              Zuora__Status__c, Quote__r.Account.ACC_Entreprise__c, Quote__r.Account.billingCountry, Quote__r.AccountId, owner.Name, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c
                                              FROM Zuora__Subscription__c
                                              WHERE Id = :subId ];
        string techSubName = originalSub.Zuora__SubscriptionNumber__c.replace('A', 'T') + '%';

        // get all technical Sub related to the original one
        list<Zuora__Subscription__c> listTechSub = [SELECT Id, Zuora__SubscriptionNumber__c, Zuora__Status__c
                                                    FROM Zuora__Subscription__c
                                                    WHERE Zuora__SubscriptionNumber__c like :techSubName
                                                    ORDER BY Zuora__SubscriptionNumber__c DESC];

        //check if the status of the main sub is pending
        if(originalSub.Zuora__Status__c == 'Active' || originalSub.Zuora__Status__c == 'Suspended') {

            string newTechSubName;
            if(listTechSub != null && listTechSub.size() > 0) {
                string lastTechSubName = listTechSub[0].Zuora__SubscriptionNumber__c;
                string techSubNumber = lastTechSubName.subString(lastTechSubName.lastIndexOf('-') + 1, lastTechSubName.length());
                integer numberOfTechSub = integer.valueOf(techSubNumber) + 1;
                newTechSubName = lastTechSubName.substring(0, lastTechSubName.lastIndexOf('-') + 1) + ZuoraSubscriptionActions.stringFormatting(numberOfTechSub);
            } else {
                newTechSubName = techSubName.substring(0, techSubName.length() - 1) + '-001';
            }

            //get Tax rate Plan
            string userCountry = '%' + originalSub.Zuora__Account__r.BillingCountry;
            string previewResult;
            double currentAmount;

            // get payment amount from the preview sub
            previewResult = ZuoraSubscriptionActions.createPreviewSubscription(1, originalSub.Zuora__Account__r.BillingCountry, originalSub.Zuora__Account__r.CurrencyIsoCode, listOfProductId, null, null, null, null);
            ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

            if(preview.zuoraLogs != null && preview.zuoraLogs.size() > 0)
                setLogs.addAll(preview.zuoraLogs);
            if(preview.success) {
                currentAmount = preview.previewResult.invoices[0].amount;
            } else {
                currentAmount = 0;
            }
            boolean isRDC = ZuoraSubscriptionActions.checkRDCUser();

            // ensure that listOfProductId isn't empty
            if(listOfProductId != null && listOfProductId.size() > 0) {

                double refundAmount = 0;
                if(returnRDC != null && !string.isBlank(string.valueOf(returnRDC)) &&
                   returnDollar != null && !string.isBlank(string.valueOf(returnDollar))) {
                    refundAmount = returnDollar + (returnRDC / conversionRate);
                }

                //create Sub
                ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillCreateTechnicalSubscription(originalSub, newTechSubName, currentAmount, isRDC, listOfProductId);
                HttpResponse response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.NEW_SUBSCRIPTION);

                ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                    response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), originalSub.Zuora__Account__c, null, orderResponse.subscriptionNumbers[0], ZuoraObjects.ordersAPIUrl, response.getBody(),
                                                                    orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                if(orderResponse.success) {
                    string InvoiceNumber = orderResponse.invoiceNumbers[0];
                    ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreatePayment(subId, originalSub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, 1,
                                                                                          orderResponse.orderNumber, currentAmount + refundAmount, originalSub.Zuora__Account__r.CurrencyIsoCode, paymentMethode, true,
                                                                                          string.valueOf(paymentRDC), paymentDollar == null?null : string.valueOf(paymentDollar + refundAmount),
                                                                                          conversionRate == null?null : string.valueOf(conversionRate), transactionNumber, operator, aggregator,
                                                                                          originalSub.owner.Name, currentUser.USR_DistributeurID__c);

                    try {
                        HttpResponse newPaymentResponse = ZuoraManager.createPayment(paymentInfo);
                        string responseAdjustment = newPaymentResponse.getBody().replaceAll('number', 'number_toReplace');
                        ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                            responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                        setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(paymentInfo, true), originalSub.Zuora__Account__c, null, orderResponse.subscriptionNumbers[0], ZuoraObjects.paymentAPIUrl, newPaymentResponse.getBody(),
                                                                            paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true));

                        if(paymentResponse.zuoraLogs != null && paymentResponse.zuoraLogs.size() > 0)
                            setLogs.addAll(paymentResponse.zuoraLogs);
                        if(paymentResponse.success) {

                            string InvoiceId;
                            // get invoice Id from an account
                            HttpResponse accountResponse = ZuoraManager.getAccountSummary(originalSub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                            ZuoraResponseObjects.ZuoraGetAccount getAccountInfoResponse = new ZuoraResponseObjects.ZuoraGetAccount();
                            getAccountInfoResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(
                                accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                            if(getAccountInfoResponse.success) {

                                // get invoice id of the request invoice number
                                for(ZuoraResponseObjects.ZuoraInvoices zInvoice : getAccountInfoResponse.invoices) {

                                    if(zInvoice.InvoiceNumber == InvoiceNumber) {
                                        invoiceId = zInvoice.id;
                                        break;
                                    }
                                }
                            }
                            string invoiceCustomFields = ZuoraSubscriptionActions.updateBillCustomFields(true, invoiceId, '1', null, string.valueOf(conversionRate));
                            ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse = new ZuoraResponseObjects.ZuoraBill();

                            invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(invoiceCustomFields, ZuoraResponseObjects.ZuoraBill.class);
                            if(invoiceUpdateResponse.zuoraLogs != null && invoiceUpdateResponse.zuoraLogs.size() > 0)
                                setLogs.addAll(invoiceUpdateResponse.zuoraLogs);
                            invoiceUpdateResponse.zuoraLogs = setLogs;
                            if(invoiceUpdateResponse.success) {

                                string applyPayment = ZuoraSubscriptionActions.applyPaymentToBill(currentAmount, paymentResponse.id, invoiceId);
                                ZuoraResponseObjects.ZuoraPayment applyPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
                                paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                                    applyPayment, ZuoraResponseObjects.ZuoraPayment.class);

                                if(paymentResponse.zuoraLogs != null && paymentResponse.zuoraLogs.size() > 0)
                                    setLogs.addALL(paymentResponse.zuoraLogs);

                                if(setLogs.size() > 0 && setLogs != null) {
                                    listLogs.addAll(setLogs);

                                    insert listLogs;
                                }

                                return json.serialize(paymentResponse, true);

                            } else {
                                if(setLogs.size() > 0 && setLogs != null) {
                                    listLogs.addAll(setLogs);
                                    insert listLogs;
                                }
                                insert AP01_ErreurInterface.insertError('Erreur API', null, null, invoiceUpdateResponse.reasons[0].message, listLogs[listLogs.size()].id, ZuoraObjects.invoiceAPIUrl + invoiceId);

                                return json.serialize(paymentResponse, true);
                            }
                        } else {
                            if(setLogs.size() > 0 && setLogs != null) {
                                listLogs.addAll(setLogs);
                                insert listLogs;
                            }
                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, paymentResponse.reasons[0].message, listLogs[listLogs.size()].id, ZuoraObjects.paymentAPIUrl);

                            return response.getBody();
                        }
                    } catch(Exception e) {

                        throw new AuraHandledException(e.getMessage());
                    }
                } else {
                    if(setLogs.size() > 0 && setLogs != null) {
                        listLogs.addAll(setLogs);
                        insert listLogs;
                    }
                    insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, listLogs[0].id, ZuoraObjects.ordersAPIUrl);

                    return response.getBody();
                }
            } else {
                return System.label.Empty_QLI_Message;
            }
        } else {
            return System.label.Active_Subscription;
        }
    }
}