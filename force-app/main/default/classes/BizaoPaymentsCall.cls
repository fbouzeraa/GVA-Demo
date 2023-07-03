/**
 * @author      Nicolas Brosse
 * @date         20-07-2022
 *
 * @description  Class to call the function from BizaoPayments while saving
 * or updating the data of the renew subcription in the the object RenewSubscriptionData__c
 */

public with sharing class BizaoPaymentsCall {

    /**
     * Méthode permettant de faire un simple renew preview
     */
    @AuraEnabled
    public static string callRenewSubPreview(Id subId, Integer nbPeriodes, Boolean withoutTax, String paymentMode,
                                             Boolean fromUI, String operator, String transactionNumber,
                                             Double dollarPayment, Integer CDFPayment, Integer dollarRefund,
                                             Integer CDFRefund, String selectedRenewOffer, String PRPId){

        String renewSubPreviewResponseJson;
        try {
            renewSubPreviewResponseJson = SubscriptionRenewalActions.renewSubPreview(subId, nbPeriodes, withoutTax, paymentMode, fromUI, PRPId, null, null, null);
        } catch (Exception e) {
            system.debug(e.getLineNumber()+': '+e.getMessage());
            throw new CustomException(e.getMessage() +' '+ e.getLineNumber());
        }

        RenewSubPreviewResponse renewSubPreviewResponse = RenewSubPreviewResponse.parse(renewSubPreviewResponseJson);
        String bizaoOrderId = setBizaoOrderId(renewSubPreviewResponse);
        renewSubPreviewResponse.bizaoOrderId = bizaoOrderId;

        // creer un enregistrement log pour les actions bizao dans l'objet RenewSubscriptionData__c
        RenewSubscriptionData__c renewSubscriptionData = setRenewSubscriptionData(renewSubPreviewResponse, bizaoOrderId, subId, nbPeriodes,
                                                                                    paymentMode, transactionNumber, operator, dollarPayment,
                                                                                    CDFPayment, dollarRefund, CDFRefund, selectedRenewOffer);
        insert renewSubscriptionData;

        return JSON.serialize(renewSubPreviewResponse);
    }
    /**
     * Méthode permettant de faire un renew avec upgrade preview
     */
    @AuraEnabled
    public static string callUpgradeSubscriptionProductPreview(Id subscriptionId, Integer nbPeriodes, String modeDePaiement,
                                                               String operator, String transactionNumber,
                                                               Double dollarPayment, Integer CDFPayment, Integer dollarRefund,
                                                               Integer CDFRefund, String selectedRenewOffer){

        Boolean isPreview = true;
        Boolean immediateUpgrade  = false;
        Boolean withRenew  = true;
        String bizaoOrderId = null;

        String renewSubPreviewResponseJson;
        try {
            renewSubPreviewResponseJson = SubscriptionRenewalActions.upgradeSubscriptionProduct(subscriptionId, nbPeriodes, isPreview,
                                                                                                   withRenew, immediateUpgrade,  modeDePaiement,  transactionNumber, operator,
                                                                                                   dollarPayment, CDFPayment,  dollarRefund, CDFRefund, bizaoOrderId, null, null, null);
        } catch (Exception e) {
            system.debug(e.getLineNumber()+': '+e.getMessage());
            throw new CustomException(e.getMessage() +' '+ e.getLineNumber());
        }
        
        RenewSubPreviewResponse renewSubPreviewResponse = RenewSubPreviewResponse.parse(renewSubPreviewResponseJson);
        bizaoOrderId = setBizaoOrderId(renewSubPreviewResponse);
        renewSubPreviewResponse.bizaoOrderId = bizaoOrderId;
        
        RenewSubscriptionData__c renewSubscriptionData = setRenewSubscriptionData(renewSubPreviewResponse, bizaoOrderId, subscriptionId, nbPeriodes,
                                                                                modeDePaiement, transactionNumber, operator, dollarPayment,
                                                                                CDFPayment, dollarRefund, CDFRefund, selectedRenewOffer);
        insert renewSubscriptionData;

        return JSON.serialize(renewSubPreviewResponse);
    }
    /**
     * Méthode permettant d'ouvrir la page de bizao Mobile Money
     */
    @AuraEnabled
    public static string callMobileMoneyPayment(String order){

        // cherche les log RenewSubscriptionData__c deja creer dans le preview
        RenewSubscriptionData__c renewSubscriptionData = getRenewSubscriptionData(order);
        String mobileMoneyPaymentResponse = BizaoPayments.mobileMoneyPayment(Integer.valueOf(renewSubscriptionData.RSD_Amount__c),
                                                                             renewSubscriptionData.RSD_Operator__c,
                                                                             renewSubscriptionData.RSD_OrderId__c,
                                                                             renewSubscriptionData.RSD_SubscriptionId__c);
        renewSubscriptionData.RSD_IsOrderOpen__c = true;
        update renewSubscriptionData;

        return mobileMoneyPaymentResponse;
    }
    /**
     * Méthode permettant d'ouvrir la page de bizao credit card
     */
    @AuraEnabled
    public static string callBankPayment(String order){

        // cherche les log RenewSubscriptionData__c deja creer dans le preview
        RenewSubscriptionData__c renewSubscriptionData =  getRenewSubscriptionData(order);
        String bankPaymentResponse = BizaoPayments.bankPayment(Integer.valueOf(renewSubscriptionData.RSD_Amount__c),
                                                               renewSubscriptionData.RSD_OrderId__c,
                                                               renewSubscriptionData.RSD_SubscriptionId__c);
        renewSubscriptionData.RSD_IsOrderOpen__c = true;
        update renewSubscriptionData;

        return bankPaymentResponse;
    }
    /**
     * Méthode permettant de construire l'order Id de chaque appel
    */
    private static RenewSubscriptionData__c getRenewSubscriptionData(String order){
        return [SELECT Id, RSD_Amount__c, RSD_SubscriptionId__c, RSD_Operator__c, RSD_OrderId__c
                FROM RenewSubscriptionData__c
                WHERE RSD_OrderId__c = : order
                LIMIT 1];
    }
    /**
     * Méthode permettant de construire l'order Id de chaque appel
     */
    private static String setBizaoOrderId(RenewSubPreviewResponse renewSubPreviewResponse){

        Datetime dateTimeNow = Datetime.now();
        String dateString = String.valueOf(dateTimeNow.year()) +
        String.valueOf(dateTimeNow.month()) +
        String.valueOf(dateTimeNow.day()) +
        String.valueOf(dateTimeNow.hour()) +
        String.valueOf(dateTimeNow.minute());

        RenewSubPreviewResponse.PreviewResult previewList = renewSubPreviewResponse?.previewResult;
        String bizaoOrderId;
        if(!previewList?.invoices.isEmpty()) {
            RenewSubPreviewResponse.Invoices invoice = previewList?.invoices[0];
            if(!invoice?.invoiceItems.isEmpty()) {
                String subscriptionNumber = invoice?.invoiceItems[0]?.subscriptionNumber;
                bizaoOrderId = subscriptionNumber + '-' + dateString;
            }
        }

        return bizaoOrderId;
    }
    /**
     * Méthode permettant de creer les logs des appels bizao dans l'objet RenewSubscriptionData__c
     */
    private static RenewSubscriptionData__c setRenewSubscriptionData(RenewSubPreviewResponse renewSubPreviewResponse, String bizaoOrderId, Id subId,
                                                                     Integer nbPeriodes, String paymentMode, String transactionNumber, String operator,
                                                                     Double dollarPayment, Integer CDFPayment, Integer dollarRefund, Integer CDFRefund,
                                                                     String selectedRenewOffer) {
        RenewSubscriptionData__c renewSubscriptionData = new RenewSubscriptionData__c();
        renewSubscriptionData.RSD_Amount__c = renewSubPreviewResponse.previewResult.invoices[0].amount;
        renewSubscriptionData.RSD_OrderId__c = bizaoOrderId;
        renewSubscriptionData.RSD_SubscriptionId__c = subId;
        renewSubscriptionData.RSD_NumberOfPeriods__c = nbPeriodes;
        renewSubscriptionData.RSD_Payment_Method__c = paymentMode; // modeDePaiement
        renewSubscriptionData.RSD_TransactionNumber__c = transactionNumber;
        renewSubscriptionData.RSD_Operator__c = operator;
        renewSubscriptionData.RSD_DollarPayment__c = dollarPayment;
        renewSubscriptionData.RSD_CDFPayment__c = CDFPayment;
        renewSubscriptionData.RSD_DollarRefund__c = dollarRefund;
        renewSubscriptionData.RSD_CDFRefund__c = CDFRefund;
        renewSubscriptionData.RSD_SelectedRenewOffer__c = selectedRenewOffer;
        renewSubscriptionData.RSD_IsOrderOpen__c = false;
        renewSubscriptionData.RSD_LogBizaoRestApi__c =  Datetime.now() + ' Creation of the order;';

        return renewSubscriptionData;
    }

    public class CustomException extends Exception {}
}