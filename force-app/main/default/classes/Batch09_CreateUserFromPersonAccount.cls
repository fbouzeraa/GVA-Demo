public with sharing class Batch09_CreateUserFromPersonAccount implements Database.Batchable<sObject> {

    private String countryCode;
    private List<Id> accountIds;
    
    public Batch09_CreateUserFromPersonAccount(List<Id> accountIds, String countryCode){
        this.countryCode = countryCode;
        this.accountIds = accountIds;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
        return Database.getQueryLocator([SELECT Id, FirstName, MiddleName, LastName, Suffix, PersonContactId, 
                                            PersonEmail, CurrencyIsoCode, BillingCity, BillingState, 
                                            BillingStreet, BillingPostalCode, BillingCountry, BillingCountryCode, 
                                            PersonMobilePhone, Phone, ACC_Indicatif__c, ACC_LatLong__Latitude__s,
                                             ACC_LatLong__Longitude__s 
                                        FROM Account
                                        WHERE BillingCountryCode = :countryCode
                                        AND IsPersonAccount = true
                                        AND RecordTypeId = :personAccountId
                                        AND Id IN :accountIds]);
    }

    public void execute(Database.BatchableContext bc, List<Account> personAccounts){
        Map<Id, Set<Zuora__Subscription__c>> accountToZuoraSubscription = CreateUserHandler.getAccountToZuoraSubscription(personAccounts);
        Set<Account> personAccountsWithAtLeastOneSubcription = getAccountsAtLeastOneSubscription(personAccounts, accountToZuoraSubscription);
        List<User> users = CreateUserHandler.createUsers(personAccountsWithAtLeastOneSubcription);
        List<Database.UpsertResult> upsertResults = Database.upsert(users, User.Username, false);
        System.debug('upsertResult : ' + upsertResults);
    }

    private static Set<Account> getAccountsAtLeastOneSubscription(List<Account> accts, Map<Id, Set<Zuora__Subscription__c>> accountToZuoraSubscription){
        Set<Account> acctsWithSingleSubscription = new Set<Account>();
        for(Account acct : accts) {
            Set<Zuora__Subscription__c> zuoraSubscriptions = accountToZuoraSubscription.get(acct.Id);
             if(zuoraSubscriptions != null && zuoraSubscriptions.size() > 0) {
                acctsWithSingleSubscription.add(acct);
             }
        }
        return acctsWithSingleSubscription;
    }

    public void finish(Database.BatchableContext bc){
        System.debug('bc : ' + bc);
        // execute any post-processing operations
    }

}