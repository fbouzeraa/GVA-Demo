/**
 * Test Class : USSD_Payments_Test
 * @author Jackie Abi Nassif
 * @date 2022-10-21
 * A record triggered flow (FLW_26_RetryRenew_Payment) call this class when a record is created
 * Agregator_Transaction__c is created with AT_SourceOfRequest__c = USSD if any error occured in WS08_USSDTransaction
 */
public without sharing class USSD_Payments {

    @InvocableMethod(label = 'retry payment')
    public static Void retryPayment(list<id> listPaymentId){

        if(listPaymentId.size() > 0 && listPaymentId != null)
        {
            try {
                // get record that triggered the flow and all needed info ( Mainly it's one record the the list listPaymentId)
                list<Agregator_Transaction__c> listPayments = [SELECT Id, CurrencyIsoCode, CreatedDate, LastModifiedDate, AT_Prepaid_Period__c,
                                                               AT_Transaction_Reference__c, AT_Renew_Type__c, AT_Subscription__c, AT_Status__c,
                                                               AT_Payment_Method__c, AT_Operator__c, AT_SourceOfRequest__c, Try_again__c, error_message__c,
                                                               Number_of_retry_attempts__c, Current_Expected_Renewal_Date__c, AT_Subscription__r.ExpectedRenewalDate__c
                                                               FROM Agregator_Transaction__c
                                                               WHERE Id IN :listPaymentId
                                                               AND AT_Status__c = :System.Label.NotTreated_Value
                                                               AND AT_SourceOfRequest__c = :System.Label.USSD_Value];

                list<Agregator_Transaction__c> listToBeUpdated = new list<Agregator_Transaction__c>();
                list<Agregator_Transaction__c> listOfFailed = new list<Agregator_Transaction__c>();
                String renewResponse;

                for(Agregator_Transaction__c agg : listPayments) {

                    // expected renewal date doesn't change means that the error occured before the create order request
                    if(agg.AT_Subscription__r.ExpectedRenewalDate__c == agg.Current_Expected_Renewal_Date__c) {
                        // check the type of te renew and try it again
                        integer prepaidPeriod = integer.valueOf(agg.AT_Prepaid_Period__c);
                        if(agg.AT_Renew_Type__c == System.Label.LWC_Simple_Renew_Type) {

                            renewResponse = SubscriptionRenewalActions.renewSubscription(agg.AT_Subscription__c, prepaidPeriod,
                                                                                         agg.AT_Payment_Method__c, agg.AT_Transaction_Reference__c, agg.AT_Operator__c, null, null, null, null, null, null, null, null);

                        } else if(agg.AT_Renew_Type__c == System.Label.LWC_Renew_With_Upgrade_Type) {

                            renewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(agg.AT_Subscription__c, prepaidPeriod,
                                                                                                  false, true, false, agg.AT_Payment_Method__c, agg.AT_Transaction_Reference__c, agg.AT_Operator__c, null, null, null, null, null, null, null, null);

                        } else if(agg.AT_Renew_Type__c == System.Label.LWC_Renew_With_Downgrade_Type) {

                            renewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(agg.AT_Subscription__c, null,
                                                                                                    prepaidPeriod, false, agg.AT_Payment_Method__c, agg.AT_Transaction_Reference__c, agg.AT_Operator__c, null, null, null, null, null, null, null, null);
                        }

                        ZuoraResponseObjects.ZuoraPayment responseObject = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(renewResponse, ZuoraResponseObjects.ZuoraPayment.class);
                        system.debug('retry renew response ' + responseObject);

                        // if renew success update status to treated if not success trigger the flow again
                        agg.AT_Status__c = System.Label.Treated_Value;
                        agg.Try_again__c = false;
                        listToBeUpdated.add(agg);

                        if(!responseObject.success) {
                            system.debug('responseObject '+responseObject);
                            agg.AT_Status__c = System.Label.NotTreated_Value;
                            agg.Try_again__c = true;
                            agg.Number_of_retry_attempts__c += 1;
                            listOfFailed.add(agg);
                        }
                    } 
                    else {
                        agg.error_message__c = agg.error_message__c + ' ///// ' + 'Subscription is renewed check the payment';
                    }

                }

                // can't merge the two lists because we need to make the update twice to launch again the flow if this retry is failed
                if(listToBeUpdated != null && listToBeUpdated.size() > 0) {
                    update listToBeUpdated;
                }
                // update checkbox to true and trigger the flow
                if(listOfFailed != null && listOfFailed.size() > 0) {
                    update listOfFailed;
                }

            } catch(Exception e) {
                system.debug(e.getMessage() + e.getLineNumber() );
                throw new CustomException(e.getLineNumber() + ': ' + e.getMessage());
            }
        }

    }
    public class CustomException extends Exception {}
}