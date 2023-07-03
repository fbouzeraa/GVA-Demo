/*
 * Classe pour créer des quotes, rendre les quote primaire,
 * ajouter une quote et le numero de commande pour chaque souscription
 */
public class AP01_Quotes {
    /**
     * Methode pour ajouter le numero de commande sur la souscription
     * @param listSub liste des souscription cree
     */
    public static void addOrderNumberToSub(list<Zuora__Subscription__c> listSub) {
        list<string> listQuoteId = new List<string>();
        list<id> listNewQuoteId = new List<id>();

        for(Zuora__Subscription__c sub : listSub) {

            if((Sub.Zuora__Status__c == 'Pending Activation' || Sub.Zuora__SubscriptionNumber__c.contains('T-S')) && sub.SF_QuoteID__c != null) {
                listQuoteId.add(sub.SF_QuoteID__c);
            }
        }
        if(listQuoteId.size() > 0 && listQuoteId != null) {
            for(string currentId : listQuoteId) {
                listNewQuoteId.add(id.valueOf(currentId));
            }

            list<Quote> listQuote = [SELECT Name, Account.ownerId, QUO_IsCollaborator__c, QUO_T_numero_de_Commande__c, Account.PersonContactId, Id,
                                     Account.BillingCountryCode, QUO_Offer__c, QUO_Options__c, QUO_Tech_Material__c
                                     FROM Quote
                                     WHERE Id IN :listNewQuoteId ];

            for(Quote currentQuote : listQuote) {
                for(Zuora__Subscription__c sub : listSub) {
                    if(sub.SF_QuoteID__c == string.valueOf(currentQuote.Id)) {
                        sub.isCollaborator__c = currentQuote.QUO_IsCollaborator__c;
                        sub.Quote__c = id.valueOf(sub.SF_QuoteID__c);
                        sub.SUB_Contact__c = currentQuote.Account.PersonContactId;
                        sub.SUB_T_Account_Country__c = currentQuote.Account.BillingCountryCode;
                        sub.ownerId = currentQuote.Account.ownerId;
                        sub.SUB_Tech_Material__c = currentQuote.QUO_Tech_Material__c;
                        sub.SUB_Offer__c = currentQuote.QUO_Offer__c;
                        sub.SUB_Options__c = currentQuote.QUO_Options__c;
                        if(sub.Zuora__Status__c == 'Pending Activation') {
                            sub.SUB_Tech_Abo_En_Cours__c = true;
                        }

                    }
                }
            }
        }
    }

    /**
     * methode pour remplir les champs qui sont en relation avec le contact
     * @param listQuote liste des devis
     */
    public static void fillQuoteContactInfo(list<quote> listQuote) {
        map<id, id> quoteOpportunityMap = new Map<id, id>();
        map<id, id> opportunityAccountMap = new Map<id, id>();
        map<id, id> accountContactMap = new Map<id, id>();

        for(quote currentQuote : listQuote) {
            quoteOpportunityMap.put(currentQuote.id, currentQuote.OpportunityId);
        }

        list<Opportunity> listOpp = [
            SELECT AccountId
            FROM Opportunity
            WHERE id IN :quoteOpportunityMap.values()
        ];

        for(Opportunity opp : listOpp) {
            opportunityAccountMap.put(opp.id, opp.AccountId);
        }

        list<contact> listContact = [ SELECT id, AccountId, CreatedBy.CountryCode
                                      FROM Contact
                                      WHERE AccountId IN :opportunityAccountMap.values()        ];
        for(Contact con : listContact) {
            accountContactMap.put(con.AccountId, con.id);
        }

        if(!listContact.isEmpty() && !opportunityAccountMap.isEmpty() && !quoteOpportunityMap.isEmpty()) {
            for(quote newQuote : listQuote) {
                if(
                    quoteOpportunityMap.get(newQuote.Id) != null &&
                    opportunityAccountMap.get(quoteOpportunityMap.get(newQuote.Id)) !=  null &&
                    accountContactMap.get(opportunityAccountMap.get(quoteOpportunityMap.get(newQuote.Id))) != null
                ) {
                    newQuote.ContactId = accountContactMap.get(opportunityAccountMap.get(quoteOpportunityMap.get(newQuote.Id)));
                    newQuote.QUO_Version__c = 1;
                    newQuote.QUO_T_Account__c = opportunityAccountMap.get(quoteOpportunityMap.get(newQuote.Id));
                    newQuote.QUO_Tech_Nombre_De_Produits__c = 0;
                    newQuote.QUO_Pays__c = listContact[0].CreatedBy.CountryCode;
                }
            }
        }
    }

