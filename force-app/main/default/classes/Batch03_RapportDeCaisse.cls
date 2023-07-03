/*
 * Classe Batch pour envoyer le rapport de caisse
 */
global class Batch03_RapportDeCaisse implements Database.Batchable<sObject>, Database.AllowsCallouts {
    /**
     * Start Method to filter Batch records
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //get all users having distributor
        string query = 'SELECT USR_DistributeurID__c,Email,CountryCode FROM user WHERE USR_DistributeurID__c != null' + (Test.isRunningTest()?' LIMIT 1' : '');

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<User> listUser){

        QueueFund updateJob = new QueueFund(listUser);

        System.enqueueJob(new QueueFund(listUser));
    }

    global void finish(Database.BatchableContext bc){}
}