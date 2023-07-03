public with sharing class FooterController {

    private static String getUserCountryCode(Id userId){
        User currentUser = [SELECT Id, CountryCode FROM USER WHERE Id = :userId];
        return currentUser.countryCode;
    }

    private static CountryContactInfo__mdt getCountryContactInfo(String countryCode){
        List<CountryContactInfo__mdt> countryContactInfo = [SELECT  Email__c, Phone__c, Instagram__c, 
                                                                    Facebook__c, Twitter__c, YouTube__c,
                                                                    InstagramMessenger__c, FacebookMessenger__c,
                                                                    TwitterMessenger__c, WhatsApp__c
                                                            FROM CountryContactInfo__mdt 
                                                            WHERE CountryCode__c = :countryCode];
       if(countryContactInfo.size() > 0){
            return countryContactInfo.get(0);
       }
       return null;
    }

    @AuraEnabled(cacheable=true)
    public static FooterWrapperResponse getUserCountryInfo(){
        Id userId = UserInfo.getUserId();
        return new FooterWrapperResponse(userId);
    }

    @TestVisible 
    private class FooterWrapperResponse {

        @AuraEnabled
        public String countryCode{get; set;}

        @AuraEnabled
        public CountryContactInfo__mdt countryContactInfo{get; set;}
        
        FooterWrapperResponse(Id userId){
            this.countryCode = getUserCountryCode(userId);
            this.countryContactInfo = getCountryContactInfo(this.countryCode);
        }
	}
}