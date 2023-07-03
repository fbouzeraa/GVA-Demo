@RestResource(urlMapping = '/v1/suivis/*')
global class WS01_SuiviCommandeAPI {

    /* Methode permettant GVAdmin de faire un appel à Salesforce via API pour demander
     * la liste des Suivis non traités
     * @return Liste des Suivis de Commande non traités
     * */
    @HttpPost
    global static List<Suivi_de_Souscription__c> doGet() {
        RestRequest req = RestContext.request;

        System.debug(RestContext.request.requestBody.toString());
        SuiviObjects.SuivisListRequest suiviRequest = (SuiviObjects.SuivisListRequest) JSON.deserialize(RestContext.request.requestBody.toString(), SuiviObjects.SuivisListRequest.class);

        //RestResponse res = RestContext.response;
        List<Suivi_de_Souscription__c> results = new List<Suivi_de_Souscription__c>();

        // Check if Object is accessible by calling user.
        // Get all Suivis that are "A traiter" and have destination "GVAdmin"
        if(Schema.sObjectType.Suivi_de_Souscription__c.isAccessible()) {
            String query = 'SELECT ID, Name, SV_Box_Number__c, SV_Code_Action__c, SV_Date_Action__c, SV_Id_Souscription__c, SV_Pays__c, SV_PTO__c, SV_Statut__c,';
            query += 'SV_Valeur_Apres__c, SV_Valeur_Avant__c, SV_Code_Souscription__c, SV_Statut_Souscription__c, SV_Reference_Externe__c';
            query += ' FROM Suivi_de_Souscription__c';
            query += ' WHERE SV_Statut__c = \'STA001\'';
            query += ' AND SV_Destination__c = \'DST001\'';
            query += ' AND SV_Code_Action__c != \'ACT011\'';
            query += ' AND SV_Id_Souscription__r.Zuora__Account__r.RecordType.DeveloperName != \'ACC_ComptePartenaire\'';

            System.debug('query' + query);
            // Add filters for Actions
            if(suiviRequest.Actions != null && suiviRequest.Actions.size() > 0) {
                List<String> actions = suiviRequest.Actions;
                query += ' AND SV_Code_Action__c IN :actions';
            }

            // Add filters for Pays
            if(suiviRequest.Pays != null && suiviRequest.Pays.size() > 0) {
                List<String> pays = suiviRequest.Pays;
                query += ' AND SV_Pays__c IN :pays';
            }

            query += ' ORDER BY Name ASC';
            results = Database.query(query);
        }

        return results;
    }

    /* Méthode permettant GVAdmin de fair un appel via API à Salesforce pour mettre à jour
     *  l'état du Suivi de Souscription à 'Traité'
     * @return Retourne le résultat des mises à jour
     * */
    @HttpPatch
    global static List<SuiviObjects.SuiviUpdateResponse> doUpdate() {
        RestRequest req = RestContext.request;
        list<id> listSuiviId = new list<id>();
        try {
            List<SuiviObjects.SuivisUpdateRequest> updateRequestList = (List<SuiviObjects.SuivisUpdateRequest>) System.JSON.deserialize(RestContext.request.requestBody.toString(), List<SuiviObjects.SuivisUpdateRequest> .class);

            Map<Id, String> mapSuiviToRefExterne = new Map<Id, String>();
            List<Suivi_de_Souscription__c> updatedSuivis = new List<Suivi_de_Souscription__c>();
            List<SuiviObjects.SuiviUpdateResponse> results = new List<SuiviObjects.SuiviUpdateResponse>();

            if(updateRequestList != null && updateRequestList.size() > 0) {
                for(SuiviObjects.SuivisUpdateRequest upReq : updateRequestList) {
                    mapSuiviToRefExterne.put(id.valueOf(upReq.ID), upReq.referenceexterne);
                }
            }
            listSuiviId.addAll(mapSuiviToRefExterne.keySet());
            for(Id suiviID : mapSuiviToRefExterne.keySet()) {
                Suivi_de_Souscription__c updatedRecord = new Suivi_de_Souscription__c();
                updatedRecord.Id = suiviID;
                updatedRecord.SV_Statut__c = 'STA002';  // Traité
                updatedRecord.SV_Reference_Externe__c = mapSuiviToRefExterne.get(suiviID);

                updatedSuivis.add(updatedRecord);

            }

            if(updatedSuivis.size() > 0) {
                List<Database.SaveResult> updateResults = Database.update(updatedSuivis, false);
                for(Integer i = 0; i < updateResults.size(); i++) {

                    SuiviObjects.SuiviUpdateResponse updateResponse = new SuiviObjects.SuiviUpdateResponse();
                    updateResponse.updatedSuivi = new Suivi_de_Souscription__c(Id = updateResults.get(i).getId());

                    if(updateResults.get(i).isSuccess()) {
                        updateResponse.success = true;

                    } else if(!updateResults.get(i).isSuccess()) {
                        // DML operation failed
                        updateResponse.success = false;

                        updateResponse.errors = new List<String>();
                        for(Database.Error error : updateResults.get(i).getErrors()) {
                            updateResponse.errors.add(error.getMessage());
                        }
                    }
                    results.add(updateResponse);
                }
            }

            return results;
        }
        catch(exception error) {
            insert AP01_ErreurInterface.insertError(error.getTypeName(), error.getCause() == null?null : error.getCause().getMessage(), error.getLineNumber(), error.getMessage(), String.join(listSuiviId, ','), 'doUpdate');

            System.debug('Error from Suivi de Souscription Update RestAPI ' + error.getMessage());
            SuiviObjects.SuiviUpdateResponse errorResponse = new SuiviObjects.SuiviUpdateResponse();
            errorResponse.success = false;
            errorResponse.errors = new List<String>();
            errorResponse.errors.add(error.getMessage());

            List<SuiviObjects.SuiviUpdateResponse> results = new List<SuiviObjects.SuiviUpdateResponse>();
            results.add(errorResponse);

            return results;
        }
    }
}