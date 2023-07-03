/**
 * @author      Nicolas Brosse
 * @date         20-07-2022
 *  
 * @Changes     Jackie abi Nassif
 * @Date         14-12-2022
 * 
 * @description  Class to receive post API call confirmation payment from Bizao
 * and save the renew subscription if the status of the  payment is "Succesfull"
 */
@RestResource(urlMapping = '/bizaorest')
global with sharing class BizaoRest {

    @HttpPost
    global static String doPost() {

        RestRequest req = RestContext.request;
        System.debug('req.requestBody.toString() : ' + req.requestBody.toString());

        BizaoBodyRequest bizaoBodyRequest = BizaoBodyRequest.parse(req.requestBody.toString());
        String orderId = bizaoBodyRequest.order_id;
        String renewSubcriptionStatus;

        list<RenewSubscriptionData__c> listOfRenewSubscriptionData = [SELECT Id, RSD_Amount__c, RSD_Operator__c,  RSD_SubscriptionId__c, RSD_NumberOfPeriods__c,
                                                                        RSD_Payment_Method__c, RSD_TransactionNumber__c, RSD_DollarPayment__c, RSD_CDFPayment__c,
                                                                        RSD_DollarRefund__c, RSD_CDFRefund__c, RSD_OrderId__c, RSD_SelectedRenewOffer__c, RS_Status__c,
                                                                        RSD_IsOrderOpen__c, RSD_LogBizaoRestApi__c
                                                                    FROM RenewSubscriptionData__c
                                                                    WHERE RSD_OrderId__c = :orderId];

        if(listOfRenewSubscriptionData != null && listOfRenewSubscriptionData.size() == 1){

           RenewSubscriptionData__c renewSubscriptionData = listOfRenewSubscriptionData[0];

            if(bizaoBodyRequest.status == 'Failed') {
            
                // Close the order if the Bizao response is failed
                renewSubscriptionData.RSD_IsOrderOpen__c = false;
                renewSubscriptionData.RSD_LogBizaoRestApi__c += '\n' + Datetime.now() + ' Bizao notification status : Failed;';
                renewSubscriptionData.RS_Status__c = 'ST001'; // ST001 = Treated
                update renewSubscriptionData;

                renewSubcriptionStatus = 'Subcription renew failed';
                                            
            }else if(bizaoBodyRequest.status == 'Successful') {

                // if record found and the order is still open renew the subscription
                if(renewSubscriptionData.RSD_IsOrderOpen__c == true) {

                    renewSubscriptionData.RSD_LogBizaoRestApi__c += '\n' + Datetime.now() + ' Bizao notification status : Successful;';
                    renewSubcriptionStatus = handleRenewSubscription(renewSubscriptionData);
                 // if order is no more open --> renew is treated by the flow 27 and the get status request (Request from SF to Bizao to check payment )
                }else if(renewSubscriptionData.RSD_IsOrderOpen__c == false) {

                    renewSubscriptionData.RSD_LogBizaoRestApi__c += '\n' + Datetime.now() + ' Response has already been treated for this order;';
                    update renewSubscriptionData;

                    renewSubcriptionStatus = 'Bizao response has already been treated for this order';
                }
            }else{
                renewSubcriptionStatus = 'Unvalid status from Bizao';
            }
        }else if(listOfRenewSubscriptionData != null && listOfRenewSubscriptionData.size() > 1){
            renewSubcriptionStatus = 'Duplicate Renew Subscription Data was Found with the specific order Id';
        }else{
            renewSubcriptionStatus = 'No Renew Subscription Data was Found with the specific order Id';         
        }

        return renewSubcriptionStatus;
    }

    // Renew the subscription based on the type of the request simple, uograde or downgrade
    private static String handleRenewSubscription(RenewSubscriptionData__c renewSubscriptionData){

        String renewSubcriptionStatus;
        if(renewSubscriptionData.RSD_selectedRenewOffer__c == System.Label.BizaoValue_REABO) { // simple renew

            try {
                String renewSubResponseJson = SubscriptionRenewalActions.renewSubscription(
                                                renewSubscriptionData.RSD_SubscriptionId__c, Integer.valueOf(renewSubscriptionData.RSD_NumberOfPeriods__c),
                                                renewSubscriptionData.RSD_Payment_Method__c, renewSubscriptionData.RSD_TransactionNumber__c, 
                                                'Bizao', Integer.valueOf(renewSubscriptionData.RSD_DollarPayment__c), 
                                                Integer.valueOf(renewSubscriptionData.RSD_CDFPayment__c), Integer.valueOf(renewSubscriptionData.RSD_DollarRefund__c),
                                                Integer.valueOf(renewSubscriptionData.RSD_CDFRefund__c), renewSubscriptionData.RSD_OrderId__c, null, null, null);

                string responseAdjustment = renewSubResponseJson.replaceAll('number', 'number_toReplace');
                ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                                                
                if(paymentResponse.success) {
                    
                    RenewSubscriptionResponse renewSubscriptionResponse = RenewSubscriptionResponse.parse(responseAdjustment);
                    // ajouter le numero du paiement sur la souscription (SUB_T_Payment_Number__c)
                    SubscriptionRenewalActions.addPaymentNumberToSubscription(renewSubscriptionData.RSD_SubscriptionId__c, renewSubscriptionResponse.number_Z);
        
                    renewSubcriptionStatus = 'Subcription renew successful';
                }else {
                    renewSubcriptionStatus = 'Subcription renew failed: ' + paymentResponse.reasons[0].message;
                }
            } catch (Exception e) {
                system.debug(e.getLineNumber()+': '+e.getMessage());
                renewSubcriptionStatus = e.getLineNumber()+': '+e.getMessage();
                throw new CustomException(e.getMessage() +' '+ e.getLineNumber());
            }
        }
        else if(renewSubscriptionData.RSD_selectedRenewOffer__c == System.Label.BizaoValue_REABO_UPG) { // upgrade renew

            Boolean isPreview = false;
            Boolean withRenew = true;
            Boolean immediateUpgrade = false;

            try {
                String renewSubResponseJson = SubscriptionRenewalActions.upgradeSubscriptionProduct(
                                                renewSubscriptionData.RSD_SubscriptionId__c, Integer.valueOf(renewSubscriptionData.RSD_NumberOfPeriods__c), isPreview, 
                                                withRenew, immediateUpgrade, renewSubscriptionData.RSD_Payment_Method__c, renewSubscriptionData.RSD_TransactionNumber__c, 
                                                'Bizao', Integer.valueOf(renewSubscriptionData.RSD_DollarPayment__c), 
                                                Integer.valueOf(renewSubscriptionData.RSD_CDFPayment__c), Integer.valueOf(renewSubscriptionData.RSD_DollarRefund__c),
                                                Integer.valueOf(renewSubscriptionData.RSD_CDFRefund__c), renewSubscriptionData.RSD_OrderId__c, null, null, null);


                string responseAdjustment = renewSubResponseJson.replaceAll('number', 'number_toReplace');
                ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                
                if(paymentResponse.success) {

                    RenewSubscriptionResponse renewSubscriptionResponse = RenewSubscriptionResponse.parse(responseAdjustment);
                    // ajouter le numero du paiement sur la souscription (SUB_T_Payment_Number__c)
                    SubscriptionRenewalActions.addPaymentNumberToSubscription(renewSubscriptionData.RSD_SubscriptionId__c, renewSubscriptionResponse.number_Z);
        
                    renewSubcriptionStatus = 'Subcription renew successful';
                }else {
                    renewSubcriptionStatus = 'Subcription renew failed: ' + paymentResponse.reasons[0].message;
                }
            } catch (Exception e) {
                system.debug(e.getLineNumber()+': '+e.getMessage());
                renewSubcriptionStatus = e.getLineNumber()+': '+e.getMessage();
                throw new CustomException(e.getMessage() +' '+ e.getLineNumber());
            }
        }
        else if(renewSubscriptionData.RSD_selectedRenewOffer__c == System.Label.BizaoValue_REABO_DOWN) {

            renewSubcriptionStatus = 'Renew with downgrade is not possible';
        }else{
            renewSubcriptionStatus = 'Type of the renew is undefined';
        }

        // ajouter le status du reabo dans l'enregistrement de l'objet RenewSubscriptionData__c
        renewSubscriptionData.RSD_LogBizaoRestApi__c += '\n' + Datetime.now() + ' Renew Subcription Status : ' + renewSubcriptionStatus + ';';
        closeOrder(renewSubscriptionData, renewSubcriptionStatus);

        return renewSubcriptionStatus;
    }

    private static void closeOrder(RenewSubscriptionData__c renewSubscriptionData, string renewSubcriptionStatus){

        if(renewSubcriptionStatus.contains('failed')) {

            //check if a follow up is created --> if yes it's mean that the payment is failed --> in this case the payment will be recreated in the batch
            list<Suivi_de_Souscription__c> listSuivi = [SELECT Id FROM Suivi_de_Souscription__c
                                                        WHERE createdDate = :date.today() AND SV_Code_Action__c IN ('ACT003', 'ACT004')
                                                        AND SV_Id_Souscription__c = :renewSubscriptionData.RSD_SubscriptionId__c AND ownerId =:UserInfo.getUserId()];
            
            if(listSuivi != null && listSuivi.size() > 0) {
                renewSubscriptionData.RS_Status__c = 'ST001';
                renewSubscriptionData.RSD_IsOrderOpen__c = false;
            } else {
                renewSubscriptionData.RS_Status__c = 'ST002';
            }
        }else if(renewSubcriptionStatus.contains('successful')){
            renewSubscriptionData.RS_Status__c = 'ST001';
            renewSubscriptionData.RSD_IsOrderOpen__c = false;
        }else{
            renewSubscriptionData.RS_Status__c = 'ST002';
        }

        System.debug('Total number of records retrieved by SOQL queries:'+Limits.getLimitDmlRows());
        System.debug('Number of records retrieved by SOQL queries so far: ' + Limits.getDmlRows());
        
        update renewSubscriptionData;
    }

    public class CustomException extends Exception {}
}