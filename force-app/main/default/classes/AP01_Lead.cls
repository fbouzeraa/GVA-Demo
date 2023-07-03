/**
 * Classe pour stocker les enrichissements pour Piste.
 *
 * @author Maroun Yazbeck
 * @date 23 Février 2021
 */
public class AP01_Lead {
    /**
     * Methode utilisée pour enrichir les Pistes après la modification du Building ID
     * @param map des Pistes avant et après la modification
     */
    public static void triggerHandler(Map<Id, Lead> mapOfNewLead, Map<Id, Lead> mapOfOldLead){
        Set<Id> leadIds = new Set<Id>();

        // on insert
        if(mapOfOldLead == null) {
            for(Lead piste : mapOfNewLead.values()) {
                leadIds.add(piste.Id);
            }
        } else {
            for(Lead piste : mapOfNewLead.values()) {
                // on update, check if Buildng Id is changed or not.
                if(piste.LEA_IDBatiment__c != mapOfOldLead.get(piste.Id).LEA_IDBatiment__c && piste.LEA_IDBatiment__c != null) {
                    leadIds.add(piste.Id);
                }
            }
        }

        if(leadIds.size() > 0) {
            enrichLeadData(leadIds);
        }
    }

    /**
     * Methode utilisée pour enrichir les données de Piste suivant le Building ID
     * @param Liste des ID de Pistes
     */
    @future(callout = true)
    public static void enrichLeadData(Set<Id> leadIds){
        User currentUser = [SELECT Id, CountryCode
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1 ];
        List<Lead> updatedLeads = new List<Lead>();
        Lead updatedLead;
        // Calling API for just these Leads supplying the Building ID as parameter
        for(Lead piste : [SELECT Id, LEA_Quartier__c, LEA_IDBatiment__c, LEA_Pays__c FROM Lead WHERE Id IN : leadIds]) {
            updatedLead = new Lead();
            updatedLead.Id = piste.Id;
            HttpResponse response = EligibilityManager.doCallout(EligibilityObjects.buildingsAPIUrl + piste.LEA_IDBatiment__c, EligibilityObjects.get, '');
            string jsonObj = response.getBody().replace('\n', ''); // Removing unescaped character if present
            // If the request is successful, parse the JSON response.
            if(response.getStatusCode() == 200) {
                // Deserialize the JSON string
                EligibilityObjects.BuildingsAPIResponse leadInfo = (EligibilityObjects.BuildingsAPIResponse) System.JSON.deserialize(jsonObj, EligibilityObjects.BuildingsAPIResponse.class);
                if(leadInfo != null) {
                    // Remove Foyer suffix if present
                    string currentBuildingID = String.valueOf(piste.LEA_IDBatiment__c);
                    string cleanedBuildingID = currentBuildingID.countMatches('_') > 1 ? currentBuildingID.substring(0, currentBuildingID.lastIndexOf('_')) : currentBuildingID;

                    updatedLead.LEA_IDBatiment__c = currentBuildingID;
                    updatedLead.LEA_Quartier__c = leadInfo.neighborhood;
                    updatedLead.LEA_Pays__c = currentUser.CountryCode;
                    // updatedLead.LEA_LatLong__latitude__s = leadInfo.geom.coordinates[0];
                    // updatedLead.LEA_LatLong__longitude__s = leadInfo.geom.coordinates[1];
                }
            } else {
                // Deserialize the error
                //EligibilityObjects.BuildingsAPIError leadError = (EligibilityObjects.BuildingsAPIError) System.JSON.deserialize(jsonObj, EligibilityObjects.BuildingsAPIError.class);
                // Clear the lead info fields
                updatedLead.LEA_Quartier__c = null;
                updatedLead.LEA_Pays__c = currentUser.CountryCode;
                // updatedLead.LEA_LatLong__latitude__s = null;
                // updatedLead.LEA_LatLong__longitude__s = null;
            }

            updatedLeads.add(updatedLead);
        }

        // Updating the modified Leads in the database
        if(updatedLeads.size() > 0) {
            update updatedLeads;
        }
    }

    public class CustomException extends Exception {}
}