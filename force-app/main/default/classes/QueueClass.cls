/*
 * Classe Queue pour mettre à jour les lignes de suivis après l'installation
 */
global class QueueClass implements Queueable, Database.AllowsCallouts {
    List<Suivi_de_Souscription__c> listSuivis;

    public QueueClass(List<Suivi_de_Souscription__c> listSuivis){
        this.listSuivis = listSuivis;
    }
    /**
     * Method to execute the queue over list of suivi records
     */
    public void execute(QueueableContext context) {
        List<Suivi_de_Souscription__c> listSuivisToUpdate = new List<Suivi_de_Souscription__c>();
        if(listSuivis != null && listSuivis.size() > 0) {
            // map of suivi and related accounts for installed box
            Map<Id, Zuora__Subscription__c> mapNewSubscription = new Map<Id, Zuora__Subscription__c>();
            list<Account> listAccountToUpdate = new list<Account>();
            set<Zuora__Subscription__c> setSubToUpdate = new set<Zuora__Subscription__c>();
            list<Zuora__Subscription__c> listSubToUpdate = new list<Zuora__Subscription__c>();
            //set of zuora Logs
            Set<Log__c> setLog = new set<Log__c>();
            list<Log__c> listLog = new list<Log__c>();
            //list of reactivation follow up
            list<Suivi_de_Souscription__c> listReactivationFollowUp = new list<Suivi_de_Souscription__c>();
            for(Suivi_de_Souscription__c suivi : listSuivis) {
                CanalBoxObjects.Orders order = new CanalBoxObjects.Orders();
                order.order_ref = suivi.SV_Reference_Externe__c;

                // call installation API to check if the box is installed or not
                HttpResponse installationResponse = CanalBoxManager.boxInstallation(order);

                //system.debug('Installation ' + installationResponse.getBody());

                CanalBoxObjects.OrderResponse orderResponse = new CanalBoxObjects.OrderResponse();
                if(installationResponse.getBody() != null){
                    orderResponse = (CanalBoxObjects.OrderResponse)JSON.deserialize(installationResponse.getBody(), CanalBoxObjects.OrderResponse.class);
                    // check suspended and pending subscription
                    if(suivi.SV_Id_Souscription__r.Zuora__Status__c == 'Pending Activation') {
                        // successed order
                        if(installationResponse.getStatusCode() == 200) {
                            if(orderResponse.services != null && orderResponse.services.size() > 0) {
                                date installationDate = null;
                                for(CanalBoxObjects.OrderServiceItemResponse service : orderResponse.services) {
                                    if(service.new_address != null && !string.isBlank(string.valueOf (service.new_address))) {
                                        Account acc = new Account();
                                        acc.id = suivi.SV_Id_Souscription__r.Zuora__Account__c;
                                        acc.ACC_BuildingID__c = string.isBlank(service.new_address.mq_building_id)?suivi.SV_Id_Souscription__r.Zuora__Account__r.ACC_BuildingID__c : service.new_address.mq_building_id;
                                        acc.ACC_Escalier__c = string.isBlank(service.new_address.mq_escalier)?suivi.SV_Id_Souscription__r.Zuora__Account__r.ACC_Escalier__c : service.new_address.mq_escalier;
                                        // Demande ticket 496
                                        // acc.ACC_NumeroDEtage__c = string.isBlank(service.new_address.mq_etage)?suivi.SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroDEtage__c : double.valueOf(service.new_address.mq_etage);
                                        acc.ACC_Porte__c = string.isBlank(service.new_address.mq_porte)?suivi.SV_Id_Souscription__r.Zuora__Account__r.ACC_Porte__c : service.new_address.mq_porte;
                                        acc.ACC_NumeroPTO_cc__c = string.isBlank(service.new_address.mq_pto_ref)?suivi.SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroPTO_cc__c : service.new_address.mq_pto_ref;
                                        acc.BillingPostalCode = string.isBlank(service.new_address.zip)?suivi.SV_Id_Souscription__r.Zuora__Account__r.BillingPostalCode : service.new_address.zip;
                                        listAccountToUpdate.add(acc);
                                    }
                                    if(service.status == 'actif' && service.activation_date != null && !string.isBlank(service.activation_date)) {
                                        Zuora__Subscription__c sub = new Zuora__Subscription__c();
                                        sub.Zuora__ServiceActivationDate__c = date.valueOf(service.activation_date);//date.today();
                                        sub.Id = suivi.SV_Id_Souscription__c;
                                        if(service.pxo_date_rdv != null && !string.isBlank(string.valueOf(service.pxo_date_rdv))) {

                                            installationDate = date.valueOf(service.pxo_date_rdv);
                                        }
                                        sub.Date_De_RDV_Dinstallation__c = installationDate;
                                        sub.Etat_De_Linstallation__c = service.status;
                                        sub.Suivi_de_installation__c = service.suivi;
                                        sub.SUB_Ref_service__c =  service.service_ref;
                                        //System.debug('sub.SUB_Ref_service__c'+sub.SUB_Ref_service__c);
                                        mapNewSubscription.put(suivi.SV_Id_Souscription__c, sub);
                                    }
                                    else if((service.pxo_date_rdv != null || service.status != null) && string.isBlank(service.activation_date)) {

                                        if(service.pxo_date_rdv != null && !string.isBlank(string.valueOf(service.pxo_date_rdv))) {

                                            installationDate = date.valueOf(service.pxo_date_rdv);
                                        }
                                        Zuora__Subscription__c sub = new Zuora__Subscription__c();
                                        sub.Date_De_RDV_Dinstallation__c = installationDate;
                                        sub.Id = suivi.SV_Id_Souscription__c;
                                        sub.Suivi_de_installation__c = service.suivi;
                                        sub.Etat_De_Linstallation__c = service.status;
                                        sub.SUB_Ref_service__c =  service.service_ref;
                                        //System.debug('sub.SUB_Ref_service__c'+sub.SUB_Ref_service__c);
                                        setSubToUpdate.add(sub);
                                    }
                                }
                            }
                        } 
                        else {
                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.error, suivi.SV_Id_Souscription__c, 'API Installation');

                            System.debug('Erreur dans le Batch ' + String.valueOf(orderResponse.code) + ' ' + orderResponse.error);
                        }
                    } else if(suivi.SV_Id_Souscription__r.Zuora__Status__c == 'Suspended') {
                        /**
                         * steps to do in this batch
                         * update BCD on account the the day of suspension
                         */
                        if(installationResponse.getStatusCode() == 200) {
                            if(orderResponse.order != null) {
                                if(orderResponse.order.status == 'produit' && !string.isBlank(orderResponse.order.recette_date)) {

                                    date resumeDate = date.valueOf(orderResponse.order.recette_date);

                                    //get number of prepaid period till now
                                    // integer prepaidperiod = Date.today().monthsBetween(suivi.SV_Id_Souscription__r.ExpectedRenewalDate__c);

                                    //update suspend reason et date de resume sur l'abo
                                    ZuoraObjects.ZuoraOrderSubscription subCustomField = ZuoraMapper.fillMoveCustomField(string.valueOf(resumeDate));
                                    HttpResponse movecustomFieldResponse = ZuoraManager.updateSubscriptionCustomFields(subCustomField, suivi.SV_Id_Souscription__r.Name);

                                    ZuoraResponseObjects.ZuoraSubscriptions updateSubResponse = new ZuoraResponseObjects.ZuoraSubscriptions();
                                    updateSubResponse = (ZuoraResponseObjects.ZuoraSubscriptions) JSON.deserialize(movecustomFieldResponse.getBody(), ZuoraResponseObjects.ZuoraSubscriptions.class);
                                    
                                    setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(subCustomField, true), null, suivi.SV_Id_Souscription__c, suivi.SV_Id_Souscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.subscriptionAPIUrl + suivi.SV_Id_Souscription__r.Zuora__SubscriptionNumber__c + '/customFields', movecustomFieldResponse.getBody(),
                                                                                    updateSubResponse.success, updateSubResponse.reasons == null?null : updateSubResponse.reasons[0].message, ZuoraObjects.post, false));
                                    if(updateSubResponse.success) {
                                        //create follow up for reactivation
                                        listReactivationFollowUp.add(ZuoraSubscriptionActions.createSuivi(
                                                                        suivi.SV_Id_Souscription__r.BoxNumber__c, 'ACT003', Datetime.now(),
                                                                        'DST001', suivi.SV_Id_Souscription__c, null, suivi.SV_Id_Souscription__r.Zuora__Account__r.ACC_NumeroPTO_cc__c, 'STA001', null, null, null, null, null, null, null));

                                        Suivi_de_Souscription__c suiviToUpdate = new Suivi_de_Souscription__c();
                                        suiviToUpdate.Id = suivi.Id;
                                        suiviToUpdate.SV_Tech_Installation_Termine__c = true;
                                        listSuivisToUpdate.add(suiviToUpdate);

                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(mapNewSubscription != null && !mapNewSubscription.isEmpty()) {
                //update sub records
                //System.debug('1 Abdellatif SUB '+mapNewSubscription.values());
                update mapNewSubscription.values();
                
            }

            if(listSuivisToUpdate.size() > 0 && listSuivisToUpdate != null) {
                update listSuivisToUpdate;
            }
            if(listAccountToUpdate.size() > 0 && listAccountToUpdate != null) {
                update listAccountToUpdate;
            }
            if(setSubToUpdate.size() > 0 && setSubToUpdate != null) {
                listSubToUpdate.addAll(setSubToUpdate);
                //System.debug('2 Abdellatif SUB '+listSubToUpdate);
                update listSubToUpdate;
            }
            if(setLog.size() > 0 && setLog != null) {
                listLog.addALL(setLog);
                insert listLog;
            }
            if(listReactivationFollowUp.size() > 0 && listReactivationFollowUp != null) {
                insert listReactivationFollowUp;
            }
        }
    }
}