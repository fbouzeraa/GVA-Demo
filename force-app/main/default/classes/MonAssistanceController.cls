public with sharing class MonAssistanceController {

    private static final Id PERSON_ACCOUNT_RECORD_TYPE_ID =  
                Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
    
    private static final Id CASE_INCIDENT_RECORD_TYPE_ID =  
                Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAS_Incident').getRecordTypeId();

    @AuraEnabled
    public static String createPortalClientCase(String caseInfoWrapperStringify){
        CaseInfoWrapper caseInfoWrapper = (CaseInfoWrapper) JSON.deserialize(caseInfoWrapperStringify, CaseInfoWrapper.class);
        Table_de_routage__c tableDeRoutage = retrieveTableDeRoutage(caseInfoWrapper.ExitCode);
        if (tableDeRoutage == null) return 'Failed';
        Case portalClientCase = createCase(tableDeRoutage, caseInfoWrapper);
        insert portalClientCase;
        return 'Success';     
    }

    private static Case createCase(Table_de_routage__c tableDeRoutage, CaseInfoWrapper caseInfoWrapper){
        Id userId = UserInfo.getUserId();
        return new Case(
            ContactId = retrieveUserContactId(userId),
            AccountId = retrieveUserAccountId(userId),
            RecordTypeId = CASE_INCIDENT_RECORD_TYPE_ID,
            CAS_Exit_Code__c = tableDeRoutage.Name,
            Exit_Code__c = tableDeRoutage.Id,
            CAS_Pays__c = retrieveUserCountryCode(userId),
            CAS_Canal__c = 'Espace Client',
            OwnerId = tableDeRoutage.TDR_FileDAttente__c,
            CAS_Categorie1__c = tableDeRoutage.TDR_Categorie1__c,
            CAS_Categorie2__c = tableDeRoutage.TDR_Categorie2__c,
            CAS_Categorie3__c = tableDeRoutage.TDR_Categorie3__c,
            CAS_Recommandations__c = tableDeRoutage.TDR_Recommandations__c,
            CAS_Impact__c = tableDeRoutage.TDR_Impact__c,
            Type = tableDeRoutage.TDR_Type__c,
            Reason = tableDeRoutage.TDR_Reason__c,
            Description = createCaseDescription(caseInfoWrapper),
            CAS_ExitCodeDiagnostiquant__c = tableDeRoutage.TDR_ExitCodeDiagnostiquant__c,
            Origin = 'Selfcare Espace client'
        );
    }

    private static String createCaseDescription(CaseInfoWrapper caseInfoWrapper){
        if(String.isNotBlank(caseInfoWrapper.Address)){
           return createAddressDescription(caseInfoWrapper);
        }
        if(String.isNotBlank(caseInfoWrapper.Desription)){
            return caseInfoWrapper.Desription;
        }
        return  '';
    }

    private static String createAddressDescription(CaseInfoWrapper caseInfoWrapper){
         return 'New address : ' + caseInfoWrapper.Address 
                + '\n Latitude : ' + caseInfoWrapper.Latitude 
                + '\n Longitude : ' + caseInfoWrapper.Longitude 
                + '\n Moving Date : ' + caseInfoWrapper.movingUnixDate;
    }

    private static Table_de_routage__c retrieveTableDeRoutage(String exitCode){
        
        List<Table_de_routage__c> tableDeRoutage = [SELECT Id, Name, TDR_FileDAttente__c, 
                                                    TDR_Categorie1__c, TDR_Categorie2__c,
                                                    TDR_Categorie3__c, TDR_Recommandations__c,
                                                    TDR_Impact__c, TDR_Type__c, TDR_Reason__c,
                                                    TDR_ExitCodeDiagnostiquant__c
                                                    FROM Table_de_routage__c 
                                                    WHERE Name = :exitCode  
                                                    LIMIT 1];   
        if(tableDeRoutage == null){ return null; }
        if(tableDeRoutage.size() == 0){ return null; }
        return tableDeRoutage[0];
    }

    private static String retrieveUserCountryCode(String userId) {
        return  [SELECT CountryCode FROM User WHERE Id = :userId LIMIT 1].CountryCode;
    }

    private static Id retrieveUserContactId(Id userId){
        return [SELECT Id, ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
    }
        
    private static Id retrieveUserAccountId(Id userId){   
        Id contactId = retrieveUserContactId(userId);
        return [SELECT Id FROM Account WHERE PersonContactId = :contactId 
                                                AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID 
                                                LIMIT 1].Id;
    }


    @TestVisible 
    private class CaseInfoWrapper {

        @AuraEnabled
        public String ExitCode{get; set;}

        @AuraEnabled
        public String Address{get; set;}

        @AuraEnabled
        public Double Latitude{get; set;}

        @AuraEnabled
        public Double Longitude{get; set;}

        @AuraEnabled
        public String MovingUnixDate{get; set;}

        @AuraEnabled
        public String Desription{get; set;}

        @TestVisible
        CaseInfoWrapper(String exitCode, String address, Double latitude, Double longitude, String movingUnixDate,  String desription){
            this.exitCode = exitCode;
            this.address = address;
            this.latitude = latitude;
            this.longitude = longitude;
            this.movingUnixDate = movingUnixDate;
            this.desription = desription;
        }

	}

}