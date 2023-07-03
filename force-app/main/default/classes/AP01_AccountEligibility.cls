/**
 * Classe pour stocker les résultats du test d'éligibilité.
 *
 * @author Yara Bourdoukan
 * @date 28 Novembre 2020
 */
public class AP01_AccountEligibility {
    /**
     * Methode utilisée pour verifier si le compte est eligible apres la modification du building id
     * @param map des comptes avant et apres la modification
     */
    // (Cette methode est fusionner avec autre dans AP01_AccounttriggerHandler)
        // public static void triggerHandler(Map<Id, Account> mapOfNewAccount, Map<Id, Account> mapOfOldAccount){
        //     //map<string,Id> mapAccountsToCheck = new map<string, Id>();
        //     Set<Id> accountIds = new Set<Id>();
        //     //get record type id of personal account
        //     //Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();

        //     // on insert
        //     if(mapOfOldAccount == null) {
        //         for(Account acc : mapOfNewAccount.values()) {
        //             //acc.RecordTypeId == recordTypeId &&
        //             if((acc.ACC_BuildingID__c != null && !string.IsBlank(acc.ACC_BuildingID__c))) {
        //                 //mapAccountsToCheck.put(acc.ACC_BuildingID__c, acc.Id);
        //                 accountIds.add(acc.Id);
        //             }
        //         }
        //     } else {

        //         for(Account acc : mapOfNewAccount.values()) {
        //             // if(acc.RecordTypeId == recordTypeId) {

        //             // on update, check if Buildng Id is changed or not.
        //             if(acc.ACC_BuildingID__c != mapOfOldAccount.get(acc.Id).ACC_BuildingID__c && acc.ACC_BuildingID__c != null) {
        //                 //mapAccountsToCheck.put(acc.ACC_BuildingID__c, acc.Id);
        //                 accountIds.add(acc.Id);
        //             }
        //             // }
        //         }
        //     }
        //     if(accountIds.size() > 0 && accountIds != null) {
        //         checkEligibility(accountIds);
        //         enrichAccountData(accountIds);
        //     }
        // }

    @AuraEnabled
    public static void fillAccountFields(String accountId){
        Account currentAccount = [SELECT Id, Name, ACC_BuildingID__c FROM Account WHERE Id =:accountId];
        if(currentAccount != null && !String.isBlank(currentAccount.ACC_BuildingID__c)) {
            checkEligibility(new Set<Id> {Id.valueOf(accountId)});
        }
    }

    /**
     * Methode utilisée pour vérifier l'éligibilité du Compte suivant le Building ID
     * @param Liste des ID de Compte
     */
    @future(callout = true)
    public static void checkEligibility(Set<Id> accountIds){

        List<Account> updatedAccounts = new List<Account>();
        Account updatedAccount;
        String currentBuildingID;
        String cleanedBuildingID;

        try {

            // Calling API for just these Accounts supplying the Building ID as parameter
            for(Account act : [SELECT Id, ACC_BuildingID__c FROM Account WHERE Id IN : accountIds]) {
                
                // Update Account after result
                updatedAccount = new Account();
                updatedAccount.Id = act.Id;

                // Remove Foyer suffix if present before calling the Eligibility API
                currentBuildingID = String.valueOf(act.ACC_BuildingID__c);

                cleanedBuildingID = currentBuildingID.countMatches('_') > 1 ? currentBuildingID.substring(0, currentBuildingID.lastIndexOf('_')) : currentBuildingID;

                HttpResponse response = EligibilityManager.doCallout(EligibilityObjects.rawFeasibilityAPIUrl, EligibilityObjects.post, '{"building_id":"' + cleanedBuildingID + '"}');
                string jsonObj = response.getBody();

                // If the request is successful, parse the JSON response.
                if(response.getStatusCode() == 200) {
                    // Deserialize the JSON string
                    EligibilityObjects.FeasibilityAPIResponse feasibilityInfo = (EligibilityObjects.FeasibilityAPIResponse) System.JSON.deserialize(jsonObj, EligibilityObjects.FeasibilityAPIResponse.class);
                    if(feasibilityInfo != null) {

                        updatedAccount.ACC_Alerte__c = feasibilityInfo.info.message;
                        updatedAccount.ACC_Eligible__c = feasibilityInfo.feasible;
                        updatedAccount.ACC_Date_Dernier_Test__c = System.now();
                    }
                } else {
                    // Deserialize the error
                    EligibilityObjects.FeasiblityError feasibilityError = (EligibilityObjects.FeasiblityError) System.JSON.deserialize(jsonObj, EligibilityObjects.FeasiblityError.class);
                    if(feasibilityError != null && feasibilityError.errors[0] != null){
                        updatedAccount.ACC_Alerte__c = feasibilityError.errors[0];
                    }
                    updatedAccount.ACC_Eligible__c = false;
                    updatedAccount.ACC_Date_Dernier_Test__c = System.now();
                }

                updatedAccounts.add(updatedAccount);
            }
        } catch (Exception e) {
            system.debug('checkelig error '+e.getLineNumber()+' >>> '+e.getMessage());
        }
        // Updating the modified Accounts in the database
        if(updatedAccounts.size() > 0) {
            try {
                update updatedAccounts;
            }catch(Exception e) {
                system.debug(e.getMessage());
            }

        }
    }

