public with sharing class Batch08_SuiviGVAdmin implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id,Name,CurrencyIsoCode,SV_Statut__c,SV_Reference_Externe__c,LastModifiedDate,SV_Id_Souscription__c,SV_Id_Souscription__r.Suivi_de_installation__c ' +
                                        'FROM Suivi_de_Souscription__c WHERE SV_Reference_Externe__c != null AND SV_Statut__c = \'STA002\' AND (LastModifiedDate = LAST_N_DAYS: 1 OR SV_T_GVAStatusKO__c = true)');
    }

    public void execute(Database.BatchableContext BC, list<Suivi_de_Souscription__c> listOfSuivi){

        List<Zuora__Subscription__c> listOfSubToUpdate = new List<Zuora__Subscription__c>();
        List<Suivi_de_Souscription__c> listOfSuiviToUpdate = new List<Suivi_de_Souscription__c>();

        for(Suivi_de_Souscription__c suivi : listOfSuivi) {

            CanalBoxObjects.Orders order = new CanalBoxObjects.Orders();
            order.order_ref = suivi.SV_Reference_Externe__c;

            // call installation API to check statutGVAdmin
            HttpResponse installationResponse = CanalBoxManager.boxInstallation(order);
            CanalBoxObjects.OrderResponse orderResponse = new CanalBoxObjects.OrderResponse();
            orderResponse = (CanalBoxObjects.OrderResponse)JSON.deserialize(installationResponse.getBody(), CanalBoxObjects.OrderResponse.class);
            // successed order
            if(installationResponse.getStatusCode() == 200) {
                if(orderResponse.services != null && orderResponse.services.size() > 0) {
                    system.debug('services ' + orderResponse.services);
                    for(CanalBoxObjects.OrderServiceItemResponse service : orderResponse.services) {
                        date installationDate = null;
                        // get the subscription of this Suivi
                        Zuora__Subscription__c sub = new Zuora__Subscription__c();
                        sub.Id = suivi.SV_Id_Souscription__c;
                        if(service.pxo_date_rdv != null && !string.isBlank(string.valueOf(service.pxo_date_rdv))) {

                            installationDate = date.valueOf(service.pxo_date_rdv);
                        }
                        sub.Date_De_RDV_Dinstallation__c = installationDate;
                        sub.Etat_De_Linstallation__c = service.status;
                        sub.SUB_Ref_service__c =  service.service_ref;
                        // update Statut and Resultat on Zuora__Subscription__c
                        if(service.suivi != null && !service.suivi.contains('KO')) {
                            sub.Suivi_de_installation__c = service.suivi;
                            listOfSubToUpdate.add(sub);
                            suivi.SV_T_GVAStatusKO__c = false;
                            listOfSuiviToUpdate.add(suivi);
                        } else if(service.suivi.contains('KO')) {
                            sub.Suivi_de_installation__c = service.suivi;
                            listOfSubToUpdate.add(sub);
                            // Status of the Api if KO (error) recheck until its OK
                            suivi.SV_T_GVAStatusKO__c = true;
                            listOfSuiviToUpdate.add(suivi);
                        }
                    }
                }
            }
        }

        if(listOfSubToUpdate != null && listOfSubToUpdate.size() > 0) {
            try {
                update listOfSubToUpdate;
            } catch(Exception e) {
                system.debug('update subscription error ' + e);
            }
        }

        if(listOfSuiviToUpdate != null && listOfSuiviToUpdate.size() > 0) {
            try {
                system.debug('listOfSuiviToUpdate ' + listOfSuiviToUpdate);
                update listOfSuiviToUpdate;
                system.debug('update done');
            } catch(Exception ee) {
                system.debug(ee.getMessage() + ' ' + ee.getlinenumber());
                system.debug('update suivi error ' + ee);
            }
        }
    }

    public void finish(Database.BatchableContext BC){}
}