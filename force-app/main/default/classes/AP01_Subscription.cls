public with sharing class AP01_Subscription {
    /**
     * Method utilisee por obtenir la date de fin de la souscription
     * @param recordId
     */
    @AuraEnabled(cacheable = true)
    public static Zuora__Subscription__c getCurrentSubFields(Id recordId){

        Zuora__Subscription__c sub = [SELECT id, ExpectedRenewalDate__c, SUB_T_YS_isActive__c, Zuora__Status__c, CurrencyIsoCode,SUB_Produit_de_Base_courant__c,
                                      SUB_T_Produit_De_Base__c, SUB_T_YS_EndDate__c, SUB_T_YS_StartDate__c, SUB_T_YS_EndDate2__c, SUB_T_YS_StartDate2__c
                                      FROM Zuora__Subscription__c
                                      WHERE id =: recordId];

        return sub;
    }

    /**
     * Method utilisee por Creer une souscirpion et paiement dans Zuora pour l'activation Youscribe
     * @param subId current subscription
     * @param activationDate Date de debut de l'option YS
     * @param finalDate Date de fin de l'option
     * @param totalAmount montant a paye
     * @param paymentMode methode de paiement
     * @param CDFPayment paiement en CDF pour le pays RDC
     * @param dollarPayment paiement en $ pour le pays RDC    
     * @param conversionRate Taux de conversion du CDF --> & pour le pays RDC
     * @param transactionId
     * @param operator
     * @param aggregator
     * @param CDFRefund montant a retourne en CDF pour le pays RDC
     * @param dollarRefund montant a retourne en $ pour le pays RDC
     * @param duree la duree de l'activation de l'option YS
     * @param chargeOvrd partie charge override dans la creation de l'order dans zuora est requis ou non ? (Selon si c'est un ajous de mois complet ou jusqu'une date precis)
     * @param previewOnly si c'est un request du preview ou creation
     */
    @AuraEnabled
    public static String createYSPaymentAndOrder(Id subId, String activationDate, String finalDate, String totalAmount, String paymentMode,
                                                 String CDFPayment, String dollarPayment, String conversionRate, String transactionId,
                                                 String operator, String aggregator, String CDFRefund, String dollarRefund, String duree,
                                                 boolean chargeOvrd, boolean previewOnly){

        set<Log__c> setLogs = new set<Log__c>();
        list<Log__c> listOfallLogs = new list<Log__c>();

        // removeDate is the real final date (to avoid confusion when 1 month is substract from the finalDate)
        String removeDate = finalDate; 
        Date dateDebut = Date.valueOf(activationDate);
        Date dateFin = Date.valueOf(finalDate);

        // get all info
        User currentUser = [SELECT Id, Name, USR_DistributeurID__c
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1];

        Zuora__Subscription__c sub = [ SELECT Id, Name, Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                       CurrencyIsoCode, Zuora__Account__c, Zuora__SubscriptionNumber__c, Zuora__CustomerAccount__c,
                                       Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, SUB_T_YS_isActive__c, SUB_T_YS_EndDate__c,
                                       SUB_T_YS_StartDate__c, SUB_T_YS_StartDate2__c, SUB_T_YS_EndDate2__c, ExpectedRenewalDate__c
                                       FROM Zuora__Subscription__c
                                       WHERE Id = :subId ];
        // get the box of the current subscription (exemple: Canalbox-Togo)
        list<Zuora__SubscriptionProductCharge__c> subProd = [SELECT Zuora__Product__r.Name, Zuora__Subscription__c
                                                       FROM Zuora__SubscriptionProductCharge__c
                                                       WHERE Zuora__Subscription__c = :subId LIMIT 1];

        String likeSubProdCountry = subProd[0].Zuora__Product__r.Name;
        system.debug('%%% '+likeSubProdCountry);

        list<zqu__productrateplancharge__c> productRP = [SELECT Id, zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c, zqu__ProductRatePlan__r.zqu__ZProduct__r.Name
                                                         FROM zqu__productrateplancharge__c
                                                         WHERE Name = 'YouScribe' AND
                                                         zqu__ProductRatePlan__r.zqu__ZProduct__r.Name like :likeSubProdCountry AND
                                                             (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                             (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                         zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                                         LIMIT 1];
        system.debug('pp '+productRP);

        // if prePaidPeriod is a whole number it's an api with chargeOverrides Zuora object
        integer prePaidPeriod;
        if(chargeOvrd) {
            prePaidPeriod = integer.valueOf(duree);
        } else  {
            prePaidPeriod = 0;
        }

        if(previewOnly) {
            return createYSPreviewSubscription(sub, activationDate, finalDate, removeDate, productRP[0], prePaidPeriod, chargeOvrd);
        } else  {

            ZuoraObjects.ZuoraOrder zYSOrder = ZuoraMapper.fillCreateYSOrdrer(sub, activationDate, finalDate, removeDate, productRP[0], prePaidPeriod, chargeOvrd);

            // send request to create order and get Order response
            HttpResponse response = ZuoraManager.createOrder(zYSOrder, ZuoraObjects.OrderType.ADD_PRODUCT );
            ZuoraResponseObjects.ZuoraCreateOrderResponse ySOrderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

            // create logs
            setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zYSOrder, true), sub.Zuora__Account__c, sub.id, sub.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, response.getBody(),
                        ySOrderResponse.success, ySOrderResponse.reasons == null?null : ySOrderResponse.reasons[0].message, ZuoraObjects.post, false));
            listOfallLogs.addAll(setLogs);

            // if success create payment
            if(ySOrderResponse.success) {

                set<Log__c> setPaymentLog = new set<Log__c>();

                double amount = double.valueOf(totalAmount);
                String invoiceId = null; /*= ySOrderResponse.invoiceIds[0];*/
                String invoiceNumber = ySOrderResponse.invoiceNumbers[0];
                String orderNumber = ySOrderResponse.orderNumber;

                if(invoiceId == null) {

                    HttpResponse accountResponse = ZuoraManager.getAccountSummary(sub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                    ZuoraResponseObjects.ZuoraGetAccount getAccountInfoResponse = new ZuoraResponseObjects.ZuoraGetAccount();
                    getAccountInfoResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                    if(getAccountInfoResponse.success) {
                        // get invoice id of the request invoice number
                        for(ZuoraResponseObjects.ZuoraInvoices zInvoice : getAccountInfoResponse.invoices) {
                            if(invoiceNumber != null && zInvoice.InvoiceNumber == invoiceNumber) {
                                invoiceId = zInvoice.id;
                                break;
                            }
                        }
                    }
                }

                // create payment in zuora jackie To Check
                ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreateRenewPayment(sub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                                                           prePaidPeriod, amount, transactionId, operator, orderNumber, invoiceId,
                                                                                           sub.CurrencyIsoCode, paymentMode, CDFPayment, dollarPayment, conversionRate, dollarRefund,
                                                                                           CDFRefund, false, sub.Zuora__Account__c);

                // get payment response
                HttpResponse responsePayment = ZuoraManager.createPayment(paymentInfo);
                string responseAdjustment = responsePayment.getBody().replaceAll('number', 'number_toReplace');
                ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);

                // create payment logs
                setPaymentLog.add(ZuoraSubscriptionActions.createZuoraLog(json.serialize(paymentInfo, true), sub.Zuora__Account__c, sub.Id, null, ZuoraObjects.paymentAPIUrl,
                                      responsePayment.getBody(), paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message,
                                      ZuoraObjects.post, true));

                paymentResponse.zuoraLogs = setPaymentLog;
                listOfallLogs.addAll(setPaymentLog);

                if(paymentResponse.success) {

                    updateSubscriptionAfterActivation(sub, dateFin, dateDebut);
                    if(listOfallLogs != null && listOfallLogs.size() > 0){
                        insert listOfallLogs;
                    }

                    return responsePayment.getBody();
                } else  {

                    if(listOfallLogs != null && listOfallLogs.size() > 0){
                        insert listOfallLogs;
                    }

                    return responsePayment.getBody();
                }
            } else  {

                if(listOfallLogs != null && listOfallLogs.size() > 0){
                    insert listOfallLogs;
                }

                system.debug('create order error ' + response.getBody());
                insert AP01_ErreurInterface.insertError('Erreur API', null, null, ySOrderResponse.reasons[0].message, sub.Id, ZuoraObjects.ordersAPIUrl);

                return response.getBody();
            }
        }
    }

    @AuraEnabled
    public static String createYSPreviewSubscription(Zuora__Subscription__c sub, String activationDate, String finalDate, String removeDate, zqu__productrateplancharge__c productRP, integer prePaidPeriod, boolean chargeOvrd){

        Set<Log__c> setLog = new set<Log__c>();
        list<Log__c> listOfLog = new list<Log__c>();

        ZuoraObjects.ZuoraOrder previewYSZOrder = ZuoraMapper.fillYSPreviewSubscription(sub, activationDate, finalDate, removeDate, productRP, prePaidPeriod, chargeOvrd);

        try {

            // send preview request and get response
            system.debug('preview order object ' + JSON.serialize(previewYSZOrder));
            HttpResponse response = ZuoraManager.previewOrder(previewYSZOrder);
            system.debug('preview order response ' + response);
            ZuoraResponseObjects.ZuoraPreviewResponse orderResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraPreviewResponse.class);

            setLog.add(ZuoraSubscriptionActions.createZuoraLog(json.serialize(previewYSZOrder, true), null, null, null, ZuoraObjects.subscriptionAPIUrl, response.getBody(),
                                                               orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));
            orderResponse.zuoraLogs = setLog;

            if(orderResponse.success) {

                double amount = orderResponse.previewResult.invoices.size() == 0?0 : orderResponse.previewResult.invoices[0].amount;
                list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                                   FROM CurrencyType
                                                   WHERE IsoCode = 'USD'];

                //add charge name to the previewresult
                map<string, ZuoraResponseObjects.ZuoraInvoiceItems> chargeNameInfo = new map<string, ZuoraResponseObjects.ZuoraInvoiceItems>();
                if(orderResponse.previewResult.invoices.size() > 0 && orderResponse.previewResult.invoices != null) {
                    for(ZuoraResponseObjects.ZuoraInvoiceItems zInvoice : orderResponse.previewResult.invoices[0].invoiceItems) {
                        chargeNameInfo.put(zInvoice.productRatePlanChargeId, zInvoice);
                    }
                }

                // get charge name of each product from product charge and add it to the preview result
                list<ZuoraResponseObjects.ZuoraInvoiceItems> listZInvoice = new list<ZuoraResponseObjects.ZuoraInvoiceItems>();
                for(AggregateResult subProduct : [SELECT  count(id), Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c
                                                FROM zuora__subscriptionProductCharge__c
                                                WHERE Zuora__RatePlanName__c != null AND Zuora__ProductRatePlanChargeId__c IN : chargeNameInfo.keyset() GROUP BY Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c]) 
                {
                    String productId = (String) subProduct.get('Zuora__ProductRatePlanChargeId__c');
                    String ratePlanName = (String) subProduct.get('Zuora__RatePlanName__c');
                    chargeNameInfo.get(productId).ratePlanName = ratePlanName;
                }
                listZInvoice.addAll(chargeNameInfo.Values());

                if(orderResponse.previewResult.invoices.size() > 0) {
                    orderResponse.previewResult.invoices[0].invoiceItems = listZInvoice;
                    orderResponse.previewResult.invoices[0].amount = amount;
                }

                // add the conversion rate based on the value in salesforce
                orderResponse.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);

                if(setLog != null && setLog.size() > 0){
                    listOfLog.addAll(setLog);
                    insert listOfLog;
                }

                return JSON.serialize(orderResponse);
            } else  {

                if(setLog != null && setLog.size() > 0){
                    listOfLog.addAll(setLog);
                    insert listOfLog;
                }

                insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, null, ZuoraObjects.previewOrdersAPIUrl);

                return response.getBody();
            }

        } catch(Exception e) {
            System.debug(e.getMessage() + ' ' + e.getLineNumber());
            throw new CustomException(e.getMessage());
        }

    }

    @AuraEnabled
    public static void updateSubscriptionAfterActivation(Zuora__Subscription__c currentSub, Date dateFin, Date dateDebut){

        Date today = Date.today();
        // check if the first field of date is valid
        if(currentSub.SUB_T_YS_StartDate__c != null && currentSub.SUB_T_YS_StartDate__c > today) {
            currentSub.SUB_T_YS_EndDate2__c = dateFin;
            currentSub.SUB_T_YS_StartDate2__c = dateDebut;
        } else  {
            currentSub.SUB_T_YS_EndDate__c = dateFin;
            currentSub.SUB_T_YS_StartDate__c = dateDebut;
        }

        try {
            update currentSub;
        } catch(Exception e) {
            system.debug('update Subscription After Activation error' + e);
        }
    }

    public class CustomException extends Exception {}
}