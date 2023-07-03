public with sharing class BundleCMapper {
    /**
     * Fix Values:
     * Partner Id = GVA,
     * User Id = WS_GVA,
     * broadcastVectorId = SAT,
     * commercialOperator = GVA
     * salesDevice = PARTENAIRE (except for modifyOffer And Renwew --> salesDevice = BACKOFFICE)
     */

    public static String thePartnerId = System.Label.CBundle_PartnerId;

    /**
     * Méthode pour remplir la demande de commande de création d'un abo
     * @param currentAccount le compte,
     * @param contact
     * @param mainSub
     * @param prepaidPeriod
     * @return CBundleObjects.CESAR_SUBSCRIPTION
     * */
    public static CBundleObjects.CESAR_SUBSCRIPTION fillCreateSubscription(Account currentAccount, Contact contact, Zuora__Subscription__c mainSub, integer prepaidPeriod,
                                                                           string offerName, list<String> offerOptions, list<equipment__c> listEquipment) {

        String phoneCode = '';
        switch on currentAccount.BillingCountryCode {
            when 'CI' {
                phoneCode = '00225';
            }
        }
        CBundleObjects.SubscriptionObject sub = new CBundleObjects.SubscriptionObject();
        Distributor_And_Internet_Provider__mdt distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c
                                                                         FROM Distributor_And_Internet_Provider__mdt
                                                                         WHERE Country_Code__c = :currentAccount.BillingCountryCode];
        CBundleObjects.PersonObject personObj = new CBundleObjects.PersonObject();
        CBundleObjects.PhoneObject phoneObj = new CBundleObjects.PhoneObject();
        CBundleObjects.AddressObject addressInfo = new CBundleObjects.AddressObject();
        CBundleObjects.EmailObject emailObj = new CBundleObjects.EmailObject();

        personObj.externalClientId = mainSub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
        if(currentAccount.IsPersonAccount) {

            personObj.civility = currentAccount.Salutation == null?null : (currentAccount.Salutation.contains('.')?currentAccount.Salutation.replace('.', '') : currentAccount.Salutation);
            personObj.firstName = currentAccount.FirstName;
            personObj.lastName = currentAccount.LastName;

            if(currentAccount.Phone != null && !string.isBlank(currentAccount.Phone)) {
                phoneObj.phoneNumber = phoneCode + currentAccount.Phone;
                phoneObj.phoneType = 'MOBILE1';
                list<CBundleObjects.PhoneObject> listPhoneObj = new list<CBundleObjects.PhoneObject>();
                listPhoneObj.add(phoneObj);
                sub.phones = listPhoneObj;
            }

            addressInfo.city = currentAccount.QU_Quartier__c;
            addressInfo.countryId = currentAccount.BillingCountryCode;
            addressInfo.street2 = currentAccount.BillingStreet == null?currentAccount.BillingCity : currentAccount.BillingStreet;

            emailObj.email = currentAccount.personEmail;
            emailObj.emailType = 'MAIN';
        } else {
            personObj.civility = contact.Salutation == null?null : (contact.Salutation.contains('.')?contact.Salutation.replace('.', '') : contact.Salutation);
            personObj.firstName = contact.FirstName;
            personObj.lastName = contact.LastName;

            if(contact.Phone != null && !string.isBlank(contact.Phone)) {
                phoneObj.phoneNumber =  phoneCode + contact.Phone;
                phoneObj.phoneType = 'MOBILE1';
                list<CBundleObjects.PhoneObject> listPhoneObj = new list<CBundleObjects.PhoneObject>();
                listPhoneObj.add(phoneObj);
                sub.phones = listPhoneObj;
            }

            addressInfo.city = contact.MailingCity;
            addressInfo.countryId = contact.MailingCountryCode;
            addressInfo.street3 = contact.MailingStreet == null?contact.MailingCity : contact.MailingStreet;

            emailObj.email = contact.email;
        }

        list<CBundleObjects.EmailObject> listEmailObj = new list<CBundleObjects.EmailObject>();
        listEmailObj.add(emailObj);

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = distributorAndProvider.Internet_Provider_Id__c;

        list<CBundleObjects.EquipmentCommon> listEquip = new list<CBundleObjects.EquipmentCommon>();
        for(equipment__c eq : listEquipment) {
            CBundleObjects.EquipmentCommon equip = new CBundleObjects.EquipmentCommon();
            equip.equipmentId = eq.Equipment_Id__c;
            equip.equipmentType = eq.Equipment_Type__c;
            listEquip.add(equip);
        }

        CBundleObjects.ProductObject prod = new CBundleObjects.ProductObject();
        prod.mainOffer = offerName;
        prod.options = offerOptions;

        datetime dt = Datetime.now();

        CBundleObjects.ContractObject contractObj = new CBundleObjects.ContractObject();
        contractObj.duration = prepaidPeriod;
        contractObj.externalContractId = mainSub.SUB_Subscription_Number__c == null?mainSub.Name : mainSub.Name + '-' + mainSub.SUB_Subscription_Number__c;
        contractObj.startDate = string.valueOf(mainSub.Prior_expedted_renewal_Date__c != null ? mainSub.Prior_expedted_renewal_Date__c : Date.Today()) + 'T00:00:00.000Z';
        contractObj.broadcastVectorId = 'SAT';
        contractObj.commercialOperator = 'GVA';
        contractObj.fifthCategoryIndicator = false;
        contractObj.dateToDateIndicator = true;
        contractObj.meaningOfPayment = '18';
        contractObj.products = prod;

        sub.person = personObj;
        sub.providerInfos = provInfo;
        sub.equipments = listEquip;
        sub.address = addressInfo;
        sub.email = listEmailObj;
        sub.contract = contractObj;

        CBundleObjects.CESAR_SUBSCRIPTION cesarSub = new CBundleObjects.CESAR_SUBSCRIPTION();
        cesarSub.subscription = sub;
        cesarSub.creationDate = string.valueOf(date.today()) + 'T00:00:00.000Z';
        cesarSub.partnerId = thePartnerId;
        cesarSub.salesDevice = 'PARTENAIRE';
        cesarSub.userId = 'WS_GVA';
        cesarSub.transactionId = mainSub.Name + '-' + String.valueOf(Datetime.now()).replaceAll('[^a-zA-Z0-9]',''); // 2023-06-06 13:20:41

        return cesarSub;
    }

    /**
     * Méthode pour remplir la demande de commande de l'annulation d'un abo
     * @param cancelReason raison d'annulation,
     * @param sub
     * @return CBundleObjects.CESAR_CANCELLATION
     * */
    public static CBundleObjects.CESAR_CANCELLATION fillCancelSubscription(Zuora__Subscription__c sub, string cancelReason) {
        user currentUser = [SELECT countryCode
                            FROM User
                            WHERE Id = : UserInfo.getUserId()];
        Distributor_And_Internet_Provider__mdt distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c
                                                                         FROM Distributor_And_Internet_Provider__mdt
                                                                         WHERE Country_Code__c = :currentUser.countryCode];

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = distributorAndProvider.Internet_Provider_Id__c;
        dateTime dt = Datetime.now();

        CBundleObjects.CESAR_CANCELLATION cancelSub = new CBundleObjects.CESAR_CANCELLATION();
        cancelSub.providerInfos = provInfo;
        cancelSub.cancellationDate = string.valueOf(date.today()) + 'T00:00:00.000Z';
        cancelSub.externalContractId = sub.SUB_Bundle_Contract_Id__c;
        cancelSub.cancelReason = cancelReason;
        cancelSub.transactionId = sub.SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        cancelSub.userId = 'WS_GVA';
        cancelSub.partnerId = thePartnerId;
        cancelSub.externalClientId = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;//sub.account.accountNumer ==> zuora

        return cancelSub;
    }

    /**
     * Méthode pour remplir la demande de commande d'un reabo'
     * @param sub la souscription,
     * @param prepaidPeriod
     * @return CBundleObjects.CESAR_RENEWAL
     * */
    public static CBundleObjects.CESAR_RENEWAL fillRenewSubscription(Zuora__Subscription__c sub, integer prepaidPeriod, string offerName, list<string> offerOptions) {
        user currentUser = [SELECT countryCode
                            FROM User
                            WHERE Id =:UserInfo.getUserId()];

        Distributor_And_Internet_Provider__mdt distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c
                                                                         FROM Distributor_And_Internet_Provider__mdt
                                                                         WHERE Country_Code__c = :currentUser.countryCode];

        CBundleObjects.ProductObject product = new CBundleObjects.ProductObject();
        product.mainOffer = offerName;
        product.options = offerOptions;

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = distributorAndProvider.Internet_Provider_Id__c;

        CBundleObjects.CESAR_RENEWAL renewSub = new CBundleObjects.CESAR_RENEWAL();
        renewSub.products = product;
        renewSub.providerInfos = provInfo;
        renewSub.transactionId = sub.SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        renewSub.externalContractId = sub.SUB_Bundle_Contract_Id__c;
        renewSub.userId = 'WS_GVA';
        renewSub.partnerId = thePartnerId;
        renewSub.salesDevice = 'BACKOFFICE';
        renewSub.duration = prepaidPeriod;
        renewSub.externalClientId = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;

        return renewSub;
    }

    /**
     * Méthode pour remplir la demande de pour suspendre un abo
     * @param sub la souscription,
     * @param suspensionReason
     * @param suspensionDate
     * @return CBundleObjects.CESAR_SUSPENSION
     * */
    public static CBundleObjects.CESAR_SUSPENSION fillSuspendSubscription(Zuora__Subscription__c sub, String suspensionReason, String suspensionDate) {
        user currentUser = [SELECT countryCode
                            FROM User
                            WHERE Id =:UserInfo.getUserId()];

        Distributor_And_Internet_Provider__mdt distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c
                                                                         FROM Distributor_And_Internet_Provider__mdt
                                                                         WHERE Country_Code__c = :currentUser.countryCode];

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = distributorAndProvider.Internet_Provider_Id__c;

        CBundleObjects.CESAR_SUSPENSION suspendSub = new CBundleObjects.CESAR_SUSPENSION();
        suspendSub.providerInfos = provInfo;
        suspendSub.transactionId = sub.SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        suspendSub.externalContractId = sub.SUB_Bundle_Contract_Id__c;
        suspendSub.userId = 'WS_GVA';
        suspendSub.partnerId = thePartnerId;
        suspendSub.salesDevice = 'PARTENAIRE';
        suspendSub.suspensionDate = suspensionDate;
        suspendSub.suspensionReason = suspensionReason;
        suspendSub.externalClientId = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;

        return suspendSub;
    }

    /**
     * Méthode pour remplir la demande de pour activer un abo
     * @param sub la souscription,
     * @param distributorId
     * @param providerId
     * @param activationDate
     * @return CBundleObjects.CESAR_ACTIVATION
     * */
    public static CBundleObjects.CESAR_ACTIVATION fillActivateSubscription( Zuora__Subscription__c sub, string distributorId, string providerId, date activationDate) {

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorId;//distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = providerId;//distributorAndProvider.Internet_Provider_Id__c;

        CBundleObjects.CESAR_ACTIVATION activateSub = new CBundleObjects.CESAR_ACTIVATION();
        activateSub.providerInfos = provInfo;
        activateSub.externalContractId = sub.SUB_Bundle_Contract_Id__c;
        activateSub.userId = 'WS_GVA';
        activateSub.partnerId = thePartnerId;
        activateSub.activationDate = string.valueOf(activationDate) + 'T00:00:00.000Z';
        activateSub.transactionId = sub.SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        activateSub.salesDevice =  'PARTENAIRE';
        activateSub.externalClientId = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;

        return activateSub;
    }

    /**
     * Méthode pour remplir la demande pour modifier l'offre existant
     * @param sub la souscription,
     * @param offerName
     * @param offerOptions
     * @return CBundleObjects.CESAR_MODIFYOFFER
     * */
    public static CBundleObjects.CESAR_MODIFYOFFER fillModifyOffer(Zuora__Subscription__c sub, string offerName, list<String> offerOptions) {
        user currentUser = [SELECT countryCode
                            FROM User
                            WHERE Id =:UserInfo.getUserId()];
        Distributor_And_Internet_Provider__mdt distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c
                                                                         FROM Distributor_And_Internet_Provider__mdt
                                                                         WHERE Country_Code__c = :currentUser.countryCode];

        CBundleObjects.ProductObject product = new CBundleObjects.ProductObject();
        product.mainOffer = offerName;
        product.options = offerOptions;

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = distributorAndProvider.Internet_Provider_Id__c;

        CBundleObjects.CESAR_MODIFYOFFER modifyOffer = new CBundleObjects.CESAR_MODIFYOFFER();
        modifyOffer.products = product;
        modifyOffer.providerInfos = provInfo;
        modifyOffer.transactionId = sub.SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        modifyOffer.externalContractId = sub.SUB_Bundle_Contract_Id__c;
        modifyOffer.userId = 'WS_GVA';
        modifyOffer.partnerId = thePartnerId;
        modifyOffer.salesDevice = 'PARTENAIRE';
        modifyOffer.externalClientId = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;

        return modifyOffer;
    }

    /**
     * Méthode pour remplir la demande pour changer le materiel
     * @param sub la souscription,
     * @param equipmentId
     * @param equipmentType
     * @param oldEquipmentId
     * @param oldEquipmentType
     * @return CBundleObjects.CESAR_EXCHANGE_MATERIAL
     * */
    public static CBundleObjects.CESAR_EXCHANGE_MATERIAL fillExchangeMaterial(Zuora__Subscription__c sub, string equipmentId, String equipmentType, string oldEquipmentId, String oldEquipmentType) {
        user currentUser = [SELECT countryCode
                            FROM User
                            WHERE Id =:UserInfo.getUserId()];
        Distributor_And_Internet_Provider__mdt distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c
                                                                         FROM Distributor_And_Internet_Provider__mdt
                                                                         WHERE Country_Code__c = :currentUser.countryCode];

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = distributorAndProvider.Internet_Provider_Id__c;

        CBundleObjects.OldEquipment oldEquip = new CBundleObjects.OldEquipment();
        oldEquip.equipmentId = oldEquipmentId;
        oldEquip.equipmentType = oldEquipmentType;

        CBundleObjects.NewEquipment newEquip = new CBundleObjects.NewEquipment();
        newEquip.equipmentId = equipmentId;
        newEquip.equipmentType = equipmentType;

        CBundleObjects.CESAR_EXCHANGE_MATERIAL exchangeMaterial = new CBundleObjects.CESAR_EXCHANGE_MATERIAL();
        exchangeMaterial.newEquipment = newEquip;
        exchangeMaterial.oldEquipment = oldEquip;
        exchangeMaterial.providerInfos = provInfo;
        exchangeMaterial.partnerId = thePartnerId;
        exchangeMaterial.salesDevice = 'PARTENAIRE';
        exchangeMaterial.userId = 'WS_GVA';
        exchangeMaterial.transactionId = sub.SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        exchangeMaterial.externalContractId = sub.SUB_Bundle_Contract_Id__c;
        exchangeMaterial.externalClientId = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;

        return exchangeMaterial;
    }

    /**
     * Méthode pour remplir la demande de commande d'un reabo'
     * @param currentAccount le compte,
     * @param contact
     * @param sub
     * @return CBundleObjects.CESAR_FAST_REACTIVATION
     * */
    public static CBundleObjects.CESAR_FAST_REACTIVATION fillFastRenewSubscription(Zuora__Subscription__c sub) {
        user currentUser = [SELECT countryCode
                            FROM User
                            WHERE Id =:UserInfo.getUserId()];
        Distributor_And_Internet_Provider__mdt distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c
                                                                         FROM Distributor_And_Internet_Provider__mdt
                                                                         WHERE Country_Code__c = :currentUser.countryCode];

        CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
        provInfo.distributorId = distributorAndProvider.Distributor_Id__c;
        provInfo.internetProviderId = distributorAndProvider.Internet_Provider_Id__c;

        CBundleObjects.CESAR_FAST_REACTIVATION fastRenew = new CBundleObjects.CESAR_FAST_REACTIVATION();
        fastRenew.providerInfos = provInfo;
        fastRenew.transactionId = sub.SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
        fastRenew.externalContractId = sub.SUB_Bundle_Contract_Id__c;
        fastRenew.userId = 'WS_GVA';
        fastRenew.partnerId = thePartnerId;
        fastRenew.salesDevice = 'PARTENAIRE';
        fastRenew.externalClientId = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;

        return fastRenew;
    }

    /**
     * Méthode pour remplir la demande de modifier un contact
     * @param currentAccount le compte,
     * @param map AccountId --> sub
     * @return CBundleObjects.CESAR_MODIFY_CONTACTS
     * */
    public static list<CBundleObjects.CESAR_MODIFY_CONTACTS> fillmodifyContactSubscription(Map<Id, Account> mapOfAccount, Map<Id, Zuora__Subscription__c> mapOfAccIdSubs) {

        List<CBundleObjects.CESAR_MODIFY_CONTACTS> listOfCModifyContact = new List<CBundleObjects.CESAR_MODIFY_CONTACTS>();
        Map<String, Distributor_And_Internet_Provider__mdt> mapOfCountryCodeDist = new Map<String, Distributor_And_Internet_Provider__mdt>();

        List<Distributor_And_Internet_Provider__mdt> distributorAndProvider = [SELECT Distributor_Id__c, Internet_Provider_Id__c, Country_Code__c
                                                                               FROM Distributor_And_Internet_Provider__mdt];

        for(Distributor_And_Internet_Provider__mdt dist : distributorAndProvider) {
            mapOfCountryCodeDist.put(dist.Country_Code__c, dist);
        }

        for(Account acc : mapOfAccount.values()) {
            CBundleObjects.CESAR_MODIFY_CONTACTS modifyContact = new CBundleObjects.CESAR_MODIFY_CONTACTS();
            CBundleObjects.ProviderInfosObject provInfo = new CBundleObjects.ProviderInfosObject();
            provInfo.distributorId = mapOfCountryCodeDist.get(acc.BillingCountryCode).Distributor_Id__c;
            provInfo.internetProviderId = mapOfCountryCodeDist.get(acc.BillingCountryCode).Internet_Provider_Id__c;

            CBundleObjects.PersonObject personObj = new CBundleObjects.PersonObject();
            personObj.civility = acc.Salutation;
            personObj.firstName = acc.FirstName;
            personObj.lastName = acc.LastName;
            if(acc.personMobilePhone != null && !string.isBlank(acc.personMobilePhone)) {
                CBundleObjects.PhoneObject phoneObj = new CBundleObjects.PhoneObject();
                phoneObj.phoneNumber = acc.personMobilePhone;
                list<CBundleObjects.PhoneObject> listPhoneObj = new list<CBundleObjects.PhoneObject>();
                listPhoneObj.add(phoneObj);
                modifyContact.phones = listPhoneObj;
            }

            CBundleObjects.AddressObject addressInfo = new CBundleObjects.AddressObject();
            addressInfo.city = acc.BillingCity;
            addressInfo.countryId = acc.BillingCountryCode;
            addressInfo.street2 = acc.BillingStreet == null?acc.BillingCity : acc.BillingStreet;

            CBundleObjects.EmailObject emailObj = new CBundleObjects.EmailObject();
            emailObj.email = acc.personEmail;
            emailObj.emailType = 'MAIN';
            list<CBundleObjects.EmailObject> listEmailObj = new list<CBundleObjects.EmailObject>();
            listEmailObj.add(emailObj);

            modifyContact.externalClientId = mapOfAccIdSubs.get(acc.Id).Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
            modifyContact.externalContractId = mapOfAccIdSubs.get(acc.Id).SUB_Bundle_Contract_Id__c;
            modifyContact.transactionId = mapOfAccIdSubs.get(acc.Id).SUB_Bundle_Contract_Id__c + '-' + Datetime.now().format('ddMMyyyyhhmm');
            modifyContact.userId = 'WS_GVA';
            modifyContact.partnerId = thePartnerId;
            modifyContact.salesDevice = 'BACKOFFICE';
            modifyContact.providerInfos = provInfo;
            modifyContact.person = personObj;
            modifyContact.address = addressInfo;
            modifyContact.email = listEmailObj;

            listOfCModifyContact.add(modifyContact);
        }

        return listOfCModifyContact;
    }

    /**
     * Méthode pour remplir la demande de modifier un contact
     * @param 
     * @param
     * @return list of CBundleObjects.ELIGIBILITY_MIGRATION
    * */
    public static List<CBundleObjects.ELIGIBILITY_MIGRATION> fillEligibilityMigration(List<String> listOfEquipmentsId){

        List<CBundleObjects.ELIGIBILITY_MIGRATION> listOfEligMigrationObjects = new List<CBundleObjects.ELIGIBILITY_MIGRATION>();

        for(String equip : listOfEquipmentsId){

            CBundleObjects.ELIGIBILITY_MIGRATION eligMigration = new CBundleObjects.ELIGIBILITY_MIGRATION();

            eligMigration.partnerIdId = thePartnerId;
            eligMigration.equipmentId = equip;

            listOfEligMigrationObjects.add(eligMigration);
        }
        
        return listOfEligMigrationObjects;
    }

    /**
     * Méthode pour envoyer la demande de migration
     * @param listOfSubs list of subscription
     * @return list of CBundleObjects.REQUEST_MIGRATION
    * */
    public static CBundleObjects.REQUEST_MIGRATION fillRequestMigration(Zuora__Subscription__c sub, String prepaidPeriod, String offerValue, Boolean adultContent, list<String> options, String eqipId){

        CBundleObjects.REQUEST_MIGRATION requMigration = new CBundleObjects.REQUEST_MIGRATION();

        // map utiliser pour relier chaque country avec le numero de ditributeur
        Map<String, Distributor_And_Internet_Provider__mdt> mapOfCountryCodeDist = new Map<String, Distributor_And_Internet_Provider__mdt>();

        List<Distributor_And_Internet_Provider__mdt> distributorAndProvider = Distributor_And_Internet_Provider__mdt.getAll().values();

        for(Distributor_And_Internet_Provider__mdt dist : distributorAndProvider) {
            mapOfCountryCodeDist.put(dist.Country_Code__c, dist);
        }

        if(sub != null){

            CBundleObjects.PartnerObject partner = new CBundleObjects.PartnerObject();
            CBundleObjects.ContractObject contract = new CBundleObjects.ContractObject();
            CBundleObjects.ProductObjectMigration product = new CBundleObjects.ProductObjectMigration();
    
            partner.partnerIdId  = thePartnerId;
            partner.transactionId  = sub.Name + '-' + String.valueOf(Datetime.now()).replaceAll('[^a-zA-Z0-9]','');
            partner.internetProviderId  =  mapOfCountryCodeDist.get(sub.Zuora__Account__r.BillingCountryCode).Internet_Provider_Id__c; // (GVA-CountryCode)
            partner.externalPersonId  = sub.Zuora__CustomerAccount__r.Zuora__AccountNumber__c;
            partner.externalContractId  = sub.SUB_Subscription_Number__c == null? sub.Name : sub.Name + '-' + sub.SUB_Subscription_Number__c;
    
            // contract.startDate = sub.SUB_Activation_Date__c != null ? String.valueof(sub.SUB_Activation_Date__c) : null; // <<<<<<<>>>>>>>> Eliminated
            contract.duration = Integer.valueOf(prepaidPeriod);
            contract.broadcastVectorId = 'SAT';
            contract.saleGroupId = 'GVA'; // GVA fix
            contract.dateToDate = true; // in our case always true
    
            product.offerCode = offerValue; // example: 10GVAAC|ACDD
            product.adultContent = adultContent; // (default true) 
            product.options = options != null && options.size() > 0 ? options : null; 
    
            requMigration.partner  = partner;
            requMigration.contract  = contract;
            requMigration.product  = product;
            requMigration.distributorId  = mapOfCountryCodeDist.get(sub.Zuora__Account__r.BillingCountryCode).Distributor_Id__c;
            requMigration.equipmentId  = eqipId;
        }

        return requMigration;
    }

    /**
     * Méthode pour remplir la demande d'annulation d'une migration'
     * @param orderId returned in the migration response
     * @return CBundleObjects.CANCEL_MIGRATIION
    * */
    public static CBundleObjects.CANCEL_MIGRATIION fillCancelMigration(String orderId) {

        CBundleObjects.CANCEL_MIGRATIION cancelMigration = new CBundleObjects.CANCEL_MIGRATIION();
        cancelMigration.orderId = orderId;

        return cancelMigration;
    }

    /**
     * Méthode pour remplir la demande de modifier un contact
     * @param 
     * @param
     * @return list of CBundleObjects.REQUEST_MIGRATION
    * */
    public static list<CBundleObjects.PERSON_IDENTIFICATION> fillPersonIdentification() {

        list<CBundleObjects.PERSON_IDENTIFICATION> listOfPersonIdentification = new list<CBundleObjects.PERSON_IDENTIFICATION>();

        CBundleObjects.PERSON_IDENTIFICATION personIdentification = new CBundleObjects.PERSON_IDENTIFICATION();
        CBundleObjects.PartnerObject partner = new CBundleObjects.PartnerObject();
        CBundleObjects.identificationKeyObject identificationKey = new CBundleObjects.identificationKeyObject();

        partner.internetProviderId = '';
        partner.externalPersonId = '';

        identificationKey.equipmentId = '';
        identificationKey.phone = '';
        identificationKey.email = '';

        personIdentification.partner = partner;
        personIdentification.identificationKey = identificationKey;

        listOfPersonIdentification.add(personIdentification);


        return listOfPersonIdentification;
    } 
}