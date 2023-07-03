/**
 * Classe permettant de définir les différentes méthodes qui récupèrents les Product Rate Plan et qui permettent de créer des nouvelles
 * lignes de dévis pour la dévis concernée.
 *
 * @author Bilal El Aly
 * @date 16 Novembre 2020
 */
public with sharing class AP01_ProductRatePlanHelper {
    
    /**
     * Methode utilisée pour récupérer les Product Rate Plan deja choisis par l'utilisateur
     * @param quote id
     * @return List<id> Une liste de Product Rate Plan choisis
     */
    public static List<id> getQuoteProductRatePlansList(id quoteId) {
        list<QuoteLineItem> listQuoteLineItem = [ SELECT Product_Rate_Plan__c
                                                  FROM QuoteLineItem
                                                  WHERE QuoteId = :quoteId ];
        list<id> listProductRatePlanId = new List<id>();
        for(QuoteLineItem QLI : listQuoteLineItem) {
            listProductRatePlanId.add(QLI.Product_Rate_Plan__c);
        }

        return listProductRatePlanId;
    }

    /**
     * Methode utilisée pour récupérer les Product Rate Plan de type base de l'environnement avec les produits associés
     * @param quoteId id du devis
     * @return List<zqu__ProductRatePlan__c> Une liste de Product Rate Plan qui existent dans l'environnement
     */
    @AuraEnabled(cacheable = true)
    public static List<zqu__ProductRatePlan__c> getBaseProductRatePlansList(id quoteId) {
        Quote currentQuote = [SELECT Account.RecordType.DeveloperName
                              FROM Quote
                              WHERE id =:quoteId];
        Id pbId = ZuoraSubscriptionActions.getUserPricebookID(Id.valueOf(UserInfo.getUserId()));
        system.debug('pbId '+pbId);
        if(pbId != null) {
            // Check if the Price Book is shared with the current User
            String currentUserID = UserInfo.getUserId();
            UserRecordAccess accessCheck  = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :currentUserID AND RecordId = :pbId];

            if(accessCheck.HasReadAccess != false) {
                list<id> listProductRatePlanID = getQuoteProductRatePlansList(quoteId);
                string filterProd;
                if(currentQuote.Account.RecordType.DeveloperName.contains('SME')) {
                    filterProd = '%SME';
                } else {
                    filterProd = '%';
                }

                Id productId = [SELECT Product2Id
                                FROM PriceBookEntry
                                WHERE Pricebook2Id = : pbId AND isActive = true AND Product2.Name like: filterProd AND Product2.IsActive = true
                                ORDER BY Product2.Name
                                LIMIT 1].Product2Id;
                system.debug('productId '+productId);

                string filterCategory;
                if(currentQuote.Account.RecordType.DeveloperName == System.label.Distributor_RecordType) {
                    return [ SELECT Id, Name, zqu__Product__r.Name, zqu__ZuoraId__c, Type__c, Category__c
                             FROM zqu__ProductRatePlan__c
                             WHERE id NOT IN : listProductRatePlanID AND
                                 (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                 (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                             zqu__Deleted__c = FALSE AND zqu__ProductRatePlanFullName__c != : system.label.Rate_Plan_Timbre_Fiscal AND
                             Type__c = 'Base' AND zqu__Product__c = : productId AND Category__c like 'Distributor' ];

                } else {
                    list<string> listCategories = System.label.Exclude_categories_from_base_productList.split(',');

                    return [ SELECT Id, Name, zqu__Product__r.Name, zqu__ZuoraId__c, Type__c, Category__c
                             FROM zqu__ProductRatePlan__c
                             WHERE id NOT IN : listProductRatePlanID AND
                                 (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                 (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                             zqu__Deleted__c = FALSE AND zqu__ProductRatePlanFullName__c != : system.label.Rate_Plan_Timbre_Fiscal AND
                             Type__c = 'Base' AND zqu__Product__c = : productId AND Category__c NOT IN : listCategories ];
                }
            } else {
                throw new CustomException('User has no access to the priceBook2Id');
            }
        } else {
            return null;
        }
    }
    /**
     * Methode utilisée pour récupérer les Product Rate Plan de type accessoire de l'environnement avec les produits associés
     * @param quoteId id du devis
     * @return List<zqu__ProductRatePlan__c> Une liste de Product Rate Plan qui existent dans l'environnement
     */
    @AuraEnabled(cacheable = true)
    public static List<zqu__ProductRatePlan__c> getAddOnProductRatePlansList(id quoteId) {
        Quote currentQuote = [SELECT Account.RecordType.DeveloperName
                              FROM Quote
                              WHERE id =:quoteId];
        Id pbId = ZuoraSubscriptionActions.getUserPricebookID(Id.valueOf(UserInfo.getUserId()));

        if(pbId != null) {
            // Check if the Price Book is shared with the current User
            String currentUserID = UserInfo.getUserId();
            UserRecordAccess accessCheck  = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :currentUserID AND RecordId = :pbId];
            
            if(accessCheck.HasReadAccess != false)
            {
                list<id> listProductRatePlanID = getQuoteProductRatePlansList(quoteId);
                string filterProd;
                if(currentQuote.Account.RecordType.DeveloperName.contains('SME')) {
                    filterProd = '%SME';
                } else {
                    filterProd = '%';
                }

                string filterCategory;
                if(currentQuote.Account.RecordType.DeveloperName == System.label.Distributor_RecordType) {
                    filterCategory = 'Distributor';
                } else {
                    filterCategory = '%';
                }

                Id productId = [SELECT Product2Id
                                FROM PriceBookEntry
                                WHERE Pricebook2Id = : pbId AND isActive = true AND Product2.Name like: filterProd
                                ORDER BY Product2.Name
                                LIMIT 1].Product2Id;

                // return list of AddOn Products that are not coupon or Buncle c or Timbre
                return [ SELECT Id, Name, zqu__Product__c, zqu__Product__r.Name, zqu__ZuoraId__c, Type__c, Category__c
                         FROM zqu__ProductRatePlan__c
                         WHERE id NOT IN : listProductRatePlanID AND
                             (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                             (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                         zqu__Deleted__c = FALSE AND zqu__ProductRatePlanFullName__c != : system.label.Rate_Plan_Timbre_Fiscal AND Category__c != : System.label.Coupon AND
                         Type__c = 'AddOn' AND zqu__Product__c = : productId AND Category__c like : filterCategory AND category__c != 'Bundle C' /* IN (SELECT Product2Id
                                                                                                                                                    FROM PriceBookEntry
                                                                                                                                                    WHERE Pricebook2Id = : pbId AND isActive = true AND Product2.Name like: filterProd
                                                                                                                                                    ORDER BY Product2.Name
                                                                                                                                                    LIMIT 1)*/
                         ORDER BY Category__c DESC];
            } else {
                return null;
            }
        } else {
            return null;
        }
    }
    /**
     * Methode pour eviter l'insertion de plusieurs produit de base
     * @param quoteId id du devis
     * @param selectedJson liste des produits selectionnés
     * @return string
     */
    @AuraEnabled
    public static string verifySelectedProducts(id quoteId, string selectedJSON, boolean onlyBase){
        try {
            quote currentQuote = [SELECT Account.RecordType.DeveloperName
                                  FROM Quote WHERE Id = :quoteId LIMIT 1];
            //get base prod
            List<QuoteLineItem> listBaseQLI = [SELECT id, createdBy.CountryCode
                                               FROM QuoteLineItem
                                               WHERE quoteId = :quoteId AND Product_Rate_Plan__r.Type__c = 'Base'];
            //get equipment prod
            list<QuoteLineItem> listExistingQLI =  [ SELECT Id
                                                     FROM QuoteLineItem
                                                     WHERE QuoteId = :quoteId AND Product_Rate_Plan__r.Type__c = :System.label.Equipment_Type];

            List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(selectedJSON);
            integer existingBaseProduct = 0;
            integer canalBoxProduct = 0;
            string baseProductName;
            string serviceProductName = null;
            string ProductId;
            list<zqu__ProductRatePlan__c> listBoxFibre = new list<zqu__ProductRatePlan__c>();

            for(Object field : fieldList) {
                Map<String, Object> data = (Map<String, Object>) field;

                if((String)data.get('Type__c') == 'Base') {
                    existingBaseProduct = existingBaseProduct + 1;
                    baseProductName = (String)data.get('Name');
                }
                if( (String)data.get('Type__c') == 'AddOn' &&
                    (String)data.get('Category__c') == System.label.Equipment_Type) {
                    canalBoxProduct = canalBoxProduct + 1;
                }
                if( (String)data.get('Type__c') == 'AddOn' &&
                    (String)data.get('Category__c') == System.label.Service_installation) {
                    serviceProductName = (String)data.get('Name');
                }
                ProductId = (String)data.get('zqu__Product__c');
            }

            if(!onlyBase) {
                listBoxFibre = [SELECT id
                                FROM zqu__ProductRatePlan__c
                                WHERE Type__c = 'AddOn' AND Category__c = :System.label.Equipment_Type AND zqu__Product__c =:ProductId AND
                                    (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                    (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                                zqu__Deleted__c = FALSE];
            }
            // enforce user to have only one base product
            if(onlyBase && existingBaseProduct + listBaseQLI.size() > 1) {
                return system.label.Base_Product_Selection;
            } 
            else if(onlyBase && existingBaseProduct + listBaseQLI.size() == 0) {
                return system.label.LWC_Select_Product_Warning;
            }// partner account should not add add on product
            else if(currentQuote.Account.RecordType.DeveloperName != System.label.Distributor_RecordType)
            {
                if(!onlyBase && serviceProductName != null && !serviceProductName.contains(baseProductName) &&
                   (serviceProductName.contains('Premium') || serviceProductName.contains('Start')))
                {
                    return System.label.Incompatible_Product;
                }// enforce user to choose a box fibre product, if this product exist
                else if(!onlyBase && listBoxFibre.size() > 0 && ( (canalBoxProduct == 0 && listExistingQLI.size() == 0) || canalBoxProduct + listExistingQLI.size() > 1))
                {
                    return system.label.AddOn_Product_Selection;
                } else return null;
            } else return null;

        } catch(Exception e) {
            system.debug(e.getMessage() + ' ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Methode utilisée pour insérrer les lignes des dévis avec les Product Rate Plan choisis sur l'écran par le user
     * @param quoteId id du devis
     * @param selectedJson liste des produits selectionnés
     * @param paymentMethod mode de paiement
     * @param nbPeriod nombre de periode prepayee
     * @return string
     */
    @AuraEnabled
    public static string insertQuoteLineItems(String quoteId, String selectedJSON, string paymentMethod, string nbPeriod,
                                              string transactionNumber, string operator, string article, string creditOption, string aggregator,
                                              string offerName, list<string> listOptions, string equipments, string category) {
        try {
            string offerOptions = '';
            if(listOptions != null && listOptions.size() > 0) {
                for(string option : listOptions) {
                    offerOptions = offerOptions + option + ';';
                }
                offerOptions = offerOptions.substring(0, offerOptions.length() - 1);
            }

            List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(selectedJSON);

            // Get opportunity Price Book
            Quote currentQuote = [ SELECT Opportunity.PriceBook2Id, QUO_TECH_Nombre_De_Produits__c, QUO_Mode_de_paiement__c, QUO_Tech_Material__c,
                                   QUO_Periodes_Prepayees__c, QUO_Numero_de_transaction__c, QUO_T_Produit_De_Base__c, QUO_Operateur__c,
                                   QUO_Reference_article__c, QUO_Credit_Option__c, QUO_Aggregator__c, QUO_Offer__c, QUO_Options__c
                                   FROM Quote
                                   WHERE id = :id.valueOf(quoteId)];

            if(currentQuote.Opportunity.PriceBook2Id != null) {
                // Get all Price Book Entries for the selected Price Book
                List<PricebookEntry> pbeList = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice
                                                FROM PricebookEntry
                                                WHERE Pricebook2Id = :currentQuote.Opportunity.PriceBook2Id];

                if(pbeList.size() > 0) {
                    Map<Id, PriceBookEntry> pbePerProductMap = new Map<Id, PricebookEntry>();
                    for(PricebookEntry PBE : pbeList) {
                        pbePerProductMap.put(PBE.Product2Id, PBE);
                    }

                    //Get price of product rate plan charge for the selected Price Book
                    list<zqu__productrateplanchargetier__c> listProductRatePlanPrice = [ SELECT zqu__Price__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, zqu__DiscountAmount__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name
                                                                                         FROM zqu__productrateplanchargetier__c
                                                                                         WHERE(zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Product__c IN: pbePerProductMap.keyset() AND
                                                                                                   (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                                   (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                                                               zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ProductRatePlanFullName__c != : system.label.Rate_Plan_Timbre_Fiscal)
                                                                                         OR (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Category__c = 'Bundle C')
                                                                                         order by zqu__Price__c ];
                    // if products of type Fiber or Bundle is found for the specific priceBook -->
                    if(listProductRatePlanPrice != null && listProductRatePlanPrice.size() > 0) {

                        Map<Id, Double> pricePerProductRatePlanMap = new Map<Id, Double>();
                        double discountAmount = 0;
                        double originalAmount = 0;
                        // Map Each product rate plan Id with his Price
                        for(zqu__productrateplanchargetier__c PRPC : listProductRatePlanPrice) {
                            Double price = Double.valueof(PRPC.zqu__Price__c);

                            // calculate the Dicount amount of Booster products
                            if(PRPC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name.contains('Booster')) {
                                if(price > 0 && Double.valueof(PRPC.zqu__DiscountAmount__c) > 0) {
                                    discountAmount = Double.valueof(PRPC.zqu__DiscountAmount__c);
                                } else if(price > 0 && string.isBlank(string.valueof(PRPC.zqu__DiscountAmount__c)) ) {

                                    originalAmount = price;
                                }
                                if(discountAmount > 0 && originalAmount > 0) {
                                    pricePerProductRatePlanMap.put(PRPC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, originalAmount - discountAmount);
                                }
                            } else {
                                pricePerProductRatePlanMap.put(PRPC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, price);
                            }

                        }

                        List<QuoteLineItem> listQuoteLineItemsToInsert = new List<QuoteLineItem>();
                        string baseProd = null;
                        string productId;
                        if(pbeList.size() > 0 && pbePerProductMap.keySet().size() > 0) {
                            // fieldList is the selected fiber product
                            for(Object fld : fieldList) {
                                Map<String, Object> data = (Map<String, Object>) fld;
                                if((String) data.get('Type__c') == 'Base') {
                                    baseProd =  (String) data.get('Name');
                                }
                                productId = (String)data.get('zqu__Product__c');
                                //Create Quote Line Items for the Quote
                                QuoteLineItem item = new QuoteLineItem();
                                item.QuoteId = quoteId;
                                item.Product2Id = (String) data.get('zqu__Product__c');
                                item.Product_Rate_Plan__c = (String) data.get('Id');
                                item.Quantity = 1;
                                item.UnitPrice = pricePerProductRatePlanMap.get(item.Product_Rate_Plan__c);
                                item.PricebookEntryId = pbePerProductMap.get(item.Product2Id).Id;
                                listQuoteLineItemsToInsert.add(item);
                            }
                        }
                        // If equipments and options of Bundle Products not null
                        if(equipments != null && !string.isblank(equipments) && listOptions != null && listOptions.size() > 0) {
                            string access = baseProd + ' ' + category;

                            listOptions.add(access);
                            list<zqu__ProductRatePlan__c> listBundleProducts = [SELECT id, name, zqu__Product__r.name, Category__c, zqu__Product__c
                                                                                FROM zqu__ProductRatePlan__c
                                                                                WHERE Category__c = 'Bundle C' AND zqu__Product__c = :productId AND name IN :listOptions ];

                            if(listBundleProducts.size() > 0 && listBundleProducts != null) {
                                for(zqu__ProductRatePlan__c bundlePRP : listBundleProducts) {
                                    QuoteLineItem item = new QuoteLineItem();
                                    item.QuoteId = quoteId;
                                    item.Product2Id = bundlePRP.zqu__Product__c;
                                    item.Product_Rate_Plan__c = bundlePRP.Id;
                                    item.Quantity = 1;
                                    item.UnitPrice = pricePerProductRatePlanMap.get(item.Product_Rate_Plan__c);
                                    item.PricebookEntryId = pbePerProductMap.get(item.Product2Id).Id;
                                    listQuoteLineItemsToInsert.add(item);
                                }
                            }

                        }
                        system.debug('listQuoteLineItemsToInsert---' + listQuoteLineItemsToInsert);
                        insert listQuoteLineItemsToInsert;

                        // fill payment info + offer and option info of Bundle product on the Quote
                        if(paymentMethod != null || nbPeriod != null) {
                            // update quote fields

                            currentQuote.QUO_TECH_Nombre_De_Produits__c = fieldList.size();
                            currentQuote.QUO_Mode_de_paiement__c = paymentMethod;
                            currentQuote.QUO_Periodes_Prepayees__c = nbPeriod;
                            currentQuote.QUO_Numero_de_transaction__c = transactionNumber;
                            currentQuote.QUO_T_Produit_De_Base__c = baseProd;
                            currentQuote.QUO_Operateur__c = operator;
                            currentQuote.QUO_Reference_article__c = article;
                            currentQuote.QUO_Credit_Option__c = creditOption;
                            currentQuote.QUO_Aggregator__c = aggregator;
                            // Bundle info
                            currentQuote.QUO_Tech_Material__c = equipments;
                            currentQuote.QUO_Offer__c = offerName;
                            currentQuote.QUO_Options__c = offerOptions;
                            update currentQuote;
                        }

                        // update used equipment to Already_Used__c true in the equipment custom object
                        if(equipments != null && !string.isBlank(equipments)) {
                            list<equipment__c> listEquipment = new list<equipment__c>();
                            List<Object> fieldEqList = (List<Object>) JSON.deserializeUntyped(equipments);
                            for(Object fld : fieldEqList) {
                                Map<String, Object> data = (Map<String, Object>) fld;

                                equipment__c eq = new equipment__c( id = (String)data.get('Id'), Equipment_Type__c = (String)data.get('Equipment_Type__c'), Equipment_Id__c = (String)data.get('Equipment_Id__c'), Already_Used__c = true );
                                listEquipment.add(eq);

                            }
                            if(listEquipment.size() > 0) {
                                update listEquipment;
                            }
                        }

                        return null;
                    } else {
                        return System.label.Products_Not_Found;
                    }
                } else {
                    return System.label.PriceBook_Or_PBE_Not_Found;
                }
            } else {
                return System.label.PriceBook_Or_PBE_Not_Found;
            }
        }
        catch(Exception e) {
            system.debug('Insert QLI exception: ' + e.getMessage() + ' ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * Methode utilisée pour récupérer les Product Rate Plan deja choisis par l'utilisateur
     * @param quote id
     * @return List<QuoteLineItem> Une liste de Product qui existent dans l'environnement
     */
    @AuraEnabled
    public static List<QuoteLineItem> getQuoteLineItemProductRatePlansList( id quoteId) {
        List<QuoteLineItem> listQLI = [
            SELECT
            Product_Rate_Plan__r.zqu__ProductRatePlanFullName__c,
            Product_Rate_Plan__r.zqu__Price_Summary__c,
            UnitPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ];

        return listQLI;
    }

    /**
     * Méthode utilisée pour récupérer les valeurs du champ categorie
     * @param quoteId id du devis
     */
    @AuraEnabled
    public static list<string> getCategoryValues(id quoteId){
        try {
            /* Schema.SObjectType s = Schema.getGlobalDescribe().get('zqu__productRatePlan__c') ;
               Schema.DescribeSObjectResult r = s.getDescribe() ;
               Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
               Schema.DescribeFieldResult fieldResult = fields.get('category__c').getDescribe();
               List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
               List<string> plv = new list<string>();
               for( Schema.PicklistEntry pickListVal : ple){
                 if(pickListVal.getValue() != 'Offer')
                 {
                     plv.add(pickListVal.getValue());
                 }
               }
               return plv;*/
            set<string> distinctPlv = new set<string>();
            list<string> plv = new list<string>();
            //get Add on Product
            List<zqu__ProductRatePlan__c> listProducts = getAddOnProductRatePlansList(quoteId);
            if(listProducts.size() > 0 && listProducts != null) {
                // get category of each product
                for(zqu__ProductRatePlan__c zPr : listProducts) {
                    distinctPlv.add(zPr.Category__c);
                }
            }
            //convert set to list
            plv.addAll(distinctplv);

            return plv;

        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Methode utilisée pour récupérer les Product Rate Plan de type addOn de l'environnement avec les produits associés
     * @param quote id
     * @return List<zqu__ProductRatePlan__c> Une liste de Product Rate Plan qui existent dans l'environnement
     */
    /*  public static List<zqu__ProductRatePlan__c> getAddOnProductList(id quoteId) {

          Id pbId = ZuoraSubscriptionActions.getUserPricebookID(Id.valueOf(UserInfo.getUserId()));

          if (pbId != null) {
              list<id> listProductRatePlanID = getQuoteProductRatePlansList(quoteId);

              return [
                  SELECT Id, Name, zqu__Product__r.Name, zqu__ZuoraId__c
                  FROM zqu__ProductRatePlan__c
                  WHERE id NOT IN : listProductRatePlanID AND zqu__Deleted__c = FALSE
                  AND zqu__EffectiveEndDate__c > TODAY AND Type__c = 'AddOn'
                  AND zqu__ProductRatePlanFullName__c != :system.label.Rate_Plan_Timbre_Fiscal
                  AND zqu__Product__c IN (
                      SELECT Product2Id
                      FROM PriceBookEntry
                      WHERE Pricebook2Id = : pbId)];
          } else {
              return null;
          }
       }*/
    @AuraEnabled(cacheable = true)
    public static map<String, list<string>> getDependentPicklistValues(list<string> listFieldName){

        User currentUser = [SELECT Id, CountryCode
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1 ];

        String objectName = 'Quote';
        map<String, list<string>> mapFieldDependencies = new map<String, list<string>>();
        for(string fieldName : listFieldName) {
            //Get the type being dealt with
            Schema.SObjectType objType = Schema.getGlobalDescribe( ).get(objectName);
            Schema.DescribeSObjectResult describeResult = objType.getDescribe();
            //Get controlling field values
            Schema.DescribeFieldResult depend = describeResult.fields.getMap().get(fieldName).getDescribe ( );

            //Schema.DescribeFieldResult depend = dependToken.getDescribe();
            Schema.sObjectField controlToken = depend.getController();

            if(controlToken == null) return null;
            Schema.DescribeFieldResult control = controlToken.getDescribe();
            List<Schema.PicklistEntry> controlEntries = (control.getType() == Schema.DisplayType.Boolean?   null :   control.getPicklistValues());

            String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
            Map<Object, List<String>> dependentPicklistValues = new Map<Object, List<String>>();
            for(Schema.PicklistEntry entry : depend.getPicklistValues() ) if(entry.isActive() ) {
                    List<String> base64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )).split( '' );
                    for(Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {

                        Object controlValue =
                        (controlEntries == null?   (Object) (index == 1) : (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getValue() : null));
                        Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                        // if(controlValue == null ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        //     continue;
                        if(!dependentPicklistValues.containsKey( controlValue ) ) {
                            dependentPicklistValues.put( controlValue, new List<String>() );
                        }
                        dependentPicklistValues.get( controlValue ).add( entry.getValue() );
                    }
                }
            mapFieldDependencies.put(fieldName, dependentPicklistValues.get(currentUser.CountryCode));
        }

        return mapFieldDependencies;

    }
    public class CustomException extends Exception {}
}