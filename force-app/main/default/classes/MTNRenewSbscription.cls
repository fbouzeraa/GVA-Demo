public with sharing class MTNRenewSbscription extends RestRoute {
    private String body;
    public MTNRenewSbscription(string valditationBody){
        this.body = valditationBody;
    }
    /* Methode permettant Bizao de faire un appel à Salesforce via API
     * pour assurer que le compte est valide
     * @return string
     * */
    /* protected override Object doPost() {
         RestRequest req = RestContext.request;

         MTNObjects.SubscriptionRenewalRequest renewSubRequest = (MTNObjects.SubscriptionRenewalRequest) JSON.deserialize(RestContext.request.requestBody.toString(), MTNObjects.SubscriptionRenewalRequest.class);

         //RestResponse res = RestContext.response;
         MTNObjects.MTNAPIResponse response = new MTNObjects.MTNAPIResponse();

         string results;
         set<string> setAvailableOperator = new set<string>();
         // list of errors
         list<string> listErrors = new list<String>();
         if(Schema.sObjectType.Suivi_de_Souscription__c.isAccessible()) {

             // Check Subscription Id
             if(renewSubRequest.SubscriptionId == null && string.isBlank(renewSubRequest.SubscriptionId)) {
                 listErrors.add(System.label.Subscription_Id_Required);
             }

             // Check Renew prepaidPeriod
             if(renewSubRequest.Duration == null && string.isBlank(string.valueOf(renewSubRequest.Duration))) {
                 listErrors.add(System.label.Prepaid_Period_Required);
             }

             // Check Subscription Id
             if(renewSubRequest.CountryCode == null && string.isBlank(renewSubRequest.CountryCode)) {
                 listErrors.add('Country is Required');
             } else {
                 //get mobile money operator
                 List<String> ple = AP01_ProductRatePlanHelper.getDependentPicklistValues('QUO_Operateur__c', renewSubRequest.countryCode);
                 for(String pickListVal : ple) {
                     setAvailableOperator.add(pickListVal.toUpperCase());
                 }
             }
             if(renewSubRequest.OperationType == null && string.isBlank(string.valueOf(renewSubRequest.OperationType))) {
                 listErrors.add('Operation Type is Required');
             }
             // check paiement Mode OPerator
             if(renewSubRequest.OperatorName != null && !string.isBlank(renewSubRequest.OperatorName)) {
                 if(!setAvailableOperator.contains(renewSubRequest.OperatorName.toUpperCase()))
                     listErrors.add('Operator not found');
             } else {
                 listErrors.add('Operator is required');
             }
             // check transaction Number
             if(renewSubRequest.TransactionNumber == null && string.isBlank(string.valueOf(renewSubRequest.TransactionNumber))) {
                 listErrors.add('Transaction type is required');
                 // transactionNb = renewSubRequest.TransactionNumber;
             }

             // check payment methode
             if(renewSubRequest.OperationType != null && !string.isBlank(string.valueof(renewSubRequest.OperationType))) {
                 if(renewSubRequest.OperationType != 1 || renewSubRequest.OperationType != 2 || renewSubRequest.OperationType != 3) {
                     listErrors.add(System.label.Invalid_Renew_Type);
                 }
             } else {
                 listErrors.add(System.label.Renew_Type_Required);
             }
             if(listErrors != null && listErrors.size() > 0) {
                 // create a suivi record
                 Suivi_de_Souscription__c sv = new Suivi_de_Souscription__c();
                 MTNObjects.SuiviDetails svDetail = new MTNObjects.SuiviDetails();
                 if(renewSubRequest.OperationType == 1) {
                     svDetail.IDSouscription = renewSubRequest.SubscriptionId;
                     svDetail.Operateur = renewSubRequest.OperatorName;
                     svDetail.ModeDePaiement = 'Mobile_Money';
                     svDetail.NumeroDeTransaction = renewSubRequest.TransactionNumber;
                     svDetail.Periode = renewSubRequest.Duration;
                     sv.SV_Id_Souscription__c = renewSubRequest.SubscriptionId;
                     // dest SF
                     sv.SV_Destination__c = 'DST002';
                     // reabo simple
                     sv.SV_Code_Action__c = 'ACT003';

                     sv.SV_Details__c = JSON.serialize(svDetail, true);

                 } else if(renewSubRequest.OperationType == 2) {
                     svDetail.IDSouscription = renewSubRequest.SubscriptionId;
                     svDetail.Operateur = renewSubRequest.OperatorName;
                     svDetail.ModeDePaiement = 'Mobile_Money';
                     svDetail.NumeroDeTransaction = renewSubRequest.TransactionNumber;
                     svDetail.Periode = renewSubRequest.Duration;
                     svDetail.typeOperation = 2;

                     sv.SV_Id_Souscription__c = renewSubRequest.SubscriptionId;
                     // dest SF
                     sv.SV_Destination__c = 'DST002';
                     // reabo simple
                     sv.SV_Code_Action__c = 'ACT004';

                     sv.SV_Details__c = JSON.serialize(svDetail, true);

                 } else {
                     svDetail.IDSouscription = renewSubRequest.SubscriptionId;
                     svDetail.Operateur = renewSubRequest.OperatorName;
                     svDetail.ModeDePaiement = 'Mobile_Money';
                     svDetail.NumeroDeTransaction = renewSubRequest.TransactionNumber;
                     svDetail.Periode = renewSubRequest.Duration;
                     svDetail.typeOperation = 3;

                     sv.SV_Id_Souscription__c = renewSubRequest.SubscriptionId;
                     // dest SF
                     sv.SV_Destination__c = 'DST002';
                     // reabo simple
                     sv.SV_Code_Action__c = 'ACT004';

                     sv.SV_Details__c = JSON.serialize(svDetail, true);

                 }

                 try {
                     insert sv;
                     response.Success = true;
                     response.Message = System.label.Successful_Response;

                     results = JSON.serialize(response, true);
                 }
                 catch(Exception e) {
                     listErrors.add(e.getMessage());
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
       }*/
}