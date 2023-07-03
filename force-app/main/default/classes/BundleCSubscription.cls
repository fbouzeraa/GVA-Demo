/**
 * BundleCSubscription classe include all functions to create, activate,cancel,suspend and renew a Sub
 */

public with sharing class BundleCSubscription {
    /**
     * Method used to get all products of Bundle C related to the client country
     * @param recordId id of zuora subscription
     */
    @AuraEnabled(cacheable = true)
    public static list<Product2> getBundleProducts (id recordId, string fromQuote){

        try {
            // renewable product = 0 on create and = 1 on renew
            string renewable = '0';
            string countryCode;
            // If request sent from quote that means before creation of Zuora subscription
            if(fromQuote == 'false') {

                Zuora__Subscription__c currentSub = [SELECT Zuora__Account__r.BillingCountryCode, SUB_Subscription_Number__c, SUB_Status__c, SUB_Subscriber_Number__c
                                                     FROM Zuora__Subscription__c
                                                     WHERE id = :recordId
                                                     LIMIT 1];
                countryCode = currentSub.Zuora__Account__r.BillingCountryCode;
                if((currentSub.SUB_Subscriber_Number__c != null || currentSub.SUB_Subscription_Number__c != null) && currentSub.SUB_Status__c != 'Cancelled') {
                    renewable = '1';
                } else if((currentSub.SUB_Subscriber_Number__c != null || currentSub.SUB_Subscription_Number__c != null) && currentSub.SUB_Status__c == 'Cancelled') {
                    renewable = '0';
                }
            } else {

                Quote currentQuote = [SELECT Account.BillingCountryCode
                                      FROM Quote
                                      WHERE id = :recordId
                                      LIMIT 1];
                countryCode = currentQuote.Account.BillingCountryCode;
            }
            list<product2> listProd =  [SELECT Id, Name, ProductCode, Family, Company__c, PRO_Country_Code__c, PRO_Canal_Options__c, PRO_Renewable__c, PRO_Duree__c
                                        FROM product2
                                        WHERE PRO_Country_Code__c = : countryCode AND PRO_Renewable__c = : renewable];

            map<string, product2> mapProduct = new map<string, product2>();

            for(product2 prod : listProd) {
                mapProduct.put(prod.Family, prod);
            }

            return mapProduct.values();
        } catch(Exception e) {
            system.debug('exception get offer '+e.getLineNumber()+': '+e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }
    /**
     * Method used to get Bundle C equiment related to the client country
     * @param recordId id of zuora subscription
     */
    @AuraEnabled(cacheable = true)
    public static list<Equipment__c> getEquipmentList (id recordId, string fromQuote, string material){

        try {
            string countryCode; 
            list<Equipment__c> listEquipsToreturn = new list<Equipment__c>();     

            list<String> listOfFilters = new list<String>();
            if(material != null && material.contains(System.Label.Bundle_Material_MATOTT)){
                listOfFilters.add(System.Label.Bundle_Equip_type_54);
            }else if (material != null && material.contains(System.Label.Bundle_Material_TERMZ4)){
                listOfFilters.add(System.Label.Bundle_Equip_type_Z4);
            }else if(material != null && material.contains(System.Label.Bundle_Material_TERMG11A)){
                listOfFilters.add(System.Label.Bundle_Equip_type_G11A);
                listOfFilters.add(System.Label.Bundle_Equip_type_NVSAG11A);
            }else if(material != null && material.contains('Carte G11')){
                listOfFilters.add(System.Label.Bundle_Equip_type_NVSAG11A);
            }
            else{
                listOfFilters.add(System.Label.Bundle_Equip_type_54);
                listOfFilters.add(System.Label.Bundle_Equip_type_G11A);
                listOfFilters.add(System.Label.Bundle_Equip_type_NVSAG11A);
                listOfFilters.add(System.Label.Bundle_Equip_type_Z4);
            }

            if(fromQuote == 'false') {
                list<Zuora__Subscription__c> currentSub = [SELECT Zuora__Account__r.BillingCountryCode
                                                     FROM Zuora__Subscription__c
                                                     WHERE id = :recordId
                                                     LIMIT 1];
                if(currentSub != null && currentSub.size() > 0)
                countryCode   = currentSub[0].Zuora__Account__r.BillingCountryCode;
            } else {
                list<Quote> currentQuote = [SELECT Account.BillingCountryCode
                                      FROM Quote
                                      WHERE id = :recordId
                                      LIMIT 1];
                if(currentQuote != null && currentQuote.size() > 0)
                countryCode   = currentQuote[0].Account.BillingCountryCode;
            }

            listEquipsToreturn = [SELECT Equipment_Id__c, Equipment_Type__c, EQ_Decodeur__c, EQ_Have_Decoder__c
                                FROM Equipment__c
                                WHERE Country_Code__c = : countryCode AND Already_Used__c = false AND Equipment_Type__c IN :listOfFilters
                                ];
            return listEquipsToreturn;

        } catch(Exception e) {
            system.debug(e.getLineNumber()+': '+e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }
    /**
     * Method to Subscribe to C+ Bundle
     * @param recordId
     * @param offerName
     * @param listOptions
     * @param equipmentId
     * @param equipmentType
     * @param period
     */
    @AuraEnabled
    public static string subscribeToC (id recordId, string offerName, list<string> listOptions, string equipments, string period, Boolean fromRenewButton){
        try {
            Account acc;
            Contact con;
            string offerOptions = '';
            string equipmentType = '';
            string equipmentId = '';
            if(listOptions != null && listOptions.size() > 0)
            {
                for(string option : listOptions) {
                    offerOptions = offerOptions + option + ';';
                }

                // remove last character ';'
                offerOptions = offerOptions.substring(0, offerOptions.length() - 1);
            }

            Zuora__Subscription__c currentSub = [SELECT Name, Zuora__Account__r.IsPersonAccount, Zuora__Account__c, SUB_Offer__c, SUB_Options__c, Zuora__Account__r.Phone, SUB_Tech_Material__c, 
                                                 Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Subscription_Number__c, SUB_Status__c, SUB_End_Date__c, Prior_expedted_renewal_Date__c,
                                                 SUB_EquipmenId_CBundle__c, SUB_EquipmentType_CBundle__c, SUB_Subscriber_Number__c, SUB_Bundle_Contract_Id__c, Create_Bundle_C_subscription__c  
                                                 FROM Zuora__Subscription__c
                                                 WHERE id = :recordId
                                                 LIMIT 1];
            acc = [SELECT Salutation, FirstName, LastName, personMobilePhone, BillingCity, BillingCountryCode, BillingStreet, personEmail, IsPersonAccount, Phone, QU_Quartier__c
                   FROM Account
                   WHERE id = :currentSub.Zuora__Account__c
                   LIMIT 1];
            
            if(!currentSub.Zuora__Account__r.IsPersonAccount) {
                con = [SELECT Salutation, FirstName, LastName, MobilePhone, MailingCity, MailingCountryCode, MailingStreet, Email, Phone
                        FROM Contact
                        WHERE AccountId = :currentSub.Zuora__Account__c
                        LIMIT 1];
            }

            // get selected rows from LWC JS return a list of object type or from the technical field SUB_Tech_Material__c if it's a -renew fiber but create bundle-
            List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(equipments);

            list<equipment__c> listEquipment = new list<equipment__c>();
            if(fieldList != null && fieldList.size() > 0){
                for(Object fld : fieldList) {

                    Map<String, Object> data = (Map<String, Object>) fld;

                    equipment__c eq = new equipment__c( id = (String)data.get('Id'), Equipment_Type__c = (String)data.get('Equipment_Type__c'), Equipment_Id__c = (String)data.get('Equipment_Id__c'));
                    if(!eq.Already_Used__c){
                        eq.Already_Used__c = true;
                        listEquipment.add(eq);
                    }
                    if((boolean)data.get('EQ_Have_Decoder__c') || fieldList.size() == 1) {
                        equipmentId = (String)data.get('Equipment_Id__c');
                        equipmentType = (String)data.get('Equipment_Type__c');
                    }
                }
            }

            integer prepaidPeriod = (period == null || period == '')? 0:Integer.valueOf(period);

            // create bundle subscription object and send the request
            CBundleObjects.CESAR_SUBSCRIPTION cBundleSub = BundleCMapper.fillCreateSubscription(acc, con, currentSub, prepaidPeriod, offerName, listOptions, listEquipment);

            HttpResponse response = BundleCManager.doCallout(CBundleObjects.subscriptionAPIUrl, CBundleObjects.post, json.serialize(cBundleSub, true));
            system.debug('Bundle response '+response.getBody());
            CBundleObjects.newSubResponse newSub =  (CBundleObjects.newSubResponse) JSON.deserialize(response.getBody(), CBundleObjects.newSubResponse.class);
            
            // create log of the request
            Log__c lg = createBundleLog(json.serialize(cBundleSub, true), currentSub.Zuora__Account__c, currentSub.Id, null, CBundleObjects.subscriptionAPIUrl,
                                        response.getBody(), newSub.returnCode == 'OK'?true : false, newSub.message, CBundleObjects.post);

            if(newSub.returnCode == 'OK') {

                currentSub.SUB_Subscriber_Number__c = newSub.data.numabo;
                currentSub.SUB_Status__c = 'Active';
                currentSub.SUB_End_Date__c = date.today().addMonths(prepaidPeriod);
                currentSub.SUB_Offer__c = offerName;
                currentSub.SUB_Options__c = offerOptions == null ? null : offerOptions;
                currentSub.SUB_EquipmentType_CBundle__c = equipmentType;
                currentSub.SUB_EquipmenId_CBundle__c = equipmentId;
                currentSub.SUB_Bundle_Contract_Id__c = currentSub.SUB_Subscription_Number__c == null?currentSub.Name : currentSub.Name + '-' + currentSub.SUB_Subscription_Number__c;
                currentSub.SUB_Subscription_Number__c = newSub.data.numabont;
                currentSub.Create_Bundle_C_subscription__c = false;
                currentSub.SUB_Activation_Date__c = Date.Today();
                update currentSub;

                if(listEquipment.size() > 0) {
                    update listEquipment;
                }

                // create C Bundle follow up
                createBundleFollowUp(currentSub, 'ACT001', null);
            }

            insert lg;

            return response.getBody();
        } catch(Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            throw new CustomException('Line: '+e.getLineNumber() + ' ' + e.getMessage());
        }
    }

    /**
     * Method to get C+ bundle subscription
     * @param recordId subscription Id
     */
    @AuraEnabled(Cacheable = true)
    public static Zuora__Subscription__c getCanalSubscription (id recordId){
        try {

            return [SELECT Name, SUB_Subscription_Number__c, SUB_Bundle_Contract_Id__c, SUB_Subscriber_Number__c, SUB_Status__c, SUB_End_Date__c,  C_Migration_Date__c, CurrencyIsoCode,
                    SUB_EquipmenId_CBundle__c, SUB_EquipmentType_CBundle__c, SUB_Activation_Date__c, CBundle_Periode__c, Zuora__Account__r.BillingCountryCode, Zuora__Status__c,SUB_T_Produit_De_Base__c
                    FROM Zuora__Subscription__c
                    WHERE id = : recordId
                    LIMIT 1];

        } catch(Exception e) {

            throw new CustomException(e.getMessage());
        }
    }

    /**
     * Method to Verify if selected iptions exist all in one offer and return the period value
     * @param recordId subscription Id
     */
    @AuraEnabled
    public static string verifiyOptionsCompatibility (id recordId, string fromQuote, string productName, string category, list<string> listOPtions, string renewable){

        try {
            string options = ''; string allOptions;
            if(listOPtions != null && listOPtions.size() > 0) {
                for(string option : listOPtions) {
                    if(option != null && !string.isBlank(option)){
                        options = options + option + ';';
                    }
                }
                // remove last character ';'
                options = options != null && options != '' ? options.substring(0, options.length() - 1) : null;
                allOptions = options != null && options != '' ? '(\'' + options + '\')' : null;
            }

            string countryCode;
            if(fromQuote == 'false') {
                Zuora__Subscription__c currentSub = [SELECT Zuora__Account__r.BillingCountryCode
                                                     FROM Zuora__Subscription__c
                                                     WHERE id = :recordId
                                                     LIMIT 1];
                countryCode   = currentSub.Zuora__Account__r.BillingCountryCode;
            } else {
                Quote currentQuote = [SELECT Account.BillingCountryCode
                                      FROM Quote
                                      WHERE id = :recordId
                                      LIMIT 1];
                countryCode   = currentQuote.Account.BillingCountryCode;
            }
            system.debug(countryCode + ' ' + allOptions + ' ' + renewable + ' ' + category + ' ' + productName);
            String query = 'SELECT id, PRO_Duree__c ';
            query += 'FROM Product2 ';
            query += 'WHERE  PRO_Country_Code__c = :countryCode  AND Family = :category AND Name = :productName  AND PRO_Renewable__c = :renewable ';
            if(allOptions != null){
                query += 'AND PRO_Canal_Options__c includes ' + allOptions;
            }

            List<Product2> listProduct = Database.query(query);
            if(listProduct != null && listProduct.size() > 0) {
                return listProduct[0].PRO_Duree__c;
            } else {
                return null;
            }

        } catch(Exception e) {
            system.debug('getCanal Sub error  '+e.getLineNumber()+'  >>>>> '+e.getMessage());
            throw new CustomException(e.getMessage()+'  '+e.getLineNumber());
        }
    }

    /**
     * Method to Cancel the subscription to C+ Bundle
     * @param recordId
     * @param cancelReason
     */
    @AuraEnabled
    public static string cancelBundleC (id recordId, string cancelReason){
        try {

            string cancelResponse;
            Zuora__Subscription__c currentSub = [SELECT Name, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Subscription_Number__c, SUB_Bundle_Contract_Id__c,
                                                 SUB_Subscriber_Number__c, SUB_Status__c, SUB_EquipmenId_CBundle__c, SUB_EquipmentType_CBundle__c,
                                                 Create_Bundle_C_subscription__c, SUB_Tech_Material__c, SUB_Offer__c,SUB_Options__c     
                                                 FROM Zuora__Subscription__c
                                                 WHERE id = :recordId
                                                 LIMIT 1];
            
            if(currentSub != null)
            {
                list<equipment__c> listEquipment = new list<equipment__c>();
                CBundleObjects.newSubResponse cancelSub = new CBundleObjects.newSubResponse();
                // if Bundle subscription is active send a cancel request to canal + //// if subscription not active yet just liberate the equipment
                if(currentSub.SUB_Status__c == 'Active' && currentSub.SUB_Subscription_Number__c != null && currentSub.SUB_Subscriber_Number__c != null && currentSub.SUB_Tech_Material__c != null)
                {
                    CBundleObjects.CESAR_CANCELLATION cancelCBundleSub = BundleCMapper.fillCancelSubscription(currentSub, cancelReason);
                    HttpResponse response = BundleCManager.doCallout(CBundleObjects.cancellationAPIUrl, CBundleObjects.put, json.serialize(cancelCBundleSub, true));
                    cancelSub =  (CBundleObjects.newSubResponse) JSON.deserialize(response.getBody(), CBundleObjects.newSubResponse.class);

                    listEquipment = [SELECT Id, Already_Used__c
                                    FROM Equipment__c 
                                    WHERE Equipment_Id__c =:currentSub.SUB_EquipmenId_CBundle__c AND Equipment_Type__c =: currentSub.SUB_EquipmentType_CBundle__c];
                    
                    cancelResponse = response.getBody();
                }
                else{
    
                    List<Object> equips = (List<Object>) JSON.deserializeUntyped(currentSub.SUB_Tech_Material__c);

                    if(equips != null && equips.size() > 0){
                        for(Object fld : equips) {
        
                            Map<String, Object> data = (Map<String, Object>) fld;
        
                            equipment__c eq = new equipment__c( id = (String)data.get('Id'));
                            listEquipment.add(eq);
                        }
                    }

                    cancelResponse = 'Done';
                }
                    
                if(cancelResponse == 'Done' || cancelSub.returnCode == 'OK') {
                    currentSub.SUB_Status__c = 'Cancelled';
                    currentSub.Create_Bundle_C_subscription__c = false;
                    // currentSub.SUB_End_Date__c = date.today();
                    
                    for(equipment__c equ : listEquipment){
                        equ.Already_Used__c = false;
                    }

                    update listEquipment;
                    update currentSub;

                    createBundleFollowUp(currentSub, 'ACT002', null);
                }
            }
            else{
                cancelResponse = System.Label.Subscription_Not_Found;
            }

            return cancelResponse;
        } catch(Exception e) {
            system.debug(e.getMessage() + ' ' + e.getLineNumber());
            throw new CustomException(e.getMessage() + '   ' + e.getLineNumber());
        }
    }
    /**
     * Method to renew the subscription to C+ Bundle
     * @param recordId
     * @param prepaidPeriod
     * @param offer
     * @param options
     * @param fromRenewButton
     */
    @AuraEnabled
    public static string renewBundleC (id recordId, integer prepaidPeriod, string offer, list<string> options, boolean fromRenewButton){
        try {
            Zuora__Subscription__c currentSub = [SELECT Name, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Subscription_Number__c,
                                                 SUB_Subscriber_Number__c, SUB_Status__c, SUB_Bundle_Contract_Id__c, Zuora__Account__c,  
                                                 SUB_Offer__c, SUB_Options__c, SUB_End_Date__c, SUB_EquipmenId_CBundle__c, SUB_Tech_Material__c
                                                 FROM Zuora__Subscription__c
                                                 WHERE id = :recordId
                                                 LIMIT 1];

            CBundleObjects.CESAR_RENEWAL renewCBundleSub = BundleCMapper.fillRenewSubscription(currentSub, prepaidPeriod, offer, options);

            HttpResponse response = BundleCManager.doCallout(CBundleObjects.reactivationAPIUrl, CBundleObjects.put, json.serialize(renewCBundleSub, true));
            CBundleObjects.subActionsResponse renewSub =  (CBundleObjects.subActionsResponse) JSON.deserialize(response.getBody(), CBundleObjects.subActionsResponse.class);
            // create log of the request
            Log__c lg = createBundleLog(json.serialize(renewCBundleSub, true), currentSub.Zuora__Account__c, currentSub.Id, null, CBundleObjects.reactivationAPIUrl,
                                        response.getBody(), renewSub.codeHttp == 201?true : false, null, CBundleObjects.put);
            insert lg;
            Zuora__Subscription__c subToupdate = new Zuora__Subscription__c();
            if(renewSub.codeHttp == 201) {
                if(renewSub.severity == 'SUCCESS') {
                    subToupdate.id = recordId;
                    subToupdate.SUB_End_Date__c = (currentSub.SUB_End_Date__c == null || currentSub.SUB_End_Date__c < date.today())?date.today().addMonths(prepaidPeriod) : currentSub.SUB_End_Date__c.addMonths(prepaidPeriod);
                    subToupdate.SUB_Offer__c = offer;
                    subToupdate.CBundle_Periode__c = prepaidPeriod;
                    subToupdate.SUB_Activation_Date__c = Date.Today();
                    string offerOptions = '';
                    if(options != null && options.size() > 0) {
                        for(string option : options) {
                            offerOptions = offerOptions + option + ';';
                        }
                        offerOptions = offerOptions.substring(0, offerOptions.length() - 1);
                    }

                    subToupdate.SUB_Options__c = offerOptions;

                    createBundleFollowUp(currentSub, 'ACT003', null);
                }
            }
            if(fromRenewButton) {
                return json.serialize(subToupdate);
            } else {
                if(renewSub.severity == 'SUCCESS') {
                    update subToupdate;
                }

                return response.getBody();
            }

        } catch(Exception e) {
            system.debug(e.getMessage() + e.getLineNumber());
            throw new CustomException(e.getMessage());
        }
    }
    /**
     * Method to suspend the subscription to C+ Bundle
     * @param recordId
     * @param suspensionReason
     * @param suspensionDate
     */
    @AuraEnabled
    public static string suspendBundleC (id recordId, String suspensionReason, String suspensionDate){
        try {
            Zuora__Subscription__c currentSub = [SELECT Name, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Subscription_Number__c, SUB_EquipmenId_CBundle__c,  
                                                 SUB_Status__c, SUB_Offer__c, SUB_Options__c, SUB_End_Date__c, SUB_Subscriber_Number__c, SUB_Bundle_Contract_Id__c, SUB_Tech_Material__c
                                                 FROM Zuora__Subscription__c
                                                 WHERE id = :recordId
                                                 LIMIT 1];
            CBundleObjects.CESAR_SUSPENSION suspendCBundleSub = BundleCMapper.fillSuspendSubscription(currentSub, suspensionReason, suspensionDate);

            HttpResponse response = BundleCManager.doCallout(CBundleObjects.suspensionAPIUrl, CBundleObjects.put, json.serialize(suspendCBundleSub, true));
            CBundleObjects.subActionsResponse suspendSub =  (CBundleObjects.subActionsResponse) JSON.deserialize(response.getBody(), CBundleObjects.subActionsResponse.class);

            if(suspendSub.codeHttp == 200) {
                currentSub.SUB_Status__c = 'Suspended';
                update currentSub;

                createBundleFollowUp(currentSub, 'ACT006', null);
            }

            return response.getBody();
        } catch(Exception e) {
            system.debug('suspend catch ' + e);
            throw new CustomException(e.getMessage());
        }
    }
    /**
     * Method to Modify Offer of the subscription C+ Bundle
     * @param recordId
     * @param offerName
     * @param listOptions
     */
    @AuraEnabled
    public static string modifyOfferBundleC (Id recordId,  string offerName, list<string> listOptions){
        try {
            string offerOptions = '';

            for(string option : listOptions) {
                offerOptions = offerOptions + option + ';';
            }
            offerOptions = offerOptions.substring(0, offerOptions.length() - 1);

            Zuora__Subscription__c currentSub = [SELECT Name, Zuora__Account__c, SUB_Offer__c, SUB_Options__c, SUB_Subscriber_Number__c, SUB_EquipmenId_CBundle__c,   
                                                 Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Subscription_Number__c, SUB_Bundle_Contract_Id__c,SUB_Tech_Material__c
                                                 FROM Zuora__Subscription__c
                                                 WHERE id = :recordId
                                                 LIMIT 1];

            CBundleObjects.CESAR_MODIFYOFFER modifyOfferCBundleSub = BundleCMapper.fillModifyOffer(currentSub, offerName, listOptions);

            HttpResponse response = BundleCManager.doCallout(CBundleObjects.modifyOffersAPIUrl, CBundleObjects.patch, json.serialize(modifyOfferCBundleSub, true));

            CBundleObjects.subActionsResponse modifyOfferSub =  (CBundleObjects.subActionsResponse) JSON.deserialize(response.getBody(), CBundleObjects.subActionsResponse.class);
            if(modifyOfferSub.codeHttp == 200) {
                currentSub.SUB_Offer__c = offerName;
                currentSub.SUB_Options__c = offerOptions;
                update currentSub;
                createBundleFollowUp(currentSub, 'ACT004', null);
            }

            return response.getBody();
        } catch(Exception e) {
            system.debug('modify catch ' + e.getMessage() + ' ' + e.getLineNumber());
            throw new CustomException(e.getMessage());
        }
    }

    /**
     * Method to Fast reactivate the subscription to C+ Bundle
     * @param recordId
     */
    @AuraEnabled
    public static string fastRenewBundleC (Id recordId){
        try {
            Zuora__Subscription__c currentSub = [SELECT Name, Zuora__Account__c, SUB_Offer__c, SUB_Options__c, SUB_Subscriber_Number__c,
                                                 Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Subscription_Number__c, SUB_Bundle_Contract_Id__c
                                                 FROM Zuora__Subscription__c
                                                 WHERE id = :recordId
                                                 LIMIT 1];

            CBundleObjects.CESAR_FAST_REACTIVATION fastReactivateCBundleSub = BundleCMapper.fillFastRenewSubscription(currentSub);

            HttpResponse response = BundleCManager.doCallout(CBundleObjects.fastReactivationAPIUrl, CBundleObjects.patch, json.serialize(fastReactivateCBundleSub, true));

            CBundleObjects.subActionsResponse fastRenewOfferSub =  (CBundleObjects.subActionsResponse) JSON.deserialize(response.getBody(), CBundleObjects.subActionsResponse.class);

            // if(fastRenewOfferSub.returnCode == 'OK') {

            //    update currentSub;
            // }

            return response.getBody();
        } catch(Exception e) {
            system.debug('fast renew catch ' + e.getLineNumber() + ': ' + e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }

    /**
     * Methode utilisée pour activer l'abo C+
     * @param subId id de l'abo
     */
    @AuraEnabled
    public static string activateCBundle(id subId,  Date activationDate){

        List<Zuora__Subscription__c> updatedSubs = new List<Zuora__Subscription__c>();

        list<Distributor_And_Internet_Provider__mdt> listDistributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c, Country_Code__c
                                                                                   FROM Distributor_And_Internet_Provider__mdt];

        map<string, Distributor_And_Internet_Provider__mdt> mapCountryDistributor = new map<string, Distributor_And_Internet_Provider__mdt>();
        for(Distributor_And_Internet_Provider__mdt distributorProvider : listDistributorAndProvider) {
            mapCountryDistributor.put(distributorProvider.Country_Code__c, distributorProvider);
        }
        // Calling API for just these Accounts supplying the Building ID as parameter
        Zuora__Subscription__c sub = [SELECT Id, Name, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Status__c,
                                      SUB_Activation_Date__c, Zuora__Account__r.BillingCountryCode, SUB_Bundle_Contract_Id__c
                                      FROM Zuora__Subscription__c
                                      WHERE Id = : subId];

        CBundleObjects.CESAR_ACTIVATION activateCBundleSub = BundleCMapper.fillActivateSubscription( sub, mapCountryDistributor.get(sub.Zuora__Account__r.BillingCountryCode).Distributor_Id__c, mapCountryDistributor.get(sub.Zuora__Account__r.BillingCountryCode).Internet_Provider_Id__c, activationDate);

        HttpResponse response = BundleCManager.doCallout(CBundleObjects.activationAPIUrl, CBundleObjects.put, json.serialize(activateCBundleSub, true));

        CBundleObjects.subActionsResponse activateSub =  (CBundleObjects.subActionsResponse) JSON.deserialize(response.getBody(), CBundleObjects.subActionsResponse.class);
        if(activateSub.codeHttp == 200) {
            sub.SUB_Status__c = 'Active';
            sub.SUB_Activation_Date__c = activationDate;
            update sub;
        }

        return response.getBody();
    }
    /*
     * methode pour identifier s'il y a eu un changement affectant Canal+ 
    */
    // (Cette methode est fusionner avec autre dans AP01_AccounttriggerHandler)
        // public static void checkFieldModicfication(Map<Id, Account> mapOfNewAcct, Map<Id, Account> mapOfOldAcct){

        //     Map<Id, Account> accountToUpdate = new Map<Id, Account>();
        //     Map<Id, Zuora__Subscription__c> mapOfAcctIdSub = new Map<Id, Zuora__Subscription__c>();
        //     list<Zuora__Subscription__c> listOfSubscription = [SELECT Name, SUB_Status__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__Account__c, SUB_Bundle_Contract_Id__c
        //                                                        FROM Zuora__Subscription__c
        //                                                        WHERE Zuora__Account__c IN : mapOfNewAcct.KeySet() AND SUB_Status__c != null];

        //     if(listOfSubscription != null && listOfSubscription.Size() > 0) {
        //         for(Zuora__Subscription__c sub : listOfSubscription) {
        //             mapOfAcctIdSub.put(sub.Zuora__Account__c, sub);
        //         }
        //         for(Account acc : mapOfNewAcct.Values()) {
        //             if(acc.IsPersonAccount && mapOfAcctIdSub.containsKey(acc.id)) {
        //                 String accId = acc.Id;
        //                 if(acc.Salutation != mapOfOldAcct.get(accId).Salutation || acc.FirstName != mapOfOldAcct.get(accId).FirstName || acc.LastName != mapOfOldAcct.get(accId).LastName || acc.personMobilePhone != mapOfOldAcct.get(accId).personMobilePhone || acc.BillingCity != mapOfOldAcct.get(accId).BillingCity || acc.BillingCountryCode != mapOfOldAcct.get(accId).BillingCountryCode || acc.BillingStreet != mapOfOldAcct.get(accId).BillingStreet || acc.personEmail != mapOfOldAcct.get(accId).personEmail) {
        //                     accountToUpdate.put(accId, acc);
        //                 }
        //             }
        //         }
        //         if(accountToUpdate != null && accountToUpdate.size() > 0) {
        //             modifyContactBundleC(JSON.serialize(accountToUpdate), JSON.serialize(mapOfAcctIdSub));
        //         }
        //     }
        // }
    
    @future(callout = true)
    public static void modifyContactBundleC(String mapIdAccount, String mapIdSubscription){

        Map<Id, Account> mapOfAccounts = (Map<Id, Account>) JSON.deserialize(mapIdAccount, Map<Id, Account> .class);
        Map<Id, Zuora__Subscription__c> mapOfSubs = (Map<Id, Zuora__Subscription__c>) JSON.deserialize(mapIdSubscription, Map<Id, Zuora__Subscription__c> .class);

        list<CBundleObjects.CESAR_MODIFY_CONTACTS> listOfmodifyContactCBundleSub = BundleCMapper.fillmodifyContactSubscription(mapOfAccounts, mapOfSubs);

        List<CBundleObjects.newSubResponse> listOfSubResponse = new List<CBundleObjects.newSubResponse>();
        if(listOfmodifyContactCBundleSub != null && listOfmodifyContactCBundleSub.size() > 0) {
            for(CBundleObjects.CESAR_MODIFY_CONTACTS cModifyContact : listOfmodifyContactCBundleSub) {

                HttpResponse response =
                BundleCManager.doCallout(CBundleObjects.modifyContactsAPIUrl, CBundleObjects.patch, json.serialize(listOfmodifyContactCBundleSub, true));
                CBundleObjects.newSubResponse modifyContactSub =
                (CBundleObjects.newSubResponse) JSON.deserialize(response.getBody(), CBundleObjects.newSubResponse.class);
                if(modifyContactSub.returnCode == 'PROCESS_SUCCESS') {
                    listOfSubResponse.add(modifyContactSub);
                }
            }
        }
    }

    /**
     * Methode utilisée pour Marker les abos si ils ont ete creer avec des produits C+ et ils ont ete activer alors le Batch11 les detectes
     * @param subId id de l'abo
     */
    public static void createBundleSub(map<id, Zuora__Subscription__c> newMap, map<id, Zuora__Subscription__c> oldMap ){
        list<Zuora__Subscription__c> listSub = new list<Zuora__Subscription__c>();
        for(Zuora__Subscription__c sub : newMap.values()) {
            if(sub.Zuora__Status__c == 'Active' && oldMap.get(sub.Id).Zuora__Status__c == 'Pending Activation' &&
               sub.SUB_Tech_Material__c != null && !string.isBlank(sub.SUB_Tech_Material__c)  &&
               sub.SUB_Offer__c != null && !string.isBlank(sub.SUB_Offer__c)) {

                sub.Prior_expedted_renewal_Date__c = Date.Today();
                sub.Create_Bundle_C_subscription__c = true;
            }
        }
    }

    /**
     * Methode pour cree l'apercu d'un upgrade
     * <p>
     * @param accountNumber numero du compte,
     * @param subNumber numero de la souscription,
     * @param prodToAddId id du produit a ajouter,
     * @param expectedRenewalDate la date de renouvellement d'un abo,
     * @param triggerDate date du debut du reabo
     * @param fiscalId id du timbre fiscal,
     * @param chargeId id du de la charge produit timbre fiscal,
     * @param totalAmount prix total des produits
     * @return resultat de l'appel API
     */
    public static string changeMaterialPreview(string accountNumber, string subNumber, string prodToAddId, string chargeId, date expectedRenewalDate, date triggerDate) {

        set<Log__c> setLog = new set<Log__c>();
        string previewResult;
        // fill upgrade preview order fields
        ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillChangeMaterialPreview(accountNumber, subNumber, prodToAddId, chargeId, expectedRenewalDate, triggerDate);

        try {
            HttpResponse response = ZuoraManager.previewOrder(zSub);
            ZuoraResponseObjects.ZuoraPreviewResponse orderResponse = new ZuoraResponseObjects.ZuoraPreviewResponse();
            orderResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraPreviewResponse.class);
            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), null, null, subNumber, ZuoraObjects.previewOrdersAPIUrl, response.getBody(),
                                                               orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));
            if(orderResponse.success) {
                //add charge name to the previewresult
                map<string, ZuoraResponseObjects.ZuoraInvoiceItems> chargeNameInfo = new map<string, ZuoraResponseObjects.ZuoraInvoiceItems>();
                if(orderResponse.previewResult.invoices.size() > 0 && orderResponse.previewResult.invoices != null) {
                    for(ZuoraResponseObjects.ZuoraInvoiceItems zInvoice : orderResponse.previewResult.invoices[0].invoiceItems) {
                        chargeNameInfo.put(zInvoice.productRatePlanChargeId, zInvoice);
                    }
                }

                // get charge name of each product
                list<ZuoraResponseObjects.ZuoraInvoiceItems> listZInvoice = new list<ZuoraResponseObjects.ZuoraInvoiceItems>();
                for(AggregateResult subProduct : [SELECT  count(id), Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c
                                                    FROM zuora__subscriptionProductCharge__c
                                                    WHERE Zuora__RatePlanName__c != null AND Zuora__ProductRatePlanChargeId__c IN : chargeNameInfo.keyset() GROUP BY Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c]) {
                    String ratePlanName = (String) subProduct.get('Zuora__RatePlanName__c');
                    String productId = (String) subProduct.get('Zuora__ProductRatePlanChargeId__c');
                    chargeNameInfo.get(productId).ratePlanName = ratePlanName;
                }
                listZInvoice.addAll(chargeNameInfo.Values());
                if(orderResponse.previewResult.invoices.size() > 0 && orderResponse.previewResult.invoices != null) {
                    orderResponse.previewResult.invoices[0].invoiceItems = listZInvoice;
                }

                //add conversion rate to the response
                list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                                   FROM CurrencyType
                                                   WHERE IsoCode = 'USD'];

                orderResponse.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);
                orderResponse.zuoraLogs = setLog;
                orderResponse.previewResult.invoices[0].invoiceItems[0].subscriptionNumber = subNumber;
                system.debug(response.getBody());

                return JSON.serialize(orderResponse, true);
            } else {
                insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, subNumber, ZuoraObjects.previewOrdersAPIUrl);
                list<Log__c> listLog = new list<Log__c>();
                if(setLog != null && setLog.size() > 0) {

                    listLog.addAll(setLog);
                    insert listLog;
                }

                return response.getBody();
            }
        } catch(Exception e) {
            ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
            error.message = e.getMessage();
            error.zuoraLog = setLog;
            system.debug(e.getLineNumber());
            throw new CustomException(json.serialize(error, true));
        }
    }
    /**
     * Methode pour faire upgrade d'un produit sur la souscription
     * <p>
     * @param subscriptionId  id de la souscription,
     * @param nbPeriodes nombre de periode en cas de reabo,
     * @param isPreview choix du preview
     * @param withRenew pour indiquer si le upgrade est avec ou sans reabonnement,bizaOrder
     * @param immediateUpgrade boolean pout l'upgrade immediat
     * @param modeDePaiement mode de paiement
     * @param transactionNumber Numéro de transaction
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string changeMaterialInZuora(id subscriptionId, boolean isPreview, string modeDePaiement, string transactionNumber,
                                               string operator, double dollarPayment, integer CDFPayment, integer dollarRefund, integer CDFRefund, string equipmentName){

        list<Log__c> listLog = new list<Log__c>();
        set<Log__c> setLog = new set<Log__c>();

        if(equipmentName == System.Label.Bundle_Equip_type_54){
            equipmentName = System.Label.Bundle_Material_MATOTT;
        }else if(equipmentName == System.Label.Bundle_Equip_type_G11A){
            equipmentName = System.Label.Bundle_Material_TERMG11A;
        }else if (equipmentName == System.Label.Bundle_Equip_type_Z4){
            equipmentName = System.Label.Bundle_Material_TERMZ4;
        }

        user currentUser = [SELECT USR_DistributeurID__c, Profile.Name
                            FROM User
                            WHERE id = :UserInfo.getUserId()];

        list<Zuora__SubscriptionProductCharge__c> listProduct = [ SELECT Zuora__RatePlanName__c, Name, Zuora__Zuora_Id__c, Zuora__RatePlanId__c,
                                                                  Zuora__Subscription__r.ExpectedRenewalDate__c, Zuora__Subscription__r.Zuora__Status__c,
                                                                  Zuora__Subscription__r.Zuora__SubscriptionNumber__c, Zuora__Subscription__r.Zuora__Account__r.BillingCountry,
                                                                  Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode, Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode,
                                                                  Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__Subscription__r.CurrencyIsoCode,
                                                                  Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Status__c, Zuora__Subscription__r.Coupon__c,
                                                                  Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                                  Zuora__Subscription__r.BoxNumber__c, Zuora__Subscription__r.Zuora__Zuora_Id__c,
                                                                  Zuora__Subscription__r.RenewalSequenceNumber__c, Zuora__Product__r.Zuora__External_Id__c, Zuora__Product__r.Name,
                                                                  Zuora__Subscription__c
                                                                  FROM Zuora__SubscriptionProductCharge__c
                                                                  WHERE Zuora__Type__c = 'Recurring'  AND Zuora__Subscription__c = : subscriptionId LIMIT 1];
        
        list<zqu__ProductRatePlanCharge__c> listBundleProducts = [SELECT id, name, zqu__ZuoraId__c, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                  FROM zqu__ProductRatePlanCharge__c
                                                                  WHERE zqu__ProductRatePlan__r.Category__c = 'Bundle C' AND zqu__ProductRatePlan__r.zqu__Product__r.Name = : listProduct[0].Zuora__Product__r.Name AND zqu__ProductRatePlan__r.name like :equipmentName AND
                                                                      (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                      (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                                  zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE ];

        //check if the subscription have product of charge 'start'
        if((listProduct != null && listProduct.size() > 0) && (listBundleProducts != null && listBundleProducts.size() > 0)) {
            // check if sub is activated or suspended
            if(listProduct[0].Zuora__Subscription__r.Zuora__Status__c == 'Active') {

                // call preview sub to get the needed amount for this action
                string previewResult;
                double nonTaxableAmount;
                previewResult  = changeMaterialPreview( listProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,  listProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                        listBundleProducts[0].zqu__ProductRatePlan__r.zqu__ZuoraId__c, listBundleProducts[0].zqu__ZuoraId__c, listProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c,  date.today());

                ZuoraResponseObjects.ZuoraPreviewResponse firstPreview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                nonTaxableAmount = null;

                ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                if(preview.success) {
                    double currentAmount = preview.previewResult.invoices[0].amount;
                    if(isPreview) {
                        listLog.addAll(preview.zuoraLogs);
                        insert listLog;

                        return previewResult;
                    } else {
                        ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillChangeMaterialOrdrer(listProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, listProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, listBundleProducts[0]);
                        HttpResponse response;
                        response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.ADD_PRODUCT );
                        ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                        orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), null, subscriptionId, null, ZuoraObjects.ordersAPIUrl, response.getBody(),
                                                                           orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                        if(orderResponse.success) {
                            double amount = double.valueOf(currentAmount);
                            String invoiceId;
                            String invoiceNumber = orderResponse.invoiceNumbers[0];
                            String orderNumber = orderResponse.orderNumber;

                            HttpResponse accountResponse = ZuoraManager.getAccountSummary(listProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                            ZuoraResponseObjects.ZuoraGetAccount getAccountInfoResponse = new ZuoraResponseObjects.ZuoraGetAccount();
                            getAccountInfoResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                            if(getAccountInfoResponse.success) {
                                // get invoice id of the request invoice number
                                for(ZuoraResponseObjects.ZuoraInvoices zInvoice : getAccountInfoResponse.invoices) {
                                    if(invoiceNumber != null && zInvoice.InvoiceNumber == invoiceNumber) {
                                        invoiceId = zInvoice.id;
                                        break;
                                    }
                                }
                                integer period = 0;

                                // create payment in zuora
                                ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreateRenewPayment(listProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                                                                           0, amount, transactionNumber, operator, orderNumber, invoiceId,
                                                                                                           listProduct[0].Zuora__Subscription__r.CurrencyIsoCode, modeDePaiement, string.valueOf(CDFPayment), string.valueOf(dollarPayment), null, string.valueOf(dollarRefund),
                                                                                                           string.valueOf(CDFRefund), false, listProduct[0].Zuora__Subscription__r.Zuora__Account__c);

                                // get payment response
                                HttpResponse responsePayment = ZuoraManager.createPayment(paymentInfo);
                                string responseAdjustment = responsePayment.getBody().replaceAll('number', 'number_toReplace');
                                ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);

                                if(!paymentResponse.success) {
                                    SubscriptionRenewalActions.sleepAfterBCD();
                                    // create payment in zuora
                                    paymentInfo = ZuoraMapper.fillCreateRenewPayment(listProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                                                     0, amount, transactionNumber, operator, orderNumber, invoiceId,
                                                                                     listProduct[0].Zuora__Subscription__r.CurrencyIsoCode, modeDePaiement, string.valueOf(CDFPayment), string.valueOf(dollarPayment), null, string.valueOf(dollarRefund),
                                                                                     string.valueOf(CDFRefund), false, listProduct[0].Zuora__Subscription__r.Zuora__Account__c);

                                    // get payment response
                                    responsePayment = ZuoraManager.createPayment(paymentInfo);
                                    responseAdjustment = responsePayment.getBody().replaceAll('number', 'number_toReplace');
                                    paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                                }
                                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(paymentInfo, true), null, subscriptionId, null, ZuoraObjects.paymentAPIUrl, response.getBody(),
                                                                                   paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true));

                                if(setLog.size() > 0 && setLog != null) {
                                    listLog.AddAll(setLog);
                                    insert listLog;
                                }

                                return responsePayment.getBody();
                            }

                            return accountResponse.getBody();
                        } else {
                            return response.getBody();
                        }
                    }
                } else {
                    insert AP01_ErreurInterface.insertError('Erreur API', null, null, preview.reasons[0].message, subscriptionId, 'upgradeSubscriptionProduct');

                    return previewResult;
                }
            } 
            else {
                return system.label.Impossible_Action;
            }
        }
        else {
            return System.label.Upgrade_Product_Failure;
        }
    }
    /**
     * Method to Exhange Material of the subscription C+ Bundle
     * @param recordId
     * @param equipmentId
     * @param equipmentType
     */
    @AuraEnabled
    public static list<String> exchangeMaterialBundleC (Id recordId, List<string> equipmentId, List<string> equipmentType, List<String> equipmentIdSF){

        try {
            // in case of echange G11 and carte G11 we should always receive the G11 at index 0 and NVSAG11A index 1

            List<Equipment__c> listOfEquips = new List<Equipment__c>();
            map<Integer, String> listOfOldType = new map<Integer, String>();
            map<Integer, String> listOfOldId = new map<Integer, String>();
            map<Integer, String> listOfOldIdSF = new map<Integer, String>();
            list<String> listOfResponses = new list<String>();
            list<Log__c> listOflogs = new list<Log__c>();
            Boolean success = false;

            list<Zuora__Subscription__c> currentSub = [SELECT Id, Name, Zuora__Account__c, SUB_EquipmenId_CBundle__c, SUB_EquipmentType_CBundle__c, SUB_Bundle_Contract_Id__c, SUB_Offer__c,  
                                                 Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Subscription_Number__c, SUB_Subscriber_Number__c, SUB_Tech_Material__c,SUB_Options__c
                                                 FROM Zuora__Subscription__c
                                                 WHERE id = :recordId
                                                 LIMIT 1];

            if(currentSub != null && currentSub.size() > 0 && equipmentId != null && equipmentId.size() > 0){

                // to get the old equipments in salesforce use the technical field SUB_Tech_Material__c
                List<Object> equips = (List<Object>) JSON.deserializeUntyped(currentSub[0].SUB_Tech_Material__c);

                if(equips != null && equips.size() > 0){
                    for(Object fld : equips) {
    
                        Map<String, Object> data = (Map<String, Object>) fld;

                        integer key; // build a map to separate the normal equipment and the NSVGA11 (carte)  
                        if((String)data.get('Type') == System.Label.Bundle_Equip_type_NVSAG11A){
                            key = 1;
                        }else{
                            key = 0;
                        }
                        listOfOldType.put(key, (String)data.get('Type'));
                        listOfOldId.put(key, (String)data.get('Equipment'));
                        listOfOldIdSF.put(key, (String)data.get('Id'));
                    }
                }

                for(Integer i = 0; i < equipmentId.size(); i++){
                    
                    // get the old equipment valid with the new ones --> new GA11 get Old GA11 not NSVGA11 and vice versa
                    id oldequipmentIdSF = listOfOldIdSF.get(equipmentType.size() == 1 && equipmentType[0] == System.Label.Bundle_Equip_type_NVSAG11A ? 1 : i);
                    String oldEquipmentId = listOfOldId.get(equipmentType.size() == 1 && equipmentType[0] == System.Label.Bundle_Equip_type_NVSAG11A ? 1 : i);
                    String oldEquipmentType = listOfOldType.get(equipmentType.size() == 1 && equipmentType[0] == System.Label.Bundle_Equip_type_NVSAG11A ? 1 : i);
                    
                    // fill the request body
                    CBundleObjects.CESAR_EXCHANGE_MATERIAL exchangeMaterialCBundleSub = BundleCMapper.fillExchangeMaterial(currentSub[0], equipmentId[i], equipmentType[i], oldEquipmentId, oldEquipmentType);
                    system.debug('API body '+json.serialize(exchangeMaterialCBundleSub, true));
                    // send request API
                    HttpResponse response = BundleCManager.doCallout(CBundleObjects.materialExchangeAPIUrl, CBundleObjects.put, json.serialize(exchangeMaterialCBundleSub, true));
                    CBundleObjects.subActionsResponse exchangeMaterialSub = new CBundleObjects.subActionsResponse();
                    try {
                        exchangeMaterialSub = (CBundleObjects.subActionsResponse) JSON.deserialize(response.getBody(), CBundleObjects.subActionsResponse.class);
                        listOfResponses.add(response.getBody());
                    } catch (Exception e) {
                        system.debug(e.getmessage()+ ' >>> '+response);
                    }

                    // create log of the API
                    Log__c lg = createBundleLog(json.serialize(exchangeMaterialCBundleSub, true), currentSub[0].Zuora__Account__c, currentSub[0].Id, null, CBundleObjects.materialExchangeAPIUrl,
                                    response.getBody(), exchangeMaterialSub.codeHttp == 200 ?true : false, null, CBundleObjects.put);
                    listOflogs.add(lg);

                    if(exchangeMaterialSub.codeHttp != null && exchangeMaterialSub.codeHttp == 200)
                    {

                        // if on of the for loop request is successful change the boolean
                        success = true;

                        // create JSON body format to replace the equipment in SUB_Tech_Material__c field so we can use it again in another change material request
                        CBundleObjects.Materialobject material = new CBundleObjects.Materialobject();
                        material.eQ_Decodeur = equipmentType[i] == System.Label.Bundle_Equip_type_NVSAG11A ? true : false; 
                        material.eQ_Have_Decoder = equipmentType[i] == System.Label.Bundle_Equip_type_G11A ? true : false; 
                        material.id = equipmentIdSF[i];
                        material.equipment = equipmentId[i];
                        material.type = equipmentType[i];
                        String newMaterial = json.serialize(material, true);

                        // add a new list of equip to the SUB_Tech_Material__c field if request is successful
                        currentSub[0].SUB_Tech_Material__c.replace(']',',');
                        if(i == 0){
                            currentSub[0].SUB_EquipmenId_CBundle__c = equipmentId[0];
                            currentSub[0].SUB_EquipmentType_CBundle__c = equipmentType[0];
                            currentSub[0].SUB_Tech_Material__c += newMaterial;
                        }else{ // if it's the second loop add a , between the 2 differents equips
                            currentSub[0].SUB_Tech_Material__c += ','+newMaterial;
                        }
                        // liberate and reserve the equips
                        Equipment__c eq = new Equipment__c(id = equipmentIdSF[i], Already_Used__c = true);
                        listOfEquips.add(eq);
                        Equipment__c oldEq = new Equipment__c(id = oldequipmentIdSF, Already_Used__c = false);
                        listOfEquips.add(oldEq);
                    }
                }

                if(listOflogs != null && listOflogs.size() > 0) { insert listOflogs;}   
                if(listOfEquips != null && listOfEquips.size() > 0){ update listOfEquips; }
                if(success){
                    currentSub[0].SUB_Tech_Material__c += ']';
                    update currentSub;
                    createBundleFollowUp(currentSub[0], 'ACT005', json.serialize(listOfOldId, true));
                }
                
                return listOfResponses;
            }

            return null;
        } catch(Exception e) {
            system.debug('exchange catch line ' + e.getLineNumber() + ':'  + e.getMessage());
            throw new CustomException(e.getMessage()+'  >> '+e.getLineNumber());
        }
    }

    // On renewal preview if Bundle offer and equipments are selected save them on the sub only if it's a renew fiber with creat Canal subscription
    @AuraEnabled
    public static void saveEquipementValue(String subId, String equipments, String options, String offer, integer period){

        Zuora__Subscription__c sub = [SELECT Id, ExpectedRenewalDate__c FROM Zuora__Subscription__c WHERE Id =: subId LIMIT 1];
        try {
            Zuora__Subscription__c currentSub = new Zuora__Subscription__c();
            currentSub.Id = subId;
            currentSub.SUB_Tech_Material__c = equipments;
            currentSub.SUB_Offer__c = offer.replace('"', '');
            currentSub.SUB_Options__c = options.replace('"', '');
            currentSub.SUB_Options__c = currentSub.SUB_Options__c.replace(',', ';');
            currentSub.SUB_Options__c = currentSub.SUB_Options__c.replace('[', '');
            currentSub.SUB_Options__c = currentSub.SUB_Options__c.replace(']', '');
            currentSub.CBundle_Periode__c = integer.valueof(period);
            currentSub.Prior_expedted_renewal_Date__c = sub.ExpectedRenewalDate__c > Date.Today() ? sub.ExpectedRenewalDate__c : Date.Today() ;
            update currentSub;
        } catch (Exception e) {
            system.debug(e.getLineNumber()+': '+e.getMessage());
        }
    }

    /**
     * methode utiliser pour liberer les equipement canal+ apres suppression d'un devis
     * <p>
     * @param quotes list des quotes after delete
     * @return static
     * */
    public static void libarateEquipsOnQuoteDelete(List<Quote> quotes){

        List<Object> listOfAllEquipments = new List<Object>();
        List<Equipment__c> listEquipment = new List<Equipment__c>();

        for(Quote qut : quotes)
        {
            if(qut.QUO_Tech_Material__c != null && qut.Status != 'Accepted')
            {
                List<Object> equips = (List<Object>) JSON.deserializeUntyped(qut.QUO_Tech_Material__c);
                listOfAllEquipments.addALL(equips);
            }else if(qut.Status == 'Accepted'){
                qut.addError(System.Label.Delete_Quotes_Error);
            }
        }

        if(listOfAllEquipments != null && listOfAllEquipments.size() > 0){
            for(Object fld : listOfAllEquipments) {

                Map<String, Object> data = (Map<String, Object>) fld;
                equipment__c eq = new equipment__c( id = (String)data.get('Id'));
                eq.Already_Used__c = false;
                listEquipment.add(eq);
            }
        }

        if(listEquipment != null && listEquipment.size() > 0){
            update listEquipment;
        }
    }
    
    /**
     * methode utiliser pour tester si ce client est eligible pour une migration vers GVA
     * <p>
     * @param equipmentId list of Canal+ equipmentId
     * @return list<String>
     * */
    @AuraEnabled(cacheable = true)
    public static list<String> EligMigrationTest(list<String> listOfSubId, List<String> equipmentId, String countryCodeValue){

        List<CBundleObjects.ELIGIBILITY_MIGRATION> listOfEligiblityMig = new List<CBundleObjects.ELIGIBILITY_MIGRATION>();
        List<CBundleObjects.EligMigrationResponse> listOfEligMigResponse = new List<CBundleObjects.EligMigrationResponse>();
        List<String> listOfresponses = new List<String>();

        if(equipmentId != null && equipmentId.size() > 0){
            // fill the requests body
            listOfEligiblityMig = BundleCMapper.fillEligibilityMigration(equipmentId);

            if(listOfEligiblityMig != null && listOfEligiblityMig.size() > 0){
                for(CBundleObjects.ELIGIBILITY_MIGRATION eligTest : listOfEligiblityMig){
                    // send requests
                    HttpResponse response = BundleCManager.migrationCallout(CBundleObjects.eligMigrationAPIUrl, CBundleObjects.put, json.serialize(eligTest, true), false, null);
                    // response Body
                    // CBundleObjects.EligMigrationResponse isEligForMigration =  (CBundleObjects.EligMigrationResponse) JSON.deserialize(response.getBody(), CBundleObjects.EligMigrationResponse.class);
                    // listOfEligMigResponse.add(isEligForMigration);
                    listOfresponses.add(response.getBody());
                }
            }
        }

        return listOfresponses;
    } 

    /**
     * methode utiliser pour envoyer une demande de migration vers canal+
     * <p>
     * @param listOfSubIds list of subscription Ids
     * @return list<String>
     * */
    @AuraEnabled
     public static list<String> requestMigration(List<String> listOfSubIds, String prepaidPeriod, String offerValue, Boolean adultContent, String options, String eqipId, String equipType){

        CBundleObjects.REQUEST_MIGRATION requestMig = new CBundleObjects.REQUEST_MIGRATION();
        list<Zuora__Subscription__c> subsToUpdate = new list<Zuora__Subscription__c>();
        List<String> listOfresponses = new List<String>();
        list<Log__c> listOflogs = new list<Log__c>();

        // remove those charachters "" and []
        options = options.replaceAll('[\"\\[\\]]', '');
        list<String> listOfOtions = options.split(',');

        list<Zuora__Subscription__c> listOfSubs = [SELECT Name, SUB_Subscription_Number__c, SUB_Bundle_Contract_Id__c, SUB_Subscriber_Number__c, SUB_Status__c, Quote__r.QUO_Periodes_Prepayees__c,
                                                        SUB_End_Date__c, SUB_EquipmenId_CBundle__c, SUB_EquipmentType_CBundle__c,SUB_Activation_Date__c, CBundle_Periode__c,
                                                        Zuora__Account__r.BillingCountryCode, Sub_CanalMigration_orderId__c, Sub_CanalMigration_personId__c, SUB_Offer__c, 
                                                        C_Migration_Date__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_Options__c
                                                    FROM Zuora__Subscription__c
                                                    WHERE id IN : listOfSubIds AND Zuora__Status__c != 'Cancelled' 
                                                        AND SUB_Status__c = null];
        if(listOfSubIds != null && listOfSubIds.size() > 0){

            for(Zuora__Subscription__c sub: listOfSubs){

                CBundleObjects.RequestMigrationResponse migrationResponse =new CBundleObjects.RequestMigrationResponse();

                // fill the requests body
                requestMig = BundleCMapper.fillRequestMigration(sub, prepaidPeriod, offerValue, adultContent, listOfOtions, eqipId);
                // send requests
                HttpResponse response = BundleCManager.migrationCallout(CBundleObjects.requMigrationAPIUrl, CBundleObjects.post, json.serialize(requestMig, true), true, sub.Zuora__Account__r.BillingCountryCode);
                listOfresponses.add(response.getBody());

                if(response.getStatusCode() == 200){
                    migrationResponse =  (CBundleObjects.RequestMigrationResponse) JSON.deserialize(response.getBody(), CBundleObjects.RequestMigrationResponse.class);
                    if(migrationResponse.orderId != null){
                        // The specified string should use the standard date format “yyyy-MM-dd HH:mm:ss” in the local time zone.
                        system.debug('response date >> '+migrationResponse.activationDate.replace('T',' '));
                        sub.C_Migration_Date__c = dateTime.valueOf(migrationResponse.activationDate.replace('T',' '));
                        sub.Sub_CanalMigration_personId__c = string.valueOf(migrationResponse.personId);
                        sub.Sub_CanalMigration_orderId__c = migrationResponse.orderId;
                        sub.SUB_EquipmenId_CBundle__c = eqipId;
                        sub.SUB_EquipmentType_CBundle__c = equipType;
                        subsToUpdate.add(sub);
                    }
                }

                // create log of the API
                Log__c lg = createBundleLog(json.serialize(requestMig, true), sub.Zuora__Account__c, sub.Id, null, CBundleObjects.requMigrationAPIUrl,
                                            response.getBody(), response.getStatusCode() == 200 ?true : false, migrationResponse.detail, CBundleObjects.post);
                listOflogs.add(lg);
            }

            if(listOflogs != null && listOflogs.size() > 0) { insert listOflogs;}
            if(subsToUpdate != null && subsToUpdate.size() > 0){
                try {
                    update subsToUpdate;
                } catch (Exception e) {
                    system.debug('update sub error >> '+e.getLineNumber()+' : '+ e.getMessage());
                    throw new CustomException(e.getLineNumber()+' : '+ e.getMessage());
                } 
            }
        }

        return listOfresponses;
    } 

    /**
     * methode utiliser pour envoyer une demande d'annulation de la migration
     * <p>
     * @param listOfSubIds list of subscription Ids
     * @return list<String>
     * */
    @AuraEnabled
    public static map<String, String> cancelCanalMigration(List<String> listOfSubIds){

        CBundleObjects.CANCEL_MIGRATIION cancelMig = new CBundleObjects.CANCEL_MIGRATIION();
        list<Zuora__Subscription__c> subsToUpdate = new list<Zuora__Subscription__c>();
        map<String, String> mapOfOrderIdResponse = new map<String, String>();
        list<Log__c> listOflogs = new list<Log__c>();

        list<Zuora__Subscription__c> listOfSubs = [SELECT Name,  SUB_Status__c, SUB_End_Date__c, SUB_EquipmenId_CBundle__c, SUB_EquipmentType_CBundle__c,SUB_Activation_Date__c, CBundle_Periode__c,
                                                        Zuora__Account__r.BillingCountryCode, Sub_CanalMigration_orderId__c, Sub_CanalMigration_personId__c, C_Migration_Date__c
                                                    FROM Zuora__Subscription__c
                                                    WHERE id IN : listOfSubIds AND Zuora__Status__c != 'Cancelled' 
                                                        AND SUB_Status__c != null AND C_Migration_Date__c != null AND Sub_CanalMigration_orderId__c != null];

        if(listOfSubIds != null && listOfSubIds.size() > 0){

            for(Zuora__Subscription__c sub : listOfSubs){

                // fill the requests body
                cancelMig = BundleCMapper.fillCancelMigration(sub.Sub_CanalMigration_orderId__c);

                // send requests
                HttpResponse response = BundleCManager.migrationCallout(CBundleObjects.cancelMigrationAPIURL, CBundleObjects.post, json.serialize(cancelMig, true), true, sub.Zuora__Account__r.BillingCountryCode);
                
                if(response.getStatusCode() == 204){
                    mapOfOrderIdResponse.put(sub.Sub_CanalMigration_orderId__c, 'Success');

                    sub.C_Migration_Date__c = null;
                    subsToUpdate.add(sub);
                }else{
                    mapOfOrderIdResponse.put(sub.Sub_CanalMigration_orderId__c, response.getBody());
                }

                // create log of the API
                Log__c lg = createBundleLog(json.serialize(cancelMig, true), sub.Zuora__Account__c, sub.Id, null, CBundleObjects.cancelMigrationAPIURL,
                                            response.getBody(), response.getStatusCode() == 204 ?true : false, null, CBundleObjects.post);
                listOflogs.add(lg);
            }

            if(listOflogs != null && listOflogs.size() > 0) { insert listOflogs;}   

            if(subsToUpdate != null && subsToUpdate.size() > 0){ update subsToUpdate;}
        }

        return mapOfOrderIdResponse;
    } 

    public static void createBundleFollowUp(Zuora__Subscription__c sub, string action, String oldEquipmentId){
        Bundle_C_Follow_up__c followUp = new Bundle_C_Follow_up__c();
        followUp.BC_Code_Action__c = action;
        followUp.BC_Subscription__c = sub.Id;
        followUp.BC_Contract_Id__c = sub.SUB_Bundle_Contract_Id__c == null?sub.Name : sub.SUB_Bundle_Contract_Id__c;
        followUp.BC_Contact_Id__c = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
        followUp.Old_Equipment__c = oldEquipmentId;
        followUp.New_Equipment__c = sub.SUB_EquipmenId_CBundle__c;
        followUp.Canal_Offer__c = sub.SUB_Offer__c != null ? sub.SUB_Offer__c : null;
        followUp.Options__c = sub.SUB_Options__c != null ? sub.SUB_Options__c : null;
        insert followUp;
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
    public static Log__c createBundleLog(string boby, id IDCompte, id IDAbonnement, string subNumber, string URL,
                                            string reponse, boolean success, string reason, string type){

        Log__c newLog = new Log__c();
        newLog.LG_Body__c = boby;
        newLog.LG_Account__c = IDCompte;
        newLog.LG_Subscription__c = IDAbonnement;
        newLog.LG_Method_URL__c = URL;
        newLog.LG_Subscription_Number__c = subNumber;
        newLog.LG_Response__c = reponse;
        newLog.LG_Interface__c = 'Bundle C+';
        newLog.LG_Success__c = success;
        newLog.LG_Error_Message__c = reason;
        newLog.LG_Method_Type__c = type;

        return newLog;
    }

    /**
     * Methode utilisée pour créér un enregistrement dans l'objet requestToPayDemand__c pour sauvegarder la date de la migration et les info de l'offre choisi
     * <p>
     * @param boby corps de l'appel,
     **/
    @AuraEnabled
    public static void createSuiviforMigration(String action, String subId, String transactionId, String  allInfobody, String paymentBodyInfo){

        list<String> details = allInfobody.split('<CUTHERE>');
        list<String> paymentDetails = paymentBodyInfo.split('<CUTHERE>');

        Bundle_C_Follow_up__c followUp = new Bundle_C_Follow_up__c();
        followUp.BC_Code_Action__c = action;
        followUp.BC_Subscription__c = subId;
        followUp.Transaction_Id__c = transactionId;

        followUp.Payment_Method__c = paymentDetails[0];
        followUp.Operator__c =  paymentDetails[1];
        followUp.Dollar_Payment__c =  paymentDetails[2];
        followUp.CDF_Payment__c  =  paymentDetails[3];
        followUp.Dollars_Refund__c =  paymentDetails[4];
        followUp.CDF_Refund__c =  paymentDetails[5];

        followUp.Old_Equipment__c = details[0];
        followUp.New_Equipment__c = details[0];
        followUp.Payment_Amount__c = details[1];
        followUp.Fiber_Offer__c = details[2];
        followUp.Canal_Offer__c = details[3];
        followUp.Canal_Category__c = details[4];
        followUp.Prepaid_Period__c = details[5];
        followUp.Options__c = details[6];
        followUp.Migration_Date__c = date.valueOf(details[7]);

        insert followUp;
    }

    // methode utilise pour verifier si l'utilisateur actuel peut voir les options Bundle
    @AuraEnabled
    public static boolean userCanSee(){

        String currentUserID = UserInfo.getUserId();
        String names = System.Label.LWC_ListOfNames;
        list<String> listOfNames = names.split(',');
        map<Id, User> mapOfUserwithAccess = new map<Id,User>([SELECT Id, Profile.Name FROM User 
                                                            WHERE Profile.Name = 'System Administrator' OR (Profile.Name != 'Utilisateur du Portail Distributeurs' 
                                                            AND FirstName IN : listOfNames) OR (Profile.Name = 'Utilisateur du Portail Distributeurs')]);
    
        if(mapOfUserwithAccess != null && mapOfUserwithAccess.KeySet().size() > 0){
            if( mapOfUserwithAccess.KeySet().contains(currentUserID)){ 
                    return true;
            }
        }
        return false;
    }

    public class CustomException extends Exception {}
}