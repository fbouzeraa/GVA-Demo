/*
 * Classe Batch pour activer les abo installé
 */
global class Batch02_Installation implements Database.Batchable<sObject>, Database.AllowsCallouts {
/**
 * Start Method to filter Batch records
 */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //get all suivis of created subscription
        string createdCodeAction = 'ACT001';
        string suiviStatus = 'STA002';
        string pendingStatus = 'Pending Activation';
        string moveCodeAction = 'ACT007';
        string suspendedStatus = 'Suspended';

//SV_Tech_Installation_Termine__c
        return Database.getQueryLocator('SELECT Id,	SV_Date_activation__c, SV_Id_Souscription__c,SV_Reference_Externe__c, SV_Id_Souscription__r.Date_De_RDV_Dinstallation__c,SV_Id_Souscription__r.ExpectedRenewalDate__c,' +
                                        'SV_Id_Souscription__r.Zuora__Account__c,SV_Id_Souscription__r.Etat_De_Linstallation__c, SV_Id_Souscription__r.Zuora__Account__r.ACC_BuildingID__c,SV_Id_Souscription__r.Zuora__SubscriptionNumber__c, ' +
                                        'SV_Id_Souscription__r.Zuora__Account__r.ACC_Escalier__c,SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroDEtage__c,SV_Id_Souscription__r.Zuora__Account__r.ACC_Porte__c, ' +
                                        'SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroPTO_cc__c,SV_Id_Souscription__r.Zuora__Account__r.BillingPostalCode,SV_Id_Souscription__r.SUB_T_Credit_Memo_Id__c,' +
                                        'ownerId, SV_Id_Souscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, SV_Id_Souscription__r.Name, SV_Id_Souscription__r.BoxNumber__c,SV_Id_Souscription__r.Zuora__Status__c, ' +
                                        'createdDate, SV_Id_Souscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,SV_Tech_Installation_Termine__c ' +
                                        ' FROM Suivi_de_Souscription__c' +
                                        ' WHERE SV_Tech_Installation_Termine__c = false AND SV_Id_Souscription__c != null AND SV_Reference_Externe__c != null AND SV_Statut__c =  \'' + String.escapeSingleQuotes(suiviStatus) + '\' AND ' +
                                        ' ((SV_Code_Action__c = \'' + String.escapeSingleQuotes(createdCodeAction) + '\' AND SV_Id_Souscription__r.Zuora__Status__c = \'' + String.escapeSingleQuotes(pendingStatus) + '\') OR ' +
                                        ' (SV_Code_Action__c = \'' + String.escapeSingleQuotes(moveCodeAction) + '\' AND SV_Id_Souscription__r.Zuora__Status__c = \'' + String.escapeSingleQuotes(suspendedStatus) + '\'))');
    }

    global void execute(Database.BatchableContext bc, List<Suivi_de_Souscription__c> listSuivi){

        QueueClass updateJob = new QueueClass(listSuivi);

        System.enqueueJob(new QueueClass(listSuivi));
    }

    global void finish(Database.BatchableContext bc){
        /*     Datetime dt = system.now().addMinutes(30);
             string second ='00';
             string minute = string.valueOf(dt.minute());
             string hour = string.valueOf(dt.hour());
             string day = string.valueOf(dt.day());
             string month = string.valueOf(dt.month());
             string year = string.valueOf(dt.year());
             string schedule = second +' '+minute+' '+hour+' '+day+' '+month+' ? '+year;
             BulkInstallationBatchScheduler intallation = new BulkInstallationBatchScheduler();
             String jobId = System.schedule('Batch02_Installation ', schedule, intallation);*/

    }
}