public class MTNRenewalPreview extends RestRoute {
    private String body;
    public MTNRenewalPreview(string valditationBody){
        this.body = valditationBody;
    }
    /**
     * We have 4 required inputs:
     * SubscriptionId,OperatorName, Currency, Country, Main Offer, Duration
     * Payment Method is Mobile Money
     *
     * if inputs meet a subscription, return:
     *  -Subscription Number
     *  -Account Id
     *  -List of available offers
     *  -Account currency
     */
    /* protected override Object doPost() {

         MTNObjects.SubscriptionRenewalRequest SubscriptionRenewalRequest = (MTNObjects.SubscriptionRenewalRequest) JSON.deserialize(this.body, MTNObjects.SubscriptionRenewalRequest.class);

         //RestResponse res = RestContext.response;
         MTNObjects.MTNAPIResponse response = new MTNObjects.MTNAPIResponse();

         string results;

         // list of errors
         list<string> listErrors = new list<String>();
         set<string> setAvailableOperator = new set<string>();
         try {

             if(Schema.sObjectType.Zuora__Subscription__c.isAccessible()) {

                 // Check Subscription Id
                 if(SubscriptionRenewalRequest.SubscriptionId == null && string.isBlank(SubscriptionRenewalRequest.SubscriptionId)) {
                     listErrors.add(System.label.Subscription_Id_Required);
                 }

                 // Check Renew prepaidPeriod
                 if(SubscriptionRenewalRequest.Duration == null && string.isBlank(string.valueOf(SubscriptionRenewalRequest.Duration))) {
                     listErrors.add(System.label.Prepaid_Period_Required);
                 }

                 // Check Subscription Id
                 if(SubscriptionRenewalRequest.CountryCode == null && string.isBlank(SubscriptionRenewalRequest.CountryCode)) {
                     listErrors.add('Country is Required');
                 } else {
                     //get mobile money operator
                     /*   List<String> ple = AP01_ProductRatePlanHelper.getDependentPicklistValues('QUO_Operateur__c', SubscriptionRenewalRequest.countryCode);
                        for(String pickListVal : ple) {
                            setAvailableOperator.add(pickListVal.toUpperCase());
                        }*/
    /*    }
        if(SubscriptionRenewalRequest.OperationType == null && string.isBlank(string.valueOf(SubscriptionRenewalRequest.OperationType))) {
            listErrors.add('Operation Type is Required');
        }
        // check paiement Mode OPerator
        if(SubscriptionRenewalRequest.OperatorName != null && !string.isBlank(SubscriptionRenewalRequest.OperatorName)) {
            if(!setAvailableOperator.contains(SubscriptionRenewalRequest.OperatorName.toUpperCase()))
                listErrors.add('Operator not found');
        } else {
            listErrors.add('Operator is required');
        }

        if(listErrors.size() == 0 && listErrors != null) {

            list<Zuora__Subscription__c> listSub = [SELECT Zuora__Account__r.CurrencyIsoCode, ExpectedRenewalDate__c, Zuora__Status__c
                                                    FROM Zuora__subscription__c
                                                    WHERE id =: SubscriptionRenewalRequest.SubscriptionId];
            if(listSub.size() > 0 && listSub != null) {

                string previewResult;
                // 1--> Simple Renew
                // 2--> Renew with Upgrade
                // 3--> Renew with Downgrade
                if(SubscriptionRenewalRequest.OperationType == 1) {
                    previewResult = SubscriptionRenewalActions.renewSubPreview(SubscriptionRenewalRequest.SubscriptionId, SubscriptionRenewalRequest.Duration, true, 'Mobile_Money', true, null);
                } else if(SubscriptionRenewalRequest.OperationType == 2) {
                    //  previewResult = SubscriptionRenewalActions.upgradeSubscriptionProduct(SubscriptionRenewalRequest.SubscriptionId, SubscriptionRenewalRequest.Duration, true, true, false, 'Mobile_Money', null, SubscriptionRenewalRequest.OperatorName, null, null, null, null);
                } else {
                    //  previewResult = SubscriptionRenewalActions.downgradeSubscriptionProduct(SubscriptionRenewalRequest.SubscriptionId, null, SubscriptionRenewalRequest.Duration, true, 'Mobile_Money', null, SubscriptionRenewalRequest.OperatorName, null, null, null, null);
                }
                if(previewResult != System.label.Impossible_Action && previewResult != System.label.Empty_Subscription_Product &&
                   previewResult != System.label.Upgrade_Product_Failure && previewResult != System.label.Impossible_Action) {
                    ZuoraResponseObjects.ZuoraPreviewResponse subPreview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                        previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                    response.Success = true;
                    response.SubscriptionId = SubscriptionRenewalRequest.SubscriptionId;
                    response.AccountCurrency = listSub[0].Zuora__Account__r.CurrencyIsoCode;
                    response.Amount = subPreview.previewResult.invoices[0].amount;
                    response.EndDate = listSub[0].Zuora__Status__c == 'Active'?listSub[0].ExpectedRenewalDate__c.addMonths(SubscriptionRenewalRequest.Duration) : Date.Today().addMonths(SubscriptionRenewalRequest.Duration);
                    results = JSON.serialize(response, true);
                } else {
                    listErrors.add(previewResult);
                    response.Errors = listErrors;
                    response.Success = false;
                    results = JSON.serialize(response, true);
                }

            } else {
                listErrors.add('Subscription Not Found');
                response.Errors = listErrors;
                response.Success = false;
                results = JSON.serialize(response, true);
            }

        } else {
            response.Errors = listErrors;
            response.Success = false;
            results = JSON.serialize(response, true);
        }
       }

       return results;
       }
       catch(Exception e) {
       response.Errors = new list<string> {e.getMessage()};
       response.Success = false;
       results = JSON.serialize(response, true);

       return results;
       }

       }*/

}