    /**
     * Methode utilisée pour enrichir les données du Compte suivant le Building ID
     * @param Liste des ID de Compte
     */
    @future(callout = true)
    public static void enrichAccountData(Set<Id> accountIds){

        List<Account> updatedAccounts = new List<Account>();
        String currentBuildingID;
        String cleanedBuildingID;

        // Calling API for just these Accounts supplying the Building ID as parameter
        for(Account act : [SELECT Id, QU_Quartier__c, ACC_LatLong__c,  ACC_BuildingID__c, ACC_NumeroDEtage__c, RecordType.DeveloperName FROM Account WHERE Id IN : accountIds]) {
            
            // Remove Foyer suffix if present before calling the Eligibility API
            currentBuildingID = String.valueOf(act.ACC_BuildingID__c);
            cleanedBuildingID = currentBuildingID.countMatches('_') > 1 ? currentBuildingID.substring(0, currentBuildingID.lastIndexOf('_')) : currentBuildingID;

            HttpResponse response = EligibilityManager.doCallout(EligibilityObjects.buildingsAPIUrl + cleanedBuildingID, EligibilityObjects.get, '');
            string jsonObj = response.getBody().replace('\n', ''); // Removing unescaped character if present
            
            // If the request is successful, parse the JSON response.
            if(response.getStatusCode() == 200) {
                // Deserialize the JSON string
                EligibilityObjects.BuildingsAPIResponse accountInfo = (EligibilityObjects.BuildingsAPIResponse) System.JSON.deserialize(jsonObj, EligibilityObjects.BuildingsAPIResponse.class);
                if(accountInfo != null) {
                    act.QU_Quartier__c = accountInfo.neighborhood;
                    act.ACC_LatLong__latitude__s = accountInfo.geom.coordinates[0];
                    act.ACC_LatLong__longitude__s = accountInfo.geom.coordinates[1];
                    if(act.RecordType.DeveloperName != System.Label.Personal_Account_RecordType){
                        act.ACC_NumeroDEtage__c = accountInfo.nb_floors;
                    }
                }
            } else {
                // Deserialize the error
                //EligibilityObjects.BuildingsAPIError accountError = (EligibilityObjects.BuildingsAPIError) System.JSON.deserialize(jsonObj, EligibilityObjects.BuildingsAPIError.class);
                // Clear the account info fields
                act.QU_Quartier__c = null;
                act.ACC_LatLong__latitude__s = null;
                act.ACC_LatLong__longitude__s = null;
                if(act.RecordType.DeveloperName != System.Label.Personal_Account_RecordType){
                    act.ACC_NumeroDEtage__c = null;
                }
            }

            updatedAccounts.add(act);
        }

        // Updating the modified Accounts in the database
        if(updatedAccounts.size() > 0) {
            update updatedAccounts;
        }
    }

    public class CustomException extends Exception {
        /// commit test
    }
}