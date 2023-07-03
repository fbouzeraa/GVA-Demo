public with sharing class Batch10_SendWelcomeSmsToPortalUser implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private String countryCode;
    private List<Id> userIds;

    public Batch10_SendWelcomeSmsToPortalUser(List<Id> userIds, String countryCode){
        this.countryCode = countryCode;
        this.userIds = userIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client' LIMIT 1];
     
        return Database.getQueryLocator([SELECT Id
                                        FROM User
                                        WHERE ProfileId = :clientPortalProfile.Id
                                        AND Id IN :userIds
                                        AND countryCode = :countryCode]);
                                        // AND CreatedDate > :createdDate
                                        // AND CreatedDate < :createdDate.addDays(1)
                                        
    }

    public void execute(Database.BatchableContext bc, List<User> users){
        UserTriggerHandler.sendWelcomeSmsToClientPortalUsers(users);
    }

    public void finish(Database.BatchableContext bc){
    }
    
}