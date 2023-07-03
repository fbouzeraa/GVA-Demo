public class MTNValidation extends RestRoute {
    private String body;
    public MTNValidation(string valditationBody){
        this.body = valditationBody;
    }
    /**
     * We have 4 required inputs:
     * Box Number, Account currency, operator name and operation type
     * For the operation type we have 2 options (1 and 2):
     *  1- Value 1 means renew to the same product
     *  2- Value 2 means renew with Upgrade
     *  3- Value 3 means renew with Downgrade
     *
     * if inputs meet a subscription, return:
     *  -Subscription Number
     *  -Account Id
     *  -List of available offers
     *  -Account currency
     */
    /*  protected override Object doPost() {

          MTNObjects.ValidAccountRequest subscriptionRequest = (MTNObjects.ValidAccountRequest) JSON.deserialize(this.body, MTNObjects.ValidAccountRequest.class);

          //RestResponse res = RestContext.response;
          MTNObjects.MTNAPIResponse response = new MTNObjects.MTNAPIResponse();

          string results;

          // list of required status
          list<string> listSubStatus = new list<string> {'Active', 'Suspended'};

          // Subscription base product type
          string productType = 'Recurring';
          integer operationType;
          string countryCode;
          list<String> listAvailableOffers = new list<string>();
          set<String> setAvailableOperator = new set<string>();

          // list of errors
          list<string> listErrors = new list<String>();

          //set of available base product
          set<string> setAvailableProduct = new set<string>();
          try {

              if(Schema.sObjectType.Zuora__Subscription__c.isAccessible()) {

                  String query = 'SELECT Zuora__RatePlanName__c,Zuora__Subscription__r.Zuora__Account__c,Zuora__Subscription__c,Zuora__Product__c,Zuora__Product__r.Name, ';
                  query += ' Zuora__OriginalProductRatePlanChargeId__c,Zuora__Subscription__r.Name,Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode ';
                  query += ' FROM Zuora__SubscriptionProductCharge__c';
                  query += ' WHERE Zuora__Subscription__r.Zuora__Status__c IN :listSubStatus  AND Zuora__Type__c = :productType ';

                  // Add box Number filter
                  if(subscriptionRequest.CountryCode != null && !string.isBlank(subscriptionRequest.CountryCode)) {
                      CountryCode = subscriptionRequest.CountryCode;
                  } else {
                      listErrors.add('Country code is required');
                  }
                  //get mobile money operator
                  /*  List<String> ple = AP01_ProductRatePlanHelper.getDependentPicklistValues('QUO_Operateur__c', countryCode);
                     for(String pickListVal : ple) {
                        setAvailableOperator.add(pickListVal.toUpperCase());
                     }*/
    // Add box Number filter
    /*   if(subscriptionRequest.BoxNumber != null && !string.isBlank(subscriptionRequest.BoxNumber)) {
           String boxNumber = subscriptionRequest.BoxNumber;
           query += ' AND Zuora__Subscription__r.BoxNumber__c = :boxNumber';
       } else {
           listErrors.add(system.label.Box_Number_Required);
       }

       // Add Account currency
       if(subscriptionRequest.AccountCurrency != null && !string.isBlank(subscriptionRequest.AccountCurrency)) {
           String AccountCurrency = subscriptionRequest.AccountCurrency;
           query += ' AND Zuora__Subscription__r.Zuora__Account__r.currencyISOCode = :AccountCurrency';
       } else {
           listErrors.add('Currency is required');
       }

       // check paiement Mode
       if(subscriptionRequest.OperatorName != null && !string.isBlank(subscriptionRequest.OperatorName)) {
           if(!setAvailableOperator.contains(subscriptionRequest.OperatorName.toUpperCase()))
               listErrors.add('Operator not found');
       } else {
           listErrors.add('Operator is required');
       }
       // check renew mode
       if(subscriptionRequest.OperationType != null && !string.isBlank(string.valueOf(subscriptionRequest.OperationType))) {
           operationType = subscriptionRequest.OperationType;
       } else {
           listErrors.add('Operation type is required');
       }

       if(listErrors.size() == 0 && listErrors != null) {

           List<Zuora__SubscriptionProductCharge__c> listSubProd =  Database.query(query);
           if(listSubProd.size() > 0 && listSubProd != null) {
               list<zqu__ProductRatePlanCharge__c> listBasePRP = [SELECT name, zqu__ZuoraId__c
                                                                  FROM zqu__ProductRatePlanCharge__c
                                                                  WHERE zqu__ProductRatePlan__r.Category__c = 'Offer' AND
                                                                  zqu__ProductRatePlan__r.zqu__Product__r.name = :listSubProd[0].Zuora__Product__r.Name AND
                                                                      (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                      (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY))];

               String currentOffer;

               // get current Offer
               for(zqu__ProductRatePlanCharge__c prpCharge : listBasePRP) {
                   for(Zuora__SubscriptionProductCharge__c subProd : listSubProd) {
                       if(prpCharge.zqu__ZuoraId__c == subProd.Zuora__OriginalProductRatePlanChargeId__c) {
                           currentOffer = prpCharge.name;
                           break;
                       }
                   }
               }
               // 2 = Upgrade, 3 = Downgrade
               if((operationType == 2 && currentOffer == 'Start') || (operationType == 3 && currentOffer == 'Premium') || operationType == 1) {

                   response.Success = true;
                   response.SubscriptionNumber = listSubProd[0].Zuora__Subscription__r.Name;
                   response.SubscriptionId = listSubProd[0].Zuora__Subscription__c;
                   response.AccountId = listSubProd[0].Zuora__Subscription__r.Zuora__Account__c;
                   response.AccountCurrency = listSubProd[0].Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode;
                   results = JSON.serialize(response, true);
               } else {
                   listErrors.add('Any product is found for this operation type');
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

       }

       /* protected override Object doPost() {
       if(!String.isEmpty(this.param)) {
       throw new RestRouteError.RestException('Create Operation does not support Company Identifier', 'NOT_SUPPORTED', 404);
       } else {
       return createCompany();
       }
       }
     */

}