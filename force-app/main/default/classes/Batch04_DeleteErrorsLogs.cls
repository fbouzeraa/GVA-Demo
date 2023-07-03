/*
 * Classe Batch pour créer pour supprimer les logs et les erreurs d'interface
 */
global class Batch04_DeleteErrorsLogs implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        //get logs records created in last 15 days
        date last15days = date.today().addDays(-15);

        return Database.getQueryLocator('SELECT Id, Name ' +
                                        'FROM Log__c ' +
                                        'WHERE createdDate <= :last15days');
    }

    global void execute(Database.BatchableContext bc, List<Log__c> records){

        if(records != null && records.size() > 0) {
//add try catch
            delete records;
            date last15days = date.today().addDays(-15);
            //get Errors records created in last 15 days
            list<Erreur_de_Interface__c> listError = [SELECT Id, Name
                                                      FROM Erreur_de_Interface__c
                                                      WHERE createdDate <= :last15days];
            if(listError.size() > 0 && listError != null)
                delete listError;

        }

    }

    global void finish(Database.BatchableContext bc){}
}