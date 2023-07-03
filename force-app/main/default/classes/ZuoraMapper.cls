/*
 * Classe Mapper pour Zuora et Salesforce
 */
public with sharing class ZuoraMapper {

    /**
     * Méthode pour remplir la demande de commande de création d'un compte
     * @param currentAccount le compte,
     * @param contact le contact,
     * @param mainDistId id du distributeur parent
     * @return ZuoraObjects.ZuoraAccount
     * */
    public static ZuoraObjects.ZuoraAccount fillCreateB2BAccount(Account currentAccount, Contact contact, string mainDistId, boolean isDistributor, Quote currentQuote) {

        boolean isSME = false;
        string countryCode = contact.MailingCountryCode;
        ZuoraObjects.ZuoraAccountCustomFields accountCustomFields = new ZuoraObjects.ZuoraAccountCustomFields();

        ZuoraObjects.ZuoraAccount createdAccount = new ZuoraObjects.ZuoraAccount();
        createdAccount.autoPay = false;
        createdAccount.billCycleDay = 0;
        if(currentAccount != null) {

            createdAccount.currency_toReplace = currentAccount.CurrencyIsoCode;
            createdAccount.name = currentAccount.Name;
            createdAccount.crmId = string.valueOf(currentAccount.Id);
            accountCustomFields.Company_Reserved = currentAccount.ACC_Entreprise__c;
            createdAccount.DataAccess_h = (currentAccount.ACC_Entreprise__c.contains('\'')?currentAccount.ACC_Entreprise__c.replaceAll('\'', '') : currentAccount.ACC_Entreprise__c) + ' - ' + (currentAccount.BillingCity == null?contact.MailingCity.toUpperCase() : currentAccount.BillingCity.toUpperCase());
            if(currentAccount.RecordType.DeveloperName.contains('SME')) {
                isSME = true;
                accountCustomFields.Segment_Reserved = 'SME';
            }
        } else {

            createdAccount.currency_toReplace = currentQuote.Account.CurrencyIsoCode;
            createdAccount.name = currentQuote.Account.Name;
            createdAccount.crmId = string.valueOf(currentQuote.AccountId);
            accountCustomFields.Company_Reserved = currentQuote.Account.ACC_Entreprise__c;
            createdAccount.DataAccess_h = (currentQuote.Account.ACC_Entreprise__c.contains('\'')?currentQuote.Account.ACC_Entreprise__c.replaceAll('\'', '') : currentQuote.Account.ACC_Entreprise__c) + ' - ' + (currentQuote.Account.BillingCity == null?contact.MailingCity.toUpperCase() : currentQuote.Account.BillingCity.toUpperCase());
            if(currentQuote.Account.RecordType.DeveloperName.contains('SME')) {

                accountCustomFields.Segment_Reserved = 'SME';
                accountCustomFields.Type_Reserved = 'Prepaid';
            }
        }

        if(isDistributor) {

            accountCustomFields.Type_Reserved = 'Distributor';
            accountCustomFields.Segment_Reserved = 'DIST';
            accountCustomFields.DistributorNumber_Reserved = currentAccount.ACC_Distributor_Number__c;
            createdAccount.parentId = mainDistId == null?null : mainDistId;
            createdAccount.batch = 'Batch50';
        }
        createdAccount.customFields = accountCustomFields;

        if(String.isNotBlank(countryCode) ) {
            // Try to find if a metadata configuration exists for the Country
            //
            List<Template_Setting__mdt> templateSettings = [SELECT Communication_Profile_Id__c, Sequence_Set_Id__c,
                                                            Invoice_Template_Id__c, Pays__c,
                                                            DM_Template_Id__c, CM_Template_Id__c
                                                            FROM Template_Setting__mdt
                                                            WHERE Pays__c = :countryCode ];
            if(templateSettings.size() > 0) {
                createdAccount.communicationProfileId = templateSettings[0].Communication_Profile_Id__c;
                createdAccount.sequenceSetId = templateSettings[0].Sequence_Set_Id__c;
                createdAccount.invoiceTemplateId = templateSettings[0].Invoice_Template_Id__c;
                createdAccount.debitMemoTemplateId = templateSettings[0].DM_Template_Id__c;
                createdAccount.creditMemoTemplateId = templateSettings[0].CM_Template_Id__c;
            }
        }

        // for B2B account bill to and sold to represents the contact
        ZuoraObjects.ZuoraContact billToContactInfo = new ZuoraObjects.ZuoraContact();
        billToContactInfo.firstName = contact.FirstName;
        billToContactInfo.lastName = contact.LastName;
        billToContactInfo.country = contact.MailingCountry;
        billToContactInfo.city = contact.MailingCity;
        billToContactInfo.postalCode = contact.MailingPostalCode;
        billToContactInfo.state = contact.MailingState;
        billToContactInfo.workEmail = contact.Email;

        CreatedAccount.billToContact = billToContactInfo;
        CreatedAccount.soldToContact = billToContactInfo;

        return createdAccount;
    }
    /**
     * Méthode pour remplir la demande de commande de création d'un compte
     * @param currentQuote le devis
     * @return ZuoraObjects.ZuoraAccount
     * */
    public static ZuoraObjects.ZuoraAccount fillCreatePersonAccount(Quote currentQuote) {
        ZuoraObjects.ZuoraTaxInfo tax = new ZuoraObjects.ZuoraTaxInfo();

        ZuoraObjects.ZuoraAccountCustomFields accountCustomFields = new ZuoraObjects.ZuoraAccountCustomFields();
        accountCustomFields.Segment_Reserved = 'B2C';
        accountCustomFields.Type_Reserved = 'Prepaid';
        accountCustomFields.Company_Reserved = currentQuote.Account.ACC_Entreprise__c;

        ZuoraObjects.ZuoraAccount createdAccount = new ZuoraObjects.ZuoraAccount();
        createdAccount.DataAccess_h = (currentQuote.Account.ACC_Entreprise__c.contains('\'')?currentQuote.Account.ACC_Entreprise__c.replaceAll('\'', '') : currentQuote.Account.ACC_Entreprise__c) + ' - ' + currentQuote.Account.BillingCity.toUpperCase();
        createdAccount.autoPay = false;
        createdAccount.currency_toReplace = currentQuote.Account.CurrencyIsoCode;
        createdAccount.billCycleDay = 0;
        createdAccount.name = currentQuote.Account.Name;
        createdAccount.taxInfo = tax;
        createdAccount.crmId = string.valueOf(currentQuote.AccountId);
        createdAccount.customFields = accountCustomFields;
        if(String.isNotBlank(currentQuote.Account.BillingCountryCode)) {
            // Try to find if a metadata configuration exists for the Country
            //
            List<Template_Setting__mdt> templateSettings = [SELECT Communication_Profile_Id__c, Sequence_Set_Id__c,
                                                            Invoice_Template_Id__c, Pays__c,
                                                            DM_Template_Id__c, CM_Template_Id__c
                                                            FROM Template_Setting__mdt
                                                            WHERE Pays__c = :currentQuote.Account.billingCountryCode];
            if(templateSettings.size() > 0) {
                createdAccount.communicationProfileId = templateSettings[0].Communication_Profile_Id__c;
                createdAccount.sequenceSetId = templateSettings[0].Sequence_Set_Id__c;
                createdAccount.invoiceTemplateId = templateSettings[0].Invoice_Template_Id__c;
                createdAccount.debitMemoTemplateId = templateSettings[0].DM_Template_Id__c;
                createdAccount.creditMemoTemplateId = templateSettings[0].CM_Template_Id__c;
            }
        }

        // for personal account bill to = sold to
        ZuoraObjects.ZuoraContact billToContactInfo = new ZuoraObjects.ZuoraContact();
        billToContactInfo.firstName = currentQuote.Account.FirstName;
        billToContactInfo.lastName = currentQuote.Account.LastName;
        billToContactInfo.country = currentQuote.Account.BillingCountryCode;
        billToContactInfo.city = currentQuote.Account.BillingCity;
        billToContactInfo.postalCode = currentQuote.Account.BillingPostalCode;
        billToContactInfo.state = currentQuote.Account.BillingState;
        billToContactInfo.personalEmail = currentQuote.Account.PersonEmail;
        billToContactInfo.workEmail = currentQuote.Account.PersonEmail;
        billToContactInfo.mobilePhone = currentQuote.Account.PersonMobilePhone;

        CreatedAccount.billToContact = billToContactInfo;
        CreatedAccount.soldToContact = billToContactInfo;

        return createdAccount;
    }
    /**
     * Méthode pour remplir la demande de commande de création d'abonnement
     * @param currentQuote le devis,
     * @param listQuoteLineItem list de l'objet QuoteLineItem
     * @param timbreFiscal
     * @param totalAmount montant total sur lequel les fiscaux sont appliqués
     * @param B2BRepresentative le contact d'un compte B2B
     * @param collaboratorId id du produit collaborateur
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillCreateOrder(
        Quote currentQuote, Account currentAccount, list<String> listProducts, string warranty, zqu__productrateplancharge__c timbreFiscal, double totalAmount,
        Contact B2BRepresentative, string collaboratorId, string parentAccountId) {
        //get logged user
        User currentUser = [SELECT Id, Name, USR_DistributeurID__c
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1];

        ZuoraObjects.ZuoraInitialTerm initialTerms = new ZuoraObjects.ZuoraInitialTerm();
        initialTerms.termType = System.label.B2C_Subscription_Term_Type;

        ZuoraObjects.ZuoraTerms term = new ZuoraObjects.ZuoraTerms();
        term.initialTerm = initialTerms;

        ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
        list<ZuoraObjects.ZuorasubscribeToRatePlans> listSubscribeToRatePlans = new List<ZuoraObjects.ZuorasubscribeToRatePlans>();

        for(string prod : listProducts) {
            subscribeToRatePlan.productRatePlanId = prod;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
            subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
        }
        if(collaboratorId != null) {
            ZuoraObjects.ZuorasubscribeToRatePlans subscribeTocollabProd = new ZuoraObjects.ZuorasubscribeToRatePlans();
            subscribeTocollabProd.productRatePlanId = collaboratorId;
            listSubscribeToRatePlans.add(subscribeTocollabProd);
        }
        if(timbreFiscal != null && totalAmount != null) {
            subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
            subscribeToRatePlan.productRatePlanId = timbreFiscal.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

            ZuoraObjects.ZuoraOneTimeTiered oneTimeTiered = new ZuoraObjects.ZuoraOneTimeTiered();
            oneTimeTiered.quantity = totalAmount;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.oneTimeTiered = oneTimeTiered;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = timbreFiscal.zqu__ZuoraId__c;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            subscribeToRatePlan.chargeOverrides = listChargeOverride;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
        }

        ZuoraObjects.ZuoraCreateSubscription subscription = new ZuoraObjects.ZuoraCreateSubscription();
        //add term to subscription
        subscription.terms = term;
        subscription.subscribeToRatePlans = listSubscribeToRatePlans;

        //add subscription to order action
        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrder.createSubscription = subscription;
        zuoraOrder.type = System.label.Create_Subscription_Order_Type;
        ZuoraObjects.ZuoraAccount zAcc = new ZuoraObjects.ZuoraAccount();

        if(B2BRepresentative == null) {
            zAcc = fillCreatePersonAccount(currentQuote);
        } else {
            if(currentQuote == null && currentAccount != null) {
                //activate the sub
                ZuoraObjects.ZuoraTriggerDate trigger0 = new ZuoraObjects.ZuoraTriggerDate();
                trigger0.name = System.label.Service_Activation_Trigger_Name;
                trigger0.triggerDate = string.valueOf(date.today());
                list<ZuoraObjects.ZuoraTriggerDate> listTriggerDate = new List<ZuoraObjects.ZuoraTriggerDate>();
                listTriggerDate.add(trigger0);
                zuoraOrder.triggerDates = listTriggerDate;

                zAcc = fillCreateB2BAccount(currentAccount, B2BRepresentative, parentAccountId, true, null);
            } else {
                zAcc = fillCreateB2BAccount(null, B2BRepresentative, null, false, currentQuote);
            }

        }
        list<ZuoraObjects.ZuoraOrderAction> listOrderActions = new List<ZuoraObjects.ZuoraOrderAction>();
        listOrderActions.add(zuoraOrder);
        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomFields = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomFields.SF_QuoteID_Reserved = currentQuote == null?null : string.valueOf(currentQuote.Id);
        subCustomFields.Type_Reserved = 'Standard';
        subCustomFields.RenewalSequenceNumber_Reserved = '0';
        subCustomFields.BoxNumber_Reserved = currentQuote == null?null : currentQuote.QUO_T_Numero_du_Box__c;
        subCustomFields.WarrantyEndDate_Reserved = string.valueOf(date.today().addMonths(integer.valueOf(warranty)));
        subCustomFields.isCollaborator_Reserved = currentQuote == null?null : currentQUote.QUO_IsCollaborator__c;
        //subCustomFields.Version_Reserved = string.valueOf(currentQuote.QUO_Version__c);

        //create subscription
        ZuoraObjects.ZuoraOrderSubscription zuoraSubscription = new ZuoraObjects.ZuoraOrderSubscription();
        zuoraSubscription.customFields = subCustomFields;
        zuoraSubscription.orderActions = listOrderActions;

        list<ZuoraObjects.ZuoraOrderSubscription> listZuoraSubscription = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listZuoraSubscription.add(zuoraSubscription);

        ZuoraObjects.ZuoraOrderCustomFields orderCustomFields = new ZuoraObjects.ZuoraOrderCustomFields();
        orderCustomFields.OperatorAgent_Reserved = currentUser.Name;
        orderCustomFields.SourceOperator_Reserved = currentUser.USR_DistributeurID__c;
        orderCustomFields.Source_Reserved = 'Shop';

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.subscriptions = listZuoraSubscription;
        zSub.orderDate = string.valueOf(date.today());
        zSub.orderNumber = currentQuote == null?string.valueOf(B2BRepresentative.id) : string.valueOf(currentQuote.Name);
        zSub.customFields = orderCustomFields;
        zSub.newAccount = zAcc;

        return zSub;
    }
    /**
     * Méthode pour remplir la demande de creation d'un apercu de l'abo
     * @param prepaidPeriodle nombre de périodes prépayées,
     * @param billingCountry le pays du compte,
     * @param accountCurrency devise du compte
     * @param listProductId list Product rate plan zuora Id
     * @param fiscalId id du product rate plan 'timbre fiscal'
     * @param totalAmount le prix total des produits
     * @param chargeId id du charge timbre fiscal
     * @param collaboratrId id du prp collaborator
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillPreviewSubscription(integer prepaidPeriod, string billingCountry, string accountCurrency, list<String> listProductId,
                                                                  string fiscalId, double totalAmount, string chargeId, string collaboratrId){
        ZuoraObjects.ZuoraPreviewAccount accountInfo = new ZuoraObjects.ZuoraPreviewAccount();

        accountInfo.currency_toReplace = accountCurrency;
        accountInfo.billCycleDay = 0;
        ZuoraObjects.ZuoraContact soldToContactInfo = new ZuoraObjects.ZuoraContact();
        soldToContactInfo.country = billingCountry;
        accountInfo.soldToContact = soldToContactInfo;

        ZuoraObjects.ZuoraInitialTerm initialTerms = new ZuoraObjects.ZuoraInitialTerm();
        initialTerms.termType = System.label.B2C_Subscription_Term_Type;

        ZuoraObjects.ZuoraTerms term = new ZuoraObjects.ZuoraTerms();
        term.initialTerm = initialTerms;

        list<ZuoraObjects.ZuorasubscribeToRatePlans> listSubscribeToRatePlans = new List<ZuoraObjects.ZuorasubscribeToRatePlans>();
        if(collaboratrId != null) {
            ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
            subscribeToRatePlan.productRatePlanId = collaboratrId;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
        }
        if(fiscalId == null && chargeId == null) {
            /* for(string prodId : listProducts){
               ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
               subscribeToRatePlan.productRatePlanId = prodId;
               listSubscribeToRatePlans.add(subscribeToRatePlan);
               }*/

            for(String prodId : listProductId) {
                ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
                subscribeToRatePlan.productRatePlanId = prodId;
                listSubscribeToRatePlans.add(subscribeToRatePlan);
            }
        } else {
            ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
            subscribeToRatePlan.productRatePlanId = fiscalId;

            ZuoraObjects.ZuoraOneTimeTiered oneTimeTiered = new ZuoraObjects.ZuoraOneTimeTiered();
            oneTimeTiered.quantity = totalAmount;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.oneTimeTiered = oneTimeTiered;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = chargeId;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            subscribeToRatePlan.chargeOverrides = listChargeOverride;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
        }

        ZuoraObjects.ZuoraCreateSubscription subscription = new ZuoraObjects.ZuoraCreateSubscription();
        //add term to subscription
        subscription.terms = term;
        subscription.subscribeToRatePlans = listSubscribeToRatePlans;

        list<string> listPreviewType = new List<string>();
        listPreviewType.add('BillingDocs');

        ZuoraObjects.ZuoraPreviewOptions option = new ZuoraObjects.ZuoraPreviewOptions();
        option.previewTypes = listPreviewType;
        option.previewThruType = 'SpecificDate';
        option.specificPreviewThruDate = string.valueOf(date.today().addMonths(prepaidPeriod - 1)); //integer.valueOf(currentQuote.QUO_Duree_de_l_Abonnement__c - 1)));

        //add subscription to order action
        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrder.triggerDates = fillTriggerDates(string.valueOf(date.today()), false);
        zuoraOrder.createSubscription = subscription;
        zuoraOrder.type = System.label.Create_Subscription_Order_Type;

        list<ZuoraObjects.ZuoraOrderAction> listOrderActions = new List<ZuoraObjects.ZuoraOrderAction>();
        listOrderActions.add(zuoraOrder);

        //create subscription
        ZuoraObjects.ZuoraOrderSubscription zuoraSubscription = new ZuoraObjects.ZuoraOrderSubscription();
        zuoraSubscription.orderActions = listOrderActions;
        list<ZuoraObjects.ZuoraOrderSubscription> listZuoraSubscription = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listZuoraSubscription.add(zuoraSubscription);
        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.subscriptions = listZuoraSubscription;
        zSub.orderDate = string.valueOf(system.today());
        zSub.previewAccountInfo = accountInfo;
        zSub.previewOptions = option;
        zSub.orderNumber = string.valueOf(Datetime.now().format('ddMMyyyyhhmm'));

        return zSub;
    }
    /**
     * Méthode pour remplir la demande de création d'un apercu d'un réabo
     * @param nbPeriodes le nombre de périodes prépayées,
     * @param prodId id du produit,
     * @param accountNumber numero du compte,
     * @param date expectedRenewalDate de renouvellement
     * @param timbreFiscal produit timbre fiscal
     * @param totalAmount prix total sur lequel le tax est appliqué
     * @param PRPId id du produit Collaborateur
     * @param ratePlanId id du rate rate plan collaborateur
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillRenewPreviewSubscription(
        integer nbPeriodes, string prodId, string accountNumber, date expectedRenewalDate, zqu__productrateplancharge__c timbreFiscal,
        double totalAmount, string PRPId, zqu__ProductRatePlanCharge__c coupon, Double couponValue, list<string> listBundleId) {

        ZuoraObjects.ZuoraInitialTerm initialTerms = new ZuoraObjects.ZuoraInitialTerm();
        initialTerms.termType = System.label.B2C_Subscription_Term_Type;

        ZuoraObjects.ZuoraTerms term = new ZuoraObjects.ZuoraTerms();
        term.initialTerm = initialTerms;

        ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
        list<ZuoraObjects.ZuorasubscribeToRatePlans> listSubscribeToRatePlans = new List<ZuoraObjects.ZuorasubscribeToRatePlans>();

        if(timbreFiscal == null) {
            subscribeToRatePlan.productRatePlanId = prodId;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
        } else {
            subscribeToRatePlan.productRatePlanId = timbreFiscal.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

            ZuoraObjects.ZuoraOneTimeTiered oneTimeTiered = new ZuoraObjects.ZuoraOneTimeTiered();
            oneTimeTiered.quantity = totalAmount;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.oneTimeTiered = oneTimeTiered;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = timbreFiscal.zqu__ZuoraId__c;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            subscribeToRatePlan.chargeOverrides = listChargeOverride;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
        }
        if(PRPId != null) {
            subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
            subscribeToRatePlan.productRatePlanId = PRPId;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
        }
        if(listBundleId != null && listBundleId.size() > 0) {
            for(string bundleId : listBundleId) {
                subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
                subscribeToRatePlan.productRatePlanId = bundleId;
                listSubscribeToRatePlans.add(subscribeToRatePlan);
            }
        }

        if(coupon != null && (couponValue != null || !string.isBlank(string.valueOf(couponValue))) && couponValue > 0) {

            subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
            subscribeToRatePlan.productRatePlanId = coupon.zqu__ProductRatePlan__r.zqu__ZuoraId__c;
            ZuoraObjects.ZuoraRecurringFlatFee recurringFlatFree = new ZuoraObjects.ZuoraRecurringFlatFee();
            recurringFlatFree.listPrice = -couponValue;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.recurringFlatFee = recurringFlatFree;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = coupon.zqu__ZuoraId__c;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            subscribeToRatePlan.chargeOverrides = listChargeOverride;
            listSubscribeToRatePlans.add(subscribeToRatePlan);
        }
        ZuoraObjects.ZuoraCreateSubscription subscription = new ZuoraObjects.ZuoraCreateSubscription();
        //add term to subscription
        subscription.terms = term;
        subscription.subscribeToRatePlans = listSubscribeToRatePlans;
       
        list<string> listPreviewType = new List<string>();
        listPreviewType.add('BillingDocs');

        ZuoraObjects.ZuoraPreviewOptions option = new ZuoraObjects.ZuoraPreviewOptions();
        option.previewTypes = listPreviewType;
        option.previewThruType = 'SpecificDate';

        option.specificPreviewThruDate = string.valueOf(expectedRenewalDate.addMonths(nbPeriodes - 1)); //integer.valueOf(currentQuote.QUO_Duree_de_l_Abonnement__c - 1)));
        //add subscription to order action
        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrder.triggerDates = fillTriggerDates(string.valueOf(expectedRenewalDate), false);
        zuoraOrder.createSubscription = subscription;
        zuoraOrder.type = System.label.Create_Subscription_Order_Type;
        list<ZuoraObjects.ZuoraOrderAction> listOrderActions = new List<ZuoraObjects.ZuoraOrderAction>();
        listOrderActions.add(zuoraOrder);

        //create subscription
        ZuoraObjects.ZuoraOrderSubscription zuoraSubscription = new ZuoraObjects.ZuoraOrderSubscription();
        zuoraSubscription.orderActions = listOrderActions;

        list<ZuoraObjects.ZuoraOrderSubscription> listZuoraSubscription = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listZuoraSubscription.add(zuoraSubscription);
        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.subscriptions = listZuoraSubscription;
        zSub.orderDate = string.valueOf(system.today());
        zSub.previewOptions = option;
        zSub.existingAccountNumber = accountNumber;
        zSub.orderNumber = accountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     *  Méthode pour mapper le paiement lors de la création
     * @param subscriptionId l'Id de l'abonnement,
     * @param zuoraAccountId Id du compte dans zuora,
     * @param prepaidPeriod le nombre de périodes prépayées,
     * @param orderNumber le numéro de commande,
     * @param amount montant encaissé,
     * @param accountCurrency la devise du compte,
     * @param isTechnical boolean technical
     * @param CDFPayment paiement en CDF
     * @param dollarPayment paiement en dollar
     * @param conversionRate taux de change
     * @param transactionId
     * @return ZuoraObjects.ZuoraPayment
     * */
    public static ZuoraObjects.ZuoraPayment fillCreatePayment(
        id subscriptionId, string zuoraAccountId, integer prepaidPeriod, string orderNumber, double amount, string accountCurrency, string paymentMode,
        boolean isTechnical, string CDFPayment, string dollarPayment, string conversionRate, string transactionId, string operator, string aggregator,
        string operatorAgent, string distributorId){
        /*//get logged user
           User currentUser = [SELECT Id, Name, USR_DistributeurID__c
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1];*/

        list<mode_de_paiement__mdt> paymentMethod = [SELECT Methode_de_paiement_ID__c, DeveloperName
                                                     FROM mode_de_paiement__mdt
                                                     WHERE DeveloperName = :paymentMode];

        ZuoraObjects.ZuoraPayment paymentInfo = new ZuoraObjects.ZuoraPayment();

        if(zuoraAccountId == null && subscriptionId != null) {
            Zuora__Subscription__c originalSub = [SELECT Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                                  Zuora__CustomerAccount__r.Zuora__Zuora_Id__c
                                                  FROM Zuora__Subscription__c
                                                  WHERE id = :subscriptionId];

            paymentInfo.accountId = originalSub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
        } else {
            paymentInfo.accountId = zuoraAccountId;
        }

        //paymentInfo of the original subscription
        if(isTechnical) {
            paymentInfo.PrepaidPeriods_Reserved = string.valueOf(prepaidPeriod);
            paymentInfo.Processing_Reserved = 'N/A';
        } else {
            paymentInfo.PrepaidPeriods_Reserved = string.valueOf(prepaidPeriod);
            paymentInfo.Processing_Reserved = 'Batch';
        }

        //for RDC users
        if(CDFPayment != null && !string.isBlank(CDFPayment) && dollarPayment != null && !string.isBlank(dollarPayment)) {
            paymentInfo.HomeCurrency_Reserved = System.label.RDCurrency;
            paymentInfo.HomeCurrencyRate_Reserved = conversionRate.length() > 9?conversionRate.substring(0, 9) : conversionRate;
            paymentInfo.AccountCurrencyAmount_Reserved = dollarPayment;
            paymentInfo.HomeCurrencyAmount_Reserved = CDFPayment;
        }
        paymentInfo.currency_toReplace = accountCurrency;
        paymentInfo.amount = amount;
        paymentInfo.effectiveDate = string.valueOf(date.today());
        paymentInfo.type = System.label.External_Payment_Type;
        if(paymentMethod != null && paymentMethod.size() > 0) {
            paymentInfo.paymentMethodId = paymentMethod[0].Methode_de_paiement_ID__c;
        }
        paymentInfo.referenceId = transactionId;
        paymentInfo.OrderNumber_Reserved = orderNumber;
        paymentInfo.OperatorAgent_Reserved = operatorAgent;
        paymentInfo.SourceOperator_Reserved = distributorId;
        paymentInfo.Source_Reserved = 'Shop'; //or Distributor??
        paymentInfo.PaymentProcessor_Reserved = aggregator == null?operator : aggregator;

        return paymentInfo;
    }
    /**
     *  Méthode pour creer le payment d'un réabonnement
     * @param zuoraAccountId Id du compte dans zuora,
     * @param prepaidPeriod nombre de périodes prépayées,
     * @param currentAmount compte
     * @param orderNumber le numéro de commande,
     * @param invoiceId id de la facture,
     * @param accountCurrency devise du compte
     * @param CDFPayment
     * @param conversionRate
     * @param dollarRefund
     * @param CDFRefund
     * @param transactionNumber
     * @param operator operateur MM
     * @return ZuoraObjects.ZuoraPayment
     * */
    public static ZuoraObjects.ZuoraPayment fillCreateRenewPayment(
            string zuoraAccountId, integer prepaidPeriod, double currentAmount, string transactionNumber,
            string operator, string orderNumber, string invoiceId, string accountCurrency, string paymentMode,
            string CDFPayment, string dollarPayment, string conversionRate, string dollarRefund, string CDFRefund, boolean fromDistributor, id SFAccountId){
        User currentUser = new User();
        list<User> listUser = [SELECT Id, Name, USR_DistributeurID__c
                               FROM User
                               WHERE Id = :UserInfo.getUserId() AND USR_DistributeurID__c != null];//AccountId = : SFAccountId
        if(listUser.size() < 1) {
            currentUser = [ SELECT Id, Name, USR_DistributeurID__c, AccountId
                            FROM User
                            WHERE AccountId = : SFAccountId
                            LIMIT 1 ];
        }

        double totalAmount = currentAmount;
        double refundAmount = 0;
        if(CDFRefund != null && dollarRefund != null && conversionRate != null) {

            refundAmount =  integer.valueOf(dollarRefund) + integer.valueOf(CDFRefund) / double.valueOf(conversionRate);
            totalAmount = currentAmount + refundAmount;
        }

        list<mode_de_paiement__mdt> paymentMethod = [SELECT Methode_de_paiement_ID__c, DeveloperName
                                                     FROM mode_de_paiement__mdt
                                                     WHERE DeveloperName = :paymentMode];

        ZuoraObjects.ZuoraBilling invoiceInfo = new ZuoraObjects.ZuoraBilling();
        list<ZuoraObjects.ZuoraBilling> listInvoiceInfo = new List<ZuoraObjects.ZuoraBilling>();
        invoiceInfo.invoiceId = invoiceId;
        invoiceInfo.amount = currentAmount;
        listInvoiceInfo.add(invoiceInfo);

        ZuoraObjects.ZuoraPayment paymentInfo = new ZuoraObjects.ZuoraPayment();
        paymentInfo.accountId = zuoraAccountId;
        paymentInfo.PrepaidPeriods_Reserved = string.valueOf(prepaidPeriod);
        paymentInfo.Processing_Reserved = 'N/A';
        paymentInfo.currency_toReplace = accountCurrency;
        paymentInfo.referenceId = transactionNumber;
        paymentInfo.PaymentProcessor_Reserved = operator;
        paymentInfo.amount = totalAmount;
        paymentInfo.effectiveDate = string.valueOf(date.today());
        paymentInfo.type = System.label.External_Payment_Type;
        //for RDC users
        if(CDFPayment != null && !string.isBlank(CDFPayment) && conversionRate != null) {
            paymentInfo.HomeCurrency_Reserved = System.label.RDCurrency;
            paymentInfo.HomeCurrencyRate_Reserved = conversionRate.length() > 9?conversionRate.substring(0, 9) : conversionRate;
            paymentInfo.AccountCurrencyAmount_Reserved = string.valueOf((double.valueOf(dollarPayment) + refundAmount));
            paymentInfo.HomeCurrencyAmount_Reserved = CDFPayment;
        }

        if(paymentMethod.size() > 0 && paymentMethod != null) {
            paymentInfo.paymentMethodId = paymentMethod[0].Methode_de_paiement_ID__c;
        }
        paymentInfo.OrderNumber_Reserved = orderNumber;
        paymentInfo.OperatorAgent_Reserved = listUser.size() == 1?listUser[0].Name : currentUser.Name;
        paymentInfo.SourceOperator_Reserved = listUser.size() == 1?listUser[0].USR_DistributeurID__c : currentUser.USR_DistributeurID__c;
        paymentInfo.Source_Reserved = fromDistributor?'Distributor' : 'Shop'; //or Distributor??
        paymentInfo.Invoices = listInvoiceInfo;

        return paymentInfo;
    }
    /**
     * Méthode pour résumer un abo suspendu
     * @param accountNumber numero du compte,
     * @param subNumber numero de la souscription,
     * @param freeDays nombre de jours gratuits,
     * @param quoteID id du devis,
     * @param isActive boolean active,
     * @param renewalDate date de renouvellement,
     * @param nbPeriodes nombre de periode a renouvellé
     * @param timbreFiscal
     * @param totalAmount
     * @param subscriptionId
     * @param sequenceNumber nombre de reabo
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillRenewSubscription(
        string accountNumber, string subNumber, string freeDays, id quoteID, boolean isActive, date renewalDate, date nextBillDate,
        integer nbPeriodes, zqu__productrateplancharge__c timbreFiscal, double totalAmount, id subscriptionId,
        string sequenceNumber, string PRPId, string ratePlanId, zqu__ProductRatePlanCharge__c coupon, double couponValue, list<string> listBundleId, list<string> listBundleToRemove){

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();

        if(!isActive) {
            ZuoraObjects.ZuoraResumeAction resumeInactiveOrder = new ZuoraObjects.ZuoraResumeAction();
            resumeInactiveOrder.resumePolicy = 'SpecificDate';
            resumeInactiveOrder.resumeSpecificDate = string.valueOf(date.today());

            //resume Sub
            ZuoraObjects.ZuoraOrderAction resumeInactiveZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
            resumeInactiveZuoraOrder.resume = resumeInactiveOrder;
            resumeInactiveZuoraOrder.type = 'Resume';

            listZuoraOrder.add(resumeInactiveZuoraOrder);

        }
        if(timbreFiscal != null && totalAmount != null) {
            listZuoraOrder.addAll(addTax(subscriptionId, timbreFiscal, totalAmount, renewalDate));
        }
        if(coupon != null && (couponValue != null || !string.isBlank(string.valueOf(couponValue))) && couponValue > 0) {
            ZuoraObjects.ZuoraAddProduct addProd3 = new ZuoraObjects.ZuoraAddProduct();
            addProd3.productRatePlanId = coupon.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

            ZuoraObjects.ZuoraRecurringFlatFee recurringFlatFree = new ZuoraObjects.ZuoraRecurringFlatFee();
            recurringFlatFree.listPrice = -couponValue;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.recurringFlatFee = recurringFlatFree;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = coupon.zqu__ZuoraId__c;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            addProd3.chargeOverrides = listChargeOverride;

            ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(renewalDate), false);
            zuoraOrderAddProd.addProduct = addProd3;
            zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
            listZuoraOrder.add(zuoraOrderAddProd);

        }
        if(listBundleId != null && listBundleId.size() > 0) {
            for(string bundleId : listBundleId) {

                ZuoraObjects.ZuoraAddProduct addProd = new ZuoraObjects.ZuoraAddProduct();
                addProd.productRatePlanId = bundleId;
                //add Collaborator prod
                ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
                zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(renewalDate), false);
                zuoraOrderAddProd.addProduct = addProd;
                zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
                listZuoraOrder.add(zuoraOrderAddProd);

            }
        }
        //removeBundle
        if(listBundleToRemove != null && listBundleToRemove.size() > 0) {
            for(string bundleId : listBundleToRemove) {
                //Remove bundle Product
                ZuoraObjects.ZuoraRemoveProduct removeBundleProd = new ZuoraObjects.ZuoraRemoveProduct();
                removeBundleProd.ratePlanId = bundleId;
                ZuoraObjects.ZuoraOrderAction removeBundle = new ZuoraObjects.ZuoraOrderAction();
                removeBundle.triggerDates = fillTriggerDates(string.valueOf(renewalDate), false);
                removeBundle.removeProduct = removeBundleProd;
                removeBundle.type = System.label.Remove_Product_Order_Type;
                listZuoraOrder.add(removeBundle);
            }

        }
        //update expected renewal date and quote id on subscription
        ZuoraObjects.ZuoraSubscriptionCustomFields subFields = new ZuoraObjects.ZuoraSubscriptionCustomFields();

        if(freeDays != null) {

            if(integer.valueOf(freeDays) > 0) {
                //suspend Sub
                ZuoraObjects.ZuoraSuspendAction suspendAction = new ZuoraObjects.ZuoraSuspendAction();
                suspendAction.suspendPolicy = 'SpecificDate';
                suspendAction.suspendSpecificDate = string.valueOf(nextBillDate);

                ZuoraObjects.ZuoraOrderAction suspendZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
                suspendZuoraOrder.type = System.label.Suspend_Subscription_Order_Type;
                suspendZuoraOrder.suspend = suspendAction;

                //resume Sub
                ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
                resumeOrder.resumePolicy = 'SpecificDate';
                resumeOrder.resumeSpecificDate = string.valueOf(nextBillDate.addDays(integer.valueOf(freeDays)));

                ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
                resumeZuoraOrder.resume = resumeOrder;
                resumeZuoraOrder.type = 'Resume';

                listZuoraOrder.add(suspendZuoraOrder);
                listZuoraOrder.add(resumeZuoraOrder);

                subFields.ExpectedRenewalDate_Reserved = nextBillDate.addDays(integer.valueOf(freeDays));
            } else {
                subFields.ExpectedRenewalDate_Reserved = nextBillDate;
            }
        } else {
            subFields.ExpectedRenewalDate_Reserved = nextBillDate;
        }

        if(!string.isBlank(PRPId)) {
            ZuoraObjects.ZuoraAddProduct addProd = new ZuoraObjects.ZuoraAddProduct();
            addProd.productRatePlanId = PRPId;
            //add Collaborator prod
            ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(renewalDate), false);
            zuoraOrderAddProd.addProduct = addProd;
            zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
            listZuoraOrder.add(zuoraOrderAddProd);
        }
        if(!string.isBlank(ratePlanId) && ratePlanId != null) {
            //Remove Collaborator Product
            ZuoraObjects.ZuoraRemoveProduct removeProd = new ZuoraObjects.ZuoraRemoveProduct();
            removeProd.ratePlanId = ratePlanId;

            ZuoraObjects.ZuoraOrderAction zuoraOrderRemoveProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderRemoveProd.triggerDates = fillTriggerDates(string.valueOf(renewalDate), false);
            zuoraOrderRemoveProd.removeProduct = removeProd;
            zuoraOrderRemoveProd.type = System.label.Remove_Product_Order_Type;
            listZuoraOrder.add(zuoraOrderRemoveProd);
        }

        subFields.SF_QuoteID_Reserved = quoteID;
        subFields.RenewalSequenceNumber_Reserved = string.valueOf(integer.valueOf(sequenceNumber) + 1);
        subFields.CompensationDaysAtNextRenewal_Reserved = '0';

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.customFields = subFields;
        subscription.subscriptionNumber = subNumber;
        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
        billingProcess.runBilling = true;

        ZuoraObjects.ZuoraBillingOptions zbill = new ZuoraObjects.ZuoraBillingOptions();
        zbill.targetDate = string.valueOf(renewalDate.addMonths(nbPeriodes - 1));
        //zbill.targetDate=string.valueOf(date.today().addMonths(nbPeriodes-1));
        billingProcess.billingOptions = zbill;

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = accountNumber;
        zsub.processingOptions = billingProcess;
        zSub.subscriptions = listSubscriptions;
        zSub.orderNumber = accountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     * Méthode pour remplir la demande d'un upgrade de l'apercu d'un abo
     * @param accountNumber le numéro du compte,
     * @param subNumber le numéro de la souscriptin,
     * @param prodToAddId id du produit a ajouter,
     * @param prodToRemoveId id du produit a annuler,
     * @param renewalDate date de renouvellement,
     * @param triggerDate date d'activation,
     * @param isActive boolean active
     * @param fiscalId id du produit timbre fiscal
     * @param chargeId id de la charge du produit fiscal
     * @param totalAmount prix sur lequel les tax sont appliqués
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillUpgradePreviewSubscription(string accountNumber, string subNumber, string prodToAddId, string prod1ToAddId, string prodToRemoveId, string prod1ToRemoveId,
                                                                         date renewalDate, date triggerDate, boolean isActive, string fiscalId, string chargeId, double totalAmount, zqu__ProductRatePlanCharge__c coupon, double couponValue, list<string> listBundleId, list<string> listBundleToRemove){

        ZuoraObjects.ZuoraAddProduct addProd = new ZuoraObjects.ZuoraAddProduct();
        addProd.productRatePlanId = prodToAddId;

        ZuoraObjects.ZuoraAddProduct addProd1 = new ZuoraObjects.ZuoraAddProduct();
        if(!string.isBlank(prod1ToAddId) && prod1ToAddId != null)
            addProd1.productRatePlanId = prod1ToAddId;

        ZuoraObjects.ZuoraAddProduct addProd2 = new ZuoraObjects.ZuoraAddProduct();

        // add taxes
        if(fiscalId != null && totalAmount != null && chargeId != null) {
            addProd2.productRatePlanId = fiscalId;
            ZuoraObjects.ZuoraOneTimeTiered oneTimeTiered = new ZuoraObjects.ZuoraOneTimeTiered();
            oneTimeTiered.quantity = totalAmount;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.oneTimeTiered = oneTimeTiered;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = chargeId;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            addProd2.chargeOverrides = listChargeOverride;

        }

        //Remove Start Product
        ZuoraObjects.ZuoraRemoveProduct removeProd = new ZuoraObjects.ZuoraRemoveProduct();
        removeProd.ratePlanId = prodToRemoveId;

        //Remove Collaborator Prod if exist
        ZuoraObjects.ZuoraRemoveProduct removeProd1 = new ZuoraObjects.ZuoraRemoveProduct();
        if(!string.isBlank(prod1ToRemoveId) && prod1ToRemoveId != null)
            removeProd1.ratePlanId = prod1ToRemoveId;

        list<string> listPreviewType = new List<string>();
        listPreviewType.add('BillingDocs');

        ZuoraObjects.ZuoraPreviewOptions option = new ZuoraObjects.ZuoraPreviewOptions();
        option.previewTypes = listPreviewType;
        option.previewThruType = 'SpecificDate';
        option.specificPreviewThruDate = string.valueOf(renewalDate); //integer.valueOf(currentQuote.QUO_Duree_de_l_Abonnement__c - 1)));

        list<ZuoraObjects.ZuoraOrderAction> listOrderActions = new List<ZuoraObjects.ZuoraOrderAction>();
        if(!isActive) {
            ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
            resumeOrder.resumePolicy = 'SuspendDate';

            //resume Sub
            ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
            resumeZuoraOrder.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
            resumeZuoraOrder.resume = resumeOrder;
            resumeZuoraOrder.type = 'Resume';
            listOrderActions.add(resumeZuoraOrder);

        }
        //add prod
        ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
        zuoraOrderAddProd.addProduct = addProd;
        zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
        listOrderActions.add(zuoraOrderAddProd);
        // add bundle C products
        if(listBundleId != null && listBundleId.size() > 0) {
            for(string bundleId : listBundleId) {
                ZuoraObjects.ZuoraAddProduct addBundle = new ZuoraObjects.ZuoraAddProduct();
                addBundle.productRatePlanId = bundleId;
                zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
                zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                zuoraOrderAddProd.addProduct = addBundle;
                zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
                listOrderActions.add(zuoraOrderAddProd);
            }
        }
        if(!string.isBlank(prod1ToAddId) && prod1ToAddId != null) {
            zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
            zuoraOrderAddProd.addProduct = addProd1;
            zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
            listOrderActions.add(zuoraOrderAddProd);
        }
        if(addProd2.chargeOverrides != null && addProd2 != null) {
            zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
            zuoraOrderAddProd.addProduct = addProd2;
            zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
            listOrderActions.add(zuoraOrderAddProd);
        }
        //removeBundle
        if(listBundleToRemove != null && listBundleToRemove.size() > 0) {
            for(string bundleId : listBundleToRemove) {
        //Remove bundle Product
                ZuoraObjects.ZuoraRemoveProduct removeBundleProd = new ZuoraObjects.ZuoraRemoveProduct();
                removeBundleProd.ratePlanId = bundleId;
                ZuoraObjects.ZuoraOrderAction removeBundle = new ZuoraObjects.ZuoraOrderAction();
                removeBundle.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                removeBundle.removeProduct = removeBundleProd;
                removeBundle.type = System.label.Remove_Product_Order_Type;
                listOrderActions.add(removeBundle);
            }

        }
        //remove Prod
        ZuoraObjects.ZuoraOrderAction zuoraOrderRemoveProd = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderRemoveProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
        zuoraOrderRemoveProd.removeProduct = removeProd;
        zuoraOrderRemoveProd.type = System.label.Remove_Product_Order_Type;
        listOrderActions.add(zuoraOrderRemoveProd);
        if(prod1ToRemoveId != null) {
            if(string.valueOf(prod1ToRemoveId).length() == 32) {
                zuoraOrderRemoveProd = new ZuoraObjects.ZuoraOrderAction();
                zuoraOrderRemoveProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                zuoraOrderRemoveProd.removeProduct = removeProd1;
                zuoraOrderRemoveProd.type = System.label.Remove_Product_Order_Type;
                listOrderActions.add(zuoraOrderRemoveProd);
            }

        }
        if(coupon != null && (couponValue != null || !string.isBlank(string.valueOf(couponValue))) && couponValue > 0) {
            ZuoraObjects.ZuoraAddProduct addProd3 = new ZuoraObjects.ZuoraAddProduct();
            addProd3.productRatePlanId = coupon.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

            ZuoraObjects.ZuoraRecurringFlatFee recurringFlatFree = new ZuoraObjects.ZuoraRecurringFlatFee();
            recurringFlatFree.listPrice = -couponValue;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.recurringFlatFee = recurringFlatFree;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = coupon.zqu__ZuoraId__c;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            addProd3.chargeOverrides = listChargeOverride;

            zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
            zuoraOrderAddProd.addProduct = addProd3;
            zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
            listOrderActions.add(zuoraOrderAddProd);

        }
        //create subscription
        ZuoraObjects.ZuoraOrderSubscription zuoraSubscription = new ZuoraObjects.ZuoraOrderSubscription();
        zuoraSubscription.orderActions = listOrderActions;
        zuoraSubscription.subscriptionNumber = subNumber;
        list<ZuoraObjects.ZuoraOrderSubscription> listZuoraSubscription = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listZuoraSubscription.add(zuoraSubscription);
        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.subscriptions = listZuoraSubscription;
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = accountNumber;
        zSub.previewOptions = option;
        zSub.orderNumber = accountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }

    /**
     * Méthode pour remplir la demande de commande de création d'abonnement technique
     * @param originalSub l'abo,
     * @param techSubName nom de l'abonnement technique
     * @param totalAmount le prix total sur le quel est appliqué les fiscaux
     * @param isRDC
     * @param listOfProductZuoraId list Of product rate plan zuora Id
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillCreateTechnicalSubscription(Zuora__Subscription__c originalSub, string techSubName,
                                                                          double totalAmount, boolean isRDC, list<String> listOfProductZuoraId){

        //get logged user
        User currentUser = [ SELECT Id, Name, USR_DistributeurID__c
                             FROM User
                             WHERE Id = :UserInfo.getUserId()
                             LIMIT 1 ];

        ZuoraObjects.ZuoraInitialTerm initialTerms = new ZuoraObjects.ZuoraInitialTerm();
        initialTerms.termType = System.label.Termed_Subscription_Term_Type;
        initialTerms.periodType = System.label.Month_Period_Type;
        initialTerms.period = 1;
        ZuoraObjects.ZuoraTerms term = new ZuoraObjects.ZuoraTerms();

        term.autoRenew = false;
        term.initialTerm = initialTerms;
        term.renewalSetting = System.label.Renew_To_Evergreen_Renewal_Settings;

        ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
        list<ZuoraObjects.ZuorasubscribeToRatePlans> listSubscribeToRatePlans = new List<ZuoraObjects.ZuorasubscribeToRatePlans>();

        if(listOfProductZuoraId != null && listOfProductZuoraId.size() > 0) {
            for(String prodId : listOfProductZuoraId) {
                subscribeToRatePlan.productRatePlanId = prodId;
                listSubscribeToRatePlans.add(subscribeToRatePlan);
                subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
            }
        }

        ZuoraObjects.ZuoraCreateSubscription subscription = new ZuoraObjects.ZuoraCreateSubscription();
        //add term to subscription
        subscription.terms = term;
        //subscription.invoiceSeparately=false;
        subscription.subscribeToRatePlans = listSubscribeToRatePlans;
        subscription.subscriptionNumber = techSubName;

        //activate the sub
        ZuoraObjects.ZuoraTriggerDate trigger0 = new ZuoraObjects.ZuoraTriggerDate();
        trigger0.name = System.label.Service_Activation_Trigger_Name;
        trigger0.triggerDate = string.valueOf(date.today());
        list<ZuoraObjects.ZuoraTriggerDate> listTriggerDate = new List<ZuoraObjects.ZuoraTriggerDate>();
        listTriggerDate.add(trigger0);

        //add subscription to order action
        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        ZuoraOrder.triggerDates = listTriggerDate;
        zuoraOrder.createSubscription = subscription;
        zuoraOrder.type = System.label.Create_Subscription_Order_Type;

        list<ZuoraObjects.ZuoraOrderAction> listOrderActions = new List<ZuoraObjects.ZuoraOrderAction>();
        listOrderActions.add(zuoraOrder);

        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomFields = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomFields.Type_Reserved = System.label.Technical_Custom_Field_Type;

        //create subscription
        ZuoraObjects.ZuoraOrderSubscription zuoraSubscription = new ZuoraObjects.ZuoraOrderSubscription();
        zuoraSubscription.customFields = subCustomFields;
        zuoraSubscription.orderActions = listOrderActions;
        list<ZuoraObjects.ZuoraOrderSubscription> listZuoraSubscription = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listZuoraSubscription.add(zuoraSubscription);

        //add billing to the subscription
        /* ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
           billingProcess.runBilling = true;*/

        ZuoraObjects.ZuoraOrderCustomFields orderCustomFields = new ZuoraObjects.ZuoraOrderCustomFields();
        orderCustomFields.OperatorAgent_Reserved = currentUser.Name;
        orderCustomFields.SourceOperator_Reserved = currentUser.USR_DistributeurID__c;
        orderCustomFields.Source_Reserved = 'Shop';

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = originalSub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
        zSub.subscriptions = listZuoraSubscription;
        zSub.customFields = orderCustomFields;
        zSub.orderNumber = originalSub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c + '-' + Datetime.now().format('ddMMyyyyhhmm');

        if(originalSub.Zuora__Status__c == 'Active' || originalSub.Zuora__Status__c == 'Suspended' || isRDC) {
            ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
            billingProcess.runBilling = true;

            ZuoraObjects.ZuoraBillingOptions zbill = new ZuoraObjects.ZuoraBillingOptions();
            zbill.targetDate = string.valueOf(date.today());
            billingProcess.billingOptions = zbill;

            zSub.processingOptions = billingProcess;
        }

        return zSub;
    }

    /**
     *  Méthode pour appliquer le paiement sur la facture
     * @param invoiceId l'Id de la facture,
     * @param currentAmount le montant encaissé
     * @return ZuoraObjects.ZuoraPayment
     * */
    public static ZuoraObjects.ZuoraPayment fillApplyPayment(string invoiceId, integer currentAmount){
        ZuoraObjects.ZuoraPayment paymentInfo = new ZuoraObjects.ZuoraPayment();
        ZuoraObjects.ZuoraBilling invoiceInfo = new ZuoraObjects.ZuoraBilling();
        list<ZuoraObjects.ZuoraBilling> listInvoiceInfo = new List<ZuoraObjects.ZuoraBilling>();
        invoiceInfo.invoiceId = invoiceId;
        invoiceInfo.amount = currentAmount;
        listInvoiceInfo.add(invoiceInfo);
        paymentInfo.effectiveDate = string.valueOf(date.today());
        paymentInfo.Invoices = listInvoiceInfo;

        return paymentInfo;
    }
    /**
     * Méthode pour remplir les trigger dates
     * @param subActivationDate date d'activation,
     * @param subNumber numéro de la souscription
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillTriggerOrderDates(date subActivationDate, string subNumber){
        ZuoraObjects.ZuoraTriggerDate activationDate = new ZuoraObjects.ZuoraTriggerDate();
        list<ZuoraObjects.ZuoraTriggerDate> listTriggerDate = new List<ZuoraObjects.ZuoraTriggerDate>();
        activationDate.name = System.label.Service_Activation_Trigger_Name;
        activationDate.triggerDate = string.valueOf(subActivationDate);
        listTriggerDate.add(activationDate);

        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        ZuoraOrder.sequence = 0;
        ZuoraOrder.triggerDates = listTriggerDate;

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();
        listZuoraOrder.add(ZuoraOrder);

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.subscriptionNumber = subNumber;
        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.subscriptions = listSubscriptions;

        return zSub;
    }
    /**
     * Méthode pour remplir les champs personnalisés d'un abonnement
     * @param sub l'abonnement
     * @param warranty la periode de guarantie
     * @param boxNumber le numero du box reservé
     * @param nbPeriod nombre de periode prepayeés
     * @param sequenceNumber nombre de reabo
     * @return ZuoraObjects.ZuoraOrderSubscription
     * */
    public static ZuoraObjects.ZuoraOrderSubscription updateSubscriptionCustomFields(Zuora__Subscription__c sub, integer warranty, string boxNumber, date nextBillDate, string sequenceNumber){
        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomField = new ZuoraObjects.ZuoraSubscriptionCustomFields();

        if(sequenceNumber != null) {
            subCustomField.RenewalSequenceNumber_Reserved = string.valueOf(integer.valueOf(sequenceNumber) + 1);
        }
        // for box Changing
        if(boxNumber != null && warranty != null) {
            subCustomField.BoxNumber_Reserved = boxNumber;
            subCustomField.WarrantyEndDate_Reserved = string.valueOf(date.today().addMonths(warranty));
        } else if(boxNumber != null && warranty == null) {
            subCustomField.BoxNumber_Reserved = boxNumber;
        }
        // simple renew: add expected renewal date
        else if(boxNumber == null && warranty == null && nextBillDate != null) {
            subCustomField.ExpectedRenewalDate_Reserved = nextBillDate;
        }
        // on activation: add expected renewal date
        else {
            subCustomField.ExpectedRenewalDate_Reserved = sub.Zuora__ServiceActivationDate__c.addMonths(integer.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c));
        }
        subscription.customFields = subCustomField;

        return subscription;
    }

    /**
     * Méthode pour remplir les champs personnalisés d'un abonnement
     * @param collaborator
     * @return ZuoraObjects.ZuoraOrderSubscription
     * */
    public static ZuoraObjects.ZuoraOrderSubscription updateCollaboratorSubscription(string collaborator){
        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomField = new ZuoraObjects.ZuoraSubscriptionCustomFields();

        subCustomField.isCollaborator_Reserved = collaborator;
        subscription.customFields = subCustomField;

        return subscription;
    }
    /**
     * Méthode pour mettre a jour les champs personnalisés d'un abonnement
     * @param l'abonnement
     * @return ZuoraObjects.ZuoraOrderSubscription
     * */
    public static ZuoraObjects.ZuoraOrderSubscription updateSubscriptionCompensationCustomField(Zuora__Subscription__c sub){
        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomField = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomField.CompensationDaysAtNextRenewal_Reserved = String.valueOf(sub.CompensationDaysAtNextRenewal__c);
        subscription.customFields = subCustomField;

        return subscription;
    }

    /**
     *  Méthode pour remplir les champs necessaire pour mettre a jour l'addresse dans zuora
     * @param customerAccount le compte de zuora
     * @return ZuoraObjects.ZuoraAccount
     * */
    public static ZuoraObjects.ZuoraAccount fillUpdateAccountAddress( Zuora__CustomerAccount__c customerAccount){
        ZuoraObjects.ZuoraAccount zAcc = new ZuoraObjects.ZuoraAccount();
        ZuoraObjects.ZuoraContact billToContactInfo = new ZuoraObjects.ZuoraContact();
        billToContactInfo.firstName = customerAccount.Zuora__Account__r.FirstName;
        billToContactInfo.lastName = customerAccount.Zuora__Account__r.LastName;
        billToContactInfo.country = customerAccount.Zuora__Account__r.BillingCountryCode;
        billToContactInfo.city = customerAccount.Zuora__Account__r.BillingCity;
        billToContactInfo.state = customerAccount.Zuora__Account__r.BillingState;
        billToContactInfo.zipCode = customerAccount.Zuora__Account__r.BillingPostalCode;

        if(String.isNotBlank(customerAccount.Zuora__Account__r.BillingCountryCode)) {
            // Try to find if a metadata configuration exists for the Country
            //	List<Template_Setting__mdt> templateSettings = Template_Setting__mdt.getAll().values();
            List<Template_Setting__mdt> templateSettings = [ SELECT Communication_Profile_Id__c, Sequence_Set_Id__c,
                                                             Invoice_Template_Id__c, Pays__c,
                                                             DM_Template_Id__c, CM_Template_Id__c
                                                             FROM Template_Setting__mdt
                                                             WHERE Pays__c = :customerAccount.Zuora__Account__r.BillingCountry];
            if(templateSettings.size() > 0) {
                zAcc.communicationProfileId = templateSettings[0].Communication_Profile_Id__c;
                zAcc.sequenceSetId = templateSettings[0].Sequence_Set_Id__c;
                zAcc.invoiceTemplateId = templateSettings[0].Invoice_Template_Id__c;
                zAcc.debitMemoTemplateId = templateSettings[0].DM_Template_Id__c;
                zAcc.creditMemoTemplateId = templateSettings[0].CM_Template_Id__c;
            }
        }
        zAcc.billToContact = billToContactInfo;
        zAcc.soldToContact = billToContactInfo;

        zAcc.existingID = customerAccount.Zuora__Zuora_Id__c;

        return zAcc;
    }

    /**
     * Méthode pour remplir la demande de création d'une facture
     * @param listSubId liste des id des souscription,
     * @param activationDate date d'activation,
     * @param perpaidPeriods nombre de mois prépayées
     * @return ZuoraObjects.ZuoraBilling
     * */
    public static ZuoraObjects.ZuoraBilling fillGenerateBill(list<string> listSubId, date activationDate, decimal perpaidPeriods){

        ZuoraObjects.ZuoraBilling zBill = new ZuoraObjects.ZuoraBilling();
        zBill.autoPost = true;
        zBill.effectiveDate = string.valueOf(date.today());
        zBill.targetDate = string.valueOf(activationDate.addMonths(integer.valueOf(perpaidPeriods - 1)));
        zBill.subscriptionIds = listSubId;

        return zBill;
    }
    /**
     * Méthode pour remplir les champs custom d'une facture
     * @param onCreate boolean création,
     * @param perpaidPeriods nombre de périodes prépayé
     * @return ZuoraObjects.ZuoraBilling
     * */
    public static ZuoraObjects.ZuoraBilling fillInvoiceCustomFields(boolean onCreate, string perpaidPeriods, Zuora__Subscription__c sub, string conversionRate, id SFAccountId){
        //get logged user
        User currentUser = new User();
        list<User> listUser = new list<User>();
        if(SFAccountId != null) {
            listUser = [SELECT Id, Name, USR_DistributeurID__c
                        FROM User
                        WHERE AccountId =:SFAccountId OR Id = : UserInfo.getUserId()];
        } else {
            listUser = [SELECT Id, Name, USR_DistributeurID__c
                        FROM User
                        WHERE Id = : UserInfo.getUserId()];
        }

        if(listUser.size() > 1) {
            currentUser = [ SELECT Id, Name, USR_DistributeurID__c, AccountId
                            FROM User
                            WHERE AccountId = : SFAccountId
                            LIMIT 1 ];
        }

        // case of immediat upgrade without renew
        if(perpaidPeriods == null) {
            perpaidPeriods = '1';
        }
        ZuoraObjects.ZuoraBilling zBill = new ZuoraObjects.ZuoraBilling();
        if(sub == null) {
            zBill.OperatorAgent_Reserved = listUser.size() == 1?listUser[0].Name : currentUser.Name;
            zBill.SourceOperator_Reserved = listUser.size() == 1?listUser[0].USR_DistributeurID__c : currentUser.USR_DistributeurID__c;
        } else {
            zBill.OperatorAgent_Reserved = sub.Quote__r.CreatedBy.Name;
            zBill.SourceOperator_Reserved = sub.Quote__r.CreatedBy.USR_DistributeurID__c;
        }

        //for RDC
        if(conversionRate != null) {
            zBill.HomeCurrencyRate_Reserved = conversionRate.length() > 9?conversionRate.substring(0, 9) : conversionRate;
            zBill.HomeCurrency_Reserved = system.label.RDCurrency;
        }
        zBill.PrepaidPeriods_Reserved = perpaidPeriods;
        if(onCreate) {
            zBill.Source_Reserved = 'Shop';
        }
        // on renew
        else {
            zBill.Source_Reserved = 'Distributor';
        }

        return zBill;
    }

    /**
     * Méthode pour remplir la demande de commande pour annuler l'abo
     * @param originalSub l'abo,
     * @param newQuoteID Id du devis,
     * @param reasons les raisons d'annulations,
     * @param isResiliation boolean résilier
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillCancelSubscription(Zuora__Subscription__c originalSub, string newQuoteID, string reasons, boolean isResiliation){
        //get logged user
        User currentUser = [SELECT Id, Name, USR_DistributeurID__c
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1];
        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();

        if(originalSub.Zuora__Status__c == 'Suspended') {
            //resume Sub
            ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
            resumeOrder.resumePolicy = 'Today';

            ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
            resumeZuoraOrder.resume = resumeOrder;
            resumeZuoraOrder.type = 'Resume';

            listZuoraOrder.add(resumeZuoraOrder);
        }
        // static variables ==> custom labels
        ZuoraObjects.ZuoraCancelSubscription cancelAction = new ZuoraObjects.ZuoraCancelSubscription();
        cancelAction.cancellationEffectiveDate = (isResiliation == false)? string.valueOf(Date.today()) : string.valueOf(originalSub.ExpectedRenewalDate__c);
        cancelAction.cancellationPolicy = 'SpecificDate';

        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrder.type = System.label.Cancel_Subscription_Order_Type;
        ZuoraOrder.cancelSubscription = cancelAction;

        listZuoraOrder.add(ZuoraOrder);

        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomField = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomField.SF_QuoteID_Reserved = newQuoteID;
        subCustomField.CancelReason_Reserved = reasons;
        //subCustomField.BoxNumber_Reserved = '0';

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.customFields = subCustomField;
        subscription.subscriptionNumber = originalSub.Zuora__SubscriptionNumber__c;

        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraOrderCustomFields orderCustomFields = new ZuoraObjects.ZuoraOrderCustomFields();
        orderCustomFields.OperatorAgent_Reserved = currentUser.Name;
        orderCustomFields.SourceOperator_Reserved = currentUser.USR_DistributeurID__c;

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = originalSub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
        zSub.subscriptions = listSubscriptions;
        zSub.CustomFields = orderCustomFields;
        zSub.orderNumber = originalSub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     * Méthode pour remplir la demande de commande pour suspendre l'abo
     * @param originalSub l'abo,
     * @param newQuoteID Id du devis,
     * @param periodType type de période,
     * @param period la période de suspension
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillSuspendSubscription(
        Zuora__Subscription__c originalSub, string newQuoteID, string periodType, integer period){
        // static variables ==> custom labels
        ZuoraObjects.ZuoraSuspendAction suspendAction = new ZuoraObjects.ZuoraSuspendAction();
        suspendAction.suspendPeriods = period;
        suspendAction.suspendPolicy = 'FixedPeriodsFromToday';
        suspendAction.suspendPeriodsType = periodType;

        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrder.type = System.label.Suspend_Subscription_Order_Type;
        ZuoraOrder.suspend = suspendAction;

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();
        listZuoraOrder.add(ZuoraOrder);

        ZuoraObjects.ZuoraSubscriptionCustomFields quoteField = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        quoteField.SF_QuoteID_Reserved = newQuoteID;

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.customFields = quoteField;
        subscription.subscriptionNumber = originalSub.Zuora__SubscriptionNumber__c;

        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = originalSub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
        zSub.subscriptions = listSubscriptions;
        zSub.orderNumber = originalSub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     * Méthode pour remplir la demande de commande pour ajouter un produit
     * @param accountNumber numéro du compte,
     * @param subNumber numéro de la souscription,
     * @param newQuoteID id du devis,
     * @param prodToAddId id du produit a ajouter,
     * @param prodToRemoveId id du produit a annuler,
     * @param freeDays nombre de jours gratuits,
     * @param triggerDate date d'activation,
     * @param endDate date de renouvellement,
     * @param withRenew boolean réabonnement,
     * @param isActive boolean active
     * @param timbreFiscal produit timbre fiscal
     * @param amount prix total des produits
     * @param subId Id de l'abonnement
     * @param sequenceNumber nombre de reabo faite
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillUpgradeProduct(
        string accountNumber, string subNumber, string newQuoteID,
        string prodToAddId, string collabPRP, string prodToRemoveId, string collabCharge, string freeDays,
        date triggerDate, date endDate, date nextBillDate, integer nbPeriodes, boolean withRenew, boolean isActive,
        zqu__productrateplancharge__c timbreFiscal, double amount, id subId, string sequenceNumber, zqu__ProductRatePlanCharge__c coupon, double couponValue, list<string> listBundleId, list<string> listBundleToRemove){
        //Add Premium Product
        ZuoraObjects.ZuoraAddProduct addProd = new ZuoraObjects.ZuoraAddProduct();
        addProd.productRatePlanId = prodToAddId;
        //Add Collaborator Product
        ZuoraObjects.ZuoraAddProduct addProd1 = new ZuoraObjects.ZuoraAddProduct();
        if(collabPRP != null)
            addProd1.productRatePlanId = collabPRP;

        ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
        zuoraOrderAddProd.addProduct = addProd;
        zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);

        ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd1 = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderAddProd1.type = System.label.Add_Product_Order_Type;
        zuoraOrderAddProd1.addProduct = addProd1;
        zuoraOrderAddProd1.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);

        //Remove Start Product
        ZuoraObjects.ZuoraRemoveProduct removeProd = new ZuoraObjects.ZuoraRemoveProduct();
        removeProd.ratePlanId = prodToRemoveId;

        //Remove Collaborator Product
        ZuoraObjects.ZuoraRemoveProduct removeProd1 = new ZuoraObjects.ZuoraRemoveProduct();
        if(collabCharge != null)
            removeProd1.ratePlanId = collabCharge;

        ZuoraObjects.ZuoraOrderAction zuoraOrderRemoveProd = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderRemoveProd.type = System.label.Remove_Product_Order_Type;
        zuoraOrderRemoveProd.removeProduct = removeProd;
        zuoraOrderRemoveProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);

        ZuoraObjects.ZuoraOrderAction zuoraOrderRemoveProd1 = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderRemoveProd1.type = System.label.Remove_Product_Order_Type;
        zuoraOrderRemoveProd1.removeProduct = removeProd1;
        zuoraOrderRemoveProd1.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();
        if(!isActive) {
            //resume Sub
            ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
            resumeOrder.resumePolicy = 'SpecificDate';
            resumeOrder.resumeSpecificDate = string.valueOf(date.today());

            ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
            resumeZuoraOrder.triggerDates = fillTriggerDates(string.valueOf(date.today()), false);
            resumeZuoraOrder.resume = resumeOrder;
            resumeZuoraOrder.type = 'Resume';

            listZuoraOrder.add(resumeZuoraOrder);
        }
        if(timbreFiscal != null && amount != null) {
            listZuoraOrder.addAll(addTax(subId, timbreFiscal, amount, triggerDate));
        }
        listZuoraOrder.add(zuoraOrderRemoveProd);
        if(collabCharge != null) {
            if(string.valueOf(collabCharge).length() == 32) {
                listZuoraOrder.add(zuoraOrderRemoveProd1);
            }
        }
        listZuoraOrder.add(zuoraOrderAddProd);
        if(collabPRP != null)
            listZuoraOrder.add(zuoraOrderAddProd1);

        // add bundle C products
        if(listBundleId != null && listBundleId.size() > 0) {
            for(string bundleId : listBundleId) {
                ZuoraObjects.ZuoraAddProduct addBundle = new ZuoraObjects.ZuoraAddProduct();
                addBundle.productRatePlanId = bundleId;
                zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
                zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                zuoraOrderAddProd.addProduct = addBundle;
                zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
                listZuoraOrder.add(zuoraOrderAddProd);
            }
        }

        if(listBundleToRemove != null && listBundleToRemove.size() > 0) {
            for(string bundleId : listBundleToRemove) {
                //Remove bundle Product
                ZuoraObjects.ZuoraRemoveProduct removeBundleProd = new ZuoraObjects.ZuoraRemoveProduct();
                removeBundleProd.ratePlanId = bundleId;
                ZuoraObjects.ZuoraOrderAction removeBundle = new ZuoraObjects.ZuoraOrderAction();
                removeBundle.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                removeBundle.removeProduct = removeBundleProd;
                removeBundle.type = System.label.Remove_Product_Order_Type;
                listZuoraOrder.add(removeBundle);
            }

        }

        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomFields = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        if(coupon != null && (couponValue != null || !string.isBlank(string.valueOf(couponValue))) && couponValue > 0) {
            ZuoraObjects.ZuoraAddProduct addProd3 = new ZuoraObjects.ZuoraAddProduct();
            addProd3.productRatePlanId = coupon.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

            ZuoraObjects.ZuoraRecurringFlatFee recurringFlatFree = new ZuoraObjects.ZuoraRecurringFlatFee();
            recurringFlatFree.listPrice = -couponValue;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.recurringFlatFee = recurringFlatFree;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = coupon.zqu__ZuoraId__c;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            addProd3.chargeOverrides = listChargeOverride;

            zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
            zuoraOrderAddProd.addProduct = addProd3;
            zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
            listZuoraOrder.add(zuoraOrderAddProd);

        }
        if(freeDays != null) {
            if(integer.valueOf(freeDays) > 0) {
                //suspend Sub
                ZuoraObjects.ZuoraSuspendAction suspendAction = new ZuoraObjects.ZuoraSuspendAction();
                suspendAction.suspendPolicy = 'SpecificDate';
                suspendAction.suspendSpecificDate = string.valueOf(nextBillDate);

                ZuoraObjects.ZuoraOrderAction suspendZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
                suspendZuoraOrder.type = System.label.Suspend_Subscription_Order_Type;
                suspendZuoraOrder.suspend = suspendAction;

                //resume Sub
                ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
                resumeOrder.resumePolicy = 'SpecificDate';
                resumeOrder.resumeSpecificDate = string.valueOf(nextBillDate.addDays(integer.valueOf(freeDays)));

                ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
                resumeZuoraOrder.resume = resumeOrder;
                resumeZuoraOrder.type = 'Resume';

                listZuoraOrder.add(suspendZuoraOrder);
                listZuoraOrder.add(resumeZuoraOrder);

                subCustomFields.ExpectedRenewalDate_Reserved = nextBillDate.addDays(integer.valueOf(freeDays));
            } else {
                subCustomFields.ExpectedRenewalDate_Reserved = nextBillDate;
            }
        } else {
            subCustomFields.ExpectedRenewalDate_Reserved = nbPeriodes == null?triggerDate : nextBillDate;
        }

        subCustomFields.SF_QuoteID_Reserved = newQuoteID;
        subCustomFields.RenewalSequenceNumber_Reserved = string.valueOf(integer.valueOf(sequenceNumber) + 1);
        subCustomFields.CompensationDaysAtNextRenewal_Reserved = '0';//freeDays;

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.customFields = subCustomFields;
        subscription.subscriptionNumber = subNumber;
        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
        billingProcess.runBilling = true;

        ZuoraObjects.ZuoraBillingOptions zbill = new ZuoraObjects.ZuoraBillingOptions();
        zbill.targetDate = string.valueOf(endDate);
        billingProcess.billingOptions = zbill;

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.processingOptions = billingProcess;
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = accountNumber;
        zSub.subscriptions = listSubscriptions;
        zSub.orderNumber = accountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     * Méthode pour remplir la demande de commande pour downgrade un produit
     * @param accountNumber numéro du compte,
     * @param subNumber numéro de la souscription,
     * @param newQuoteID id du devis,
     * @param prodToAddId id du produit a ajouter,
     * @param prodToRemoveId id du produit a annuler,
     * @param freeDays nombre de jours gratuits,
     * @param triggerDate date d'activation,
     * @param renewalDate date de renouvellement,
     * @param isActive boolean active
     * @param timbreFiscal produit timbre fiscal
     * @param amount prix total des produits
     * @param subId Id de l'abonnement
     * @param sequenceNumber numero de reabo
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillDowngradeProduct(
        string accountNumber, string subNumber, string newQuoteID,
        string prodToAddId, string collabPRP, string prodToRemoveId, string collabCharge, string freeDays,
        date triggerDate, date renewalDate, date nextBillDate, integer nbPeriodes, boolean isActive,
        zqu__productrateplancharge__c timbreFiscal, double amount, id subId, string sequenceNumber, zqu__ProductRatePlanCharge__c coupon, 
        double couponValue, list<string> listBundleId, list<string> listBundleToRemove){
            
        //Add Premium Product
        ZuoraObjects.ZuoraAddProduct addProd = new ZuoraObjects.ZuoraAddProduct();
        addProd.productRatePlanId = prodToAddId;

        //Add Collaborator Product
        ZuoraObjects.ZuoraAddProduct addProd1 = new ZuoraObjects.ZuoraAddProduct();
        if(collabPRP != null)
            addProd1.productRatePlanId = collabPRP;

        ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
        zuoraOrderAddProd.addProduct = addProd;
        zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);

        //Remove Start Product
        ZuoraObjects.ZuoraRemoveProduct removeProd = new ZuoraObjects.ZuoraRemoveProduct();
        removeProd.ratePlanId = prodToRemoveId;
        //Remove Collaborator Product
        ZuoraObjects.ZuoraRemoveProduct removeProd1 = new ZuoraObjects.ZuoraRemoveProduct();
        if(collabCharge != null)
            removeProd1.ratePlanId = collabCharge;

        ZuoraObjects.ZuoraOrderAction zuoraOrderRemoveProd = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderRemoveProd.type = System.label.Remove_Product_Order_Type;
        zuoraOrderRemoveProd.removeProduct = removeProd;
        zuoraOrderRemoveProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();

        if(!isActive) {
            ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
            resumeOrder.resumePolicy = 'SpecificDate';
            resumeOrder.resumeSpecificDate = string.valueOf(date.today());
            //resume Sub
            ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
            resumeZuoraOrder.triggerDates = fillTriggerDates(string.valueOf(date.today()), false);
            resumeZuoraOrder.resume = resumeOrder;
            resumeZuoraOrder.type = 'Resume';
            listZuoraOrder.add(resumeZuoraOrder);
        }
        if(timbreFiscal != null && amount != null) {
            listZuoraOrder.addAll(addTax(subId, timbreFiscal, amount, triggerDate));
        }
        listZuoraOrder.add(zuoraOrderAddProd);
        //add bundle Prod
        if(listBundleId != null && listBundleId.size() > 0) {
            for(string bundleId : listBundleId) {
                ZuoraObjects.ZuoraAddProduct bundleProd = new ZuoraObjects.ZuoraAddProduct();
                bundleProd.productRatePlanId = bundleId;
                //add Collaborator prod
                ZuoraObjects.ZuoraOrderAction zuoraOrderBundleProd = new ZuoraObjects.ZuoraOrderAction();
                zuoraOrderBundleProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                zuoraOrderBundleProd.addProduct = bundleProd;
                zuoraOrderBundleProd.type = System.label.Add_Product_Order_Type;
                listZuoraOrder.add(zuoraOrderBundleProd);
            }
        }
        if(listBundleToRemove != null && listBundleToRemove.size() > 0) {
            for(string bundleId : listBundleToRemove) {
                //Remove bundle Product
                ZuoraObjects.ZuoraRemoveProduct removeBundleProd = new ZuoraObjects.ZuoraRemoveProduct();
                removeBundleProd.ratePlanId = bundleId;
                ZuoraObjects.ZuoraOrderAction removeBundle = new ZuoraObjects.ZuoraOrderAction();
                removeBundle.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                removeBundle.removeProduct = removeBundleProd;
                removeBundle.type = System.label.Remove_Product_Order_Type;
                listZuoraOrder.add(removeBundle);
            }

        }

        if(collabPRP != null) {
            ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd1 = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd1.type = System.label.Add_Product_Order_Type;
            zuoraOrderAddProd1.addProduct = addProd1;
            zuoraOrderAddProd1.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
            listZuoraOrder.add(zuoraOrderAddProd1);
        }
        listZuoraOrder.add(zuoraOrderRemoveProd);

        if(collabCharge != null) {
            if(string.valueOf(collabCharge).length() == 32) {
                ZuoraObjects.ZuoraOrderAction zuoraOrderRemoveProd1 = new ZuoraObjects.ZuoraOrderAction();
                zuoraOrderRemoveProd1.type = System.label.Remove_Product_Order_Type;
                zuoraOrderRemoveProd1.removeProduct = removeProd1;
                zuoraOrderRemoveProd1.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
                listZuoraOrder.add(zuoraOrderRemoveProd1);
            }
        }
        if(coupon != null && (couponValue != null || !string.isBlank(string.valueOf(couponValue))) && couponValue > 0) {
            ZuoraObjects.ZuoraAddProduct addProd3 = new ZuoraObjects.ZuoraAddProduct();
            addProd3.productRatePlanId = coupon.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

            ZuoraObjects.ZuoraRecurringFlatFee recurringFlatFree = new ZuoraObjects.ZuoraRecurringFlatFee();
            recurringFlatFree.listPrice = -couponValue;

            ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
            pricing.recurringFlatFee = recurringFlatFree;

            zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
            chargeOverride.pricing = pricing;
            chargeOverride.productRatePlanChargeId = coupon.zqu__ZuoraId__c;

            list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
            listChargeOverride.add(chargeOverride);

            addProd3.chargeOverrides = listChargeOverride;

            zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(triggerDate), false);
            zuoraOrderAddProd.addProduct = addProd3;
            zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;
            listZuoraOrder.add(zuoraOrderAddProd);

        }
        ZuoraObjects.ZuoraSubscriptionCustomFields subField = new ZuoraObjects.ZuoraSubscriptionCustomFields();

        if(freeDays != null) {
            if(integer.valueOf(freeDays) > 0) {
                //suspend Sub
                ZuoraObjects.ZuoraSuspendAction suspendAction = new ZuoraObjects.ZuoraSuspendAction();
                suspendAction.suspendPolicy = 'SpecificDate';
                suspendAction.suspendSpecificDate = string.valueOf(nextBillDate);

                ZuoraObjects.ZuoraOrderAction suspendZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
                suspendZuoraOrder.type = System.label.Suspend_Subscription_Order_Type;
                suspendZuoraOrder.suspend = suspendAction;

                //resume Sub
                ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
                resumeOrder.resumePolicy = 'SpecificDate';
                resumeOrder.resumeSpecificDate = string.valueOf(nextBillDate.addDays(integer.valueOf(freeDays)));

                ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
                resumeZuoraOrder.resume = resumeOrder;
                resumeZuoraOrder.type = 'Resume';

                listZuoraOrder.add(suspendZuoraOrder);
                listZuoraOrder.add(resumeZuoraOrder);

                subField.ExpectedRenewalDate_Reserved = nextBillDate.addDays(integer.valueOf(freeDays));
            } else {
                subField.ExpectedRenewalDate_Reserved = nextBillDate;
            }
        } else {
            subField.ExpectedRenewalDate_Reserved = nextBillDate;
        }

        subField.RenewalSequenceNumber_Reserved = string.valueOf(integer.valueOf(sequenceNumber) + 1);
        subField.SF_QuoteID_Reserved = newQuoteID;
        subField.CompensationDaysAtNextRenewal_Reserved = '0';//freeDays;

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.customFields = subField;
        subscription.subscriptionNumber = subNumber;
        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
        billingProcess.runBilling = true;

        ZuoraObjects.ZuoraBillingOptions zbill = new ZuoraObjects.ZuoraBillingOptions();
        zbill.targetDate = string.valueOf(renewalDate);
        billingProcess.billingOptions = zbill;

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = accountNumber;
        zSub.processingOptions = billingProcess;
        zSub.subscriptions = listSubscriptions;
        zSub.orderNumber = accountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     * Methode pour ajuster le BCD du compte
     *@param day nombre de jours
     *@return ZuoraObjects.ZuoraUpdateAccount
     */
    public static ZuoraObjects.ZuoraUpdateAccount fillAdjustAccount(integer day){
        ZuoraObjects.ZuoraUpdateAccount zAccount = new ZuoraObjects.ZuoraUpdateAccount();
        zAccount.BillCycleDay = day;
        zAccount.BcdSettingOption = 'ManualSet';

        return zAccount;
    }
    /**
     * Methode pour specifier la date effective du contract, la date d'activation d'une souscription et date d'acceptation du client
     * @param triggerDate date d'activation d'un abonnement en pending
     * @return list d'object ZuoraTriggerDate
     * */
    public static list<ZuoraObjects.ZuoraTriggerDate> fillTriggerDates( string triggerDate, Boolean allTriggerDate) {
        ZuoraObjects.ZuoraTriggerDate trigger0 = new ZuoraObjects.ZuoraTriggerDate();
        trigger0.name = System.label.Contract_Effective_Trigger_Name;
        trigger0.triggerDate = triggerDate;

        ZuoraObjects.ZuoraTriggerDate trigger1 = new ZuoraObjects.ZuoraTriggerDate();
        trigger1.name = System.label.Service_Activation_Trigger_Name;
        trigger1.triggerDate = triggerDate;

        ZuoraObjects.ZuoraTriggerDate trigger2 = new ZuoraObjects.ZuoraTriggerDate();
        trigger2.name = System.label.Customer_Acceptance_Trigger_Name;
        trigger2.triggerDate = triggerDate;

        list<ZuoraObjects.ZuoraTriggerDate> listTrigger = new List<ZuoraObjects.ZuoraTriggerDate>();
        listTrigger.add(trigger0);
        listTrigger.add(trigger1);

        if(allTriggerDate) {
            listTrigger.add(trigger2);
        }

        return listTrigger;
    }
    /**
     * Méthode pour ajouter le nombre de jours gratuit
     * @param accountNumber numéro du compte,
     * @param subNumber numéro de l'abonnement,
     * @param newQuoteID Id du devis,
     * @param nbDays nombre de jours gratuits,
     * @param newRenewalDate date de renouvellement
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillCompensationDays( string accountNumber, string subNumber, string newQuoteID, integer nbDays, date newRenewalDate){
        //suspend Sub
        ZuoraObjects.ZuoraSuspendAction suspendAction = new ZuoraObjects.ZuoraSuspendAction();
        suspendAction.suspendPolicy = 'SpecificDate';
        suspendAction.suspendSpecificDate = string.valueOf(newRenewalDate);

        ZuoraObjects.ZuoraOrderAction suspendZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        suspendZuoraOrder.type = System.label.Suspend_Subscription_Order_Type;
        suspendZuoraOrder.suspend = suspendAction;
        //resume Sub
        ZuoraObjects.ZuoraResumeAction resumeOrder = new ZuoraObjects.ZuoraResumeAction();
        resumeOrder.resumePolicy = 'SpecificDate';
        resumeOrder.resumeSpecificDate = string.valueOf(newRenewalDate.addDays(nbDays));

        ZuoraObjects.ZuoraOrderAction resumeZuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        resumeZuoraOrder.resume = resumeOrder;
        resumeZuoraOrder.type = 'Resume';

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();
        listZuoraOrder.add(suspendZuoraOrder);
        listZuoraOrder.add(resumeZuoraOrder);

        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomFields = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomFields.SF_QuoteID_Reserved = newQuoteID;
        subCustomFields.ExpectedRenewalDate_Reserved = newRenewalDate.addDays(nbDays);
        subCustomFields.CompensationDaysAtNextRenewal_Reserved = string.valueOf(0);

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.customFields = subCustomFields;
        subscription.subscriptionNumber = subNumber;
        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = accountNumber;
        zSub.subscriptions = listSubscriptions;
        zSub.orderNumber = accountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     *  Méthode pour créer un refund
     * @param currentAmount le montant total
     * @param amountCDF
     * @param amountDollar
     * @param conversionRate taux de change
     * @param originalPaymentSource
     * @return ZuoraObjects.ZuoraRefundPayment
     * */
    public static ZuoraObjects.ZuoraRefundPayment fillCreateRefund(double currentAmount, integer amountCDF, string amountDollar, string conversionRate, string originalPaymentSource, string paymentNumber, boolean fromDistributor){
        //get logged user
        User currentUser = [SELECT Id, Name, USR_DistributeurID__c
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1];

        ZuoraObjects.ZuoraRefundPayment paymentInfo = new ZuoraObjects.ZuoraRefundPayment();
        paymentInfo.methodType = 'Cash';
        paymentInfo.refundDate = string.valueOf(date.today());
        paymentInfo.totalAmount = currentAmount;
        paymentInfo.type = System.label.External_Payment_Type;
        paymentInfo.OperatorAgent_Reserved = currentUser.Name;
        paymentInfo.SourceOperator_Reserved = currentUser.USR_DistributeurID__c;
        if(!fromDistributor) {
            paymentInfo.Source_Reserved = 'Shop';
        } else {
            paymentInfo.Source_Reserved = 'Distributor';
        }
        paymentInfo.DistributorOriginalPaymentSource_Reserved = originalPaymentSource;
        paymentInfo.DistributorPaymentSource_Reserved = paymentNumber;
        if(amountCDF != null && !string.isBlank(string.valueOf(amountCDF)) && amountDollar != null && !string.isBlank(amountDollar)) {
            paymentInfo.HomeCurrency_Reserved = System.label.RDCurrency;
            paymentInfo.HomeCurrencyRate_Reserved = conversionRate.length() > 9?conversionRate.substring(0, 9) : conversionRate;
            paymentInfo.AccountCurrencyAmount_Reserved = amountDollar;
            paymentInfo.HomeCurrencyAmount_Reserved = string.valueOf(amountCDF);
        }

        return paymentInfo;

    }
    /**
     *  Méthode pour créer un usage
     * @param accountId id du compte,
     * @param amount montant,
     * @param chargeNumber charge du produit sur l'abo du distributeur
     * @param renewType upgrade,downgrade ou reabo simple
     * @param subName ,
     * @param paymentNumber numero du paiement du reabo,
     * @param invoiceNumber numero de la facture du reabo,
     * @return ZuoraObjects.ZuoraUsage
     * */
    public static ZuoraObjects.ZuoraUsage fillCreateUsage(string chargeNumber, string renewType, string accountId, double amount, string subName, string renewSubName, string paymentNumber, string invoiceNumber){
        dateTime dt = dateTime.now().dateGMT();
        String dateFormat = dt.format('yyyy-MM-dd');
        String timeFormat = dt.format('hh:mm:ss.ms');

        ZuoraObjects.ZuoraUsage usageInfo = new ZuoraObjects.ZuoraUsage();
        usageInfo.AccountId = accountId;
        usageInfo.SubscriptionNumber = subName;
        usageInfo.Description = renewType;
        usageInfo.InvoiceNumber_Reserved = invoiceNumber;
        usageInfo.PaymentNumber_Reserved = paymentNumber;
        //usageInfo.OrderNumber_Reserved;
        usageInfo.SubscriptionName_Reserved = renewSubName;
        UsageInfo.ChargeNumber = chargeNumber;
        usageInfo.Quantity = amount;
        usageInfo.UOM = 'Each';
        usageInfo.StartDateTime = dateFormat + 'T' + timeFormat + '+01:00';

        return usageInfo;

    }
    /**
     * Methode pour modifier la valeur d'un champs a null
     * @param recordId id de l'enregistrement,
     * @param fieldName le nom des champs,
     * @param ObjectName le nom de l'objet
     * @return ZuoraObjects.ZuoraNullFields
     */
    public static ZuoraObjects.ZuoraNullFields fillNullFields(string recordId, list<string> fieldName, string ObjectName){
        // créér une list d'objet contenant les champs null et l'id de chaque enregistrement
        ZuoraObjects.ZuoraNullFieldsObjects nullObject = new ZuoraObjects.ZuoraNullFieldsObjects ();
        nullObject.Id = recordId;
        nullObject.fieldsToNull = fieldName;

        list<ZuoraObjects.ZuoraNullFieldsObjects> listObjects = new list<ZuoraObjects.ZuoraNullFieldsObjects>();
        listObjects.add(nullObject);

        // créér un objet nullFields ayant le nom de l'objet et la liste  des objets
        ZuoraObjects.ZuoraNullFields nullFields = new ZuoraObjects.ZuoraNullFields();
        nullFields.type  = ObjectName;
        nullFields.objects = listObjects;

        return nullFields;
    }

    /**
     *  Methode pour modifier le champs parent id d'un compte
     * @param accountId id de l'enregistrement,
     * @param parentId id de l'enregistrement parent
     * @return ZuoraObjects.ZuoraNullFields
     */
    public static ZuoraObjects.ZuoraAccount modifyParentId(string accountId, string parentId){

        ZuoraObjects.ZuoraAccount zAcc = new ZuoraObjects.ZuoraAccount ();
        zAcc.existingID = accountId;
        zAcc.parentId = parentId;

        return zAcc;
    }
    /**
     * Méthode pour ajouter les tax
     * @param subId id de l'abonnement
     * @param timbreFiscal
     * @param totalAmount prix total des produits
     */
    public static list<ZuoraObjects.ZuoraOrderAction> addTax(id subId, zqu__productrateplancharge__c timbreFiscal, double totalAmount, date renewalDate){
        list<Zuora__SubscriptionProductCharge__c> subProd = [SELECT Zuora__Zuora_Id__c, Zuora__RatePlanId__c
                                                             FROM Zuora__SubscriptionProductCharge__c
                                                             WHERE Name = :system.label.Rate_Plan_Timbre_Fiscal AND Zuora__Subscription__c = :subId
                                                             LIMIT 1];

        list<ZuoraObjects.ZuoraOrderAction> listOrderAction = new list<ZuoraObjects.ZuoraOrderAction>();

        ZuoraObjects.ZuoraAddProduct addProd = new ZuoraObjects.ZuoraAddProduct();
        addProd.productRatePlanId = timbreFiscal.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

        ZuoraObjects.ZuoraOneTimeTiered oneTimeTiered = new ZuoraObjects.ZuoraOneTimeTiered();
        oneTimeTiered.quantity = totalAmount;

        ZuoraObjects.ZuoraPricing pricing = new ZuoraObjects.ZuoraPricing();
        pricing.oneTimeTiered = oneTimeTiered;

        zuoraObjects.ZuoraChargeOverride chargeOverride = new zuoraObjects.ZuoraChargeOverride();
        chargeOverride.pricing = pricing;
        chargeOverride.productRatePlanChargeId = timbreFiscal.zqu__ZuoraId__c;

        list<zuoraObjects.ZuoraChargeOverride> listChargeOverride = new list<zuoraObjects.ZuoraChargeOverride>();
        listChargeOverride.add(chargeOverride);

        addProd.chargeOverrides = listChargeOverride;

        ZuoraObjects.ZuoraOrderAction zuoraOrderAddProd = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrderAddProd.triggerDates = fillTriggerDates(string.valueOf(renewalDate), false);
        zuoraOrderAddProd.addProduct = addProd;
        zuoraOrderAddProd.type = System.label.Add_Product_Order_Type;

        if(subProd.size() > 0 && subProd != null) {
            //Remove Start Product
            ZuoraObjects.ZuoraRemoveProduct removeProd = new ZuoraObjects.ZuoraRemoveProduct();
            removeProd.ratePlanId = subProd[0].Zuora__RatePlanId__c;

            ZuoraObjects.ZuoraOrderAction zuoraOrderRemoveProd = new ZuoraObjects.ZuoraOrderAction();
            zuoraOrderRemoveProd.triggerDates = fillTriggerDates(string.valueOf(renewalDate), false);
            zuoraOrderRemoveProd.removeProduct = removeProd;
            zuoraOrderRemoveProd.type = System.label.Remove_Product_Order_Type;
            listOrderAction.add(zuoraOrderRemoveProd);
        }
        listOrderAction.add(zuoraOrderAddProd);
        system.debug('in mapper add tax  '+zuoraOrderAddProd);
        return listOrderAction;

    }

    /**
     * Méthode pour résumer un abo suspendu
     * @param accountNumber numero du compte,
     * @param subNumber numero de la souscription,
     * @param quoteID id du devis,
     * @param renewalDate date de renouvellement,
     * @param nbPeriodes nombre de periode a renouvellé
     * @param timbreFiscal
     * @param totalAmount
     * @param subscriptionId
     * @param sequenceNumber
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillRenewSubscriptionWithTax(
        string accountNumber, string subNumber, id quoteID, date renewalDate, integer nbPeriodes,
        zqu__productrateplancharge__c timbreFiscal, double totalAmount, id subscriptionId, string sequenceNumber){

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();

        listZuoraOrder.addAll(addTax(subscriptionId, timbreFiscal, totalAmount, renewalDate));
        //update expected renewal date and quote id on subscription
        ZuoraObjects.ZuoraSubscriptionCustomFields subFields = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subFields.ExpectedRenewalDate_Reserved = renewalDate.addMonths(nbPeriodes);
        subFields.SF_QuoteID_Reserved = quoteID;
        subFields.RenewalSequenceNumber_Reserved = string.valueOf(integer.valueOf(sequenceNumber) + 1);
        subFields.CompensationDaysAtNextRenewal_Reserved = '0';

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.customFields = subFields;
        subscription.subscriptionNumber = subNumber;
        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
        billingProcess.runBilling = true;

        ZuoraObjects.ZuoraBillingOptions zbill = new ZuoraObjects.ZuoraBillingOptions();
        zbill.targetDate = string.valueOf(renewalDate.addMonths(nbPeriodes - 1));
        billingProcess.billingOptions = zbill;

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = accountNumber;
        zsub.processingOptions = billingProcess;
        zSub.subscriptions = listSubscriptions;
        zSub.orderNumber = accountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        return zSub;
    }
    /**
     * Méthode pour remplir la demande de commande pour suspendre l'abo
     * @param sub l'abo,
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillChangeAddressSuspendedSubscription( Zuora__Subscription__c sub){

        ZuoraObjects.ZuoraSuspendAction suspendAction = new ZuoraObjects.ZuoraSuspendAction();
        suspendAction.suspendPolicy = 'Today';
        //suspendAction.suspendPolicy = 'SpecificDate';
        //suspendAction.suspendSpecificDate = string.valueOf(date.today().addDays(3));

        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
        zuoraOrder.type = System.label.Suspend_Subscription_Order_Type;
        ZuoraOrder.suspend = suspendAction;

        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new List<ZuoraObjects.ZuoraOrderAction>();
        listZuoraOrder.add(ZuoraOrder);

        ZuoraObjects.ZuoraSubscriptionCustomFields subFields = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subFields.SuspensionReason_Reserved = 'Move-Requested';

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions = listZuoraOrder;
        subscription.subscriptionNumber = Sub.Zuora__SubscriptionNumber__c;
        subscription.customFields = subFields;

        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);

        ZuoraObjects.ZuoraBillingOptions billingOption = new ZuoraObjects.ZuoraBillingOptions();
        billingOption.targetDate = string.valueOf(sub.ExpectedRenewalDate__c);

        ZuoraObjects.ZuoraProcessingOptions processOption = new ZuoraObjects.ZuoraProcessingOptions();
        processOption.applyCredit = true;
        processOption.runBilling = true;
        processOption.applicationOrder = new list<string> {'CreditMemo'};
        processOption.billingOptions = billingOption;

        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
        zSub.orderDate = string.valueOf(date.today());
        zSub.existingAccountNumber = Sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
        zSub.subscriptions = listSubscriptions;
        zSub.orderNumber = Sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        zSub.processingOptions = processOption;

        return zSub;
    }

    /**
     * Méthode pour ajouter les champs custom aprés le traitement du demenagement
     * @param resumeDate nombre de reabo
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrderSubscription fillMoveCustomField( string resumeDate){
        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomField = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomField.SuspensionReason_Reserved = 'Move-Activated';
        subCustomField.SuspensionResumeDate_Reserved = string.valueOf(resumeDate);
        subscription.customFields = subCustomField;

        return subscription;
    }

    /**
     * Méthode pour remplir les champs custom d'une credit memo
     * @return ZuoraObjects.ZuoraCreditMemo
     * */
    public static ZuoraObjects.ZuoraCreditMemo fillCMCustomFields(){
        //get logged user
        User currentUser = [ SELECT Id, Name, USR_DistributeurID__c, CountryCode
                             FROM User
                             WHERE Id = :UserInfo.getUserId()
                             LIMIT 1 ];

        ZuoraObjects.ZuoraCreditMemo zCM = new ZuoraObjects.ZuoraCreditMemo();
        zCM.OperatorAgent_Reserved = currentUser.Name;
        zCM.SourceOperator_Reserved = currentUser.USR_DistributeurID__c;
        zCM.Source_Reserved = 'Move';
        zCm.TaxAuthStatus_Reserved = 'Not Required';
        //for RDC
        if(currentUser.CountryCode == 'CD') {
            list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                               FROM CurrencyType
                                               WHERE IsoCode = 'USD'];

            zCM.HomeCurrencyRate_Reserved = string.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR)).length() > 9?string.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR)).substring(0, 9) : string.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR));
            zCM.HomeCurrency_Reserved = system.label.RDCurrency;
        }

        return zCM;
    }

    /**
     * Méthode pour remplir les champs custom d'une facture
     * @param onCreate boolean création,
     * @param perpaidPeriods nombre de périodes prépayé
     * @return ZuoraObjects.ZuoraBilling
     * */
    /*public static ZuoraObjects.ZuoraBilling fillResumeInvoiceCustomFields(id userId){
        //get logged user
        User currentUser = [ SELECT Id, Name, USR_DistributeurID__c, countryCode
                             FROM User
                             WHERE Id = :userId
                             LIMIT 1 ];

        ZuoraObjects.ZuoraBilling zBill = new ZuoraObjects.ZuoraBilling();
        zBill.OperatorAgent_Reserved = currentUser.Name;
        zBill.SourceOperator_Reserved = currentUser.USR_DistributeurID__c;

        //for RDC
        if(currentUser.CountryCode == 'CD') {
            list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                               FROM CurrencyType
                                               WHERE IsoCode = 'USD'];

            zBill.HomeCurrencyRate_Reserved = string.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR)).length() > 9?string.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR)).substring(0, 9) : string.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR));
            zBill.HomeCurrency_Reserved = system.label.RDCurrency;
        }

        zBill.Source_Reserved = 'Shop';

        return zBill;
       }*/

    /**
     *  Méthode pour mapper le paiement lors de la création
     * @param zuoraAccountId Id du compte dans zuora,
     * @param amount montant transférer,
     * @param accountCurrency la devise du compte,
     * @return ZuoraObjects.ZuoraPayment
     * */
    public static ZuoraObjects.ZuoraPayment fillCreateTransferedPayment(string zuoraAccountId, double amount, string accountCurrency, string paymentSource, string originalPaymentSource){
        //get logged user
        User currentUser = [SELECT Id, Name, USR_DistributeurID__c, countryCode
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1];
        string paymentMode = 'cash';
        list<mode_de_paiement__mdt> paymentMethod = [SELECT Methode_de_paiement_ID__c, DeveloperName
                                                     FROM mode_de_paiement__mdt
                                                     WHERE DeveloperName = :paymentMode];

        ZuoraObjects.ZuoraPayment paymentInfo = new ZuoraObjects.ZuoraPayment();
        paymentInfo.accountId = zuoraAccountId;
        paymentInfo.Processing_Reserved = 'Batch';

        //for RDC users
        if(currentUser.countryCode == 'CD') {
            list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                               FROM CurrencyType
                                               WHERE IsoCode = 'USD'];
            paymentInfo.HomeCurrency_Reserved = System.label.RDCurrency;
            paymentInfo.HomeCurrencyRate_Reserved = string.valueOf(currencyRate[0].conversionRate).length() > 9?string.valueOf(currencyRate[0].conversionRate).substring(0, 9) : string.valueOf(currencyRate[0].conversionRate);
            paymentInfo.AccountCurrencyAmount_Reserved = string.valueOf(amount);
            paymentInfo.HomeCurrencyAmount_Reserved = '0';
        }
        paymentInfo.currency_toReplace = accountCurrency;
        paymentInfo.amount = amount;
        paymentInfo.effectiveDate = string.valueOf(date.today());
        paymentInfo.type = System.label.External_Payment_Type;
        if(paymentMethod != null && paymentMethod.size() > 0) {
            paymentInfo.paymentMethodId = paymentMethod[0].Methode_de_paiement_ID__c;
        }

        //paymentInfo.OrderNumber_Reserved = orderNumber;
        paymentInfo.OperatorAgent_Reserved = currentUser.Name;
        paymentInfo.SourceOperator_Reserved = currentUser.USR_DistributeurID__c;
        paymentInfo.Source_Reserved = 'Distributor'; //or Distributor??
        paymentInfo.DistributorPaymentSource_Reserved = paymentSource;
        paymentInfo.DistributorOriginalPaymentSource_Reserved = originalPaymentSource;

        return paymentInfo;
    }

    /**
     * Méthode pour remplir la demande de création d'une facture
     * @param listSubId liste des id des souscription,
     * @param activationDate date d'activation,
     * @param perpaidPeriods nombre de mois prépayées
     * @return ZuoraObjects.ZuoraBilling
     * */
    public static ZuoraObjects.ZuoraBilling fillGenerateBillRun(list<string> listSubId){

        ZuoraObjects.ZuoraBilling zBill = new ZuoraObjects.ZuoraBilling();
        zBill.autoPost = true;
        zBill.effectiveDate = string.valueOf(date.today());
        zBill.targetDate = string.valueOf(date.today().addDays(1));
        zBill.subscriptionIds = listSubId;

        return zBill;
    }
    /**
     * Méthode pour remplir la demande d'activation de YouScribe comme preview subscription
     * @param Sub souscription,
     * @param activationDate date d'activation,
     * @param finalDate date d'expiration de l'option YouScribe
     * @param productRP product rate plan charge,
     * @param prePaidPeriod la duree de l'activation YS
     * @param chargeOvrd boolean if the api needs the ChargeOverrides
     * @return ZuoraObjects.ZuoraOrder
     */
    public static ZuoraObjects.ZuoraOrder fillYSPreviewSubscription(Zuora__Subscription__c sub, String activationDate, String finalDate, String removeDate, zqu__productrateplancharge__c productRP, integer prePaidPeriod, boolean chargeOvrd){

         // remove product
         ZuoraObjects.ZuoraRemoveProduct zOrderActionRemoveProduct = new ZuoraObjects.ZuoraRemoveProduct();
         zOrderActionRemoveProduct.uniqueToken = Sub.Name + '/' + activationDate + '/' + removeDate;

         ZuoraObjects.ZuoraOrderAction zSubOrderAction2 = new ZuoraObjects.ZuoraOrderAction();
         zSubOrderAction2.type = 'RemoveProduct';
         zSubOrderAction2.triggerDates = fillTriggerDates(removeDate, false);
         zSubOrderAction2.removeProduct = zOrderActionRemoveProduct;

         // objects needed to create zuora subscription object
         ZuoraObjects.ZuoraBilling zBilling = new ZuoraObjects.ZuoraBilling();
         zBilling.billCycleType = 'ChargeTriggerDay';

         ZuoraObjects.ZuoraChargeOverride zChargeOverride = new ZuoraObjects.ZuoraChargeOverride();
         zChargeOverride.productRatePlanChargeId = productRP.zqu__ZuoraId__c;
         zChargeOverride.billing = zBilling;
         list<ZuoraObjects.ZuoraChargeOverride> listOfZChargeOverrides = new list<ZuoraObjects.ZuoraChargeOverride> {zChargeOverride};

         ZuoraObjects.ZuoraAddProduct zOrderActionAddProduct = new ZuoraObjects.ZuoraAddProduct();
         zOrderActionAddProduct.productRatePlanId = productRP.zqu__ProductRatePlan__r.zqu__ZuoraId__c;
         zOrderActionAddProduct.uniqueToken = Sub.Name + '/' + activationDate + '/' + removeDate;
         if(chargeOvrd) {
             zOrderActionAddProduct.chargeOverrides = listOfZChargeOverrides;
         }

         ZuoraObjects.ZuoraOrderAction zSubOrderAction = new ZuoraObjects.ZuoraOrderAction();
         zSubOrderAction.type = 'AddProduct';
         zSubOrderAction.triggerDates = fillTriggerDates(activationDate, false);
         zSubOrderAction.addProduct = zOrderActionAddProduct;
         list<ZuoraObjects.ZuoraOrderAction> listOfZOrderAction = new list<ZuoraObjects.ZuoraOrderAction> {zSubOrderAction, zSubOrderAction2};

         ZuoraObjects.ZuoraOrderSubscription zOrderSub = new ZuoraObjects.ZuoraOrderSubscription();
         zOrderSub.subscriptionNumber = sub.Name;
         zOrderSub.orderActions = listOfZOrderAction;
         list<ZuoraObjects.ZuoraOrderSubscription> listOfZSubscription = new list<ZuoraObjects.ZuoraOrderSubscription> {zOrderSub};

         list<string> listPreviewType = new List<string> {'BillingDocs'};

         // The specified string should use the standard date format “yyyy-MM-dd”
         // if final date - start date < 1 month --> finalDate = StartDate (-1 month is calculated because the finalDate is sent to Zuora - 1 month)
         date finalDateTDate;
         if(prePaidPeriod != 0) {
             finalDateTDate = Date.valueOf(activationDate).addMonths(prePaidPeriod - 1);
         } else if(sub.ExpectedRenewalDate__c != Date.valueOf(removeDate))  {
             finalDateTDate = Date.valueOf(finalDate);
         } else if(Date.valueOf(activationDate).daysBetween(Date.valueOf(finalDate)) >= 31)  {
             finalDateTDate = Date.valueOf(finalDate).addMonths(-1);
         } else  {
             finalDateTDate = Date.valueOf(activationDate);
         }

         ZuoraObjects.ZuoraPreviewOptions previewOptions = new ZuoraObjects.ZuoraPreviewOptions();
         previewOptions.previewThruType = 'SpecificDate';
         previewOptions.previewTypes = listPreviewType;
         previewOptions.specificPreviewThruDate = string.valueOf(finalDateTDate);
         system.debug('specificPreviewThruDate ' + string.valueOf(finalDateTDate));

         ZuoraObjects.ZuoraOrder previewYSOrder = new ZuoraObjects.ZuoraOrder();
         previewYSOrder.existingAccountNumber = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
         previewYSOrder.orderDate = string.valueOf(date.today());
         previewYSOrder.previewOptions = previewOptions;
         previewYSOrder.subscriptions = listOfZSubscription;

         return previewYSOrder;
    }

    /**
     * Méthode pour remplir la demande d'activation de YouScribe
     * @param Sub souscription,
     * @param activationDate date d'activation,
     * @param finalDate date d'expiration de l'option YouScribe
     * @param productRP product rate plan charge,
     * @param perpaidPeriods nombre de mois prépayées pour l'activation YS
     * @param chargeOvrd boolean if the api needs the ChargeOverrides
     * @return ZuoraObjects.ZuoraOrder
     */
      public static ZuoraObjects.ZuoraOrder fillCreateYSOrdrer(Zuora__Subscription__c Sub, String activationDate, String finalDate, String removeDate, zqu__productrateplancharge__c productRP, integer prePaidPeriod, boolean chargeOvrd){

          // remove product
          ZuoraObjects.ZuoraRemoveProduct zOrderActionRemoveProduct = new ZuoraObjects.ZuoraRemoveProduct();
          zOrderActionRemoveProduct.uniqueToken = Sub.Name + '/' + activationDate + '/' + removeDate;

          ZuoraObjects.ZuoraOrderAction zSubOrderAction2 = new ZuoraObjects.ZuoraOrderAction();
          zSubOrderAction2.type = 'RemoveProduct';
          zSubOrderAction2.triggerDates = fillTriggerDates(removeDate, false);
          zSubOrderAction2.removeProduct = zOrderActionRemoveProduct;

          // add product
          ZuoraObjects.ZuoraBilling zBilling = new ZuoraObjects.ZuoraBilling();
          zBilling.billCycleType = 'ChargeTriggerDay';

          ZuoraObjects.ZuoraChargeOverride zChargeOverride = new ZuoraObjects.ZuoraChargeOverride();
          zChargeOverride.productRatePlanChargeId = productRP.zqu__ZuoraId__c;
          zChargeOverride.billing = zBilling;
          list<ZuoraObjects.ZuoraChargeOverride> listOfZChargeOverrides = new list<ZuoraObjects.ZuoraChargeOverride> {zChargeOverride};

          ZuoraObjects.ZuoraAddProduct zOrderActionAddProduct = new ZuoraObjects.ZuoraAddProduct();
          zOrderActionAddProduct.productRatePlanId = productRP.zqu__ProductRatePlan__r.zqu__ZuoraId__c;
          zOrderActionAddProduct.uniqueToken = Sub.Name + '/' + activationDate + '/' + removeDate;
          if(chargeOvrd) {
              zOrderActionAddProduct.chargeOverrides = listOfZChargeOverrides;
          }

          ZuoraObjects.ZuoraOrderAction zSubOrderAction = new ZuoraObjects.ZuoraOrderAction();
          zSubOrderAction.type = 'AddProduct';
          zSubOrderAction.triggerDates = fillTriggerDates(activationDate, false);
          zSubOrderAction.addProduct = zOrderActionAddProduct;
          list<ZuoraObjects.ZuoraOrderAction> listOfZOrderAction = new list<ZuoraObjects.ZuoraOrderAction> {zSubOrderAction, zSubOrderAction2};

          ZuoraObjects.ZuoraOrderSubscription zOrderSub = new ZuoraObjects.ZuoraOrderSubscription();
          zOrderSub.subscriptionNumber = sub.Name;
          zOrderSub.orderActions = listOfZOrderAction;
          list<ZuoraObjects.ZuoraOrderSubscription> listOfZSubscription = new list<ZuoraObjects.ZuoraOrderSubscription> {zOrderSub};

          // The specified string should use the standard date format “yyyy-MM-dd” month -1
          date finalDateTDate;
          if(prePaidPeriod != 0) {
              finalDateTDate = Date.valueOf(activationDate).addMonths(prePaidPeriod - 1);
          } else if(sub.ExpectedRenewalDate__c != Date.valueOf(removeDate))  {
              finalDateTDate = Date.valueOf(finalDate);
          } else if(Date.valueOf(activationDate).daysBetween(Date.valueOf(finalDate)) >= 31)  {
              finalDateTDate = Date.valueOf(finalDate).addMonths(-1);
          } else  {
              finalDateTDate = Date.valueOf(activationDate);
          }

          ZuoraObjects.ZuoraBillingOptions zbill = new ZuoraObjects.ZuoraBillingOptions();
          zbill.targetDate = string.valueOf(finalDateTDate);
          ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
          billingProcess.runBilling = true;
          billingProcess.billingOptions = zbill;

          ZuoraObjects.ZuoraOrder zOrder = new ZuoraObjects.ZuoraOrder();
          zOrder.orderDate = string.valueOf(date.today());
          zOrder.existingAccountNumber = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
          zOrder.subscriptions = listOfZSubscription;
          zOrder.processingOptions = billingProcess;
          zOrder.orderNumber = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c + '-' + Datetime.now().format('ddMMyyyyhhmm');

          system.debug('zOrder ' + zOrder);

          return zOrder;
       }

    /**
     * Méthode pour remplir la demande d'un upgrade de l'apercu d'un abo
     * @param accountNumber le numéro du compte,
     * @param subNumber le numéro de la souscriptin,
     * @param prodToAddId id du produit a ajouter,
     * @param renewalDate date de renouvellement,
     * @param triggerDate date d'activation,
     * @param chargeId id de la charge du produit fiscal
     * @return ZuoraObjects.ZuoraOrder
     * */
    public static ZuoraObjects.ZuoraOrder fillChangeMaterialPreview(string accountNumber, string subNumber, string prodToAddId, string chargeId,
                                                                    date renewalDate, date triggerDate){

        // objects needed to create zuora subscription object
        ZuoraObjects.ZuoraBilling zBilling = new ZuoraObjects.ZuoraBilling();
        zBilling.billCycleType = 'ChargeTriggerDay';

        ZuoraObjects.ZuoraChargeOverride zChargeOverride = new ZuoraObjects.ZuoraChargeOverride();
        zChargeOverride.productRatePlanChargeId = chargeId;
        zChargeOverride.billing = zBilling;
        list<ZuoraObjects.ZuoraChargeOverride> listOfZChargeOverrides = new list<ZuoraObjects.ZuoraChargeOverride> {zChargeOverride};

        ZuoraObjects.ZuoraAddProduct zOrderActionAddProduct = new ZuoraObjects.ZuoraAddProduct();
        zOrderActionAddProduct.productRatePlanId = prodToAddId;

        ZuoraObjects.ZuoraOrderAction zSubOrderAction = new ZuoraObjects.ZuoraOrderAction();
        zSubOrderAction.type = 'AddProduct';
        zSubOrderAction.triggerDates = fillTriggerDates(string.valueOf(date.today()), false);
        zSubOrderAction.addProduct = zOrderActionAddProduct;
        list<ZuoraObjects.ZuoraOrderAction> listOfZOrderAction = new list<ZuoraObjects.ZuoraOrderAction> {zSubOrderAction};

        ZuoraObjects.ZuoraOrderSubscription zOrderSub = new ZuoraObjects.ZuoraOrderSubscription();
        zOrderSub.subscriptionNumber = subNumber;
        zOrderSub.orderActions = listOfZOrderAction;
        list<ZuoraObjects.ZuoraOrderSubscription> listOfZSubscription = new list<ZuoraObjects.ZuoraOrderSubscription> {zOrderSub};

        list<string> listPreviewType = new List<string> {'BillingDocs'};

        ZuoraObjects.ZuoraPreviewOptions previewOptions = new ZuoraObjects.ZuoraPreviewOptions();
        previewOptions.previewThruType = 'SpecificDate';
        previewOptions.previewTypes = listPreviewType;
        previewOptions.specificPreviewThruDate = string.valueOf(date.today());

        ZuoraObjects.ZuoraOrder previewMaterial = new ZuoraObjects.ZuoraOrder();
        previewMaterial.existingAccountNumber = accountNumber;
        previewMaterial.orderDate = string.valueOf(date.today());
        previewMaterial.previewOptions = previewOptions;
        previewMaterial.subscriptions = listOfZSubscription;

        return previewMaterial;
    }

    /**
     * Méthode pour remplir la demande de chnagement des materiels bundle
     * @param Sub souscription,
     * @param activationDate date d'activation,
     * @param productRP product rate plan charge,
     * @return ZuoraObjects.ZuoraOrder
     */
    public static ZuoraObjects.ZuoraOrder fillChangeMaterialOrdrer(string SubNumber, string AccountNumber,  zqu__productrateplancharge__c productRP){

        // add product
        ZuoraObjects.ZuoraBilling zBilling = new ZuoraObjects.ZuoraBilling();
        zBilling.billCycleType = 'ChargeTriggerDay';

        ZuoraObjects.ZuoraChargeOverride zChargeOverride = new ZuoraObjects.ZuoraChargeOverride();
        zChargeOverride.productRatePlanChargeId = productRP.zqu__ZuoraId__c;
        zChargeOverride.billing = zBilling;
        list<ZuoraObjects.ZuoraChargeOverride> listOfZChargeOverrides = new list<ZuoraObjects.ZuoraChargeOverride> {zChargeOverride};

        ZuoraObjects.ZuoraAddProduct zOrderActionAddProduct = new ZuoraObjects.ZuoraAddProduct();
        zOrderActionAddProduct.productRatePlanId = productRP.zqu__ProductRatePlan__r.zqu__ZuoraId__c;

        ZuoraObjects.ZuoraOrderAction zSubOrderAction = new ZuoraObjects.ZuoraOrderAction();
        zSubOrderAction.type = 'AddProduct';
        zSubOrderAction.triggerDates = fillTriggerDates(string.valueof(date.today()), false);
        zSubOrderAction.addProduct = zOrderActionAddProduct;
        list<ZuoraObjects.ZuoraOrderAction> listOfZOrderAction = new list<ZuoraObjects.ZuoraOrderAction> {zSubOrderAction};

        ZuoraObjects.ZuoraOrderSubscription zOrderSub = new ZuoraObjects.ZuoraOrderSubscription();
        zOrderSub.subscriptionNumber = SubNumber;
        zOrderSub.orderActions = listOfZOrderAction;
        list<ZuoraObjects.ZuoraOrderSubscription> listOfZSubscription = new list<ZuoraObjects.ZuoraOrderSubscription> {zOrderSub};

        ZuoraObjects.ZuoraBillingOptions zbill = new ZuoraObjects.ZuoraBillingOptions();
        zbill.targetDate = string.valueOf(date.today());
        ZuoraObjects.ZuoraProcessingOptions billingProcess = new ZuoraObjects.ZuoraProcessingOptions();
        billingProcess.runBilling = true;
        billingProcess.billingOptions = zbill;

        ZuoraObjects.ZuoraOrder zOrder = new ZuoraObjects.ZuoraOrder();
        zOrder.orderDate = string.valueOf(date.today());
        zOrder.existingAccountNumber = AccountNumber;
        zOrder.subscriptions = listOfZSubscription;
        zOrder.processingOptions = billingProcess;
        zOrder.orderNumber = AccountNumber + '-' + Datetime.now().format('ddMMyyyyhhmm');

        system.debug('zOrder ' + zOrder);

        return zOrder;
    }
}