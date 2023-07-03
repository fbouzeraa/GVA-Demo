/**
 * Test Class : WS07_USSDVerifyAccount_test
 * @author Jackie Abi Nassif
 * @date 2022-09-27
 */
@RestResource(urlMapping = '/v1/VerifyUser/*')
global class WS07_USSDVerifyUser {

    @HttpGet
    global static String verifyUser() {

        USSDObjects.VerifyUserResponse response = new USSDObjects.VerifyUserResponse();

        // 2 way to get info based on phoneNumber or boxNumber
        if((RestContext.request.params.get(System.Label.WS_Param_PhoneNumber) != '' && RestContext.request.params.get(System.Label.WS_Param_PhoneNumber) != null)
            || (RestContext.request.params.get(System.Label.WS_Param_routerNumber) != '' && RestContext.request.params.get(System.Label.WS_Param_routerNumber) != null)){

            String phone = RestContext.request.params.get(System.Label.WS_Param_PhoneNumber);
            String boxNumber = RestContext.request.params.get(System.Label.WS_Param_routerNumber);
            list<Zuora__Subscription__c> subList = new list<Zuora__Subscription__c>();
            // if boxNumber is given get the specific Subscription if phoneNumber is given it can be more then one subscription
            if(boxNumber != null){
                subList = [SELECT Id, Zuora__Status__c,Zuora__Account__c,Name, BoxNumber__c,ExpectedRenewalDate__c,Zuora__Account__r.Name,
                            Zuora__Account__r.Phone, Zuora__Account__r.PersonMobilePhone, Zuora__Account__r.ACC_Tech_PersonMobile__c, Zuora__Account__r.BillingCountryCode,
                            Zuora__Account__r.ACC_AutreTelephone__c, Coupon__c, CompensationDaysAtNextRenewal__c, CurrencyIsoCode, SuspensionReason__c 
                            FROM Zuora__Subscription__c
                            WHERE (Zuora__Status__c = :System.Label.Sub_Status_Active OR Zuora__Status__c = :System.Label.Sub_Status_Suspended) 
                            AND BoxNumber__c = :boxNumber];
            }
            else{
                subList = [SELECT Id, Zuora__Status__c,Zuora__Account__c,Name, BoxNumber__c,ExpectedRenewalDate__c,Zuora__Account__r.Name,
                            Zuora__Account__r.Phone, Zuora__Account__r.PersonMobilePhone, Zuora__Account__r.ACC_Tech_PersonMobile__c, Zuora__Account__r.BillingCountryCode,
                            Zuora__Account__r.ACC_AutreTelephone__c, Coupon__c, CompensationDaysAtNextRenewal__c, CurrencyIsoCode ,SuspensionReason__c
                            FROM Zuora__Subscription__c
                            WHERE  (Zuora__Account__r.Phone =: phone OR Zuora__Account__r.PersonMobilePhone =: phone OR 
                            Zuora__Account__r.ACC_Tech_PersonMobile__c =: phone OR Zuora__Account__r.ACC_AutreTelephone__c =: phone)
                            AND (Zuora__Status__c = :System.Label.Sub_Status_Active OR Zuora__Status__c = :System.Label.Sub_Status_Suspended) AND BoxNumber__c != null];
            }
            
            if(subList != null && subList.size() > 0)
            {
                list<USSDObjects.Usersubscription> listOfUserSubscriptions = new list<USSDObjects.Usersubscription>();
                for(Zuora__Subscription__c sub : subList)
                {
                    USSDObjects.Usersubscription userSubscription = new USSDObjects.Usersubscription();
                    userSubscription.Name = sub.Zuora__Account__r.Name;
                    userSubscription.EndDate = String.valueOf(sub.ExpectedRenewalDate__c) ;
                    userSubscription.Status = sub.Zuora__Status__c;
                    userSubscription.boxNumber = sub.BoxNumber__c;
                    userSubscription.currentCurrency = sub.CurrencyIsoCode;
                    userSubscription.inMoveProcess = sub.SuspensionReason__c == 'Move-Requested'? true : false;
                    userSubscription.countrycodeValue = sub.Zuora__Account__r.BillingCountryCode;
                    // check if there any coupon or free days for the current subscription
                    if(sub.Coupon__c != null){
                        userSubscription.coupon = sub.Coupon__c + ' ' + sub.CurrencyIsoCode;
                    }
                    if(sub.CompensationDaysAtNextRenewal__c != '0' && sub.CompensationDaysAtNextRenewal__c != null){
                        userSubscription.freeDays = sub.CompensationDaysAtNextRenewal__c;
                    }
                    listOfUserSubscriptions.add(userSubscription);
                }
                response.Success = true;
                response.subscriptions = listOfUserSubscriptions;
            }
            else{
                response.Success = false;
                response.Message = System.Label.WS_Message_NoSub;
            }
        }
        else{
            response.Success = false;
            response.Message = System.Label.WS_Message_NoPhoneNumber;
        }

        return json.serialize(response, true);
    }
}