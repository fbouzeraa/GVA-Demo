/**
 * Test Class : USSDMTNGetStatus_Test
 * @author Jackie Abi Nassif
 * @date 2023-05-22
 * A record triggered flow (FLW_30_MTNGetStatusAndRetry) call this class when a record is updated to Request Stage = 'Successful Request To Pay'
 */
public  class USSDMTNGetStatus {

    @InvocableMethod(label = 'get requestToPay Status')
    public static void getStatus(list<id> listPaymentId) {

        if(listPaymentId != null && listPaymentId.size() > 0)
        {
            // get record that triggered the flow and all needed info ( Mainly it's one record the the list listPaymentId)
            List<requestToPayDemand__c> listRequestToPay = [SELECT Id,externalId__c,numTel__c,Currency__c,financialTransactionId__c,Amount__c, Request_Status__c,
                                                            Subscription__c, Subscription__r.Zuora__Account__r.BillingCountryCode, Subscription__r.Zuora__Account__c,
                                                            Subscription__r.ExpectedRenewalDate__c, Current_Expected_Renewal_Date__c, Current_Base_Product__c,
                                                            baseProductToAdd__c, prepaidPeriod__c,Source_operator__c
                                                            FROM requestToPayDemand__c 
                                                            WHERE Id IN : listPaymentId 
                                                            AND (Request_Stage__c = 'Successful_RequestToPay' OR Request_Stage__c = 'Failed_renewal')
                                                            AND Subscription__r.SuspensionReason__c != 'Move-Requested'];
            
            // Make sure that the record still in the 'successful request to pay' Stage to continue else the renew could be treated by the callback
            if(listRequestToPay != null && listRequestToPay.size() > 0){

                String renewResponse;
                String modeDePaiement = System.Label.ModePaiement_MobileMoney;
                list<requestToPayDemand__c> listOfRequestDemand = new list<requestToPayDemand__c>();

                for(requestToPayDemand__c rec : listRequestToPay){

                    String operator = rec.Source_operator__c;

                    // expected renewal date doesn't change means that renew is not treated 
                    if(rec.Subscription__r.ExpectedRenewalDate__c == rec.Current_Expected_Renewal_Date__c){

                        String response = apiManagerMTN.callout(rec.financialTransactionId__c, null, MTNObjects.get, MTNObjects.requesttopayAPIUrl);
                        system.debug('response '+response);
                        MTNObjects.MobileMoneyRequest getStatusresponse = (MTNObjects.MobileMoneyRequest) JSON.deserialize(response, MTNObjects.MobileMoneyRequest.class);

                        // if the payment is successful and equal the requested amount continue to the renew step
                        if(getStatusresponse.status != null && getStatusresponse.status == 'SUCCESSFUL' && integer.valueOf(getStatusresponse.amount) == rec.Amount__c){
                            // check if its a simple renewal or renewal with upgrade or downgrade
                            if(rec.baseProductToAdd__c == rec.Current_Base_Product__c) {

                                renewResponse = SubscriptionRenewalActions.renewSubscription(rec.Subscription__c, integer.valueOf(rec.prepaidPeriod__c), modeDePaiement, rec.financialTransactionId__c, 
                                                                                                operator, null, null, null, null, null, null, null, null);
                            } else if(rec.baseProductToAdd__c == System.Label.Start_BaseProduct) {

                                renewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(rec.Subscription__c, integer.valueOf(rec.prepaidPeriod__c), false, true, false, 
                                                                                                    modeDePaiement, rec.financialTransactionId__c, operator, null, null, null, null, null, null, null, null);
                            } else if(rec.baseProductToAdd__c == System.Label.Premium_BaseProduct){

                                renewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(rec.Subscription__c, null, integer.valueOf(rec.prepaidPeriod__c), false, modeDePaiement, 
                                                                                                        rec.financialTransactionId__c, operator, null, null, null, null, null, null, null, null);
                            } else{
                                rec.Request_Status__c += '\n' + Datetime.now() + ' Renew Action in Get Status is invalid';
                            }

                            ZuoraResponseObjects.ZuoraPayment responseObject = new ZuoraResponseObjects.ZuoraPayment ();
                            if(renewResponse != null){
                                responseObject = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(renewResponse, ZuoraResponseObjects.ZuoraPayment.class);
                            }

                            if(responseObject != null && responseObject.success){

                                rec.Request_Status__c += '\n' + Datetime.now() + ' Successful renewal after get Status request';
                                rec.Request_Stage__c = 'Successful_renewal';
                                rec.Success__c = true;
                            }else if(responseObject != null){

                                rec.Retry__c =  true;
                                rec.Request_Status__c += '\n' + Datetime.now() + ' UnSuccessful renewal after get Status request >> '+ responseObject.reasons[0].message;
                                rec.Request_Stage__c = 'Failed_renewal';
                            }
                        } else if(integer.valueOf(getStatusresponse.amount) != rec.Amount__c){
                            rec.Request_Status__c += '\n' + Datetime.now() + ' Renew Action in Get Status is invalid Because the paid amount != expected amount ';
                            rec.Request_Stage__c  = 'Unsuccessful_Payment';
                        } else{
                            rec.Request_Status__c += '\n' + Datetime.now() + ' Get Status Response is unsuccessful: '+ getStatusresponse.message;
                            rec.Request_Stage__c  = 'Unsuccessful_Payment';
                        }
                    }else{
                        rec.Request_Status__c += '\n' + Datetime.now() + ' invalid >>> Current Expected renewal date != expected ExpectedRenewalDate__c ';
                    }

                    listOfRequestDemand.add(rec);
                }

                if(listOfRequestDemand != null && listOfRequestDemand.size() > 0){
                    try {
                        update listOfRequestDemand;
                    } catch (Exception e) {
                        system.debug(e.getMessage() + e.getLineNumber() );
                        throw new CustomException(e.getLineNumber() + ': ' + e.getMessage());
                    }
                }
            }
        }
    }

    public class CustomException extends Exception {}
}