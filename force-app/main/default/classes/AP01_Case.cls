public class AP01_Case {

    public static void categUpdateTriggerHandler(Map<Id, Case> newMap, Map<Id, Case> oldMap) {

        String allCatgMd;
        String allCatgCs;
        String reseauGlobal = System.Label.QueueNameReseauGlobal;
        String systemGlobal = System.Label.QueueNamesystemGlobal;
        String ExploitationSI = System.Label.QueueNameExploitationSI;
        map<String, String> mapOfCategriesImpact = new map<String, String>();
        map<String, String> mapOfCategriesCompetence = new map<String, String>();
        map<String, String> mapOfQueueNameId = new map<String, String>();

        // Get all queues
        map<Id, Group> mapOfQueues = new map<Id, Group>([SELECT Name, DeveloperName, Id FROM Group where Type = 'Queue']);
        // Get Matrice_De_Diagnostic records to do the mapping between categories and impact and OwnerId
        list<Matrice_de_Diag__c> matriceDeDiagnostique = [SELECT Id, MDD_Categorie1__c, MDD_Categorie_2__c, MDD_Categorie_3__c,
                                                          MDD_Competencefield__c, Impact_client__c FROM Matrice_de_Diag__c];

        // create a map of name queue and ID
        for(Group qu : mapOfQueues.values()) {
            mapOfQueueNameId.put(qu.DeveloperName.toUpperCase(), qu.Id);
        }
        // create a map of the concatenation of 3 categories and the field impact client
        for(Matrice_de_Diag__c mdd : matriceDeDiagnostique) {
            allCatgMd = mdd.MDD_Categorie1__c + mdd.MDD_Categorie_2__c + mdd.MDD_Categorie_3__c;
            mapOfCategriesImpact.put(allCatgMd, mdd.Impact_client__c);
            mapOfCategriesCompetence.put(allCatgMd, mdd.MDD_Competencefield__c);
        }

        for(Case cs : newMap.values()) {
            allCatgCs = cs.CAS_Categorie1__c + cs.CAS_Categorie2__c + cs.CAS_Categorie3__c;
            // when a categorie field change
            if(newMap.get(cs.Id).CAS_Categorie1__c != oldMap.get(cs.Id).CAS_Categorie1__c
               || newMap.get(cs.Id).CAS_Categorie2__c != oldMap.get(cs.Id).CAS_Categorie2__c
               || newMap.get(cs.Id).CAS_Categorie3__c != oldMap.get(cs.Id).CAS_Categorie3__c) {
                if(mapOfCategriesImpact.containsKey(allCatgCs) == true && mapOfCategriesCompetence.containsKey(allCatgCs) == true) {

                    system.debug('allCatgCs ' + allCatgCs);
                    String countryName = (cs.CAS_T_CountryCode__c == null || string.isBlank(cs.CAS_T_CountryCode__c)) ? cs.CAS_Pays__c : cs.CAS_T_CountryCode__c;
                    String comp = mapOfCategriesCompetence.get(allCatgCs).replace(' ', '_');
                    String queueName = comp.toUpperCase() + '_' + countryName;
                    // fill the fields with the right values
                    cs.CAS_Impact__c = mapOfCategriesImpact.get(allCatgCs);
                    cs.Comp_tence__c = mapOfCategriesCompetence.get(allCatgCs);

                    if(mapOfCategriesCompetence.get(allCatgCs) == 'Ingénieurs Réseau Global') {
                        cs.OwnerId = mapOfQueueNameId.get(reseauGlobal.toUpperCase());
                    } else if(mapOfCategriesCompetence.get(allCatgCs) == 'Ingénieurs Système Global') {
                        cs.OwnerId = mapOfQueueNameId.get(systemGlobal.toUpperCase());
                    } else if(mapOfCategriesCompetence.get(allCatgCs) == 'Exploitation SI') {
                        cs.OwnerId = mapOfQueueNameId.get(ExploitationSI.toUpperCase());
                    } else if(mapOfQueueNameId.containsKey(queueName) == false) {
                        cs.addError('Missing Queue');
                    } else {
                        cs.OwnerId = mapOfQueueNameId.get(queueName);
                    }
                } else if(newMap.get(cs.Id).Status == 'CAS_Cloturee') {
                    cs.addError(System.label.Required_Fields);
                }
            } else if(newMap.get(cs.Id).Status == 'CAS_Cloturee' && mapOfCategriesImpact.containsKey(allCatgCs) == false) {
                cs.addError(System.label.Required_Fields);
            }
        }
    }

    @AuraEnabled(cacheable = true)
    public static list<string> getCoupons(id AccountId, id SubscriptionId){
        system.debug(AccountId);
        Zuora__Subscription__c sub = new Zuora__Subscription__c();
        if(AccountId != null) {
            sub = [SELECT SUB_T_Produit_De_Base__c, Zuora__Account__r.BillingCountryCode
                   FROM Zuora__Subscription__c
                   WHERE Zuora__Account__c = :AccountId AND (Zuora__Status__c = 'Active' OR Zuora__Status__c = 'Suspended') AND Type__c = 'Standard'
                   LIMIT 1];

        } else {
            sub = [SELECT SUB_T_Produit_De_Base__c, Zuora__Account__r.BillingCountryCode
                   FROM Zuora__Subscription__c
                   WHERE Id = :SubscriptionId AND (Zuora__Status__c = 'Active' OR Zuora__Status__c = 'Suspended') AND Type__c = 'Standard'
                   LIMIT 1];
        }

        list<Coupon__c> listCoupon = [SELECT COU_Amount__c
                                      FROM Coupon__c
                                      WHERE COU_Offer__c = :sub.SUB_T_Produit_De_Base__c AND COU_Country__c = :sub.Zuora__Account__r.BillingCountryCode];
        if(listCoupon != null && listCoupon.size() > 0) {
            list<string> listAmounts = new list<string>();
            for(Coupon__c coupon : listCoupon) {
                listAmounts.add(coupon.COU_Amount__c);
            }
            system.debug(listAmounts);

            return listAmounts;
        } else {
            return null;
        }
    }

    @auraEnabled
    public static case insertCase(id AccountId, id SubscriptionId, string status, string reason, string description, string subject, string type, string cancelReason, string termnationReason, integer freeDays, string coupon){

        string countryCode = [SELECT BillingCountryCode FROM Account WHERE id = : AccountId].BillingCountryCode;
        Case newCase = new Case();
        newCase.AccountId = AccountId;
        newCase.Status = status;
        newCase.Description = description;
        newCase.CAS_Abonnement__c = SubscriptionId;
        newCase.Subject = subject;
        newCase.Type = type;
        newCase.CAS_Motif_De_La_Requete__c = reason;
        newCase.CAS_MotifDAnnulation__c = cancelReason;
        newCase.CAS_MotifDeResiliation__c = termnationReason;
        newCase.CAS_Pays__c = countryCode;
        if(!string.isBlank(coupon) || coupon != null) {
            newCase.CAS_Coupon__c = coupon;

        }
        newCase.CAS_NombreDeJoursGratuit__c = freeDays;
        newCase.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAS_Requete').getRecordTypeId();
        try {
            insert newCase;
        }catch(exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return newCase;
}
    @auraEnabled
    public static List<Zuora__Subscription__c> getListSub(string name, id accountId){

        name = name + '%';

        return [SELECT id, Name
                FROM Zuora__Subscription__c
                WHERE Zuora__Account__c = : accountId AND (Zuora__Status__c = 'Active' OR Zuora__Status__c = 'Suspended')
                AND Type__c = 'Standard' AND Name like : name  ];

    }

}