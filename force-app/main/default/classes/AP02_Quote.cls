/**
 * @author Jackie Abi NAssif
 * @date 20 avril 2022
 */

public with sharing class AP02_Quote {

    public static String draft = System.Label.Quote_Status_Draft;
    public static String needsReview = System.Label.Quote_Status_NeedsReview;
    public static String inReview = System.Label.Quote_Status_InReview;

    @AuraEnabled
    public static list<Quote> getRequestedQuotes(){

        try {
            String query = 'SELECT Id, Name, Status, Subtotal, TotalPrice, Owner.Name, Opportunity.Name, ExpirationDate, AccountId, Account.Name ';
                query +=    'FROM Quote ';
                query +=    'WHERE Status = \''+ draft +'\'';

                List<Quote> listOfQuote =  Database.query(query);
            return listOfQuote;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void handleBulkActions(string selectedJSON, boolean bulkDelete){
        try {
            list<Quote> listQuotes = new list<Quote>();
            set<Quote> setQuote = new set<Quote>();
            List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(selectedJSON);
            for(Object fld : fieldList)
            {
                Quote quo = new Quote();
                quo.id = id.valueOf(string.valueOf(fld));
                setQuote.add(quo);
            }
            if(setQuote.size() > 0 && setQuote != null) 
            {
                listQuotes.addAll(setQuote);
                if(bulkDelete)
                {
                    try {
                        delete listQuotes;
                    } catch (Exception e) {
                        system.debug(e.getMessage());
                    }
                }
            }
        }catch(Exception e){
            system.debug(e.getMessage()+' '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

/**
     * Methode créée pour libérer box après suppression de devis
     * @param oldMapDevis
     */
    public static void liberateBoxOnQuoteDeleted(Map<Id, Quote> oldMapDevis){
        String QuoteId = oldMapDevis.values()[0].Id;
        List<Zuora__Subscription__c> listSubscriptions = [SELECT Id FROM Zuora__Subscription__c WHERE SF_QuoteID__c =:QuoteId];
        if (oldMapDevis.values()[0].QUO_T_Numero_du_Box__c != null && oldMapDevis.values()[0].QUO_Reference_article__c != null && listSubscriptions.size()==0){
            liberateBoxOnQuoteDeletedMethod(oldMapDevis.values()[0].QUO_T_Numero_du_Box__c,oldMapDevis.values()[0].QUO_Reference_article__c);
            // String response = StockActions.liberateBox(null,oldMapDevis.values()[0].QUO_T_Numero_du_Box__c,oldMapDevis.values()[0].QUO_Reference_article__c);
            // System.debug('response'+response);
        }
    }

    @future (callout=true)
    public static void liberateBoxOnQuoteDeletedMethod(String numBox, String articleBOX){
        String response = StockActions.liberateBox(null,numBox,articleBOX);
    }

    /**
     * Methode créer pour ajouter la date de modification du statut d'objet Quote
     * @param newListOfQuote
     * @param oldMapQuote
     */
    public static void addDateOfStatusUpdate(List<Quote> newListOfQuote, Map<Id, Quote> oldMapQuote){

        for(Quote qut : newListOfQuote){
            if(oldMapQuote == null || oldMapQuote.isEmpty() == true){
                if(qut.Status == draft || qut.Status == needsReview || qut.Status == inReview){
                    qut.QUO_T_Status_Update_Date__c = System.today();
                }
                else{
                    qut.QUO_T_Status_Update_Date__c = null;
                }
            }
            else{
                if(qut.Status != oldMapQuote.get(qut.Id).Status){

                    if(qut.Status == draft || qut.Status == needsReview || qut.Status == inReview){
                        qut.QUO_T_Status_Update_Date__c = System.today();
                    }
                    else{
                        qut.QUO_T_Status_Update_Date__c = null;
                        system.debug(qut.QUO_T_Status_Update_Date__c);
                        system.debug(qut.Status);
                    }
                }
            }
        }
    }

}
 /* AND OwnerId = :UserInfo.getUserId()] */