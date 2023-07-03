/*
 * Class contenant les appels API pour les differentes actions
 * faites sur la souscription comme creation,suspension, resiliation, ajouter/annuler un produit
 * Test class : ZuoraSubscriptionActions_Test
 * */
public without sharing class ZuoraSubscriptionActions {
    /**
     * Methode utilisée pour assurer que le compte est eligible avant la creation d'une suscription
     * <p>
     * @param quoteId Id du quote
     * @return boolean pour indiquer si le compte est eligible ou non
     */
    @AuraEnabled
    public static boolean checkAccountEligibility(Id quoteId) {
        Quote quote = [SELECT Account.ACC_Eligible__c, AccountId, Account.IsPersonAccount, Account.ACC_buildingID__c, Account.RecordType.DeveloperName
                       FROM Quote
                       WHERE Id = :quoteId];
        if(quote.Account.RecordType.DeveloperName != System.label.Distributor_RecordType) {
            // Remove Foyer suffix if present before calling the Eligibility API
            String currentBuildingID = String.valueOf(quote.Account.ACC_buildingID__c);

            String cleanedBuildingID = currentBuildingID.countMatches('_') > 1 ? currentBuildingID.substring(0, currentBuildingID.lastIndexOf('_')) : currentBuildingID;

            HttpResponse response = EligibilityManager.doCallout(EligibilityObjects.rawFeasibilityAPIUrl, EligibilityObjects.post, '{"building_id":"' + cleanedBuildingID + '"}');

            string jsonObj = response.getBody();
            // If the request is successful, parse the JSON response.
            if(response.getStatusCode() == 200) {
                // Deserialize the JSON string
                EligibilityObjects.FeasibilityAPIResponse feasibilityInfo = (EligibilityObjects.FeasibilityAPIResponse) System.JSON.deserialize(jsonObj, EligibilityObjects.FeasibilityAPIResponse.class);

                if(feasibilityInfo != null) {
                    if(feasibilityInfo.feasible) {
                        return true;
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else {
            return true;
        }

    }
    /**
     * Methode pour crée une souscription dans zuora a partir du quote
     * <p>
     * @param quoteId  Id du quote, boolean preview
     * @param previewOnly  boolean preview
     * @return resultat de l'appel API
     */
    @AuraEnabled
    public static string createSubscriptionInZuora(Id quoteId, boolean previewOnly) {

        set<Log__c> setLogs = new set<Log__c>();
        list<Log__c> listLogs = new list<Log__c>();
        list<String> listSubProduct = new list<String>();
        string warranty = '0';
        string previewOrder;
        //get all info nedeed to create a sub
        Quote currentQuote = [SELECT Id, Name, Subtotal, QUO_SommeEncaissee__c, opportunityId, QUO_Mode_de_paiement__c,
                              Status, QUO_Periodes_Prepayees__c, QUO_T_SubscriptionId__c, QUO_T_Numero_du_Box__c, Account.ParentId,
                              QUO_Version__c, Account.Name, AccountId, Account.billingCountry, Account.IsPersonAccount,
                              Account.LastName, Account.FirstName, Account.CurrencyIsoCode, Account.billingCountryCode,
                              Account.BillingCity, Account.BillingPostalCode, Account.BillingState, Account.PersonEmail,
                              Account.ACC_Eligible__c, Account.ACC_Entreprise__c, Account.PersonMobilePhone, QUO_IsCollaborator__c, Account.ACC_Distributor_Number__c,
                              Account.RecordType.DeveloperName, Account.ACC_TIN__c, QUO_Taux_De_Change__c, QUO_Paiement_Dollar__c, QUO_Paiement_CDF__c
                              FROM Quote
                              WHERE Id = :quoteId];
        if(currentQuote.QUO_T_Numero_du_Box__c != null && !string.isBlank(currentQuote.QUO_T_Numero_du_Box__c)) {
            string parentAccountId = null;
            if(currentQuote.Account.ParentId != null && !string.isBlank(currentQuote.Account.ParentId)) {
                list<Zuora__CustomerAccount__c> listBillingAccount = [SELECT Zuora__Account__c, Zuora__Zuora_Id__c, name
                                                                      FROM Zuora__CustomerAccount__c
                                                                      WHERE Zuora__Account__c  = :currentQuote.Account.ParentId];

                if(listBillingAccount.size() > 0 && listBillingAccount != null) {
                    parentAccountId = listBillingAccount[0].Zuora__Zuora_Id__c;
                }
            }

            //get product from QLI
            list<QuoteLineItem> listQuoteLineItem = [SELECT Product_Rate_Plan__r.zqu__ZuoraId__c, Product2.Name, Product_Rate_Plan__r.WarrantyDurationInMonth__c,
                                                     Product_Rate_Plan__r.type__c, CreatedBy.Country, Product_Rate_Plan__r.zqu__ZProduct__r.zqu__ZuoraId__c
                                                     FROM QuoteLineItem
                                                     WHERE quoteId = :quoteId ];

            //get list of sub related to a specific quote
            list<Zuora__Subscription__c> listExistingSub = [ SELECT Zuora__SubscriptionNumber__c, Zuora__Status__c
                                                             FROM Zuora__Subscription__c
                                                             WHERE Quote__c = :quoteId ];
            list<Contact> listContacts = new list<Contact>();
            string filterProd = '%';
            if(currentQuote.Account != null && currentQuote.Account.RecordType.DeveloperName.contains('SME')) {
                filterProd = '%SME';
                listContacts = [SELECT id, FirstName, LastName, Email, MailingCity, MailingCountryCode, MailingCountry, MailingPostalCode, MailingStreet, MailingState
                                FROM contact
                                WHERE AccountId = :currentQuote.AccountId AND CON_Role__c includes ('Sig')];
            }
            /* if(currentQuote.Account.RecordType.DeveloperName == System.label.Distributor_RecordType) {
                 listContacts = [SELECT FirstName, LastName, MailingCountryCode, MailingCity, MailingCountry, MailingPostalCode, MailingStreet, MailingState
                                 FROM contact
                                 WHERE AccountId = :currentQuote.AccountId];
               }*/
            string produitCollaborateur = null;
            if(listQuoteLineItem.size() > 0 && listQuoteLineItem != null) {
                if(currentQuote.QUO_IsCollaborator__c == 'Y') {
                    produitCollaborateur = getCollaboratorCharge(listQuoteLineItem[0].Product_Rate_Plan__r.zqu__ZProduct__r.zqu__ZuoraId__c);
                }
                for(QuoteLineItem QLI : listQuoteLineItem) {
                    listSubProduct.add(QLI.Product_Rate_Plan__r.zqu__ZuoraId__c);
                    if(QLI.Product_Rate_Plan__r.WarrantyDurationInMonth__c != null && QLI.Product_Rate_Plan__r.type__c == 'Base') {
                        warranty = QLI.Product_Rate_Plan__r.WarrantyDurationInMonth__c;
                    }
                }
            }
            Id pbId = getUserPricebookID(Id.valueOf(UserInfo.getUserId()));
            Id productId = [SELECT Product2Id
                            FROM PriceBookEntry
                            WHERE Pricebook2Id = : pbId AND isActive = true AND Product2.Name like: filterProd
                            ORDER BY Product2.Name
                            LIMIT 1].Product2Id;

            HttpResponse response;
            if((!currentQuote.Account.isPersonAccount  && listContacts.size() > 0 && listContacts != null && currentQuote.Account.RecordType.DeveloperName.contains('SME')) ||
               currentQuote.Account.isPersonAccount ||
               (!currentQuote.Account.isPersonAccount  && listContacts.size() > 0 && listContacts != null && currentQuote.Account.RecordType.DeveloperName == System.label.Distributor_RecordType)) {

                if((currentQuote.Status == 'In Review' || currentQuote.Status == 'Accepted') && previewOnly) {
                    // get payment amount from the preview sub
                    if(currentQuote.QUO_Mode_de_paiement__c == 'Cash') {

                        //get Tax rate Plan
                        list<zqu__productrateplancharge__c> listTimbreFiscal = [SELECT zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                                FROM zqu__productrateplancharge__c
                                                                                WHERE Name = :System.label.Rate_Plan_Timbre_Fiscal AND
                                                                                zqu__ProductRatePlan__r.zqu__Product__c = : productId AND
                                                                                    (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                    (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                                                zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                                                                LIMIT 1];

                        if(listTimbreFiscal.size() > 0 && listTimbreFiscal != null) {

                            previewOrder =  createPreviewSubscription(integer.valueOf(currentQuote.QUO_Periodes_Prepayees__c), currentQuote.Account.isPersonAccount?currentQuote.Account.billingCountry : listContacts[0].MailingCountry,
                                                                      currentQuote.Account.CurrencyIsoCode, listSubProduct, quoteId, listTimbreFiscal[0].zqu__ProductRatePlan__r.zqu__ZuoraId__c,
                                                                      listTimbreFiscal[0].zqu__ZuoraId__c, currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null);

                        } else {
                            previewOrder =  createPreviewSubscription(integer.valueOf(currentQuote.QUO_Periodes_Prepayees__c), currentQuote.Account.isPersonAccount?currentQuote.Account.billingCountry : listContacts[0].MailingCountry,
                                                                      currentQuote.Account.CurrencyIsoCode, listSubProduct, quoteId, null, null, currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null);

                        }

                    } else {

                        previewOrder =  createPreviewSubscription(integer.valueOf(currentQuote.QUO_Periodes_Prepayees__c), currentQuote.Account.isPersonAccount?currentQuote.Account.billingCountry : listContacts[0].MailingCountry,
                                                                  currentQuote.Account.CurrencyIsoCode, listSubProduct, quoteId, null, null, currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null);

                    }
                    ZuoraResponseObjects.ZuoraPreviewResponse orderResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewOrder, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                    if(orderResponse.zuoraLogs != null && orderResponse.zuoraLogs.size() > 0)
                        listLogs.addAll(orderResponse.zuoraLogs);
                    if(listLogs.size() > 0 && listLogs != null)
                        insert listLogs;

                    return previewOrder;
                }
                //check if quote is valid
                else if(currentQuote.Status == 'Accepted' && !previewOnly) {
                    boolean isRDC = checkRDCUser();
                    //check if QLI contain products
                    if(listQuoteLineItem.size() == 0) {
                        return System.label.Empty_QLI_Message;
                    }
                    //get Tax rate Plan
                    string userCountry = '%' + listQuoteLineItem[0].CreatedBy.Country;

                    list<zqu__productrateplancharge__c> listTimbreFiscal = [SELECT zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                            FROM zqu__productrateplancharge__c
                                                                            WHERE Name = :System.label.Rate_Plan_Timbre_Fiscal AND
                                                                            zqu__ProductRatePlan__r.zqu__Product__c = : productId AND
                                                                                (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                                            zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                                                            LIMIT 1];
                    //check if the number of prepaid period is filled
                    if(currentQuote.QUO_Periodes_Prepayees__c != null && currentQuote.QUO_Mode_de_paiement__c != null) {
                        //check if RDC info are filled
                        if(!isRDC ||
                           (isRDC && (currentQuote.QUO_Taux_De_Change__c != null && !string.isBlank(string.valueOf(currentQuote.QUO_Taux_De_Change__c))) && (currentQuote.QUO_Paiement_Dollar__c != null && !string.isBlank(string.valueof(currentQuote.QUO_Paiement_Dollar__c))))) {

                            //check if there any related sub to the quote
                            if(listExistingSub.size() == 0) {
                                ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
                                if(currentQuote.QUO_Mode_de_paiement__c == 'Cash' && listTimbreFiscal.size() > 0 && listTimbreFiscal != null) {

                                    string preview = createPreviewSubscription(integer.valueOf(currentQuote.QUO_Periodes_Prepayees__c), currentQuote.Account.isPersonAccount?currentQuote.Account.billingCountry : listContacts[0].MailingCountry,
                                                                               currentQuote.Account.CurrencyIsoCode, listSubProduct, null, null, null, currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null);
                                    ZuoraResponseObjects.ZuoraPreviewResponse orderResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                                        preview, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                                    double amount = orderResponse.previewResult.invoices.size() > 0?orderResponse.previewResult.invoices[0].amount : 0;
                                    if(orderResponse.zuoraLogs.size() > 0 && orderResponse.zuoraLogs != null)
                                        setLogs.addAll(orderResponse.zuoraLogs);
                                    if(currentQuote.Account.isPersonAccount) {
                                        zSub = ZuoraMapper.fillCreateOrder(currentQuote, null, listSubProduct, warranty, listTimbreFiscal[0], amount, null, currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null, parentAccountId);

                                    } else {
                                        zSub = ZuoraMapper.fillCreateOrder(currentQuote, null, listSubProduct, warranty, listTimbreFiscal[0], amount, listContacts[0], currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null, parentAccountId);

                                    }

                                } else {
                                    if(currentQuote.Account.isPersonAccount) {
                                        zSub = ZuoraMapper.fillCreateOrder(currentQuote, null, listSubProduct, warranty, null, null, null, currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null, parentAccountId);

                                    } else {
                                        zSub = ZuoraMapper.fillCreateOrder(currentQuote, null, listSubProduct, warranty, null, null, listContacts[0], currentQuote.QUO_IsCollaborator__c == 'Y'?produitCollaborateur : null, parentAccountId);

                                    }

                                }

                                try {
                                    if(zSub != null) {
                                        response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.NEW_SUBSCRIPTION);
                                    }
                                    ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                                    orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                                        response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                                    setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), currentQuote.AccountId, null, orderResponse.subscriptionNumbers == null? null : orderResponse.subscriptionNumbers[0],
                                                                                        ZuoraObjects.ordersAPIUrl, response.getBody(), orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                                    orderResponse.zuoraLogs = setLogs;

                                    return JSON.serialize(orderResponse, true);
                                } catch(Exception e) {
                                    System.debug('Create subscription error ' + e.getLineNumber() + ' : ' + e.getMessage() );
                                    throw new CustomException(e.getMessage());
                                }
                            } else {
                                return System.label.One_Subscription_Per_Quote;
                            }

                        } else {
                            return System.label.Empty_Payment_Info;
                        }
                    } else {
                        return System.label.Empty_Prepaid_Period;
                    }
                } else {
                    return System.label.Invalid_Quote_Message;
                }
            } else {
                return System.label.Empty_Signatory_Contact;
            }
        } else {
            return System.label.Empty_Box_Number;
        }
    }

    /**
     * Methode pour crée un apercu abonnement si la somme n'est pas encaissée ou au cas de demande d'aperçu
     * <p>
     * @param prepaidPeriod nombre de mois prepayées
     * @param country pays du compte
     * @param accountCurrency devis du compte attaché a l'abonnement
     * @param listQuoteLineItem liste de produit listQuoteLIneItem
     * @param quoteId id du devis
     * @param fiscalId id du Timbre fiscal
     * @param chargeId id du charge timbre fiscal
     *  @return API response
     * */
    @AuraEnabled
    public static string createPreviewSubscription(integer prepaidPeriod, string country, string accountCurrency, list<string> listSubProduct,
                                                   string quoteId, string fiscalId, string chargeId, string collabId){
        Set<Log__c> setLog = new set<Log__c>();
        //fill create preview sub order fields
        ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillPreviewSubscription(prepaidPeriod, country, accountCurrency, listSubProduct, null, null, null, collabId);

        try {
            HttpResponse response = ZuoraManager.previewOrder(zSub);
            ZuoraResponseObjects.ZuoraPreviewResponse orderResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                response.getBody(), ZuoraResponseObjects.ZuoraPreviewResponse.class);
            setLog.add(ZuoraSubscriptionActions.createZuoraLog(json.serialize(zSub, true), null, null, null, ZuoraObjects.subscriptionAPIUrl, response.getBody(),
                                                               orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));
            orderResponse.zuoraLogs = setLog;

            if(orderResponse.success) {
                double amount = orderResponse.previewResult.invoices.size() == 0?0 : orderResponse.previewResult.invoices[0].amount;
                if(fiscalId != null && chargeId != null) {
                    ZuoraResponseObjects.ZuoraPreviewResponse previewOrderResponse =  new ZuoraResponseObjects.ZuoraPreviewResponse();
                    //fill create preview sub order fields
                    ZuoraObjects.ZuoraOrder previewSub = ZuoraMapper.fillPreviewSubscription(prepaidPeriod, country, accountCurrency, null, fiscalId, amount, chargeId, null);

                    try {
                        HttpResponse previewResponse = ZuoraManager.previewOrder(previewSub);
                        previewOrderResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                            previewResponse.getBody(), ZuoraResponseObjects.ZuoraPreviewResponse.class);

                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(json.serialize(zSub, true), null, null, null, ZuoraObjects.subscriptionAPIUrl, previewResponse.getBody(),
                                                                           orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                        previewOrderResponse.zuoraLogs = setLog;
                        double tax = previewOrderResponse.previewResult.invoices[0].amount;
                        amount = amount + tax;

                    } catch(Exception e) {

                        System.debug('Create subscription error' + e.getMessage());
                        throw new CustomException(previewOrderResponse.reasons[0].message);
                    }

                }

                list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                                   FROM CurrencyType
                                                   WHERE IsoCode = 'USD'];

                // add charge name to the preview result
                map<string, ZuoraResponseObjects.ZuoraInvoiceItems> chargeNameInfo = new map<string, ZuoraResponseObjects.ZuoraInvoiceItems>();
                if(orderResponse.previewResult.invoices.size() > 0) {
                    for(ZuoraResponseObjects.ZuoraInvoiceItems zInvoice : orderResponse.previewResult.invoices[0].invoiceItems) {
                        chargeNameInfo.put(zInvoice.productRatePlanChargeId, zInvoice);
                    }
                }
                system.debug(orderResponse.previewResult.invoices[0].invoiceItems);
                /*list<zuora__subscriptionProductCharge__c> productCharge = [SELECT Zuora__RatePlanName__c, Zuora__ProductRatePlanChargeId__c
                                                                           FROM zuora__subscriptionProductCharge__c
                                                                           WHERE Zuora__ProductRatePlanChargeId__c IN :chargeNameInfo.keyset()];*/
                list<Zqu__ProductRatePlanCharge__c>  productCharge = [  SELECT zqu__ProductRatePlan__r.Name, zqu__ProductRatePlanChargeName__c, zqu__ZuoraId__c
                                                                        FROM Zqu__ProductRatePlanCharge__c
                                                                        WHERE zqu__ZuoraId__c IN  : chargeNameInfo.keyset()];
                list<ZuoraResponseObjects.ZuoraInvoiceItems> listZInvoice = new list<ZuoraResponseObjects.ZuoraInvoiceItems>();
                // get charge name from product charge and add it to the preview result
                for(ZuoraResponseObjects.ZuoraInvoiceItems zInvoice : chargeNameInfo.values()) {
                    for(Zqu__ProductRatePlanCharge__c subProduct : productCharge) {
                        if(zInvoice.productRatePlanChargeId == subProduct.zqu__ZuoraId__c) {
                            zInvoice.ratePlanName = subProduct.zqu__ProductRatePlan__r.Name;
                            break;
                        }
                    }
                    listZInvoice.add(zInvoice);
                }
                if(orderResponse.previewResult.invoices.size() > 0) {
                    orderResponse.previewResult.invoices[0].invoiceItems = listZInvoice;
                    orderResponse.previewResult.invoices[0].amount = amount;
                }
                orderResponse.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);
                if(quoteId != null && !string.isBlank(quoteId)) {
                    // Also immediately update the Quote with the Total received from the preview
                    Quote updatedQuote = new Quote(Id = quoteId, QUO_Grand_Total__c = amount);
                    update updatedQuote;
                }

                return JSON.serialize(orderResponse, true);

            } else {
                insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, null, ZuoraObjects.previewOrdersAPIUrl);

                return response.getBody();
            }
        }catch(Exception e) {

            System.debug(e.getMessage() + ' ' + e.getLineNumber());
            throw new CustomException(e.getMessage());
        }

    }
    /**
     * Methode pour créer une souscription technique qui est active
     * <p>
     * @param techQuoteId  id de la quote crée pour cette souscription
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string createTechnicalSubscription(String selectedJSON, string subscriptionId, boolean isPreview, double CDFPayment,
                                                     double dollarPayment, double exchangeRate, double returnInCDF, double returnInDollar, string transactionNumber, string operator, string aggregator, string paymentMethod) {
        list<Log__c> listLogs = new list<Log__c>();
        Set<Log__c> setLogs = new set<Log__c>();
        list<String> listSubProduct = new list<String>();
        //get list of chosen products
        List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(selectedJSON);
        for(Object fld : fieldList) {
            Map<String, Object> data = (Map<String, Object>) fld;
            listSubProduct.add((String)data.get('zqu__ZuoraId__c'));
        }

        // get info from the main sub
        list<Zuora__Subscription__c> originalSub = [SELECT Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__Account__r.CurrencyIsoCode, Zuora__Account__r.BillingCountryCode,
                                                    Zuora__SubscriptionNumber__c, Quote__c, Quote__r.CreatedBy.Country, Quote__r.QUO_Mode_de_paiement__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                    Zuora__Status__c, Zuora__Account__r.ACC_Entreprise__c, Zuora__Account__r.billingCountry, Zuora__Account__c
                                                    FROM Zuora__Subscription__c
                                                    WHERE Id = :subscriptionId ];

        // Normal sub starts with A and migrated Sub starts with M
        string techSubName = originalSub[0].Zuora__SubscriptionNumber__c.startsWith('A')?originalSub[0].Zuora__SubscriptionNumber__c.replaceAll('A', 'T') + '%' : originalSub[0].Zuora__SubscriptionNumber__c.replaceAll('M', 'T') + '%';

        // get all technical Sub related to the original one
        list<Zuora__Subscription__c> listTechSub = [SELECT Id, Zuora__SubscriptionNumber__c
                                                    FROM Zuora__Subscription__c
                                                    WHERE Zuora__SubscriptionNumber__c like :techSubName
                                                    ORDER BY Zuora__SubscriptionNumber__c DESC];
        double refundAmount = 0;
        if(returnInCDF != null && !string.isBlank(string.valueOf(returnInCDF)) &&
           returnInDollar != null && !string.isBlank(string.valueOf(returnInDollar))) {
            refundAmount = returnInDollar + (returnInCDF / Double.valueOf(exchangeRate ));
        }
        //check if the status of the main sub is pending
        if(originalSub[0].Zuora__Status__c == 'Pending Activation' || originalSub[0].Zuora__Status__c == 'Active' || originalSub[0].Zuora__Status__c == 'Suspended') {

            string newTechSubName;
            if(listTechSub.size() >= 1 && listTechSub != null) {

                string lastTechSubName = listTechSub[0].Zuora__SubscriptionNumber__c;
                string techSubNumber = lastTechSubName.subString(lastTechSubName.lastIndexOf('-') + 1, lastTechSubName.length());
                integer numberOfTechSub = integer.valueOf(techSubNumber) + 1;
                newTechSubName = lastTechSubName.substring(0, lastTechSubName.lastIndexOf('-') + 1) + stringFormatting(numberOfTechSub);

            } else {
                newTechSubName = techSubName.substring(0, techSubName.length() - 1) + '-001';
            }
            user currentUser = [SELECT Name, USR_DistributeurID__c, CountryCode
                                FROM User
                                WHERE Id = :UserInfo.getUserId()];
            //get Tax rate Plan
            string userCountry = '%' + currentUser.CountryCode;

            string previewResult;
            double currentAmount;
            // get payment amount from the preview sub
            previewResult = createPreviewSubscription(1, originalSub[0].Zuora__Account__r.billingCountry, originalSub[0].Zuora__Account__r.CurrencyIsoCode, listSubProduct, null, null, null, null);

            ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

            if(preview.zuoraLogs != null && preview.zuoraLogs.size() > 0)
                setLogs.addAll(preview.zuoraLogs);
            if(preview.success) {
                currentAmount = preview.previewResult.invoices[0].amount;
            } else {
                currentAmount = 0;
            }
            if(isPreview) {
                return previewResult;
            } else {

                boolean isRDC = checkRDCUser();
                // technical subscription for pending sub
                if(originalSub[0].Zuora__Status__c == 'Pending Activation' && !isRDC) {
                    ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillCreateTechnicalSubscription(originalSub[0], newTechSubName, currentAmount, isRDC, null);

                    HttpResponse response = ZuoraManager.createOrder( zSub, ZuoraObjects.OrderType.NEW_SUBSCRIPTION);
                    ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                    orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                        response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                    setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), originalSub[0].Zuora__Account__c, null, orderResponse.subscriptionNumbers == null?null : orderResponse.subscriptionNumbers[0], ZuoraObjects.ordersAPIUrl,
                                                                        response.getBody(), orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));
                    orderResponse.zuoraLogs = setLogs;
                    ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreatePayment(null, originalSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, 1,
                                                                                          orderResponse.orderNumber, currentAmount + refundAmount, originalSub[0].Zuora__Account__r.CurrencyIsoCode, paymentMethod, true,
                                                                                          string.valueOf(CDFPayment), dollarPayment == null?null : string.valueOf(dollarPayment + refundAmount),
                                                                                          exchangeRate == null?null : string.valueOf(exchangeRate), transactionNumber, operator, aggregator,
                                                                                          currentUser.Name, currentUser.USR_DistributeurID__c);
                    HttpResponse newPaymentResponse = ZuoraManager.createPayment(paymentInfo);
                    string responseAdjustment = newPaymentResponse.getBody().replaceAll('number', 'number_toReplace');
                    ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                        responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);

                    setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(paymentInfo, true), originalSub[0].Zuora__Account__c, null, orderResponse.subscriptionNumbers == null?null : orderResponse.subscriptionNumbers[0], ZuoraObjects.paymentAPIUrl, newPaymentResponse.getBody(),
                                                                        paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true));
                    Zuora__Subscription__c sub = new Zuora__Subscription__c();
                    sub.Id = subscriptionId;
                    sub.SUB_Technical_payment_Id__c = paymentResponse.Id;
                    update sub;
                    if(setLogs != null && setLogs.size() > 0) {

                        listLogs.addAll(setLogs);
                        insert listLogs;
                    }

                    return json.serialize(orderResponse, true);

                }
                // technical subscription for active or suspended sub, or pending sub in RDC
                else {
                    // ensure that QLI isn't empty
                    if(listSubProduct.size() > 0 && listSubProduct != null) {
                        // get technical Sub
                        List<Zuora__Subscription__c> listOriginalSub = [SELECT Zuora__CustomerAccount__r.Zuora__Zuora_Id__c
                                                                        FROM Zuora__Subscription__c
                                                                        WHERE id = :subscriptionId];

                        //create Sub
                        ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillCreateTechnicalSubscription(originalSub[0], newTechSubName, currentAmount, isRDC, listSubProduct);
                        HttpResponse response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.NEW_SUBSCRIPTION);
                        ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                        orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                            response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                        setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), originalSub[0].Zuora__Account__c, null, orderResponse.success?orderResponse.subscriptionNumbers[0] : null, ZuoraObjects.ordersAPIUrl, response.getBody(),
                                                                            orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                        if(orderResponse.success) {
                            string InvoiceNumber = orderResponse.invoiceNumbers[0];
                            ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreatePayment(null, listOriginalSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, 1,
                                                                                                  orderResponse.orderNumber, currentAmount + refundAmount, originalSub[0].Zuora__Account__r.CurrencyIsoCode, paymentMethod, true,
                                                                                                  string.valueOf(CDFPayment), dollarPayment == null?null : string.valueOf(dollarPayment + refundAmount),
                                                                                                  exchangeRate == null?null : string.valueOf(exchangeRate), transactionNumber, operator, aggregator,
                                                                                                  currentUser.Name, currentUser.USR_DistributeurID__c);

                            try {

                                HttpResponse newPaymentResponse = ZuoraManager.createPayment(paymentInfo);
                                string responseAdjustment = newPaymentResponse.getBody().replaceAll('number', 'number_toReplace');
                                ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                                    responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                                setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(paymentInfo, true), originalSub[0].Zuora__Account__c, null, orderResponse.subscriptionNumbers[0], ZuoraObjects.paymentAPIUrl, newPaymentResponse.getBody(),
                                                                                    paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true));

                                if(paymentResponse.zuoraLogs != null && paymentResponse.zuoraLogs.size() > 0)
                                    setLogs.addAll(paymentResponse.zuoraLogs);
                                if(paymentResponse.success) {
                                    string InvoiceId;
                                    // get invoice Id from an account
                                    HttpResponse accountResponse = ZuoraManager.getAccountSummary(listOriginalSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                    ZuoraResponseObjects.ZuoraGetAccount getAccountInfoResponse = new ZuoraResponseObjects.ZuoraGetAccount();
                                    getAccountInfoResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(
                                        accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                                    if(getAccountInfoResponse.success) {

                                        // get invoice id of the request invoice number
                                        for(ZuoraResponseObjects.ZuoraInvoices zInvoice : getAccountInfoResponse.invoices) {

                                            if(zInvoice.InvoiceNumber == InvoiceNumber) {
                                                invoiceId = zInvoice.id;
                                                break;
                                            }
                                        }
                                    }
                                    string invoiceCustomFields = updateBillCustomFields(true, invoiceId, '1', null, string.valueOf(exchangeRate));
                                    ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse = new ZuoraResponseObjects.ZuoraBill();

                                    invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(invoiceCustomFields, ZuoraResponseObjects.ZuoraBill.class);
                                    if(invoiceUpdateResponse.zuoraLogs != null && invoiceUpdateResponse.zuoraLogs.size() > 0)
                                        setLogs.addAll(invoiceUpdateResponse.zuoraLogs);
                                    invoiceUpdateResponse.zuoraLogs = setLogs;
                                    if(invoiceUpdateResponse.success) {

                                        string applyPayment = applyPaymentToBill(currentAmount, paymentResponse.id, invoiceId);
                                        ZuoraResponseObjects.ZuoraPayment applyPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
                                        paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                                            applyPayment, ZuoraResponseObjects.ZuoraPayment.class);

                                        if(paymentResponse.zuoraLogs != null && paymentResponse.zuoraLogs.size() > 0)
                                            setLogs.addALL(paymentResponse.zuoraLogs);

                                        if(setLogs.size() > 0 && setLogs != null) {
                                            listLogs.addAll(setLogs);

                                            insert listLogs;
                                        }

                                        return json.serialize(paymentResponse, true);

                                    } else {
                                        if(setLogs.size() > 0 && setLogs != null) {
                                            listLogs.addAll(setLogs);
                                            insert listLogs;
                                        }
                                        insert AP01_ErreurInterface.insertError('Erreur API', null, null, invoiceUpdateResponse.reasons[0].message, listLogs[listLogs.size()].id, ZuoraObjects.invoiceAPIUrl + invoiceId);

                                        return json.serialize(paymentResponse, true);
                                    }
                                } else {
                                    if(setLogs.size() > 0 && setLogs != null) {
                                        listLogs.addAll(setLogs);
                                        insert listLogs;
                                    }
                                    insert AP01_ErreurInterface.insertError('Erreur API', null, null, paymentResponse.reasons[0].message, listLogs[listLogs.size()].id, ZuoraObjects.paymentAPIUrl);

                                    return response.getBody();
                                }
                            } catch(Exception e) {

                                System.debug(e.getLinenumber());
                                throw new CustomException(e.getMessage());
                            }
                        } else {
                            if(setLogs.size() > 0 && setLogs != null) {
                                listLogs.addAll(setLogs);
                                insert listLogs;
                            }
                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, listLogs[0].id, ZuoraObjects.ordersAPIUrl);

                            return response.getBody();
                        }
                    } else {
                        return System.label.Empty_QLI_Message;
                    }

                }
            }
        } else {
            return System.label.Active_Subscription;
        }
    }
    /**
     * Methode pour obtenir l'id du compte dans zuora
     * <p>
     * @param quoteId  id du devis
     * @return id du compte dans zuora
     * */
    @AuraEnabled
    public static string getCustomerAccountId(id quoteId) {
        try {
            //get list of technical quote
            list<Quote> listQuote = [
                SELECT QUO_T_SubscriptionId__c
                FROM Quote
                WHERE id = :quoteId
            ];
            // get customer account id from te main sub
            list<Zuora__Subscription__c> currentSub = [
                SELECT Zuora__CustomerAccount__r.Zuora__Zuora_Id__c
                FROM Zuora__Subscription__c
                WHERE id = :listQuote[0].QUO_T_SubscriptionId__c
            ];

            if(currentSub != null && currentSub.size() > 0)
            {    
                return currentSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
            }else{
                return null;
            }

        } catch(Exception e) {
            System.debug('Get customer account Id errro ' + e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }

    /**
     * Methode pour créer un payment sur lequel le montant est ajouté
     * <p>
     * @param subscriptionId id de l'abonnement ,
     * @param zuoraAccountId Id du compte dans zuora,
     * @param quoteId du devis,
     * @param orderNumber numero de commande
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string createPayment(id subscriptionId, string zuoraAccountId, id quoteId, string orderNumber){
        set<Log__c> setLogs = new set<Log__c>();
        list<Log__c> listLogs = new list<Log__c>();
        boolean isTechnical;
        // get all technical quote of the main sub
        list<Quote> listTechnicalQuote = [SELECT id, QUO_T_PaymentID__c, Account.BillingCountry
                                          FROM Quote
                                          WHERE QUO_T_SubscriptionId__c != null AND id = :quoteId];

        //if any technical quote exist ==> create payment for technical sub
        if(listTechnicalQuote.size() > 0) {
            isTechnical = true;
        } else {
            isTechnical = false;
        }
        // get products from QLI
        List<QuoteLineItem> listQLI = [SELECT Id, Quote.QUO_Periodes_Prepayees__c, Product_Rate_Plan__r.zqu__ZuoraId__c, Quote.QUO_Paiement_Dollar__c, Quote.QUO_Paiement_CDF__c,
                                       Quote.Account.billingCountry, Quote.Account.CurrencyIsoCode, Quote.AccountId, Quote.QUO_Mode_de_paiement__c, CreatedBy.Country,
                                       Quote.QUO_Montant_Rendu_CDF__c, Quote.QUO_Montant_Rendu_Dollar__c, Quote.QUO_Taux_De_Change__c, Quote.QUO_Grand_Total__c, Quote.QUO_Aggregator__c,
                                       QuoteId, Quote.QUO_Numero_de_transaction__c, Quote.QUO_Operateur__c, Quote.QUO_IsCollaborator__c, Product_Rate_Plan__r.zqu__ZProduct__r.zqu__ZuoraId__c,
                                       Quote.owner.Name, quote.createdBy.USR_DistributeurID__c
                                       FROM QuoteLineItem
                                       WHERE quoteId = :quoteId];
        // ensure that QLI isn't empty
        if(listQLI.size() > 0 && listQLI != null) {
            list<string> listSubProduct = new list<String>();
            for(QuoteLineItem QLI : listQLI) {
                listSubProduct.add(QLI.Product_Rate_Plan__r.zqu__ZuoraId__c);
            }
            // get payment amount from the preview sub
            string previewResult;
            //check collaboratorId
            string collaboratorId = null;
            if(listQLI[0].Quote.QUO_IsCollaborator__c == 'Y') {
                collaboratorId = getCollaboratorCharge(listQLI[0].Product_Rate_Plan__r.zqu__ZProduct__r.zqu__ZuoraId__c);
            }
            //get Tax rate Plan
            string userCountry = '%' + listQLI[0].CreatedBy.Country;
            list<zqu__productrateplancharge__c> listTimbreFiscal = [SELECT zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                    FROM zqu__productrateplancharge__c
                                                                    WHERE Name = :System.label.Rate_Plan_Timbre_Fiscal AND
                                                                    zqu__ProductRatePlan__r.zqu__ZProduct__r.Name like :userCountry AND
                                                                        (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                        (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                                    zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                                                    LIMIT 1];

            // get payment amount from the preview sub
            if(listQLI[0].quote.QUO_Mode_de_paiement__c == 'Cash' && listTimbreFiscal.size() > 0 && listTimbreFiscal != null) {
                // get payment amount from the preview sub
                previewResult = createPreviewSubscription(integer.valueOf(listQLI[0].Quote.QUO_Periodes_Prepayees__c), listQLI[0].Quote.Account.billingCountry, listQLI[0].Quote.Account.CurrencyIsoCode, listSubProduct, null,
                                                          listTimbreFiscal[0].zqu__ProductRatePlan__r.zqu__ZuoraId__c, listTimbreFiscal[0].zqu__ZuoraId__c, listQLI[0].Quote.QUO_IsCollaborator__c == 'Y'?collaboratorId : null);
            } else {
                previewResult = createPreviewSubscription(integer.valueOf(listQLI[0].Quote.QUO_Periodes_Prepayees__c), listQLI[0].Quote.Account.billingCountry, listQLI[0].Quote.Account.CurrencyIsoCode, listSubProduct, null, null, null, listQLI[0].Quote.QUO_IsCollaborator__c == 'Y'?collaboratorId : null);
            }

            ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);
            if(preview.success) {

                double currentAmount = preview.previewResult.invoices[0].amount;
                double refundAmount = 0;
                if(listQLI[0].Quote.QUO_Montant_Rendu_CDF__c != null && !string.isBlank(string.valueOf(listQLI[0].Quote.QUO_Montant_Rendu_CDF__c)) &&
                   listQLI[0].Quote.QUO_Montant_Rendu_Dollar__c != null && !string.isBlank(string.valueOf(listQLI[0].Quote.QUO_Montant_Rendu_Dollar__c))) {
                    refundAmount = listQLI[0].Quote.QUO_Montant_Rendu_Dollar__c + (listQLI[0].Quote.QUO_Montant_Rendu_CDF__c / Double.valueOf(listQLI[0].Quote.QUO_Taux_De_Change__c ));
                }

                ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreatePayment(subscriptionId, zuoraAccountId, integer.valueOf(listQLI[0].Quote.QUO_Periodes_Prepayees__c),
                                                                                      orderNumber, currentAmount + refundAmount, listQLI[0].Quote.Account.CurrencyIsoCode, listQLI[0].Quote.QUO_Mode_de_paiement__c, isTechnical,
                                                                                      listQLI[0].Quote.QUO_Paiement_CDF__c == null?null : string.valueOf(listQLI[0].Quote.QUO_Paiement_CDF__c), listQLI[0].Quote.QUO_Paiement_Dollar__c == null?null : string.valueOf(listQLI[0].Quote.QUO_Paiement_Dollar__c + refundAmount),
                                                                                      listQLI[0].Quote.QUO_Taux_De_Change__c == null?null : string.valueOf(listQLI[0].Quote.QUO_Taux_De_Change__c), listQLI[0].Quote.QUO_Numero_de_transaction__c, listQLI[0].Quote.QUO_Operateur__c, listQLI[0].Quote.QUO_Aggregator__c,
                                                                                      listQLI[0].Quote.owner.Name, listQLI[0].quote.createdBy.USR_DistributeurID__c);

                try {
                    HttpResponse response = ZuoraManager.createPayment(paymentInfo);

                    ZuoraResponseObjects.ZuoraPayment paymentResponse = new ZuoraResponseObjects.ZuoraPayment();
                    paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                        response.getBody(), ZuoraResponseObjects.ZuoraPayment.class);
                    paymentResponse.zuoraLogs = setLogs;
                    setLogs.add(ZuoraSubscriptionActions.createZuoraLog(json.serialize(paymentInfo, true), listQLI[0].Quote.AccountId, null, null, ZuoraObjects.paymentAPIUrl, response.getBody(),
                                                                        paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true));

                    if(paymentResponse.success) {
                        if(listQLI[0].Quote.QUO_Montant_Rendu_CDF__c != null && !string.isBlank(string.valueOf(listQLI[0].Quote.QUO_Montant_Rendu_CDF__c))  &&
                           listQLI[0].Quote.QUO_Montant_Rendu_Dollar__c != null && !string.isBlank(string.valueOf(listQLI[0].Quote.QUO_Montant_Rendu_Dollar__c)) &&
                           (listQLI[0].Quote.QUO_Montant_Rendu_Dollar__c > 0 || listQLI[0].Quote.QUO_Montant_Rendu_CDF__c > 0)) {

                            ZuoraObjects.ZuoraRefundPayment refundPayment = ZuoraMapper.fillCreateRefund(refundAmount, Integer.valueOf(listQLI[0].Quote.QUO_Montant_Rendu_CDF__c),
                                                                                                         string.valueOf(listQLI[0].Quote.QUO_Montant_Rendu_Dollar__c), string.valueOf(listQLI[0].Quote.QUO_Taux_De_Change__c), null, null, true);
                            HttpResponse refundResponse = ZuoraManager.createRefundPayment(refundPayment, paymentResponse.id);
                            ZuoraResponseObjects.ZuoraRefund refundInfo = (ZuoraResponseObjects.ZuoraRefund) System.JSON.deserialize(
                                refundResponse.getBody(), ZuoraResponseObjects.ZuoraRefund.class);
                            setLogs.add (ZuoraSubscriptionActions.createZuoraLog (json.serialize(refundPayment, true), listQLI[0].Quote.AccountId, subscriptionId, null, ZuoraObjects.paymentAPIUrl + paymentResponse.id + '/refunds', refundResponse.getBody(),
                                                                                  refundInfo.success, refundInfo.reasons == null?null : refundInfo.reasons[0].message, ZuoraObjects.post, true));

                            // Also immediately update the Quote with the Total received from the preview
                            Quote updatedQuote = new Quote(Id = quoteId, QUO_Grand_Total__c = currentAmount);
                            update updatedQuote;
                        }
                        paymentResponse.zuoraLogs = setLogs;
                        /* if(setLogs != null && setLogs.size() > 0){}
                             listLogs.addAll(setLogs);
                           insert listLogs;*/

                        return json.serialize(paymentResponse, true);

                    } else {
                        if(setLogs != null && setLogs.size() > 0)
                            listLogs.addAll(setLogs);
                        insert listLogs;
                        insert AP01_ErreurInterface.insertError('Erreur API', null, null, paymentResponse.reasons[0].message, subscriptionId, ZuoraObjects.paymentAPIUrl);

                        return response.getBody();
                    }
                } catch(Exception e) {

                    throw new CustomException(e.getMessage());
                }
            } else {
                return previewResult;
            }
        } else {
            return System.label.Empty_QLI_Message;
        }
    }
    /**
     * Methode pour mettre a jour la date d'activation d'une souscription dans zuora
     * <p>
     * @param mapOfNewSubscription Map des souscriptions avant,modification
     * @param mapOfOldSubscription Map des souscriptions apres la modification
     * */
    public static void activateSubscriptionInZuora(Map<Id, Zuora__Subscription__c> mapOfNewSubscription, Map<Id, Zuora__Subscription__c> mapOfOldSubscription) {

        // create a map including sub to be activated
        list<string> listSubscriptionIdActivationDate = new List<string>();

        //if case of update
        if(mapOfOldSubscription != null) 
        {
            for(Zuora__Subscription__c sub : mapOfNewSubscription.values()) {
                // check if service activation date is changed or not.
                if(
                    sub.Zuora__ServiceActivationDate__c != mapOfOldSubscription.get(sub.Id).Zuora__ServiceActivationDate__c &&
                    mapOfOldSubscription.get(sub.Id).Zuora__Status__c != 'Active' && !string.isBlank(string.valueOf(sub.Zuora__ServiceActivationDate__c))
                ) {
                    // check if the sub is activated before or not (Difference between move and fist activation)
                    if(mapOfOldSubscription.get(sub.Id).Zuora__ServiceActivationDate__c == null) {
                        listSubscriptionIdActivationDate.add(sub.Id + ',EMPTY');
                    } else {
                        listSubscriptionIdActivationDate.add(sub.Id + ',' + mapOfOldSubscription.get(sub.Id).Zuora__ServiceActivationDate__c);
                    }
                }
            }

            if(listSubscriptionIdActivationDate.size() > 0 && !Test.isRunningTest()) {
                // list of Ids with old serviceActivation date
                updateSubscriptionTriggerDate(listSubscriptionIdActivationDate);
            }
        }
    }

    /**
     * Methode pour faire un appel API pour activer une souscription dans zuora
     * <p>
     * @param listSubscriptionIdActivationDate  list des IDs des souscription
     * */
    @future(callout = true)
    public static void updateSubscriptionTriggerDate(list<string> listSubscriptionIdActivationDate){

        Id subId;

        //set of zuora Logs
        Set<Log__c> setLog = new set<Log__c>();
        list<Log__c> listLog = new list<Log__c>();

        // list of erreur d'interface object
        list<Erreur_de_interface__c> listOfErreurInt = new list<Erreur_de_interface__c>();

        // list of subscription Id and the related technical subscriptions
        list<string> listsubscriptionId = new List<String>();

        //list of suivi de souscription to be created on sub activation
        list<Suivi_de_Souscription__c> listActivatedSuivi = new list<Suivi_de_Souscription__c>();

        map<Id, Zuora__Subscription__c> mapSubscriptiontoUpdate = new map<Id, Zuora__Subscription__c>();
        // map of paymentId and payment amount
        map<string, double> paymentIdAmountMap = new Map<string, double>();

        // map of Quote name and related paymentId
        map<string, string> QuoteNamePaymentIdMap = new Map<string, string>();

        map<Id, Date> subscriptionIdActivationDateMap = new Map<Id, Date>();

        list<Zuora__Subscription__c> listSubscription = new list<Zuora__Subscription__c>();
        list<Suivi_de_Souscription__c> listSuivi = new list<Suivi_de_Souscription__c>();
        map<String, list<String>> mapOftechSubAndZuoraId = new map<String, list<String>>();

        try
        {   
            //convert list of string to map of ID and old Service Activation Date value
            for(string subIdActivationDate : listSubscriptionIdActivationDate) {
                List<String> parts = subIdActivationDate.split(',');
                subscriptionIdActivationDateMap.put(Id.valueOf(parts[0]), parts[1] == 'EMPTY'?null : Date.valueOf(parts[1]));
            }

            //get treated suivi records
             listSuivi = [SELECT SV_Date_activation__c, SV_Tech_Installation_Termine__c, SV_Id_Souscription__c, SV_Id_Souscription__r.Zuora__Account__c,
                        SV_Id_Souscription__r.Zuora__ServiceActivationDate__c, SV_Id_Souscription__r.Quote__r.Name, SV_Id_Souscription__r.Name
                        FROM Suivi_de_Souscription__c
                        WHERE SV_Reference_Externe__c != null AND SV_Code_Action__c = 'ACT001' AND SV_Statut__c = 'STA002' AND SV_Id_Souscription__c IN :subscriptionIdActivationDateMap.keyset()];


            //get list of main sub
            listSubscription = [ SELECT Id, Zuora__ServiceActivationDate__c, Zuora__SubscriptionNumber__c, BoxNumber__c, Zuora__ContractEffectiveDate__c,
                                Zuora__Zuora_Id__c, Zuora__Account__r.BillingCountry, Zuora__Account__r.BillingCountryCode, Name,
                                SUB_T_Original_InvoiceId__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.Zuora__BcdSettingOption__c,
                                Quote__r.QUO_Periodes_Prepayees__c, Quote__r.QUO_Grand_Total__c, Quote__r.CreatedBy.Name, Quote__r.CreatedBy.USR_DistributeurID__c,
                                Quote__r.QUO_T_SubscriptionId__c, Quote__r.QUO_T_PaymentID__c, Quote__r.QUO_PTO__c, Quote__r.QUO_Taux_De_Change__c, Zuora__Account__c,
                                Quote__r.Name, SUB_Technical_payment_Id__c
                                FROM Zuora__Subscription__c
                                WHERE Id IN :subscriptionIdActivationDateMap.keyset()];

                                                    /////////////////////////////////////////////////////////////////////////////////////////////
            list<String> techSubNameLike = new list<String>();
            //get all technical subs and there paymentId, of a specific sub
            for(Zuora__Subscription__c subs : listSubscription){
                string techSubName = subs.Name.startsWith('A')?subs.Name.replaceAll('A', 'T') : subs.Name.replaceAll('M', 'T');
                techSubNameLike.add(techSubName+ '%');
            }
            //get list of technical sub
            list<Zuora__Subscription__c> listTechnicalSubscription = [SELECT id, Quote__r.QUO_T_PaymentID__c, Zuora__Zuora_Id__c, Quote__r.CreatedBy.Name, Name,
                                                                    Quote__r.QUO_T_SubscriptionId__c, Quote__r.QUO_Grand_Total__c, Quote__r.CreatedBy.USR_DistributeurID__c,
                                                                    Quote__r.Name
                                                                    FROM Zuora__Subscription__c
                                                                    WHERE Name like :techSubNameLike];

            if(listTechnicalSubscription != null && listTechnicalSubscription.size() != 0) {
                
                for(Zuora__Subscription__c techSub : listTechnicalSubscription) {
                    // return the middle unique part T-S00023344-001 ==> S00023344
                    String uniqueMiddle = techSub.Name.substringBetween('-');
                    if(!mapOftechSubAndZuoraId.keySet().contains(uniqueMiddle)){
                        mapOftechSubAndZuoraId.put(uniqueMiddle, new list<String>());
                    }
                    mapOftechSubAndZuoraId.get(uniqueMiddle).add(techSub.Zuora__Zuora_Id__c);
                }
            }
                                                    ///////////////////////////////////////////////////////////////////////////////////////////////
        } catch (Exception e) {
            system.debug(e.getLineNumber()+' .......... '+e.getMessage());
            Log__c newLog = new Log__c();
            newLog.LG_Body__c = e.getLineNumber()+' >>> '+e.getMessage();
            newLog.LG_Subscription__c = subId;
            newLog.LG_Method_URL__c = 'CustomException';
            newLog.LG_Interface__c = 'Apex';
            newLog.LG_Success__c = false;
            newLog.LG_Method_Type__c = 'QUERY';
            newLog.LG_Retry__c = false;

            setLog.add(newLog);
        }

        if(listSubscription != null && listSubscription.size() > 0)
        {
            for(Zuora__Subscription__c sub : listSubscription) 
            {
                subId = sub.Id;

                // return the middle unique part A-S00023344 ==> S00023344
                String uniqueMiddle = sub.Name.substringAfter('-');
                if(mapOftechSubAndZuoraId.keySet().contains(uniqueMiddle)){
                    listsubscriptionId.addAll(mapOftechSubAndZuoraId.get(uniqueMiddle));
                }
                listsubscriptionId.add(sub.Zuora__Zuora_Id__c);

                //get ZuoraId of related Technical Subscription
                if(sub.SUB_Technical_payment_Id__c != null && !string.isBlank(sub.SUB_Technical_payment_Id__c))
                {
                    HttpResponse getPaymentResponse = ZuoraManager.getPayment(sub.SUB_Technical_payment_Id__c);
                    ZuoraResponseObjects.ZuoraPayment currentPaymentInfo = (ZuoraResponseObjects.ZuoraPayment) System.JSON.deserialize(getPaymentResponse.getBody().replaceAll('__c', '_Reserved'), ZuoraResponseObjects.ZuoraPayment.class);
                    
                    setLog.add(createZuoraLog(sub.SUB_Technical_payment_Id__c, null, sub.Id, sub.Zuora__SubscriptionNumber__c, ZuoraObjects.paymentAPIUrl, getPaymentResponse.getBody(),
                                            currentPaymentInfo.success, currentPaymentInfo.reasons == null?null : currentPaymentInfo.reasons[0].message, ZuoraObjects.get, false));
                    if(currentPaymentInfo.success) {
                        paymentIdAmountMap.put(sub.SUB_Technical_payment_Id__c, currentPaymentInfo.amount);
                    }
                    else{
                    Log__c newLog = new Log__c();
                    newLog.LG_Body__c =getPaymentResponse.getBody();
                    newLog.LG_Subscription__c = subId;
                    newLog.LG_Method_URL__c = 'getPaymentResponse';
                    newLog.LG_Interface__c = 'Apex';
                    newLog.LG_Success__c = false;
                    newLog.LG_Method_Type__c = 'Callout';
                    newLog.LG_Retry__c = false;
				    setLog.add(newLog);
                }
                }

                //activate sub in zuora
                ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillTriggerOrderDates(sub.Zuora__ServiceActivationDate__c, sub.Zuora__SubscriptionNumber__c);
                HttpResponse response = ZuoraManager.updateTriggerOrder(zSub, sub.Quote__r.Name);
                ZuoraResponseObjects.ZuoraTriggerDate activationResponse = (ZuoraResponseObjects.ZuoraTriggerDate) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraTriggerDate.class);

                setLog.add(createZuoraLog(JSON.serialize(zSub, true), sub.Zuora__Account__c, sub.Id, sub.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl + sub.Quote__r.Name, response.getBody(),
                                        activationResponse.success, activationResponse.reasons == null?null : activationResponse.reasons[0].message, ZuoraObjects.put, false));

                if(response != null && activationResponse.success)
                {
                    boolean isActive;

                    if(sub.Zuora__ServiceActivationDate__c != sub.Zuora__ContractEffectiveDate__c)
                    {
                        //adjust the bcd on the account to adjust service period on the bill
                        ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(sub.Zuora__ServiceActivationDate__c.day());
                        HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, sub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                        ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBDCResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                        
                        setLog.add(createZuoraLog(JSON.serialize(zAccount, true), sub.Zuora__Account__c, sub.Id, sub.Zuora__SubscriptionNumber__c, ZuoraObjects.updateAccountAPIUrl, updateAccount.getBody(),
                                    adjustBDCResponse.success, adjustBDCResponse.reasons == null?null : adjustBDCResponse.reasons[0].message, ZuoraObjects.put, false));
                        if(adjustBDCResponse.success) {
                            isActive = true;
                        }else{
                            Log__c newLog = new Log__c();
                            newLog.LG_Body__c = updateAccount.getBody();
                            newLog.LG_Subscription__c = subId;
                            newLog.LG_Method_URL__c = 'adjustBDCResponse';
                            newLog.LG_Interface__c = 'Apex';
                            newLog.LG_Success__c = false;
                            newLog.LG_Method_Type__c = 'Callout';
                            newLog.LG_Retry__c = false;
                            setLog.add(newLog);
                        }
                    } 
                    else {
                        isActive = true;
                    }

                    if(isActive)
                    {
                        // generate bill for the prepaid periods
                        string billResponse = generateBill(listsubscriptionId, sub.Zuora__ServiceActivationDate__c, integer.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c),sub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                        ZuoraResponseObjects.ZuoraBill invoiceResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(billResponse, ZuoraResponseObjects.ZuoraBill.class);

                        if(invoiceResponse.zuoraLogs != null && invoiceResponse.zuoraLogs.size() > 0) {
                            setLog.AddAll(invoiceResponse.zuoraLogs);
                        }

                        if(invoiceResponse.success)
                        {
                            // add invoice custom fields
                            string invoiceCustomFields = updateBillCustomFields(true, invoiceResponse.invoices[0].id, string.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c), sub, string.valueOf(sub.Quote__r.QUO_Taux_De_Change__c));
                            ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse =  (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(invoiceCustomFields, ZuoraResponseObjects.ZuoraBill.class);

                            if(invoiceUpdateResponse.zuoraLogs != null && invoiceUpdateResponse.zuoraLogs.size() > 0){
                                setLog.addALL(invoiceUpdateResponse.zuoraLogs);
                            }

                            if(invoiceUpdateResponse.success)
                            {
                                //apply created payment to the generate bill
                                sub.SUB_T_Original_InvoiceId__c = invoiceResponse.invoices[0].id;
                                mapSubscriptiontoUpdate.put(sub.Id, sub);

                                //apply payment of technical and original subscription to the generated invoice
                                string applyResponse;
                                applyResponse = applyPaymentToBill(sub.Quote__r.QUO_Grand_Total__c, string.isBlank(sub.Quote__r.QUO_T_PaymentID__c)?QuoteNamePaymentIdMap.get(sub.Quote__r.Name) : sub.Quote__r.QUO_T_PaymentID__c, invoiceResponse.invoices[0].id);
                                ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(applyResponse, ZuoraResponseObjects.ZuoraPayment.class);

                                if(paymentResponse.zuoraLogs != null && paymentResponse.zuoraLogs.size() > 0){
                                    setLog.addAll(paymentResponse.zuoraLogs);
                                }
                                    
                                if(paymentResponse.success)
                                {
                                    //fill next renewal date on the sub
                                    string customFieldsResponse = addCustomFieldsToSubscription(sub, null, null, null, null);
                                    ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(customFieldsResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                                    if(orderResponse.zuoraLogs != null && orderResponse.zuoraLogs.size() > 0){
                                        setLog.addAll(orderResponse.zuoraLogs);
                                    }
                                        
                                    if(orderResponse.success)
                                    {
                                        // if there is related technical sub
                                        if(listsubscriptionId.size() > 1) {
                                            paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(applyResponse, ZuoraResponseObjects.ZuoraPayment.class);

                                            if(paymentResponse.zuoraLogs != null && paymentResponse.zuoraLogs.size() > 0){
                                                setLog.addALL(paymentResponse.zuoraLogs);
                                            }
                                            if(paymentResponse.success)
                                            {
                                                //also add payment of technical sub if it exist to the generated bill
                                                for(string paymentId : paymentIdAmountMap.keyset()) {
                                                    applyResponse = applyPaymentToBill(paymentIdAmountMap.get(paymentId), paymentId, invoiceResponse.invoices[0].id);
                                                    paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(applyResponse, ZuoraResponseObjects.ZuoraPayment.class);

                                                    if(paymentResponse.zuoraLogs != null && paymentResponse.zuoraLogs.size() > 0){
                                                        setLog.addAll(paymentResponse.zuoraLogs);
                                                    }
                                                }
                                            }
                                        }
                                    } 
                                    else {
                                        listOfErreurInt.add(AP01_ErreurInterface.insertError('Erreur API', null, null, 'invoiceUpdateResponse.reasons[0].message', sub.Id, ZuoraObjects.invoiceAPIUrl + invoiceResponse.invoices[0].id));
                                    }
                                }else{
                            setLog.AddAll(invoiceResponse.zuoraLogs);
                        }
                                //create suivi on activation
                                listActivatedSuivi.add(
                                    ZuoraSubscriptionActions.createSuivi(
                                        sub.BoxNumber__c, 'ACT011', Datetime.now(),
                                        'DST001', sub.id, sub.Zuora__Account__r.BillingCountryCode,
                                        sub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, null, null));
                            }
                        }
                    }
                }
                else {
                    listOfErreurInt.add(AP01_ErreurInterface.insertError('Erreur API', null, null, response.getBody(), sub.Id, ZuoraObjects.ordersAPIUrl + sub.Quote__r.Name));
                }
            }
        }else{
            Log__c newLog = new Log__c();
            newLog.LG_Method_URL__c = 'Null List Of Subscription detected';
            newLog.LG_Interface__c = 'Apex';
            newLog.LG_Success__c = false;
            newLog.LG_Retry__c = false;

            setLog.add(newLog);
        }
        
        if(setLog != null && setLog.size() > 0) {
            listLog.Addall(setLog);
            insert listLog;
        }
        if(mapSubscriptiontoUpdate.values() != null && mapSubscriptiontoUpdate.values().size() > 0){ 
            update mapSubscriptiontoUpdate.values(); 
        }
        if(listActivatedSuivi != null && listActivatedSuivi.size() > 0){ 
            insert listActivatedSuivi; 
        }
        
        list<Suivi_de_Souscription__c> listSuiviToUpdate = new list<Suivi_de_Souscription__c>();
        list<Account> listAccountToUpdate = new list<Account>();

        //update suivi records
        if(listSuivi != null && listSuivi.size() > 0){
            for(Suivi_de_Souscription__c suivi : listSuivi) {
                if(mapSubscriptiontoUpdate.keySet().contains(suivi.SV_Id_Souscription__c)){
                    suivi.SV_Tech_Installation_Termine__c = true;
                    suivi.SV_Date_activation__c = suivi.SV_Id_Souscription__r.Zuora__ServiceActivationDate__c;
                    listSuiviToUpdate.add(suivi);

                    Account acc = new Account(Id = suivi.SV_Id_Souscription__r.Zuora__Account__c, ACC_TechInstallation__c = true);
                    listAccountToUpdate.add(acc);
                }
            }
        }
        if(listSuiviToUpdate != null && !listSuiviToUpdate.isEmpty() )
        {
            update listSuiviToUpdate;

            if(listAccountToUpdate != null && listAccountToUpdate.size() > 0) {
                update listAccountToUpdate;
            }
        }
        if(listOfErreurInt!= null && listOfErreurInt.size() > 0){
            insert listOfErreurInt;
        }
    }
    /**
     * Methode pour faire un appel API pour generer une facture
     * <p>
     * @param listSubId list des IDs des souscription,
     * @param startDate date d'activation de l'abonnement,
     * @param perpaidPeriods nombre de periodes prepayées,
     * @param customerAccountId l'Id du compte dans zuora
     * @return resultat de l'appel API
     * */
    public static string generateBill(list<string> listSubId, date startDate, integer perpaidPeriods, string customerAccountId){
        // fill fields to generate a bill
        set<Log__c> setLog = new set<Log__c>();
        ZuoraObjects.ZuoraBilling zBill = ZuoraMapper.fillGenerateBill(listSubId, startDate, perpaidPeriods);

        try {
            HttpResponse billResponse = ZuoraManager.CreateBillByAccount(zBill, customerAccountId);
            ZuoraResponseObjects.ZuoraBill invoiceResponse = new ZuoraResponseObjects.ZuoraBill();
            invoiceResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(
                billResponse.getBody(), ZuoraResponseObjects.ZuoraBill.class);

            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zBill, true), null, null, null, ZuoraObjects.accountAPIUrl + customerAccountId + ZuoraObjects.billAPIUrl, billResponse.getBody(),
                                                               invoiceResponse.success, invoiceResponse.reasons == null?null : invoiceResponse.reasons[0].message, ZUoraObjects.post, true));

            invoiceResponse.zuoraLogs = setLog;

            return json.serialize(invoiceResponse, true);

        } catch(exception error) {

            System.debug('error ' + error.getMessage());

            return null;
        }
    }
    /**
     * Methode pour faire un appel API pour generer une facture
     * <p>
     * @param onCreate boolean création,
     * @param invoiceId l'id du facture,
     * @param perpaidPeriods nombre de periodes prepayées
     * @return resultat de l'appel API
     * */
    public static string updateBillCustomFields(boolean onCreate, string invoiceId, string perpaidPeriods, Zuora__Subscription__c sub, string conversionRate){

        set<Log__c> setLog = new set<Log__c>();
        // fill fields to update the generate bill custom fields
        ZuoraObjects.ZuoraBilling zBill = ZuoraMapper.fillInvoiceCustomFields(onCreate, perpaidPeriods, sub, conversionRate, sub == null?null : sub.Zuora__Account__c);

        try {
            HttpResponse billResponse;
            billResponse = ZuoraManager.updateInvoice(invoiceId, zBill);

            ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse = new ZuoraResponseObjects.ZuoraBill();
            invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(billResponse.getBody(), ZuoraResponseObjects.ZuoraBill.class);

            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zBill, true), null, sub == null?null : sub.Id, sub == null?null : sub.Zuora__SubscriptionNumber__c, ZuoraObjects.invoiceAPIUrl + invoiceId, billResponse.getBody(),
                                                               invoiceUpdateResponse.success, invoiceUpdateResponse.reasons == null?null : invoiceUpdateResponse.reasons[0].message, ZuoraObjects.put, true));

            invoiceUpdateResponse.zuoraLogs = setLog;

            return json.serialize(invoiceUpdateResponse, true);

        } catch(exception error) {

            System.debug('Update bill custom fields error ' + error.getMessage());

            return null;
        }
    }

    /**
     * Methode pour appliquer un payment sur la facture
     * <p>
     * @param amount le montant encaisse ,
     * @param paymentId id du paiement,
     * @param invoiceId id de la facture dans zuora
     * @return resultat de l'appel API
     * */
    public static string applyPaymentToBill(decimal amount, string paymentId, string invoiceId){
        set<Log__c> setLog = new set<Log__c>();
        // fill fields to apply payment on a bill
        ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillApplyPayment(invoiceId, integer.valueOf(amount));
        try {
            HttpResponse response = ZuoraManager.applyPayment(paymentInfo, paymentId);
            ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize( response.getBody(), ZuoraResponseObjects.ZuoraPayment.class);

            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(paymentInfo, true), null, null, null, ZuoraObjects.paymentAPIUrl + paymentId + '/apply', response.getBody(),
                                                               paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZUoraObjects.put, true));

            paymentResponse.zuoraLogs = setLog;

            return json.serialize(paymentResponse, true);

        } catch(exception error) {

            System.debug('Apply payment to an invoice error:  ' + error.getMessage());

            return null;
        }
    }

    /**
     * Methode pour faire un appel API pour ajouter les champs custom d'une souscription
     * <p>
     * @param subscriptionToUpdate l'abonnement sur laquelle la mise à jour est faite,
     * @param warranty nombre de mois guarantie pour une box,
     * @param boxNumber lu numero de la box
     * @return resultat de l'appel API
     * */
    public static string addCustomFieldsToSubscription(Zuora__Subscription__c subscriptionToUpdate, integer warranty, string boxNumber, date nextBillDate, string sequenceNumber){
        set<Log__c> setLog = new set<Log__c>();
        list<Log__c> listLog = new list<Log__c>();
        //update custom fields of an existing sub
        ZuoraObjects.ZuoraOrderSubscription subCustomFields = ZuoraMapper.updateSubscriptionCustomFields(subscriptionToUpdate, warranty, boxNumber, nextBillDate, sequenceNumber);

        try {
            HttpResponse response;
            response = ZuoraManager.updateSubscriptionCustomFields(subCustomFields, subscriptionToUpdate.Zuora__SubscriptionNumber__c);
            ZuoraResponseObjects.ZuoraSubscriptions updateSubResponse = (ZuoraResponseObjects.ZuoraSubscriptions) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraSubscriptions.class);

            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(subCustomFields, true), null, subscriptionToUpdate.Id, subscriptionToUpdate.Zuora__SubscriptionNumber__c, ZuoraObjects.subscriptionAPIUrl + subscriptionToUpdate.Zuora__SubscriptionNumber__c + '/customFields', response.getBody(),
                                                               updateSubResponse.success, updateSubResponse.reasons == null?null : updateSubResponse.reasons[0].message, Zuoraobjects.put, false));
            updateSubResponse.zuoraLogs = setLog;

            return json.serialize(updateSubResponse, true);

        } catch(exception error) {

            System.debug('Add subscription custom fields error: ' + error.getMessage());

            return null;
        }
    }

    /**
     * Methode pour activer la souscription avant de l'annuler
     * <p>
     * @param subscriptionId  id de la souscription
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string activateSubscription(id subscriptionId) {
        Zuora__Subscription__c originalSub = [
            SELECT
            Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
            Zuora__SubscriptionNumber__c, Zuora__ServiceActivationDate__c,
            Zuora__Status__c, Quote__r.Name, BoxNumber__c
            FROM Zuora__Subscription__c
            WHERE id = :subscriptionId
        ];
        // activate pending sub in zuora
        ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillTriggerOrderDates(Date.today(), originalSub.Zuora__SubscriptionNumber__c);

        HttpResponse response = ZuoraManager.updateTriggerOrder(zSub, originalSub.Quote__r.Name);

        return response.getBody();
    }

    /**
     * Methode pour annuler une souscription
     * <p>
     * @param subscriptionId id de la souscription,
     * @param newQuoteId id de la quote,
     * @param reasons les raisons pour lesquelles l'utilisateur annule cette souscription,
     * @param isResiliation boolean resiliation pour indiquer si c'est le cas d'une resiliation ou annulation
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string cancelSubscription(id subscriptionId, id newQuoteId, string reasons, boolean isResiliation){
        list<Log__c> listLog = new list<Log__c>();

        Zuora__Subscription__c originalSub = [SELECT Id, Zuora__Status__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Quote__c, BoxNumber__c, Zuora__Zuora_Id__c,
                                              Zuora__SubscriptionNumber__c, Zuora__ServiceActivationDate__c, Zuora__Account__c, Quote__r.QUO_Reference_article__c, SUB_Tech_Material__c,
                                              ExpectedRenewalDate__c, Zuora__Account__r.BillingCountry, Zuora__Account__r.BillingCountryCode, Quote__r.QUO_PTO__c,
                                              SUB_Status__c, SUB_EquipmenId_CBundle__c, SUB_Subscription_Number__c, SUB_Subscriber_Number__c, SUB_EquipmentType_CBundle__c
                                              FROM Zuora__Subscription__c
                                              WHERE id = :subscriptionId];
        if(originalSub != null) {
            string boxNumber = originalSub.BoxNumber__c;
            string returnedResponse;
            String canalResponse;
            //get info from account and it's related contact to create a suivi
            list<Account> listAccountContacts = [SELECT FirstName, LastName, ACC_Entreprise__c, RecordType.DeveloperName, ACC_AccountNumber__c,
                                                 ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName,
                                                 ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c,
                                                 ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c,
                                                 (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c FROM Contacts WHERE AccountId = :originalSub.Zuora__Account__c)
                                                 FROM Account
                                                 WHERE id = :originalSub.Zuora__Account__c];

            // fill cancel order fields
            ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillCancelSubscription(originalSub, originalSub.Quote__c, reasons, isResiliation);

            try {
                ZuoraObjects.ZuoraNullFields removeBoxNumber = ZuoraMapper.fillNullFields(originalSub.Zuora__Zuora_Id__c, new list<string> {'BoxNumber__c'}, 'Subscription');

                HttpResponse boxNumberResponse = ZuoraManager.emptyFields(removeBoxNumber);
                string reponse = boxNumberResponse.getBody().substring(1, boxNumberResponse.getBody().length() - 1);
                ZuoraResponseObjects.ZuoraNullFields nullResponse = new ZuoraResponseObjects.ZuoraNullFields();
                nullResponse = (ZuoraResponseObjects.ZuoraNullFields) JSON.deserialize(reponse, ZuoraResponseObjects.ZuoraNullFields.class);

                listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(removeBoxNumber, true), originalSub.Zuora__Account__c, originalSub.Id, originalSub.Zuora__SubscriptionNumber__c, ZuoraObjects.nullFieldsAPIUrl, boxNumberResponse.getBody(),
                                                                    nullResponse.Success, nullResponse.errors == null?null : nullResponse.errors[0].message, ZuoraObjects.post, false));
                if(nullResponse.success) 
                {
                    // send cancel order to Zuora
                    HttpResponse response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.CANCEL_SUBSCRIPTION);
                    ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                    orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                   
                    listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), originalSub.Zuora__Account__c, originalSub.Id, originalSub.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, response.getBody(),
                                                                        orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                    if(orderResponse.success)
                    {
                        // if Canal equipment exist
                        if(originalSub.SUB_Tech_Material__c != null)
                        {
                            // send a cancel request to CGA if Canal+ Subscription is active or an equipment is reserved
                            canalResponse = BundleCSubscription.cancelBundleC(originalSub.Id, 'A_TORT');
                        }

                        if(isResiliation)
                        {
                            //create suivi for 'Resiliation'
                            insert ZuoraSubscriptionActions.createSuivi(
                                originalSub.BoxNumber__c, 'ACT009', Datetime.now(), 'DST001',
                                subscriptionId, originalSub.Zuora__Account__r.BillingCountryCode,
                                originalSub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, SuiviMapper.fillSuiviResilier(listAccountContacts[0], listAccountContacts[0].contacts, null), null);
                        } 
                        else {
                            //create suivi for 'Annultion'
                            insert ZuoraSubscriptionActions.createSuivi(
                                originalSub.BoxNumber__c, 'ACT010', Datetime.now(), 'DST001',
                                subscriptionId, originalSub.Zuora__Account__r.BillingCountryCode,
                                originalSub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, null, null);

                            Account acc = new Account(id = originalSub.Zuora__Account__c, ACC_StatutCompte__c = 'System.label.Statut_Compte_Annule');
                            update acc;
                        }
                    } 
                    else {
                        string addBoxNumber = addCustomFieldsToSubscription(originalSub, null, boxNumber, null, null);
                        insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, null,  ZuoraObjects.ordersAPIUrl);
                    }

                    // add box number to cancel Sub response
                    ZuoraResponseObjects.ZuoraCreateOrderResponse cancelSubResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                    cancelSubResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                    cancelSubResponse.boxNumber = boxNumber;
                    cancelSubResponse.article = originalSub.Quote__r.QUO_Reference_article__c;

                    returnedResponse = JSON.serialize(cancelSubResponse, true);
                }
                else {
                    insert AP01_ErreurInterface.insertError('Erreur API', null, null, nullResponse.errors[0].message, subscriptionId, ZuoraObjects.nullFieldsAPIUrl);

                    returnedResponse = reponse;
                }

                if(listLog != null && listLog.size() > 0) {
                    insert listLog;
                }

                return returnedResponse;
            } catch(Exception e) {
                throw new CustomException(e.getMessage()+ ' ==> '+e.getLineNumber());
            }
        } 
        else {
            return null;
        }
    }

    /**
     * Methode pour suspendre une souscription
     * <p>
     * @param subscriptionId id de la souscription,
     * @param newQuoteID id de la quote ,
     * @param periodType le type de periode,
     * @param period la durée de la suspension
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string supspendSubscription(id subscriptionId, string newQuoteID, string periodType, integer period){
        list<Log__c> listLog = new list<Log__c>();
        Zuora__Subscription__c originalSub = [
            SELECT Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__SubscriptionNumber__c, Zuora__Account__c,
            Zuora__Account__r.BillingCountry, Zuora__Account__r.BillingCountryCode, Quote__r.QUO_PTO__c, Quote__c, BoxNumber__c
            FROM Zuora__Subscription__c
            WHERE id = :subscriptionId
        ];
        if(originalSub != null) {
            //get info from account and it's related contact to create a suivi
            list<Account> listAccountContacts = [SELECT FirstName, LastName, ACC_Entreprise__c, RecordType.DeveloperName, ACC_AccountNumber__c,
                                                 ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName, Name,
                                                 ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c,
                                                 ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c,
                                                 (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c FROM Contacts WHERE AccountId = :originalSub.Zuora__Account__c)
                                                 FROM Account
                                                 WHERE id = :originalSub.Zuora__Account__c];

            //fill suspend order fields
            ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillSuspendSubscription(originalSub, originalSub.Quote__c, periodType, period);

            try {
                HttpResponse response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.SUSPEND);
                ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), originalSub.Zuora__Account__c, originalSub.Id, originalSub.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, response.getBody(),
                                                                    orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));
                if(!orderResponse.success) {
                    insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, subscriptionId, ZuoraObjects.ordersAPIUrl);

                }

                if(listLog.size() > 0 && listLog != null)
                    insert listLog;

                return response.getBody();
            } catch(Exception e) {

                throw new CustomException(e.getMessage());
            }
        } else {
            return null;
        }
    }

    /**
     * Methode pour afficher les produits de type addOn
     * <p>
     * @param subscriptionId id de la souscription
     * @return list des produits
     * */
    @AuraEnabled
    public static List<zqu__ProductRatePlan__c> getProductRatePlans(){
        try {
            Id pbId = getUserPricebookID(Id.valueOf(UserInfo.getUserId()));

            Id productId = [SELECT Product2Id
                            FROM PriceBookEntry
                            WHERE Pricebook2Id = : pbId AND isActive = true LIMIT 1].Product2Id;

            list<zqu__productRatePlan__c> productRatePlan = [SELECT Id, type__c, category__c, Name, zqu__Product__r.Name, zqu__ZuoraId__c
                                                             FROM zqu__productRatePlan__c
                                                             WHERE type__c = 'AddOn'
                                                             AND (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) )
                                                             AND (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY))
                                                             AND zqu__Deleted__c = FALSE AND zqu__Product__c = : productId
                                                             ORDER BY Category__c DESC];

            return productRatePlan;
        } catch(Exception e) {
            System.debug('Get product rate plans' + e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }
    /**
     * Methode pour créer une quote pour la souscription technique
     * <p>
     * @param subscriptionId id de la souscription
     * @return id de la nouvelle quote
     * */
    /* @AuraEnabled
       public static string createTechnicalSubscriptionQuote(id subscriptionId) {
         Zuora__Subscription__c requestedSub = [
             SELECT Quote__r.OpportunityId, Quote__r.Name, Zuora__Status__c
             FROM Zuora__Subscription__c
             WHERE id = :subscriptionId
         ];
         if(requestedSub.Zuora__Status__c == 'Pending Activation' || requestedSub.Zuora__Status__c == 'Active' || requestedSub.Zuora__Status__c == 'Suspended') {
             //prepare technical quote name format
             string dToday = string.valueOf(datetime.now());
             dToday = dToday.replaceAll(' ', '');
             dToday = dToday.replaceAll('-', '');
             dToday = dToday.replaceAll(':', '');

             Quote newQuote = new Quote(
                 Name = requestedSub.Quote__r.Name + '-' + dToday + '-TECH',
                 OpportunityId = requestedSub.Quote__r.OpportunityId,
                 QUO_T_SubscriptionId__c = subscriptionId,
                 QUO_Periodes_Prepayees__c = '1');
             insert newQuote;

             return newQuote.id;
         } else {
             return System.Label.SUB_SubscriptionShouldBeActive;
         }
       }*/
    /**
     * Methode pour mettre a jour le compte et ajouter un payment par defaut sur ce compte
     * <p>
     * @param AccountId id du customer account
     * @return void
     * */
    @AuraEnabled
    public static string addDefaultPaymentMethod(string AccountId) {
        ZuoraObjects.ZuoraUpdateAccount updateAccount = new ZuoraObjects.ZuoraUpdateAccount();
        //add cash payment method to the account
        updateAccount.DefaultPaymentMethodId = System.label.Default_Payment_Method_Id;
        try {
            HttpResponse response;
            response = ZuoraManager.UpdateZuoraAccount(updateAccount, AccountId);

            return response.getBody();
        } catch(Exception e) {
            system.debug(e.getLineNumber()+'  .... '+e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }
    /**
     * Methode pour ajouter le numero de commande relative a la souscription sur la quote
     * <p>
     * @param quoteId id du devis,
     * @param orderNumber le numero de commande
     * */
    @AuraEnabled
    public static void addOrderNumberToQuote(string orderNumber, Id quoteId) {
        Quote currentQuote = [ SELECT name, QUO_T_Numero_De_Commande__c
                               FROM QUOTE
                               WHERE id = :quoteId ];
        currentQuote.QUO_T_Numero_De_Commande__c = orderNumber;
        update currentQuote;
    }
    /** Methode utilisée pour récupérer les Ids des comptes dans zuora
     * <p>
     * @param accountNumber zuora account number
     * @return appel API
     * */
    @AuraEnabled
    public static string getZuoraAccountInfo(string accountNumber) {
        return ZuoraManager.getZuoraAccount(accountNumber).getBody();
    }
    /**
     * methode pour ajouter l'Id du payment sur le devis
     * <p>
     * @param quoteId  id du devis,
     * @param paymentId id du paiement dans zuora
     * */
    @AuraEnabled
    public static void addPaymentIdToQuote(id quoteId, string paymentId) {
        list<Quote> currentSubscription = [
            SELECT QUO_T_PaymentID__c
            FROM Quote
            WHERE Id = :quoteId
        ];
        currentSubscription[0].QUO_T_PaymentID__c = paymentId;
        update currentSubscription;
    }
    /**
     * methode pour valider si l'addresse du compte est change
     *  <p>
     * @param mapOfNewAccount map des comptes avant la modification,
     * @param mapOfOldAccount map des comptes apres la modification
     * */
    // (Cette methode est fusionner avec autre dans AP01_AccounttriggerHandler)
        // public static void updateAccountAddressAndTIN(Map<Id, Account> mapOfNewAccount, Map<Id, Account> mapOfOldAccount){
        //     list<Id> listUpdatedAccounts = new List<Id>();
        //     Map<Id, String> mapUpdatedAccountsTIN  = new Map<Id, String>();
        //     for(Account acc : mapOfNewAccount.values()) {
        //         // check if Building Id is changed

        //         if(acc.ACC_BuildingID__c != mapOfOldAccount.get(acc.Id).ACC_BuildingID__c && acc.ACC_BuildingID__c != null) {
        //             listUpdatedAccounts.add(acc.Id);
        //         }
        //         if(acc.ACC_TIN__c != mapOfOldAccount.get(acc.Id).ACC_TIN__c && acc.ACC_TIN__c != null) {
        //             mapUpdatedAccountsTIN.put(acc.Id, acc.ACC_TIN__c);
        //         }
        //     }
        //     // update account address in zuora
        //     if(listUpdatedAccounts.size() != 0 && listUpdatedAccounts != null) {

        //         updateAccountAndSubscription(listUpdatedAccounts);
        //     }
        //     // update account TIN in zuora
        //     if(mapUpdatedAccountsTIN != null  &&  mapUpdatedAccountsTIN.size() != 0) {

        //         updateAccountTIN(mapUpdatedAccountsTIN);
        //     }
        // }

    /**
     * methode pour mettre a jour le TIN de l'account dans zuora
     * <p>
     * @param mapUpdatedAccountsIdTIN Map Zuora__AccountId avec les Tax a mettre à jour
     * */
    @future(callout = true)
    public static void updateAccountTIN(Map<Id, String> mapUpdatedAccountsIdTIN){

        list<Log__c> listLog = new list<Log__c>();
        // query the customer Account from the correspondent subscription to get subId and SubscriptionNumber needed to the logs
        list<Zuora__Subscription__c> listOfSubscription = [SELECT id, Zuora__CustomerAccount__c, Zuora__SubscriptionNumber__c,
                                                           Zuora__CustomerAccount__r.Zuora__Account__c,
                                                           Zuora__CustomerAccount__r.Zuora__Zuora_Id__c
                                                           FROM Zuora__Subscription__c
                                                           WHERE Zuora__CustomerAccount__r.Zuora__Account__c IN :mapUpdatedAccountsIdTIN.keySet()];

        if(listOfSubscription != null && listOfSubscription.size() > 0) {

            for(Zuora__Subscription__c subsOfAccount : listOfSubscription) {
                // update customer account TIN
                ZuoraObjects.ZuoraAccount zAcc = new ZuoraObjects.ZuoraAccount();
                zAcc.existingID = subsOfAccount.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
                zAcc.TaxID_Reserved = mapUpdatedAccountsIdTIN.get(subsOfAccount.Zuora__CustomerAccount__r.Zuora__Account__c);

                HttpResponse response = ZuoraManager.createOrUpdateAccount(zAcc);
                ZuoraResponseObjects.ZuoraUpdateAccountResponse updateAccount =
                (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAcc, true), subsOfAccount.Zuora__CustomerAccount__r.Zuora__Account__c, subsOfAccount.Id, subsOfAccount.Zuora__SubscriptionNumber__c, ZuoraObjects.accountAPIUrl, response.getBody(),
                                                                    updateAccount.success, updateAccount.reasons == null?null : updateAccount.reasons[0].message, ZuoraObjects.post, false));
            }
            if(listLog != null && listLog.size() > 0)
                insert listLog;
        }
    }

    /**
     * methode pour mettre a jour l'addresse du compte dans zuora
     * <p>
     * @param listUpdatedAccountId liste Id des comptes a mettre à jour
     * */
    @future(callout = true)
    public static void updateAccountAndSubscriptionMove(Id listUpdatedAccountId){
        list<Log__c> listLog = new list<Log__c>();
        list<Suivi_de_Souscription__c> listSuiviToUpdate = new list<Suivi_de_Souscription__c>();
        list<zuora__Subscription__c> listSub = new list<zuora__Subscription__c>();
        //get address of requested accounts: needed to update account address in zuora
        list<Zuora__CustomerAccount__c> listUpdatedAccount = [SELECT Zuora__Zuora_Id__c, Zuora__Account__r.BillingCountry, Zuora__Account__r.BillingCountryCode, Zuora__Account__r.BillingCity,
                                                              Zuora__Account__r.BillingPostalCode, Zuora__Account__r.FirstName, Zuora__Account__r.BillingState,
                                                              Zuora__Account__r.LastName, Zuora__Account__c, (SELECT id, Zuora__SubscriptionNumber__c, ExpectedRenewalDate__c, SUB_T_Produit_De_Base__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c FROM Zuora__Subscriptions__r WHERE NOT (Name LIKE 'T-S%'))
                                                              FROM zuora__CustomerAccount__c
                                                              WHERE Zuora__Account__c =:listUpdatedAccountId ];
        //get acount and relted contacts to create a suivi
        list<Account> listAccountContacts = [SELECT FirstName, LastName, ACC_Entreprise__c, RecordType.DeveloperName, BillingStreet, ACC_AccountNumber__c, ACC_BuildingID__c, ACC_NumeroPTO_cc__c, ACC_NumeroDEtage__c, ACC_Escalier__c, ACC_Porte__c,
                                             ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName, BillingCity,
                                             ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c,
                                             ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c,
                                             (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c FROM Contacts WHERE AccountId = :listUpdatedAccountId)
                                             FROM Account
                                             WHERE id = :listUpdatedAccountId];

        if(listAccountContacts.size() > 0 && listAccountContacts != null) {
            for(account acc : listAccountContacts) {
                if(listUpdatedAccount.size() > 0 && listUpdatedAccount != null) {
                    // get customer account of SF account
                    for(Zuora__CustomerAccount__c customerAccount : listUpdatedAccount) {
                        for(zuora__Subscription__c sub : customerAccount.Zuora__Subscriptions__r) {

                            if(acc.id == customerAccount.Zuora__Account__c) {
                                // Suspend sub and generate a credit memo
                                ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillChangeAddressSuspendedSubscription(sub);
                                HttpResponse suspendResponse = ZuoraManager.doCallout(zuoraObjects.ordersAPIUrl + '?returnIds=true', zuoraObjects.post, json.serialize(zSub, true));
                                ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(suspendResponse.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), acc.id, sub.Id, sub.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, suspendResponse.getBody(),
                                                                                    orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, true));
                                system.debug(orderResponse.success);
                                if(orderResponse.success) {
                                    //add custom fields to the generated memo
                                    if(orderResponse.creditMemoIds != null && orderResponse.creditMemoIds.size() > 0) {
                                        ZuoraObjects.ZuoraCreditMemo zCM = zuoraMapper.fillCMCustomFields();
                                        HttpResponse cmResponse = ZuoraManager.doCallout(ZuoraObjects.creditMemoAPIURL + orderResponse.creditMemoIds[0], ZuoraObjects.put, JSON.serialize(zCM, true));
                                        ZuoraResponseObjects.ZuoraBill updateCMFields = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(cmResponse.getBody(), ZuoraResponseObjects.ZuoraBill.class);

                                        listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zCM, true), acc.id, sub.Id, sub.Zuora__SubscriptionNumber__c, ZuoraObjects.creditMemoAPIURL + orderResponse.creditMemoIds[0],
                                                                                            cmResponse.getBody(), updateCMFields.success, updateCMFields.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.put, true));

                                    }


                                }

                            }
                        }
                    }
                }
            }
            if(listSub.size() > 0 && listSub != null) {
                update listSub;
            }
            if(listLog != null && listLog.size() > 0)
                insert listLog;
        }
    }
    
    
        /**
     * methode pour mettre a jour l'addresse du compte dans zuora
     * <p>
     * @param listUpdatedAccountId liste Id des comptes a mettre à jour
     * */
    @future(callout = true)
    public static void updateAccountAndSubscription(list<Id> listUpdatedAccountId){
        list<Log__c> listLog = new list<Log__c>();
        list<Suivi_de_Souscription__c> listSuiviToUpdate = new list<Suivi_de_Souscription__c>();
        list<zuora__Subscription__c> listSub = new list<zuora__Subscription__c>();
        //get address of requested accounts: needed to update account address in zuora
        list<Zuora__CustomerAccount__c> listUpdatedAccount = [SELECT Zuora__Zuora_Id__c, Zuora__Account__r.BillingCountry, Zuora__Account__r.BillingCountryCode, Zuora__Account__r.BillingCity,
                                                              Zuora__Account__r.BillingPostalCode, Zuora__Account__r.FirstName, Zuora__Account__r.BillingState,
                                                              Zuora__Account__r.LastName, Zuora__Account__c, (SELECT id, Zuora__SubscriptionNumber__c, ExpectedRenewalDate__c, SUB_T_Produit_De_Base__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c FROM Zuora__Subscriptions__r WHERE NOT (Name LIKE 'T-S%'))
                                                              FROM zuora__CustomerAccount__c
                                                              WHERE Zuora__Account__c IN :listUpdatedAccountId ];
        //get acount and relted contacts to create a suivi
        list<Account> listAccountContacts = [SELECT FirstName, LastName, ACC_Entreprise__c, RecordType.DeveloperName, BillingStreet, ACC_AccountNumber__c, ACC_BuildingID__c, ACC_NumeroPTO_cc__c, ACC_NumeroDEtage__c, ACC_Escalier__c, ACC_Porte__c,
                                             ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName, BillingCity,
                                             ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c,
                                             ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c,
                                             (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c FROM Contacts WHERE AccountId = :listUpdatedAccountId)
                                             FROM Account
                                             WHERE id = :listUpdatedAccountId];

        if(listAccountContacts.size() > 0 && listAccountContacts != null) {
            for(account acc : listAccountContacts) {
                if(listUpdatedAccount.size() > 0 && listUpdatedAccount != null) {
                    // get customer account of SF account
                    for(Zuora__CustomerAccount__c customerAccount : listUpdatedAccount) {
                        for(zuora__Subscription__c sub : customerAccount.Zuora__Subscriptions__r) {

                            if(acc.id == customerAccount.Zuora__Account__c) {


                                    //update customer account address
                                    ZuoraObjects.ZuoraAccount zAcc = ZuoraMapper.fillUpdateAccountAddress(customerAccount);
                                    HttpResponse response = ZuoraManager.createOrUpdateAccount(zAcc);
                                    ZuoraResponseObjects.ZuoraUpdateAccountResponse updateAccount =
                                    (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                    listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAcc, true), acc.id, sub.Id, sub.Zuora__SubscriptionNumber__c, ZuoraObjects.accountAPIUrl, response.getBody(),
                                                                                        updateAccount.success, updateAccount.reasons == null?null : updateAccount.reasons[0].message, ZuoraObjects.post, true));

                                    zuora__Subscription__c updatedSub = new zuora__Subscription__c();
                                    updatedSub.id = sub.Id;
                                    listSub.add(updatedSub);

                                

                            }
                        }
                    }
                }
            }
            if(listSub.size() > 0 && listSub != null) {
                update listSub;
            }
            if(listLog != null && listLog.size() > 0)
                insert listLog;
        }
    }

    /**
     * Methode utilisée pour créér des enregistrement dans l'objet suivi de souscription
     * <p>
     * @param boxNumber numero bu box reservée,
     * @param codeAction code de l'action faite sur l'abonnement,
     * @param dateAction date ou l'enregistrement est créé,
     * @param destination
     * @param subscriptionId Id de la souscription
     * @param Pays pays du compte,
     * @param PTO
     * @param statut status de l'enregistrement,
     * @param valeurAvant,
     * @param valeurApres,
     * @param oldOffer Nom de l'ancienne offre
     * @param newOffer Nom du nouvelle offre
     * @param details detail sur l'abonnement
     **/

    public static Suivi_de_Souscription__c createSuivi(string boxNumber, string codeAction, Datetime dateAction,
                                                       string destination, Id subscriptionId, string Pays, string PTO,
                                                       string statut, string valeurAvant, string valeurApres, integer warranty,
                                                       string oldOffer, string newOffer, string details, string paymentMode){
        Suivi_de_Souscription__c newSuivi = new Suivi_de_Souscription__c();
        newSuivi.SV_Box_Number__c = boxNumber;
        newSuivi.SV_Code_Action__c = codeAction;
        newSuivi.SV_Date_Action__c = dateAction;
        newSuivi.SV_Destination__c = destination;
        newSuivi.SV_Id_Souscription__c = subscriptionId;
        newSuivi.SV_Pays__c = Pays;
        newSuivi.SV_PTO__c = PTO;
        newSuivi.SV_Statut__c = statut;
        newSuivi.SV_Valeur_Apres__c = valeurApres;
        newSuivi.SV_Valeur_Avant__c = valeurAvant;
        newSuivi.SV_Garantie__c = warranty;
        newSuivi.SV_Ancienne_offre__c = oldOffer;
        newSuivi.SV_Nouvelle_offre__c = newOffer;
        newSuivi.SV_Details__c = details;
        newSuivi.SV_Mode_de_paiement__c = paymentMode;

        return newSuivi;
    }

    /**
     * Methode pour créé un suivi de souscription pour l'action 'achat de materiel'
     * <p>
     * @param listNewSub list des nouvelles souscriptions
     * */

    public static void newProductSuivi(list<Zuora__Subscription__c> listNewSub){
        // get new sub Id and quoteId
        map<Id, Id> newSubIdQuoteId = new map<Id, Id>();
        set<id> originalSubId = new set<Id>();
        for(Zuora__Subscription__c sub : listNewSub) {
            newSubIdQuoteId.put(sub.Id, sub.Quote__c);
            originalSubId.add(sub.Quote__r.QUO_T_SubscriptionId__c);
        }

        //get quote line item of each quote
        if(newSubIdQuoteId.size() > 0 && newSubIdQuoteId != null) {
            if(listNewSub.size() > 0 && listNewSub != null) {
                list<QuoteLineItem> QLI = [SELECT quoteId, Product_Rate_Plan__r.type__c
                                           FROM QuoteLineItem
                                           WHERE quoteId IN :newSubIdQuoteId.values()];
                //get quote Id of original sub
                set<id> setOriginalQuoteId = new set<id>();
                for(QuoteLineItem item : QLI) {
                    if(item.Product_Rate_Plan__r.type__c == 'Base') {
                        setOriginalQuoteId.add(item.quoteId);
                    }
                }
                //get technical sub
                List<Zuora__Subscription__c> listTechSub = [ SELECT Id, Quote__c, Zuora__Account__c, Quote__r.QUO_PTO__c,
                                                             Zuora__Account__r.BillingCountryCode, Quote__r.QUO_T_SubscriptionId__c
                                                             FROM Zuora__Subscription__c
                                                             WHERE id IN : newSubIdQuoteId.keyset() AND Quote__c NOT IN:setOriginalQuoteId];

                // create suivi of type 'Achat de materiel'
                /*   list<Suivi_de_Souscription__c> listSuivi = new list<Suivi_de_Souscription__c>();
                   if(listTechSub.size() > 0 && listTechSub != null) {
                       for(Zuora__Subscription__c sub : listTechSub) {
                           Suivi_de_Souscription__c newSuivi = new Suivi_de_Souscription__c();
                           newSuivi.SV_Code_Action__c = 'ACT005';
                           newSuivi.SV_Date_Action__c = Datetime.now();
                           newSuivi.SV_Destination__c = 'DST001';
                           newSuivi.SV_Pays__c = sub.Zuora__Account__r.BillingCountryCode;
                           newSuivi.SV_PTO__c = sub.Quote__r.QUO_PTO__c;
                           newSuivi.SV_Statut__c = 'STA001';
                           newSuivi.SV_Id_Souscription__c = sub.Id;

                           listSuivi.add(newSuivi);
                       }
                       insert listSuivi;
                   }*/
            }
        }
    }

    /**
     * Methode pour obtenir le catalogue de prix du pays de l'utilisateur
     * <p>
     * @param userID ID de l'utilisateur
     * @return Id du Pricebook
     * */
    public static Id getUserPricebookID(Id userID){
        List<User> currentUser = [SELECT ID, CountryCode FROM User WHERE ID = :userID];

        if(currentUser != null && currentUser.size() > 0) {
            if(!String.isBlank(currentUser[0].CountryCode)) {
                string countryCode = currentUser[0].CountryCode;
                List<Pricebook2> pbs = [SELECT ID, Name FROM Pricebook2 WHERE IsStandard = false AND IsActive = true AND Pays__c = :countryCode LIMIT 1];
                if(!pbs.isEmpty()) {
                    return pbs[0].id;
                } else {
                    throw new CustomException(Label.PB_NO_PRICEBOOK_FOUND);
                }
            } else {
                throw new CustomException(Label.USER_COUNTRY_EMPTY);
            }
        } else {
            throw new CustomException(Label.USER_NOT_FOUND);
        }
    }

    /**
     * Methode pour envoyer le rapport du caisse par email
     * <p>
     * @return Message de succés ou d'échoue
     * */
    @AuraEnabled
    public static string sendFundReport(){
        list<Log__c> listLog = new list<Log__c>();
        user currentUser  = [SELECT USR_DistributeurID__c, Email, countryCode FROM user WHERE Id = :UserInfo.getUserId()];

        if(currentUser != null && currentUser.USR_DistributeurID__c != null) {

            try {
                //Prepare Report Request
                ZuoraObjects.ZuoraWorkflow fundReport = new ZuoraObjects.ZuoraWorkflow();
                //to verify distributor ids
                fundReport.Distributor = currentUser.USR_DistributeurID__c;
                fundReport.ReceipientEmail = currentUser.email;
                if(currentUser.CountryCode == 'CD') {
                    fundReport.ManageHomeCurrency = true;
                } else {
                    fundReport.ManageHomeCurrency = false;
                }
                HttpResponse response = ZuoraManager.getWorkflowInfo(System.label.rapport_De_Caisse_Id, fundReport);
                ZuoraResponseObjects.ZuoraWorkflowResponse reportResponse = (ZuoraResponseObjects.ZuoraWorkflowResponse) JSON.deserialize(
                    response.getBody(), ZuoraResponseObjects.ZuoraWorkflowResponse.class);
                listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(fundReport, true), null, null, null,  ZuoraObjects.workflowAPIUrl + System.label.rapport_De_Caisse_Id + '/run', response.getBody(),
                                                                    reportResponse.message == null?true : false, reportResponse.message == null?null : reportResponse.message, null, false));

                insert listLog;
                // check response if succeeded or not
                if(response.getStatusCode() != 200) {
                    return reportResponse.message;//errors[0].title;
                } else {
                    return System.label.Rapport_De_Caisse_Success_Message;
                }

            } catch(Exception e) {

                System.debug('Erreur introduite sur le rapport du caisse: ' + e.getLineNumber() + ' ' + e.getMessage());
                throw new CustomException(e.getMessage());
            }

        } else {
            return System.label.Distributor_Not_Found;
        }

    }
    /**
     * Method used to define string fomat
     * @param inNumber integer value
     * @return string the formatted value
     */
    public static string stringFormatting(integer inNumber){
        string formattedString;
        if(inNumber < 10) {
            formattedString = '00' + string.valueOf(inNumber);
        } else if(inNumber >= 10 && inNumber <= 99) {
            formattedString = '0' + string.valueOf(inNumber);
        } else {
            formattedString = string.valueOf(inNumber);
        }

        return formattedString;
    }

    /**
     * Méthode pour verifier si le pays de l'utilisateur est Republic democtratic of congo
     */
    @AuraEnabled
    public static boolean checkRDCUser(){
        try {
            user currentUser = [SELECT CountryCode, Profile.Name
                                FROM User
                                WHERE id =:UserInfo.getUserId()];
            System.debug(currentUser.Profile.Name);
            // should be RDC users only
            if(currentUser.CountryCode == 'CD') {
                return true;
            } else {
                return false;
            }
        } catch(Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    /**
     * Méthode indiquant le pays de l'utilisateur
     */
    @AuraEnabled
    public static String userCountryCode(){
        try {
            user currentUser = [SELECT CountryCode, Profile.Name
                                FROM User
                                WHERE id =:UserInfo.getUserId()];

            return currentUser.CountryCode;
        } catch(Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    /**
     * Méthode pour récupérer les suivi traités de l'action échange de mteriel
     * @param mapOld
     * @param mapNew
     */
    public static void changeBoxNumber(map<id, Suivi_de_Souscription__c> mapOld, map<id, Suivi_de_Souscription__c> mapNew){

        set<Id> setSuiviId = new set<Id>();
        for(Suivi_de_Souscription__c suivi : mapNew.Values()) {
            // check if suivi is treated and related to change box action
            if(suivi.SV_Statut__c == 'STA002' && mapOld.get(suivi.Id).SV_Statut__c != suivi.SV_Statut__c &&
               !string.isBlank(suivi.SV_Reference_Externe__c) && suivi.SV_Code_Action__c == 'ACT006') {
                setSuiviId.add(suivi.Id);
            }
        }
        if(setSuiviId.size() > 0 && setSuiviId != null) {
            changeBoxNumberInZuora(setSuiviId);
        }
    }
    /**
     * Méthode pour changer le numéro de box sur l'abonnement aprés la confirmation du GVA
     * @param setSuiviId
     */
    @future(callout = true)
    public static void changeBoxNumberInZuora(set<Id> setSuiviId){
        list<Log__c> listLog = new list<Log__c>();
        list<Suivi_de_Souscription__c> listSuivi = [SELECT SV_Garantie__c, SV_Box_Number__c, SV_Id_Souscription__c,
                                                    SV_Id_Souscription__r.BoxNumber__c, SV_Id_Souscription__r.Quote__r.QUO_Reference_article__c
                                                    FROM Suivi_de_Souscription__c
                                                    WHERE id IN :setSuiviId];

        if(listSuivi.size() > 0 && listSuivi != null) {
            set<Id> setSubId = new set<Id>();
            for(Suivi_de_Souscription__c suivi : listSuivi) {
                setSubId.add(suivi.SV_Id_Souscription__c);
            }
            if(setSubId.size() > 0 && setSubId != null) {
                map<id, Zuora__Subscription__c> mapSub = new map<id, Zuora__Subscription__c>([SELECT ID, Zuora__SubscriptionNumber__c, Quote__r.QUO_Reference_article__c
                                                                                              FROM Zuora__Subscription__c
                                                                                              WHERE Id IN: setSubId]);

                for(Suivi_de_Souscription__c suivi : listSuivi) {

                    //update custom fields of an existing sub
                    ZuoraObjects.ZuoraOrderSubscription subCustomFields = ZuoraMapper.updateSubscriptionCustomFields(mapSub.get(suivi.SV_Id_Souscription__c), integer.valueOf(suivi.SV_Garantie__c), suivi.SV_Box_Number__c, null, null);
                    HttpResponse response = ZuoraManager.updateSubscriptionCustomFields(subCustomFields, mapSub.get(suivi.SV_Id_Souscription__c).Zuora__SubscriptionNumber__c);
                    ZuoraResponseObjects.ZuoraSubscriptions updateSubResponse = new ZuoraResponseObjects.ZuoraSubscriptions();
                    updateSubResponse = (ZuoraResponseObjects.ZuoraSubscriptions) JSON.deserialize(
                        response.getBody(), ZuoraResponseObjects.ZuoraSubscriptions.class);
                    listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(subCustomFields, true), null, suivi.SV_Id_Souscription__c, null,  ZuoraObjects.subscriptionAPIUrl +  mapSub.get(suivi.SV_Id_Souscription__c).Zuora__SubscriptionNumber__c + '/customFields', response.getBody(),
                                                                        updateSubResponse.success, updateSubResponse.reasons == null?null : updateSubResponse.reasons[0].message, ZuoraObjects.put, false));

                    /* if(updateSubResponse.success) {
                         string liberate = StockActions.liberateBox(null, suivi.SV_Id_Souscription__r.BoxNumber__c, suivi.SV_Id_Souscription__r.Quote__r.QUO_Reference_article__c);
                       }*/
                    if(listLog.size() > 0 && listLog != null)
                        insert listLog;

                }
            }

        }
    }
    /**
     * Méthode pour créer une suivi de souscription aprés la suspension d'un abo
     */
    public static void createSuspendedSuivi(map<id, Zuora__Subscription__c> newMap, map<id, Zuora__Subscription__c> oldMap ){
        map<Id, Id> mapSubscriptionIdAccountId = new map<Id, Id>();
        for(Zuora__Subscription__c sub : newMap.Values()) {
            if(sub.Zuora__Status__c != oldMap.get(sub.id).Zuora__Status__c && sub.Zuora__Status__c == 'Suspended') {
                mapSubscriptionIdAccountId.put(sub.Id, sub.Zuora__Account__c);
            }
        }
        if(mapSubscriptionIdAccountId != null && mapSubscriptionIdAccountId.size() > 0) {
            List<Suivi_de_Souscription__c> listSuivi = new list<Suivi_de_Souscription__c>();

            map<id, Zuora__Subscription__c> mapSuspendedSub = new map<id, Zuora__Subscription__c>([SELECT Zuora__SubscriptionNumber__c, Zuora__Account__r.BillingStreet, SuspensionReason__c, SUB_T_Produit_De_Base__c,
                                                                                                   Quote__r.QUO_PTO__c, Quote__c, BoxNumber__c, Zuora__Account__r.BillingCountryCode
                                                                                                   FROM Zuora__Subscription__c
                                                                                                   WHERE id = : mapSubscriptionIdAccountId.keySet()]);

            //get info from account and it's related contact to create a suivi
            map<id, Account> mapAccountContacts = new map<id, Account>([SELECT FirstName, LastName, Name, ACC_Entreprise__c, RecordType.DeveloperName, ACC_AccountNumber__c, ACC_Escalier__c, BillingCity,
                                                                        ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName, BillingCountryCode, BillingStreet, ACC_Porte__c, BillingPostalCode,
                                                                        ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c, ACC_NumeroPTO_cc__c,
                                                                        ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c, BillingCountry, ACC_BuildingID__c,
                                                                        (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c FROM Contacts WHERE AccountId = : mapSubscriptionIdAccountId.Values())
                                                                        FROM Account
                                                                        WHERE id = : mapSubscriptionIdAccountId.Values()]);
            list<Product_BandWidth__mdt> listProdBw = [SELECT BW_DL__c, BW_UL__c, DeveloperName, COuntry_Code__c
                                                       FROM Product_BandWidth__mdt];

            map<string, Product_BandWidth__mdt> mapBwName = new map<string, Product_BandWidth__mdt>();

            for(Product_BandWidth__mdt prodBw : listProdBw) {
                mapBwName.put(prodBw.DeveloperName, prodBw);
            }
            for(Zuora__Subscription__c sub : mapSuspendedSub.Values()) {
                Suivi_de_Souscription__c suivi = ZuoraSubscriptionActions.createSuivi(
                    sub.BoxNumber__c, 'ACT002', Datetime.now(), 'DST001',
                    sub.Id, sub.Zuora__Account__r.BillingCountryCode,
                    sub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, SuiviMapper.fillSuiviSuspendue(mapAccountContacts.get(mapSubscriptionIdAccountId.get(sub.Id)), mapAccountContacts.get(mapSubscriptionIdAccountId.get(sub.Id)).contacts, null), null);
                listSuivi.add(suivi);
                if(sub.SuspensionReason__c == 'Move-Requested') {
                    //create suivi of type demenagement
                    listSuivi.add(ZuoraSubscriptionActions.createSuivi(
                                      null, 'ACT007', Datetime.now(),
                                      'DST001', sub.Id, sub.Zuora__Account__r.BillingCountryCode,
                                      null, 'STA001', null, null, null, null, null, SuiviMapper.fillSuiviDemenagement(mapAccountContacts.get(mapSubscriptionIdAccountId.get(sub.Id)), mapAccountContacts.get(mapSubscriptionIdAccountId.get(sub.Id)).contacts, sub, mapBwName.get(sub.SUB_T_Produit_De_Base__c + '_' + sub.Zuora__Account__r.BillingCountryCode)?.BW_UL__c, mapBwName.get(sub.SUB_T_Produit_De_Base__c + '_' + sub.Zuora__Account__r.BillingCountryCode)?.BW_DL__c), null));

                }
            }

            if(listSuivi != null && listSuivi.size() > 0) {
                insert listSuivi;
            }

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

    public static Log__c createZuoraLog(string boby, id IDCompte, id IDAbonnement, string subNumber, string URL,
                                        string reponse, boolean success, string reason, string type, boolean toRetry){

        Log__c newLog = new Log__c();
        newLog.LG_Body__c = boby;
        newLog.LG_Account__c = IDCompte;
        newLog.LG_Subscription__c = IDAbonnement;
        newLog.LG_Method_URL__c = URL;
        newLog.LG_Subscription_Number__c = subNumber;
        newLog.LG_Response__c = reponse;
        newLog.LG_Interface__c = 'Zuora';
        newLog.LG_Success__c = success;
        newLog.LG_Error_Message__c = reason;
        newLog.LG_Method_Type__c = type;
        newLog.LG_Retry__c = toRetry;

        return newLog;
    }

    @AuraEnabled
    public static void insertLogs(string logs){

        list<Log__c> listLog = new list<Log__c>();
        //remove '()' from logs string
        logs = logs.left(logs.length() - 1);
        logs = logs.right(logs.length() - 1);

        List<Object> listZLog = (List<Object>) JSON.deserializeUntyped(logs);

        for(Object zLog : listZLog) {
            map<String, Object> data = (map<String, Object>) zLog;

            Log__c newLog = new Log__c();
            newLog.LG_Body__c = (string)data.get('LG_Body__c');
            newLog.LG_Account__c = (string)data.get('LG_Account__c');
            newLog.LG_Subscription__c = (string)data.get('LG_Subscription__c');
            newLog.LG_Method_URL__c = (string)data.get('LG_Method_URL__c');
            newLog.LG_Response__c = (string)data.get('LG_Response__c');
            newLog.LG_Subscription_Number__c = (string)data.get('LG_Subscription_Number__c');
            newLog.LG_Interface__c = (string)data.get('LG_Interface__c');
            newLog.LG_Success__c =  (boolean)data.get('LG_Success__c');
            newLog.LG_Error_Message__c = (string)data.get('LG_Error_Message__c');
            newLog.LG_Method_Type__c = (string)data.get('LG_Method_Type__c');

            listLog.add(newLog);
        }
        try {
            if(listLog != null && listLog.size() > 0)
                insert listLog;
        }catch(exception e) {
            system.debug(e.getMessage());
        }

    }
    /**
     * Méthode pour récupérer les abonnements collaborateur traités de l'action échange de mteriel
     * @param mapOld
     * @param mapNew
     */
    public static void checkCollaboratorSub(map<id, Zuora__Subscription__c> mapOld, map<id, Zuora__Subscription__c> mapNew){

        set<Id> setSubId = new set<Id>();
        for(Zuora__Subscription__c sub : mapNew.Values()) {
            // check if suivi is treated and related to change box action
            if(mapOld.get(sub.Id).isCollaborator__c != sub.isCollaborator__c) {
                setSubId.add(sub.Id);
            }
        }
        if(setSubId.size() > 0 && setSubId != null) {
            changeCollaboratorInZuora(setSubId);
        }
    }

    /**
     * Méthode pour changer le champ isCollaborator sur l'abonnement
     * @param setSuiviId
     */
    @future(callout = true)
    public static void changeCollaboratorInZuora(set<Id> setSubId){
        list<Log__c> listLog = new list<Log__c>();
        list<Zuora__Subscription__c> listSub = [SELECT isCollaborator__c, Zuora__SubscriptionNumber__c, id
                                                FROM Zuora__Subscription__c
                                                WHERE id IN :setSubId];

        if(listSub.size() > 0 && listSub != null) {
            for(Zuora__Subscription__c sub : listSub) {

                //update custom fields of an existing sub
                ZuoraObjects.ZuoraOrderSubscription subCustomFields = ZuoraMapper.updateCollaboratorSubscription(sub.isCollaborator__c);
                HttpResponse response = ZuoraManager.updateSubscriptionCustomFields(subCustomFields, sub.Zuora__SubscriptionNumber__c);
                ZuoraResponseObjects.ZuoraSubscriptions updateSubResponse = (ZuoraResponseObjects.ZuoraSubscriptions) JSON.deserialize( response.getBody(), ZuoraResponseObjects.ZuoraSubscriptions.class);
                
                listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(subCustomFields, true), null, sub.Id, null,  ZuoraObjects.subscriptionAPIUrl +  sub.Zuora__SubscriptionNumber__c + '/customFields', response.getBody(),
                                                                    updateSubResponse.success, updateSubResponse.reasons == null?null : updateSubResponse.reasons[0].message, ZuoraObjects.put, true));
            }
            if(listLog.size() > 0 && listLog != null)
                insert listLog;

        }
    }
    /**
     * Method pour récuperer les charges des rate plan ayant la catégorie 'Collaborator'
     */
    public static string getCollaboratorCharge(string productId ){
        string collaboratorPRP = null;
        if(productId != null) {
            // call get Product rate plan Api to get rate plans of specific product
            string url = ZuoraObjects.ratePlanAPIUrl + productId + ZuoraObjects.prpAPIUrl;
            HttpResponse response = ZuoraManager.doCallout(url, ZuoraObjects.get, '');
            ZuoraResponseObjects.ZuoraPRPResponse getPRPInfoResponse = new ZuoraResponseObjects.ZuoraPRPResponse();
            getPRPInfoResponse = (ZuoraResponseObjects.ZuoraPRPResponse) JSON.deserialize(response.getBody().replaceAll('__c', '_Reserved'), ZuoraResponseObjects.ZuoraPRPResponse.class);
            // search of collaborator PRP and it's charge
            if(getPRPInfoResponse.success) {
                for(ZuoraResponseObjects.ZuoraProductRatePlan currentPrp : getPRPInfoResponse.productRatePlans) {
                    if(currentPrp.Category_Reserved == 'Collaborator' && currentPrp.effectiveEndDate > date.today()) {
                        for(ZuoraResponseObjects.ZuoraproductRatePlanCharge charge : currentPrp.productRatePlanCharges) {
                            collaboratorPRP = currentPrp.id;
                        }
                        break;
                    }
                }
            }

        }

        return collaboratorPRP;
    }

    public class CustomException extends Exception {}
}