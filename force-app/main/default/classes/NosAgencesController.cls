public with sharing class NosAgencesController {


    @AuraEnabled(cacheable=true)
    public static List<Agency__mdt> getCurrentUserCountryAgencies() {

        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, CountryCode FROM USER WHERE Id = :currentUserId];
        String currentUserCountryCode = currentUser.countryCode;

        List<Agency__mdt> agencies = [SELECT Id, MasterLabel, Street__c, PostalCode__c, 
                                            City__c , CountryCode__c, Phone__c, 
                                            Latitude__c, Longitude__c
                                      FROM Agency__mdt
                                      WHERE CountryCode__c = :currentUserCountryCode];
        return agencies;
    }

}