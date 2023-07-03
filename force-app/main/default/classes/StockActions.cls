/**
 * Classe pour remplir les instances des objets CanalBoxObjects pour les appels API
 */
public with sharing class StockActions {
    /**
     * Methode pour obtenir le site reference d'un utilisateur
     * @return user
     */
    public static string getUserReference(){
        User currentUser = [select USR_SiteReference__c
                            FROM User WHERE id =: UserInfo.getUserId()];

        return currentUser.USR_SiteReference__c;
    }
    /**
     * Methode pour remplir le contenu d'un appel pour les produits dans stock
     * @return objet de type CanalBoxObjects.stockListing
     */
    @AuraEnabled
    public static string getBoxesInStock(string article){
        //get all boxes available in stock
        CanalBoxObjects.stockListing stockItems = new CanalBoxObjects.stockListing();
        stockItems.entity_site_ref = getUserReference();
        stockItems.type_article_ref = article;
        try {

            HttpResponse response = CanalBoxManager.stockAvailability(stockItems);
            system.debug('response  GVAdmin '+response.getBody());
            CanalBoxObjects.stockListingResponse listingBox = (CanalBoxObjects.stockListingResponse)System.JSON.deserialize(response.getBody(), CanalBoxObjects.stockListingResponse.class);

            return response.getBody();
        } catch(Exception e) {
            system.debug(e.getMessage() + ' ' + e.getLineNumber());

            throw new CustomException(e.getMessage());
        }
    }

    /**
     * Methode pour remplir le contenu d'un appel pour reserver un produit
     * @param selectedBox les boxes choisis par l'utilisateur
     * @param quoteId id du devis
     * @param subscriptionId id de l'abonnement
     * @return reponse de l'appel api
     */
    @AuraEnabled
    public static string reserveBox (string selectedBox, string quoteId, string subscriptionId, string article)
    {
        // convert selected box from an array of object to object
        selectedBox = selectedBox.left(selectedBox.length() - 1);
        selectedBox = selectedBox.right(selectedBox.length() - 1);
        CanalBoxObjects.stockArticleResponse selectedArticle = (CanalBoxObjects.stockArticleResponse)System.JSON.deserialize(selectedBox, CanalBoxObjects.stockArticleResponse.class);
        
        // reserve selected box
        CanalBoxObjects.StockReservationLiberation boxReservation = new CanalBoxObjects.StockReservationLiberation();
        boxReservation.type_article_ref = article;
        boxReservation.entity_site_ref = getUserReference();
        boxReservation.serial = selectedArticle.serial;
        try {
            HttpResponse response = CanalBoxManager.boxReservation(boxReservation);

            CanalBoxObjects.stockReservingResponse reservedBox = (CanalBoxObjects.stockReservingResponse)System.JSON.deserialize(response.getBody(), CanalBoxObjects.stockReservingResponse.class);
            system.debug('GVadmin response '+response);

            if((response.getStatusCode() == 200))
            {
                // on create sub, add reserved box to the quote
                if(quoteId != null) {
                    addBoxNumberToQuote(quoteId, boxReservation.serial, article);

                    return response.getBody();
                } else {
                    //In case of change box, modifiy box number on the existing sub
                    // and recalculate the warranty
                    string warranty;
                    Zuora__Subscription__c currentSub = [SELECT id, Quote__r.QUO_PTO__c, Zuora__Account__r.BillingCountryCode, Quote__c,
                                                         Zuora__Account__c, Zuora__ServiceActivationDate__c, Zuora__SubscriptionNumber__c,
                                                         BoxNumber__c
                                                         FROM Zuora__Subscription__c
                                                         WHERE Id = :subscriptionId];

                    if(currentSub != null) {

                        list<QuoteLineItem> listQLI = [SELECT Product_Rate_Plan__r.WarrantyDurationInMonth__c
                                                       FROM QuoteLineItem WHERE quoteId = : currentSub.Quote__c];

                        for(QuoteLineItem QLI : listQLI) {
                            if(QLI.Product_Rate_Plan__r.WarrantyDurationInMonth__c != null) {
                                warranty = QLI.Product_Rate_Plan__r.WarrantyDurationInMonth__c;
                                break;
                            }
                        }

                        list<Account> listAccountContacts = [SELECT FirstName, LastName, ACC_Entreprise__c, RecordType.DeveloperName, ACC_AccountNumber__c,
                                                             ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName, Name,
                                                             ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c,
                                                             ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c,
                                                             (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c
                                                              FROM Contacts WHERE AccountId = :currentSub.Zuora__Account__c)
                                                             FROM Account
                                                             WHERE id = :currentSub.Zuora__Account__c];

                        //create suivi for 'echange de materiel'
                        insert ZuoraSubscriptionActions.createSuivi(
                            selectedArticle.serial, 'ACT006', Datetime.now(),
                            'DST001', currentSub.Id, currentSub.Zuora__Account__r.BillingCountryCode,
                            currentSub.Quote__r.QUO_PTO__c, 'STA001', null, null, warranty == null?null : integer.valueOf(warranty), null, null, SuiviMapper.fillSuiviEchange(listAccountContacts.size() > 0?listAccountContacts[0] : null, listAccountContacts.size() > 0?listAccountContacts[0].contacts : null, null, selectedArticle.serial), null);
                    }
                    return response.getBody();
                }
            } else {

                insert AP01_ErreurInterface.insertError('Erreur API', null, null, reservedBox.errors == null?response.getStatus() : string.join(reservedBox.errors, ','), quoteId == null?subscriptionId : quoteId, CanalBoxObjects.stockReservingAPIUrl);

                return response.getBody();
            }
        }
        catch(Exception e) {
            system.debug(e.getLineNumber() + ' ' + e.getMessage());
            //insert AP01_ErreurInterface.insertError(e.getTypeName(), e.getCause()?.getMessage(), e.getLineNumber(), e.getMessage(), quoteId == null?subscriptionId : quoteId, 'reserveBox');
            throw new CustomException(e.getMessage());
        }
    }
    /**
     * Methode pour ajouter le numero du box reservé sur le devis
     * @param quoteId id du devis,
     * @param boxNumber numero bu box
     * @return void
     */
    public static void addBoxNumberToQuote(id quoteId, string boxNumber, string article) {

        quote currentQuote = [SELECT name, QUO_T_Numero_du_Box__c, id, QUO_Reference_article__c
                              FROM Quote
                              WHERE id = : quoteId ];
        try {
            currentQuote.QUO_T_Numero_du_Box__c = boxNumber;
            // currentQuote.QUO_Reference_article__c = article;
            update currentQuote;
        } catch(Exception e) {
            system.debug('box error '+e.getMessage()+': '+e.getLineNumber());
            throw new CustomException(e.getMessage());
        }

    }
    /**
     * Methode pour remplir le contenu d'un appel pour liberer un produit
     * @param selectedBox les boxes choisis par l'utilisateur
     * @param boxNumber numero bu box
     * @return reponse de l'appel api
     */
    @AuraEnabled
    public static string liberateBox ( string selectedBox, string boxNumber, string article){
        string boxToLiberate;

        // liberate Box when products aren't added to QLI
        if(selectedBox != null) {
            // convert selected box from an array of object to object
            selectedBox = selectedBox.left(selectedBox.length() - 1);
            selectedBox = selectedBox.right(selectedBox.length() - 1);

            CanalBoxObjects.stockArticleResponse selectedArticle = (CanalBoxObjects.stockArticleResponse)System.JSON.deserialize(selectedBox, CanalBoxObjects.stockArticleResponse.class);

            boxToLiberate = selectedArticle.serial;
        }
        // liberate Box after cancelling a sub
        else {

            boxToLiberate = boxNumber;
        }

        CanalBoxObjects.StockReservationLiberation boxLiberation = new CanalBoxObjects.StockReservationLiberation();
        boxLiberation.type_article_ref = article;
        boxLiberation.entity_site_ref = getUserReference();
        boxLiberation.serial = boxToLiberate;

        try {
            HttpResponse response = CanalBoxManager.boxLiberation(boxLiberation);

            if(string.isblank(response.getBody())) {
                Zuora__Subscription__c cancelledSub = [SELECT Zuora__Zuora_Id__c, Zuora__SubscriptionNumber__c
                                                       FROM Zuora__Subscription__c
                                                       WHERE boxNumber__c = :boxToLiberate];
                ZuoraSubscriptionActions.addCustomFieldsToSubscription(cancelledSub, null, boxToLiberate, null, null);
            } else {
                CanalBoxObjects.stockReservingResponse liberatedBox = (CanalBoxObjects.stockReservingResponse)System.JSON.deserialize(response.getBody(), CanalBoxObjects.stockReservingResponse.class);
                
                insert StockActions.createGVAdminLog(json.serialize(boxLiberation, true), null, null, null, CanalBoxObjects.stockLiberationAPIUrl, response.getBody());
                insert AP01_ErreurInterface.insertError('Erreur API', null, null, liberatedBox.errors == null?response.getStatus() : string.join(liberatedBox.errors, ','), null, CanalBoxObjects.stockLiberationAPIUrl);
            }

            return response.getBody();
        } catch(Exception e) {
            // insert AP01_ErreurInterface.insertError(e.getTypeName(), e.getCause()?.getMessage(), e.getLineNumber(), e.getMessage(), null, 'liberateBox');
            throw new CustomException(e.getMessage());
        }

    }
    /**
     * Methode utilisée pour créér des enregistrement dans l'objet Log Zuora
     * <p>
     * @param boby corps de l'appel,
     * @param IDCompte Compte lié à l'abonnement
     * @param IDAbonnement l'abonnement sur lequel est fait l'appel,
     * @param subNumber Numéro de l'abonnement
     * @param URL endpoint de la méthode Zuora
     * @param reponse reponse de la méthode Zuora
     **/

    public static Log__c createGVAdminLog(string boby, id IDCompte, id IDAbonnement, string subNumber, string URL, string reponse){

        Log__c newLog = new Log__c();
        newLog.LG_Body__c = boby;
        newLog.LG_Account__c = IDCompte;
        newLog.LG_Subscription__c = IDAbonnement;
        newLog.LG_Method_URL__c = URL;
        newLog.LG_Subscription_Number__c = subNumber;
        newLog.LG_Response__c = reponse;
        newLog.LG_Interface__c = 'GVAdmin';

        return newLog;
    }

    public class CustomException extends Exception {}
}