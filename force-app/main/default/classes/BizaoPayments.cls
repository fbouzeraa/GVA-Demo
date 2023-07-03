public without sharing class BizaoPayments {

    /**
     * Check if current user is francophone or not
     */
    @AuraEnabled
    public static boolean isFrancophone(){
        // les pays francophone sont Burkina, Benin, Cote d'ivoire,Gabon,Congo,...
        // pour le moment on a BF seulement
        user currentUser = [SELECT CountryCode FROM User WHERE id = :UserInfo.getUserId()];
        list<string> listFrancoCountries = new list<String> {'BF', 'CI', 'CD'};//, 'IV'};

        return listFrancoCountries.contains(currentUser.CountryCode);
    }
    /**
     * Méthode permettant d'ouvrir la page de bizao Mobile Money
     * @param amount montant à payer
     * @param operator mobile money operator
     * @param order orderId
     */
    @AuraEnabled
    public static string mobileMoneyPayment(integer amount, string operator, string order, id recordId){

        Zuora__Subscription__c sub = [SELECT Zuora__Account__r.BillingCountryCode, Zuora__Account__r.currencyISOCode FROM Zuora__Subscription__c WHERE id = :recordId];
        BIZAObjects.MobileMoneyRequest request = new BIZAObjects.MobileMoneyRequest();
        request.amount = amount;
        request.order_id = order;
        request.return_url = System.label.BIZAO_MOBILE_MONEY_PAYMENT_RETURN_URL;
        request.cancel_url = System.label.BIZAO_MOBILE_MONEY_PAYMENT_CANCEL_URL;
        request.state = 'Processing';
        request.user_msisdn = '243895840352';

        request.reference = 'GVA_' + sub.Zuora__Account__r.BillingCountryCode.toUppercase();
        if(sub.Zuora__Account__r.BillingCountryCode == 'cd'){
            request.reference = 'GVA_RDC';
        }
        //request.reference = 'CANALBOX';
        //request.reference = 'GVA_BF';
        request.currency_Reserved = sub.Zuora__Account__r.currencyISOCode;//'XOF';
        HttpResponse response = BizaoManager.mobileMoneyCallout(BIZAObjects.MobileMoneyAPIUrl, JSON.serialize(request, true),
                                                                BIZAObjects.post, operator, sub.Zuora__Account__r.BillingCountryCode.toLowercase());
        System.debug('Response of payment '+ response);

        return response.getBody();
    }
    /**
     * Méthode permettant d'ouvrir la page de bizao credit card
     * @param amount montant à payer
     * @param order orderId
     */
    @AuraEnabled
    public static string bankPayment(integer amount, string order, id recordId){
        Zuora__Subscription__c sub = [SELECT Zuora__Account__r.BillingCountryCode, Zuora__Account__r.currencyISOCode FROM Zuora__Subscription__c WHERE id = :recordId];
        BIZAObjects.MobileMoneyRequest request = new BIZAObjects.MobileMoneyRequest();
        request.amount = amount;
        request.order_id = order;
        request.return_url = System.label.BIZAO_BANK_PAYMENT_RETURN_URL;
        request.cancel_url = System.label.BIZAO_BANK_PAYMENT_CANCEL_URL;
        request.state = 'Processing';
        // if(sub.Zuora__Account__r.BillingCountryCode == 'BF') {
        //     request.reference = 'Canalbox_vmc';
        //     request.reference = 'GVA_' + sub.Zuora__Account__r.BillingCountryCode.toUppercase();
        // } else {
        //     request.reference = 'Canalbox_vmc'; // 'Canalbox_vmc2';
        // }
        //request.reference = 'GVA_BF';
        request.user_msisdn = '243895840352';

        request.reference = 'GVA_' + sub.Zuora__Account__r.BillingCountryCode.toUppercase();
        if(sub.Zuora__Account__r.BillingCountryCode == 'cd'){
            request.reference = 'GVA_RDC';
        }        
        request.currency_Reserved = sub.Zuora__Account__r.currencyISOCode;//'XOF';

        HttpResponse response = BizaoManager.debitCardCallout(BIZAObjects.DebitCardAPIURL, JSON.serialize(request, true),
                                                              BIZAObjects.post, sub.Zuora__Account__r.BillingCountryCode);

        return response.getBody();
    }
    /**
     * Méthode permettant de vérifier le statut du paiement Mobile Money
     * @param operator mobile money operator
     * @param orderId
     */
    @AuraEnabled
    public static string mobileMoneyStatus( string operator, string orderId, String subCountryCode){

        string url = BIZAObjects.MobileMoneyStatusAPIUrl + orderId;

        HttpResponse response = BizaoManager.mobileMoneyCallout(url, '', BIZAObjects.get, operator, subCountryCode.toLowercase());
        BIZAObjects.getPaymentStatus paymentResponse = (BIZAObjects.getPaymentStatus) JSON.deserialize(response.getBody(), BIZAObjects.getPaymentStatus.class);
        
        if(paymentResponse.requestError != null) {
            log__c log = new Log__c(LG_Body__c = null, LG_Subscription_Number__c = orderId.substring(0, orderId.indexOf('-')), LG_Success__c = false, LG_Error_Message__c = paymentResponse.requestError.serviceException.text,
                                    LG_Method_URL__c = BIZAObjects.MobileMoneyStatusAPIUrl + orderId, LG_Interface__c = 'BIZAO', LG_Method_Type__c = BIZAObjects.get,  LG_Response__c = response.getBody());
            insert log;
        }
        if(paymentResponse.status != 'Successful') {
            log__c log = new Log__c(LG_Body__c = null, LG_Subscription_Number__c = orderId.substring(0, orderId.indexOf('-')), LG_Response__c = response.getBody(),
                                    LG_Method_URL__c = BIZAObjects.MobileMoneyStatusAPIUrl + orderId, LG_Interface__c = 'BIZAO', LG_Method_Type__c = BIZAObjects.get);
            insert log;
        }
        system.debug('getStatusResponse '+response.getBody());

        return response.getBody();
    }
    /**
     * Méthode permettant de vérifier le statut du paiement bancaire
     * @param orderId
     */
    @AuraEnabled
    public static string bankPaymentStatus(string orderId, string recordId){
        Zuora__Subscription__c sub = [SELECT Zuora__Account__r.BillingCountryCode, Zuora__Account__r.currencyISOCode FROM Zuora__Subscription__c WHERE id = :recordId]; // WITH SECURITY_ENFORCED

        string url = BIZAObjects.DebitCardStatusAPIUrl + orderId;

        HttpResponse response = BizaoManager.debitCardCallout(url, '', BIZAObjects.get, sub.Zuora__Account__r.BillingCountryCode);
        BIZAObjects.getPaymentStatus paymentResponse = (BIZAObjects.getPaymentStatus) JSON.deserialize(response.getBody(), BIZAObjects.getPaymentStatus.class);

        if(paymentResponse.requestError != null) {
            log__c log = new Log__c(LG_Body__c = null, LG_Subscription_Number__c = orderId.substring(0, orderId.indexOf('-')), LG_Success__c = false, LG_Error_Message__c = paymentResponse.requestError.serviceException.text,
                                    LG_Method_URL__c = BIZAObjects.DebitCardStatusAPIUrl + orderId, LG_Interface__c = 'BIZAO', LG_Method_Type__c = BIZAObjects.get, LG_Response__c = response.getBody());
            insert log;
        }
        if(paymentResponse.status != 'Successful') {
            log__c log = new Log__c(LG_Body__c = null, LG_Subscription_Number__c = orderId.substring(0, orderId.indexOf('-')), LG_Response__c = response.getBody(),
                                    LG_Method_URL__c = BIZAObjects.DebitCardStatusAPIUrl + orderId, LG_Interface__c = 'BIZAO', LG_Method_Type__c = BIZAObjects.get);
            insert log;
        }
        system.debug('getStatusResponse '+response.getBody());

        return response.getBody();
    }

    @InvocableMethod(label = 'retry payment')
    public static Void retryPayment(list<id> listRenewDataId){

        if(listRenewDataId != null && listRenewDataId.size() > 0) {

            list<RenewSubscriptionData__c> renewData = [SELECT RSD_SubscriptionId__c, RS_Status__c, id, RSD_Payment_Method__c, RSD_Operator__c, RSD_OrderId__c,
                                                        RSD_LogBizaoRestApi__c, RSD_SubscriptionId__r.SUB_T_Account_Country__c
                                                        FROM RenewSubscriptionData__c
                                                        WHERE Id  =:listRenewDataId[0]];

            if(renewData != null && renewData.size() > 0) {
                // find if any suivi record is created for the current subscription
                list<Suivi_de_Souscription__c> listSuivi = [SELECT Id FROM Suivi_de_Souscription__c
                                                            WHERE createdDate = :date.today() AND SV_Code_Action__c IN ('ACT003', 'ACT004')
                                                            AND SV_Id_Souscription__c = :renewData[0].RSD_SubscriptionId__c];

                if(listSuivi == null || listSuivi.size() == 0) {

                    // If no Suivi record created for this subscription --> continue the retry action, first check the status of Bizao Payment
                    String paymentStatus;

                    try {
                        if(renewData[0].RSD_Payment_Method__c == System.Label.ModePaiement_MobileMoney) {
                            paymentStatus = mobileMoneyStatus(renewData[0].RSD_Operator__c, renewData[0].RSD_OrderId__c, renewData[0].RSD_SubscriptionId__r.SUB_T_Account_Country__c);
                        }else if(renewData[0].RSD_Payment_Method__c == System.Label.ModePaiement_CreditCard){
                            paymentStatus = bankPaymentStatus(renewData[0].RSD_OrderId__c, renewData[0].RSD_SubscriptionId__c);
                        }  
                    } catch (Exception e) {
                        RenewSubscriptionData__c renewDataRecord = updateRenewDataRecord(renewData[0].Id, e.getMessage());
                        update renewDataRecord;
                    }

                    // Check the status of the payment if success continue the renew action
                    if(paymentStatus != null) {
                        BIZAObjects.getPaymentStatus paymentResponse = (BIZAObjects.getPaymentStatus) JSON.deserialize(paymentStatus, BIZAObjects.getPaymentStatus.class);

                        if(paymentResponse.status == 'Successful') {
                            retryThePayment(listRenewDataId[0]);
                        }else{                          
                            RenewSubscriptionData__c renewDataRecord = updateRenewDataRecord(renewData[0].Id, ' getStatus indicate a failed payment from bizao;');
                            renewDataRecord.RS_Status__c = 'ST001';
                            update renewDataRecord;
                        }
                    }else  {
                        system.debug('Status check null');
                    } 
                }else {
                    renewData[0].RS_Status__c = 'ST001';
                    update renewData[0];
                }
            }

        }
    }

    // call this method to retry the renew action if payment status in BIZAO is success / ST002 = Not treated 7 ST003 = To be treated
    @future(callout = true)
    public static void retryThePayment(id renewDataId){
        try {
            List<RenewSubscriptionData__c> listRenewSubscriptionData =  [SELECT Id, RSD_Amount__c, RSD_Operator__c,  RSD_SubscriptionId__c, RSD_NumberOfPeriods__c,
                                                                         RSD_Payment_Method__c, RSD_TransactionNumber__c, RSD_DollarPayment__c, RSD_CDFPayment__c,
                                                                         RSD_DollarRefund__c, RSD_CDFRefund__c, RSD_OrderId__c, RSD_SelectedRenewOffer__c,
                                                                         RSD_IsOrderOpen__c, RSD_LogBizaoRestApi__c
                                                                         FROM RenewSubscriptionData__c
                                                                         WHERE Id = :renewDataId AND (RS_Status__c = 'ST002' OR RS_Status__c = 'ST003')];

            if(listRenewSubscriptionData != null && listRenewSubscriptionData.size() > 0) {

                // check if it's a simple renew or with upgrade or downgrade
                string renewResponse;

                if(listRenewSubscriptionData[0].RSD_SelectedRenewOffer__c == System.Label.BizaoValue_REABO) {
                    renewResponse = SubscriptionRenewalActions.renewSubscription(
                        listRenewSubscriptionData[0].RSD_SubscriptionId__c, Integer.valueOf(listRenewSubscriptionData[0].RSD_NumberOfPeriods__c),
                        listRenewSubscriptionData[0].RSD_Payment_Method__c, listRenewSubscriptionData[0].RSD_TransactionNumber__c, 'Bizao',
                        Integer.valueOf(listRenewSubscriptionData[0].RSD_DollarPayment__c), Integer.valueOf(listRenewSubscriptionData[0].RSD_CDFPayment__c), Integer.valueOf(listRenewSubscriptionData[0].RSD_DollarRefund__c),
                        Integer.valueOf(listRenewSubscriptionData[0].RSD_CDFRefund__c), listRenewSubscriptionData[0].RSD_OrderId__c, null, null, null);
                } else if(listRenewSubscriptionData[0].RSD_SelectedRenewOffer__c == System.Label.BizaoValue_REABO_UPG) {
                    renewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(
                        listRenewSubscriptionData[0].RSD_SubscriptionId__c, Integer.valueOf(listRenewSubscriptionData[0].RSD_NumberOfPeriods__c), false, true, false,
                        listRenewSubscriptionData[0].RSD_Payment_Method__c, listRenewSubscriptionData[0].RSD_TransactionNumber__c, 'Bizao',
                        Integer.valueOf(listRenewSubscriptionData[0].RSD_DollarPayment__c), Integer.valueOf(listRenewSubscriptionData[0].RSD_CDFPayment__c), Integer.valueOf(listRenewSubscriptionData[0].RSD_DollarRefund__c),
                        Integer.valueOf(listRenewSubscriptionData[0].RSD_CDFRefund__c), listRenewSubscriptionData[0].RSD_OrderId__c, null, null, null);
                } else if(listRenewSubscriptionData[0].RSD_SelectedRenewOffer__c == System.Label.BizaoValue_REABO_DOWN){
                    renewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct( listRenewSubscriptionData[0].RSD_SubscriptionId__c, null, Integer.valueOf(listRenewSubscriptionData[0].RSD_NumberOfPeriods__c), false, listRenewSubscriptionData[0].RSD_Payment_Method__c, listRenewSubscriptionData[0].RSD_TransactionNumber__c, 'Bizao',  Integer.valueOf(listRenewSubscriptionData[0].RSD_DollarPayment__c), Integer.valueOf(listRenewSubscriptionData[0].RSD_CDFPayment__c), Integer.valueOf(listRenewSubscriptionData[0].RSD_DollarRefund__c),
                                                                                             Integer.valueOf(listRenewSubscriptionData[0].RSD_CDFRefund__c), listRenewSubscriptionData[0].RSD_OrderId__c, null, null, null);
                }

                RenewSubscriptionData__c renewData = new RenewSubscriptionData__c();
                // Check the response of the renew action
                if(renewResponse != null) {

                    string responseAdjustment = renewResponse.replaceAll('number', 'number_toReplace');
                    ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                    
                    if(paymentResponse.success) {
                        renewData = updateRenewDataRecord(listRenewSubscriptionData[0].Id, ' getStatus and Renew Subscription are successful;');
                        renewData.RS_Status__c = 'ST001';
                        renewData.RSD_IsOrderOpen__c = false;
                    }else{
                        renewData = updateRenewDataRecord(listRenewSubscriptionData[0].Id, ' after getStatus, Renew Subscription is NOT successful;');
                    }
                }else{
                    renewData = updateRenewDataRecord(listRenewSubscriptionData[0].Id, ' after getStatus, Renew Subscription response is null;');
                }
                update renewData;
            }
        } catch(Exception e) {
            system.debug(e.getMessage() + e.getLineNumber() );
            throw new CustomException(e.getMessage() +' '+ e.getLineNumber());
        }
    }

    public static RenewSubscriptionData__c updateRenewDataRecord(id recordId, String logMessage){

        RenewSubscriptionData__c renewData = [SELECT Id, RSD_Amount__c, RSD_SubscriptionId__c, RSD_Operator__c, RSD_OrderId__c, RSD_LogBizaoRestApi__c
                                                FROM RenewSubscriptionData__c
                                                WHERE Id = : recordId
                                                LIMIT 1];
        
        renewData.RSD_LogBizaoRestApi__c += '\n' + Datetime.now() + logMessage;

        return renewData;
    }

    public class CustomException extends Exception {}
}