/**
 * Test Classe : WS04_BizaoValidationAPI_Test
 * @author Yara Bourdoukan
 * @date 2021-11-09
 */
@RestResource(urlMapping = '/v1/Renew/*')
global class WS05_BizaoReabonnementAPI {
    /* Methode permettant Bizao de faire un appel à Salesforce via API
     * pour assurer que le compte est valide
     * @return string
     * */
    @HttpPost
    global static string doGet() {
        RestRequest req = RestContext.request;

        BizaoObjects.SimpleRenewRequest renewSubRequest = (BizaoObjects.SimpleRenewRequest) JSON.deserialize(RestContext.request.requestBody.toString(), BizaoObjects.SimpleRenewRequest.class);

        //RestResponse res = RestContext.response;
        BizaoObjects.RenewSubResponse response = new BizaoObjects.RenewSubResponse();

        string results;
        String paymentMode;
        integer prepaidPeriod;
        string transactionNb;
        string subId;
        String type;

        // list of errors
        list<string> listErrors = new list<String>();

        set<string> setTypeOfRenew = new set<string> {'Simple'};

        set<string> setAvailablePaymentMode = new set<string>();

        // Check if Object is accessible by calling user.
        if(Schema.sObjectType.Suivi_de_Souscription__c.isAccessible()) {
            try {

                //get payment mode
                Schema.DescribeFieldResult fieldResult = Quote.QUO_Mode_De_Paiement__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for(Schema.PicklistEntry pickListVal : ple) {
                    setAvailablePaymentMode.add(pickListVal.getValue());
                }

                // check sub Id
                if(renewSubRequest.IDSouscription != null && !string.isBlank(renewSubRequest.IDSouscription)) {
                    subId = renewSubRequest.IDSouscription;
                } else   {
                    listErrors.add(System.label.Subscription_Id_Required);
                }

                // check payment methode
                if(renewSubRequest.ModeDePaiement != null && !string.isBlank(renewSubRequest.ModeDePaiement)) {
                    if(setAvailablePaymentMode.contains(renewSubRequest.ModeDePaiement)) {
                        paymentMode = renewSubRequest.ModeDePaiement;

                        if(paymentMode == 'Mobile_Money' && (string.isBlank(renewSubRequest.NumeroDeTransaction) || renewSubRequest.NumeroDeTransaction == null)) {
                            listErrors.add(System.label.Transaction_Number_Required);
                        }
                    } else   {
                        listErrors.add(System.label.Invalid_Payment_Method);
                    }

                } else   {
                    listErrors.add(System.label.Payment_Method_Required);
                }

                // check payment methode
                if(renewSubRequest.Type != null && !string.isBlank(renewSubRequest.Type)) {
                    if(setTypeOfRenew.contains(renewSubRequest.Type)) {
                        type = renewSubRequest.Type;
                    } else   {
                        listErrors.add(System.label.Invalid_Renew_Type);
                    }
                } else   {
                    listErrors.add(System.label.Renew_Type_Required);
                }

                // check number of prepaid period
                if(renewSubRequest.Periode != null && !string.isBlank(string.valueOf(renewSubRequest.Periode))) {
                    prepaidPeriod = renewSubRequest.Periode;
                } else   {
                    listErrors.add(System.label.Prepaid_Period_Required);
                }

                // check transaction Number
                if(renewSubRequest.NumeroDeTransaction != null && !string.isBlank(string.valueOf(renewSubRequest.NumeroDeTransaction))) {
                    transactionNb = renewSubRequest.NumeroDeTransaction;
                }
            }
            catch(Exception e) {
                response.Erreurs = new list<string> {e.getMessage()};
                response.Success = false;

                results = JSON.serialize(response, true);
            }

            if(listErrors.size() > 0 && listErrors != null) {
                response.Erreurs = listErrors;
                response.Success = false;
                results = JSON.serialize(response, true);
            } else   {
                Suivi_de_Souscription__c sv = new Suivi_de_Souscription__c();
                BizaoObjects.SuiviDetails svDetail = new BizaoObjects.SuiviDetails();
                if(type == 'Simple') {
                    svDetail.IDSouscription = subId;
                    svDetail.ModeDePaiement = paymentMode;
                    svDetail.NumeroDeTransaction = transactionNb;
                    svDetail.Periode = prepaidPeriod;

                    sv.SV_Id_Souscription__c = subId;
                    // dest SF
                    sv.SV_Destination__c = 'DST002';
                    // reabo simple
                    sv.SV_Code_Action__c = 'ACT003';
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
                    response.Erreurs = listErrors;
                    response.Success = false;

                    results = JSON.serialize(response, true);
                }

            }
        }

        return results;
    }
}