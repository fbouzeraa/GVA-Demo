/*
 * Classe Batch pour créer des verifier l'installation des boxes
 */
global class Batch05_RetryErrors implements Database.Batchable<sObject>, Database.AllowsCallouts {
/**
 * Start Method to filter Batch records
 */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        string zuoraInterface = 'Zuora';

        // get all zuora error logs created today
        return Database.getQueryLocator('SELECT LG_Method_Type__c, LG_Method_URL__c, LG_Body__c, LG_Error_Solved__c,LG_Account__c, LG_Subscription_Number__c, LG_Subscription__c ' +
                                        ' FROM Log__c' +
                                        ' WHERE LG_Interface__c = \'' + String.escapeSingleQuotes(zuoraInterface) + '\' AND LG_Success__c = false AND CreatedDate = TODAY AND LG_Retry__c = true');
    }

    global void execute(Database.BatchableContext bc, List<Log__c> listLogs){
        List<Log__c> listSolvedLogs = new List<Log__c>();
        List<Id> listSolvedLogsID = new List<Id>();
        for(Log__c log : listLogs) {
            HttpResponse response = ZuoraManager.doCallout(log.LG_Method_URL__c, log.LG_Method_Type__c, log.LG_Body__c.replaceAll('&quot;', '"'));
            Map<String, Object> responseMap =   (Map<String, Object>) JSON.deserializeUntyped(response.getBody().toLowerCase());
            system.debug((boolean)responseMap.get('success'));
            if((boolean)responseMap.get('success')) {
                // log__c lg = new log__c();
                // lg.Id = log.Id;
                // lg.LG_Error_Solved__c = true;
                listSolvedLogsID.add(log.Id);
            }

        }

        if(listSolvedLogsID.size() > 0 && listSolvedLogsID != null) {
            for(id logId : listSolvedLogsID) {
                log__c lg = new log__c();
                lg.Id = logId;
                lg.LG_Error_Solved__c = true;
                listSolvedLogs.add(lg);
            }
            system.debug(listSolvedLogs);
            update listSolvedLogs;
        }
    }

    global void finish(Database.BatchableContext bc){}
}