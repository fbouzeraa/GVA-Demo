@RestResource(urlMapping = '/v1/suivis/details/*')
global class WS02_SuiviCommandeAPIDetails {
    /* Methode permettant GVAdmin de faire un appel à Salesforce via API pour demander
     * des details sur une ou plusieurs suivi de souscription
     * @return object SuiviDetails
     * */
    @HttpPost
    global static list<string> doGet() {

        list<string> listResponse = new list<String>();

        //Prepare response
        SuiviObjects.SuivisDetailsRequest suiviRequest = (SuiviObjects.SuivisDetailsRequest) JSON.deserialize(RestContext.request.requestBody.toString(), SuiviObjects.SuivisDetailsRequest.class);
        if(suiviRequest.ID != null && suiviRequest.ID.size() > 0) {

            // separate IDs as valid and Invalid structure
            set<Id> SuivisIds = new Set<Id>();
            set<string> invalidIds = new Set<string>();

            for(string requestedId : suiviRequest.ID) {
                if(Pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}').matcher(requestedId).matches()) {
                    SuivisIds.add(requestedId);
                } else {
                    invalidIds.add(requestedId);
                }
            }

            string queryError;
            // get suivi record for valid id structure
            if(SuivisIds != null && SuivisIds.size() > 0) {
                list<Suivi_de_Souscription__c> listSuivi = new list<Suivi_de_Souscription__c>();

                try {
                    listSuivi = [SELECT SV_Id_Souscription__r.Zuora__Account__c, SV_Details__c, SV_Code_Action__c,
                                 CreatedDate, SV_Id_Souscription__r.BoxNumber__c, SV_Reference_Externe__c, SV_Mode_de_paiement__c,
                                 SV_Id_Souscription__r.Quote__c, SV_Id_Souscription__c, SV_Code_Souscription__c, SV_Box_Number__c,
                                 SV_Statut_Souscription__c, SV_Ancienne_offre__c, SV_Nouvelle_offre__c, SV_Id_Souscription__r.Zuora__Account__r.BillingCOuntryCode
                                 FROM Suivi_de_Souscription__c
                                 WHERE id IN :SuivisIds AND SV_Id_Souscription__c != null];

                }
                catch(QueryException QE) {
                    queryError = QE.getMessage();
                    system.debug(queryError);
                }

                // 'ACT001' (Creation) -- 'ACT002' (suspend) -- 'ACT005' (getting new Box) -- 'ACT006' (changing the old box) -- 'ACT007' (changing account address) -- 'ACT009' (resiliation) --  
                if(listSuivi.size() > 0 && listSuivi != null) 
                {
                    for(Suivi_de_Souscription__c suivi : listSuivi) 
                    {
                        SuiviObjects.suiviDetailsResponse currentSuivi = new SuiviObjects.suiviDetailsResponse();
                        SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
                        if(suivi.SV_Details__c != null)
                        {
                            // get the info already existing on the suivi
                            currentSuivi = (SuiviObjects.suiviDetailsResponse) JSON.deserialize(suivi.SV_Details__c, SuiviObjects.suiviDetailsResponse.class);
                            if(currentSuivi.Service != null)
                            {
                                Service = currentSuivi.Service;
                            }
                        }
                        currentSuivi.id = suivi.id;
                        currentSuivi.success = true;
                        currentSuivi.statutSouscription = suivi.SV_Statut_Souscription__c;

                        if(suivi.SV_Code_Action__c != 'ACT001' && suivi.SV_Code_Action__c != 'ACT007')
                        {
                            currentSuivi.IDSouscription = suivi.SV_Id_Souscription__c;
                            currentSuivi.codeSouscription = suivi.SV_Code_Souscription__c;
                        }
                        if(suivi.SV_Reference_Externe__c != null){
                            service.referenceServiceGVAdmin = suivi.SV_Reference_Externe__c;
                        }

                        switch on suivi.SV_Code_Action__c {
                            // on renew & on upgrade or downgrade 
                            when 'ACT003', 'ACT004'
                            {
                                currentSuivi.modeDePaiement = suivi.SV_Mode_de_paiement__c;
                            }
                            // on adding complementary prod 
                            when 'ACT008'
                            {
                                service.DateSouhaitee  = suivi.CreatedDate.format('yyyy-MM-dd');
                            }
                        }
                        currentSuivi.service = service;
                        listResponse.add(JSON.serialize(currentSuivi, true));
                    }
                    // for requests that contains valid and invalid id structure
                    if(invalidIds.size() > 0 && invalidIds != null) {
                        for(string wrongId : invalidIds) {
                            SuiviObjects.suiviDetailsError wrongSuivi = new SuiviObjects.suiviDetailsError ();
                            wrongSuivi.success = false;
                            wrongSuivi.id = wrongId;
                            wrongSuivi.errors = new list<string> {System.Label.Invalid_Id};

                            listResponse.add(JSON.serialize(wrongSuivi, true));
                        }
                    }
                }
            } else {
                // Id length != 15 or 18
                for(string wrongId : invalidIds) {
                    SuiviObjects.suiviDetailsError currentSuivi = new SuiviObjects.suiviDetailsError ();
                    currentSuivi.success = false;
                    currentSuivi.id = wrongId;
                    currentSuivi.errors = new list<string> {System.Label.Invalid_Id};
                    listResponse.add(JSON.serialize(currentSuivi, true));
                }
            }
        // request of empty body
        } else {
            SuiviObjects.suiviDetailsError currentSuivi = new SuiviObjects.suiviDetailsError ();
            currentSuivi.success = false;
            currentSuivi.errors = new list<string> {System.Label.Empty_list_of_ID};
            listResponse.add(JSON.serialize(currentSuivi, true));
        }

        return listResponse;
    }

}