/**
 * Test Classe : WS04_BizaoValidationAPI_Test
 * @author Yara Bourdoukan
 * @date 2021-10-21
 */
@RestResource(urlMapping = '/v1/Validation/*')
global class WS04_BizaoValidationAPI {

    /* Methode permettant Bizao de faire un appel à Salesforce via API
     * pour assurer que le compte est valide
     * @return string
     * */
    @HttpPost
    global static string doGet() {
        RestRequest req = RestContext.request;

        BizaoObjects.ValidAccountRequest subscriptionRequest = (BizaoObjects.ValidAccountRequest) JSON.deserialize(RestContext.request.requestBody.toString(), BizaoObjects.ValidAccountRequest.class);

        //RestResponse res = RestContext.response;
        BizaoObjects.ValidAccountResponse response = new BizaoObjects.ValidAccountResponse();

        string results;

        // list of required status
        list<string> listSubStatus = new list<string> {'Active', 'Suspended'};

        // Subscription base product type
        string productType = 'Recurring';

        String paymentMode;
        integer prepaidPeriod;
        double totalAmount;
        String productName;

        // list of errors
        list<string> listErrors = new list<String>();

        //set of available base product
        set<string> setAvailableProduct = new set<string>();

        set<string> setAvailablePaymentMode = new set<string>();
        // Check if Object is accessible by calling user.
        try {

            if(Schema.sObjectType.Zuora__Subscription__c.isAccessible()) {
                String query = 'SELECT Zuora__RatePlanName__c,Zuora__Subscription__c ';
                query += ' FROM Zuora__SubscriptionProductCharge__c';
                query += ' WHERE Zuora__Subscription__r.Zuora__Status__c IN :listSubStatus  AND Zuora__Type__c = :productType ';

                //get payment mode
                Schema.DescribeFieldResult fieldResult = Quote.QUO_Mode_De_Paiement__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for(Schema.PicklistEntry pickListVal : ple) {
                    setAvailablePaymentMode.add(pickListVal.getValue());
                }
                // Add Last Name filter
                if(subscriptionRequest.Nom != null && !string.isBlank(subscriptionRequest.Nom)) {
                    String lastName = subscriptionRequest.Nom;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.LastName = :lastName';
                } else   {
                    listErrors.add(system.label.Last_Name_Required);
                }

                // Add First Name filter
                if(subscriptionRequest.Prenom != null && !string.isBlank(subscriptionRequest.Prenom)) {
                    String firstName = subscriptionRequest.Prenom;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.FirstName = :firstName';
                } else   {
                    listErrors.add(System.label.First_Name_Required);
                }

                // Add country filter
                if(subscriptionRequest.Pays != null && !string.isBlank(subscriptionRequest.Pays)) {
                    String country = subscriptionRequest.Pays;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.BillingCountry = :country';

                    string product = '%' + country;
                    list<zqu__ProductRatePlan__c> baseProducts = [SELECT Name
                                                                  FROM zqu__ProductRatePlan__c
                                                                  WHERE type__c = 'Base' AND zqu__Product__r.Name like :product];
                    for(zqu__ProductRatePlan__c prod : baseProducts) {
                        setAvailableProduct.add(prod.Name);
                    }
                } else   {
                    listErrors.add(System.label.Country_Required);
                }

                // Add city filter
                if(subscriptionRequest.Ville != null && !string.isBlank(subscriptionRequest.Ville)) {
                    String city = subscriptionRequest.Ville;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.BillingCity = :city';
                }

                // Add box number filter
                if(subscriptionRequest.Routeur != null && !string.isBlank(subscriptionRequest.Routeur)) {
                    String boxNumber = subscriptionRequest.Routeur;
                    query += ' AND Zuora__Subscription__r.BoxNumber__c = :boxNumber';
                } else   {
                    listErrors.add(System.label.Box_Number_Required);
                }

                // Add phone filter
                if(subscriptionRequest.Telephone != null && !string.isBlank(subscriptionRequest.Telephone)) {
                    String landLine = subscriptionRequest.Telephone;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.Phone = :landLine';
                }

                // Add mobile filter
                if(subscriptionRequest.Mobile != null && !string.isBlank(subscriptionRequest.Mobile)) {
                    String mobilePhone = subscriptionRequest.Mobile;
                    query += ' AND Zuora__Subscription__r.Zuora__Account__r.PersonMobilePhone = :mobilePhone';
                }

                // Add product name filter
                if(subscriptionRequest.Produit != null && !string.isBlank(subscriptionRequest.Produit)) {
                    if(setAvailableProduct.contains(productName)) {
                        productName = subscriptionRequest.Produit;
                    } else   {
                        listErrors.add(System.label.Base_Product_Name);
                    }
                } else   {
                    listErrors.add(System.label.Product_Required);
                }

                // check payment method
                if(subscriptionRequest.ModeDePaiement != null && !string.isBlank(subscriptionRequest.ModeDePaiement)) {
                    if(setAvailablePaymentMode.contains(subscriptionRequest.ModeDePaiement)) {
                        paymentMode = subscriptionRequest.ModeDePaiement;
                    } else   {
                        listErrors.add(System.label.Invalid_Payment_Method);
                    }
                } else   {
                    listErrors.add(System.label.Payment_Method_Required);
                }

                // check number of prepayed period
                if(subscriptionRequest.Periode != null && !string.isBlank(string.valueOf(subscriptionRequest.Periode))) {
                    prepaidPeriod = subscriptionRequest.Periode;
                } else   {
                    listErrors.add(System.label.Prepaid_Period_Required);
                }

                // check total amount
                if(subscriptionRequest.SommeTotale != null && !string.isBlank(string.valueOf(subscriptionRequest.SommeTotale))) {
                    totalAmount = subscriptionRequest.SommeTotale;
                } else   {
                    listErrors.add(System.label.Amount_Required);
                }

                if(listErrors.size() > 0 && listErrors != null) {
                    response.Erreurs = listErrors;
                    response.Success = false;
                    results = JSON.serialize(response, true);
                } else   {
                    system.debug(query);
                    List<Zuora__SubscriptionProductCharge__c> listSub =  Database.query(query);

                    if(listSub.size() > 0 && listSub != null) {
                        // for simple renew product name should be the same of the existing Prod
                        if(listSub[0].Zuora__RatePlanName__c == productName) {
                            // call preview sub to get the needed amount for this action without tax
                            string previewResult = SubscriptionRenewalActions.renewSubPreview(listSub[0].Zuora__Subscription__c, prepaidPeriod, true, paymentMode, false, null);

                            ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                                previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                            double currentAmount = preview.previewResult.invoices[0].amount;
                            if(currentAmount == totalAmount) {
                                response.Success = true;
                                response.Valide = true;
                                response.IDSouscription = listSub[0].Zuora__Subscription__c;
                                response.ProduitDeBase = listSub[0].Zuora__RatePlanName__c;
                                response.type = 'Simple';
                                results = JSON.serialize(response, true);
                            } else   {
                                listErrors.add('La somme totale ' + totalAmount + ' est différente de la somme réelle ' + currentAmount);
                                response.Erreurs = listErrors;
                                response.Success = false;
                                results = JSON.serialize(response, true);
                            }
                        }

                    } else   {
                        response.Success = true;
                        response.Valide = false;
                        results = JSON.serialize(response, true);
                    }
                }
            }

            return results;
        }
        catch(Exception e) {
            response.Erreurs = new list<string> {e.getMessage()};
            response.Success = false;
            results = JSON.serialize(response, true);

            return results;
        }

    }

}