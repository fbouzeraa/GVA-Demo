public with sharing class AP01_SuiviDeSouscription {

    /**
     * Créér un réab
     *<p>
     * @param listNewSuivi list des suivi de destination SF
     * Test class : WS06_DPO_Test
     */
    public static void getNewSuivi(list<Suivi_de_Souscription__c> listNewSuivi){
        set<Id> newSuiviIds = new set<Id>();
        // for(Suivi_de_Souscription__c sv : listNewSuivi) {
        //     if(sv.SV_Destination__c == 'DST002')
        //         newSuiviIds.add(sv.Id);
        // }
        if(newSuiviIds.size() > 0 && newSuiviIds != null)
            // create distributor account in zuora for each distributor created in SF
            renewSubInZuora(newSuiviIds);
    }

    /**
     * Methode pour faire un réabo d'une souscription
     * @param newSuiviIds Id des nouveau suivis
     * */
    @future(callout = true)
    public static void renewSubInZuora(set<Id> newSuiviIds){
        list<Suivi_de_Souscription__c> listToUpdate = new list<Suivi_de_Souscription__c>();
        List<Suivi_de_Souscription__c> listNewSuivi = [SELECT SV_Id_Souscription__c, SV_Code_Action__c, SV_Details__c,
                                                       SV_Statut__c
                                                       FROM Suivi_de_Souscription__c
                                                       WHERE id IN: newSuiviIds];
        for(Suivi_de_Souscription__c sv : listNewSuivi) {
            SuiviDetails suiviDetail = (SuiviDetails) JSON.deserialize(sv.SV_Details__c, SuiviDetails.class);
            // reabo simple
            if(sv.SV_Code_Action__c == 'ACT003') {
                string response = SubscriptionRenewalActions.renewSubscription(sv.SV_Id_Souscription__c, integer.valueOf(suiviDetail.Periode), suiviDetail.ModeDePaiement, suiviDetail.NumeroDeTransaction, suiviDetail.Operateur, null, null, null, null, null, null, null, null);
                ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                    response, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                if(orderResponse.success) {
                    Suivi_de_Souscription__c suivi = new Suivi_de_Souscription__c();
                    suivi.SV_Statut__c = 'STA002'; // traité
                    suivi.id = sv.Id;
                    listToUpdate.add(suivi);
                } else {
                    SuiviDetails svDetail = new SuiviDetails();
                    svDetail.IDSouscription = suiviDetail.IDSouscription;
                    svDetail.ModeDePaiement = suiviDetail.ModeDePaiement;
                    svDetail.NumeroDeTransaction = suiviDetail.NumeroDeTransaction;
                    svDetail.Periode = suiviDetail.Periode;
                    suiviDetail.Erreur = orderResponse.reasons[0].message;

                    Suivi_de_Souscription__c suivi = new Suivi_de_Souscription__c();
                    suivi.SV_Statut__c = 'STA003'; // En cours
                    suivi.id = sv.Id;
                    suivi.SV_Details__c = JSON.serialize(svDetail, true);
                    listToUpdate.add(suivi);
                }
            }
            if(sv.SV_Code_Action__c == 'ACT004') {
                string response;
                if(suiviDetail.typeOperation == 2)
                    response = SubscriptionRenewalActions.upgradeSubscriptionProduct(sv.SV_Id_Souscription__c, integer.valueOf(suiviDetail.Periode), false, true, false, suiviDetail.ModeDePaiement, suiviDetail.NumeroDeTransaction, suiviDetail.operateur, null, null, null, null, null, null, null, null);
                if(suiviDetail.typeOperation == 3)
                    response = SubscriptionRenewalActions.downgradeSubscriptionProduct(sv.SV_Id_Souscription__c, null, integer.valueOf(suiviDetail.Periode), false, suiviDetail.ModeDePaiement, suiviDetail.NumeroDeTransaction, suiviDetail.operateur, null, null, null, null, null, null, null, null);
                system.debug(response);
                ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                if(orderResponse.success) {
                    Suivi_de_Souscription__c suivi = new Suivi_de_Souscription__c();
                    suivi.SV_Statut__c = 'STA002'; // traité
                    suivi.id = sv.Id;
                    listToUpdate.add(suivi);
                } else {
                    SuiviDetails svDetail = new SuiviDetails();
                    svDetail.IDSouscription = suiviDetail.IDSouscription;
                    svDetail.ModeDePaiement = suiviDetail.ModeDePaiement;
                    svDetail.NumeroDeTransaction = suiviDetail.NumeroDeTransaction;
                    svDetail.Periode = suiviDetail.Periode;
                    suiviDetail.Erreur = orderResponse.reasons[0].message;

                    Suivi_de_Souscription__c suivi = new Suivi_de_Souscription__c();
                    suivi.SV_Statut__c = 'STA003'; // En cours
                    suivi.id = sv.Id;
                    suivi.SV_Details__c = JSON.serialize(svDetail, true);
                    listToUpdate.add(suivi);
                }
            }
            // other type should be added

            if(listToUpdate.size() > 0 && listToUpdate != null)
                update listToUpdate;
        }
    }
    public class SuiviDetails {

        // Nombre de période prépayée en mois
        public integer Periode;
        // Numéro de la transaction
        public string NumeroDeTransaction;
        // Mode de paiement
        public string ModeDePaiement;
        // ID de l'abonnement
        public string IDSouscription;
        //Erreur
        public string Erreur;
        // Nom de l'operateur
        public string Operateur;
        public integer typeOperation;

    }
}