    /**
     * Methode pour créer les Suivis sur les nouvelles souscriptions
     * @param listSub Liste des nouvelles Souscriptions
     */
    public static void createSuiviRecords(list<Zuora__Subscription__c> listSub) {
        List<Suivi_de_Souscription__c> newSuivisList = new List<Suivi_de_Souscription__c>();

        Set<Id> accountIds = new Set<Id>();

        List<Zuora__Subscription__c> subList = [SELECT Id, Name, Zuora__Account__r.BillingCountry, Zuora__Account__r.BillingCountryCode, Quote__r.QUO_PTO__c,
                                                Zuora__Account__c, BoxNumber__c, CreatedDate, Zuora__SubscriptionNumber__c, Quote__r.QUO_T_Produit_De_Base__c,
                                                SUB_Tech_Abo_En_Cours__c, Zuora__status__c, quote__r.QUO_Mode_de_paiement__c
                                                FROM Zuora__Subscription__c
                                                WHERE Id IN :listSub];

        for(Zuora__Subscription__c sub : subList) {
            accountIds.add(sub.Zuora__Account__c);
        }
        if(accountIds.size() > 0 && accountIds != null) {
            //get acount and related contacts
            list<Account> listAccountContacts = [SELECT FirstName, Name, LastName, ACC_Entreprise__c, RecordType.DeveloperName, id, BillingCity, ACC_Nombre_abonnement__c,
                                                 BillingStreet, ACC_BuildingID__c, ACC_NumeroPTO_cc__c, ACC_NumeroDEtage__c, ACC_Escalier__c, ACC_StatutCompte__c,
                                                 ACC_Porte__c, ACC_AccountNumber__c, ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName,
                                                 ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c,
                                                 ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c, ACC_TECH_Abonnement_En_Cours__c,
                                                 (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c FROM Contacts WHERE AccountId IN :accountIds)
                                                 FROM Account
                                                 WHERE id IN  :accountIds];

            list<Product_BandWidth__mdt> listProdBw = [SELECT BW_DL__c, BW_UL__c, DeveloperName, COuntry_Code__c
                                                       FROM Product_BandWidth__mdt];

            map<string, Product_BandWidth__mdt> mapBwName = new map<string, Product_BandWidth__mdt>();

            for(Product_BandWidth__mdt prodBw : listProdBw) {
                mapBwName.put(prodBw.DeveloperName, prodBw);
            }

            list<Account> listAccountToUpdate = new list<Account>();
            for(Zuora__Subscription__c sub : subList) {
                Account ac = new Account(id = sub.Zuora__Account__c, ACC_TECH_Abonnement_En_Cours__c = sub.SUB_Tech_Abo_En_Cours__c);
                // if it's the first subscription to this account update the status of the account to 'Client signé'
                if(ac.ACC_Nombre_abonnement__c == null || ac.ACC_Nombre_abonnement__c == 0) {
                    ac.ACC_StatutCompte__c = System.label.Account_Status_ClientSigne;
                }
                listAccountToUpdate.add(ac);
                for(Account acc : listAccountContacts) {
                    if(sub.Zuora__Account__c == acc.Id) {
                        if(!sub.Zuora__SubscriptionNumber__c.contains('T-S')  && sub.Zuora__Status__c == 'Pending Activation') {
                            newSuivisList.add(ZuoraSubscriptionActions.createSuivi(sub.BoxNumber__c, 'ACT001', Datetime.now(), 'DST001', sub.Id, sub.Zuora__Account__r.BillingCountryCode,
                                                                                   sub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, sub.Quote__r.QUO_T_Produit_De_Base__c, SuiviMapper.fillSuiviOnCreation(sub.BoxNumber__c, acc, acc.contacts, sub, mapBwName.get(sub.Quote__r.QUO_T_Produit_De_Base__c + '_' + sub.Zuora__Account__r.BillingCountryCode)?.BW_UL__c, mapBwName.get(sub.Quote__r.QUO_T_Produit_De_Base__c + '_' + sub.Zuora__Account__r.BillingCountryCode)?.BW_DL__c), sub.quote__r.QUO_Mode_de_paiement__c));
                        } // pour les abo techniques
                        else if(sub.Zuora__SubscriptionNumber__c.contains('T-S')) {
                            newSuivisList.add(ZuoraSubscriptionActions.createSuivi(sub.BoxNumber__c, 'ACT005', Datetime.now(), 'DST001',
                                                                                   sub.Id, sub.Zuora__Account__r.BillingCountryCode, sub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, SuiviMapper.fillSuiviAdditionalProd(acc, acc.contacts, null), sub.quote__r.QUO_Mode_de_paiement__c));
                        }

                    }
                }
            }

            if(newSuivisList.size() > 0) {
                try {
                    insert newSuivisList;
                } catch(Exception e) {
                    system.debug(e.getLineNumber() + ':' + e.getMessage());
                }
            }
            if(listAccountToUpdate.size() > 0) {
                try {
                    update listAccountToUpdate;
                } catch(Exception e) {
                    system.debug(e.getLineNumber()   + ' : ' + e.getMessage());
                }
            }
        }

    }

}