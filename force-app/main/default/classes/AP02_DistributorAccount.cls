public without Sharing class AP02_DistributorAccount {
    /**
     * Methode utilisée pour récupérer les Product Rate Plan de type ayant la categorie 'Distributor' dans un produit
     * @return List<zqu__ProductRatePlan__c> Une liste de Product Rate Plan Distributeurr qui existent dans l'environnement
     */
    @AuraEnabled(cacheable = true)
    public static List<zqu__ProductRatePlan__c> getDistributorProductRatePlansList() {

        Id pbId = ZuoraSubscriptionActions.getUserPricebookID(Id.valueOf(UserInfo.getUserId()));

        if(pbId != null) {
            // Check if the Price Book is shared with the current User
            String currentUserID = UserInfo.getUserId();
            UserRecordAccess accessCheck  = [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = :currentUserID AND RecordId = :pbId];
            if(accessCheck.HasReadAccess != false) {
                // category specified for distributors only
                string filterCategory = 'Distributor';

                Id productId = [SELECT Product2Id
                                FROM PriceBookEntry
                                WHERE Pricebook2Id = : pbId AND isActive = true
                                ORDER BY Product2.Name
                                LIMIT 1].Product2Id;

                return [ SELECT Id, Name, zqu__Product__r.Name, zqu__ZuoraId__c, Type__c, Category__c
                         FROM zqu__ProductRatePlan__c
                         WHERE zqu__Deleted__c = FALSE AND zqu__Product__c = : productId AND Category__c = : filterCategory];  /*AND zqu__Product__c IN (SELECT Product2Id
                                                                                                                                  LIMIT 1)*/
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    /**
     * Methode pour crée une souscription dans zuora a partir du quote
     * <p>
     * @param AccountId  Id du compte distributeur
     * @return resultat de l'appel API
     */
    @AuraEnabled
    public static string createDistributorSubscription(Id AccountId, string selectedJSON) {

        set<Log__c> setLogs = new set<Log__c>();
        list<Log__c> listLogs = new list<Log__c>();
        list<String> listSubProduct = new list<String>();
        string previewOrder;

        //get all info nedeed to create a sub
        Account currentAccount = [SELECT Id, ParentId, Name, LastName, FirstName, currencyIsoCode, BillingCity,
                                  ACC_Eligible__c, ACC_Entreprise__c, PersonMobilePhone, ACC_Distributor_Number__c,
                                  RecordType.DeveloperName, ACC_TIN__c
                                  FROM Account
                                  WHERE Id = :AccountId];

        string parentAccountId = null;
        // Check if a Parent Account Exist and get Zuora Id
        if(Account.ParentId != null) {
            list<Zuora__CustomerAccount__c> listBillingAccount = [SELECT Zuora__Account__c, Zuora__Zuora_Id__c, name
                                                                  FROM Zuora__CustomerAccount__c
                                                                  WHERE Zuora__Account__c  = :currentAccount.ParentId];

            if(listBillingAccount.size() > 0 && listBillingAccount != null) {
                parentAccountId = listBillingAccount[0].Zuora__Zuora_Id__c;
            }
        }

        list<Contact> listContacts = [SELECT id, FirstName, LastName, Email, MailingCity, MailingCountry, MailingPostalCode, MailingStreet, MailingCountryCode, MailingState, currencyISOCode
                                      FROM contact
                                      WHERE AccountId = :AccountId
                                      ORDER BY Title DESC];

        HttpResponse response;
        if(listContacts.size() > 0 && listContacts != null && currentAccount.RecordType.DeveloperName == System.label.Distributor_RecordType) {
            
            // get Zuora ID of the selected product
            List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(selectedJSON);
            for(Object fld : fieldList) {
                Map<String, Object> data = (Map<String, Object>) fld;
                listSubProduct.add((String)data.get('zqu__ZuoraId__c'));
            }

            // try {
            //     boolean isRDC = ZuoraSubscriptionActions.checkRDCUser();
            // } catch (Exception e) {
            //     system.debug(e.getLineNumber() + ': '+ e.getMessage());
            // }

            // Create zuora order
            ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();
            zSub = ZuoraMapper.fillCreateOrder(null, currentAccount, listSubProduct, '0', null, null, listContacts[0], null, parentAccountId);
            
            system.debug('Zuora body: '+zSub);
            try {
                // Send request to create order
                if(zSub != null) {
                    response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.NEW_SUBSCRIPTION);
                }
                ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                setLogs.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), AccountId, null, orderResponse.subscriptionNumbers == null? null : orderResponse.subscriptionNumbers[0],
                                                                    ZuoraObjects.ordersAPIUrl, response.getBody(), orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));
                system.debug('Zuora response: '+response.getBody());
                orderResponse.zuoraLogs = setLogs;
                
                if(orderResponse.success) {
                    // get distributor profile id "UTILISATEUR DU POTAIL DISTRIBUTEURS"
                    Profile distributorProfile = [SELECT Id FROM Profile WHERE Name = : System.label.Distributor_Profile].get(0);
                    string alias;
                    list<User> listUsers = new list<User>();
                    // create Users fo each contact
                    for(contact con : listContacts) {

                        User newUser = new User();
                        if(String.isNotBlank(con.firstName) && String.isNotBlank(con.lastName)) {
                            Integer lengthAlias = Math.min(con.lastName.length(), 7);

                            alias = con.firstName.substring(0, 1).toLowerCase() + con.lastName.substring(0, lengthAlias).toLowerCase();
                        }
                        if(String.isBlank(con.firstName) && String.isNotBlank(con.lastName)) {
                            Integer lengthAlias = Math.min(con.lastName.length(), 8);

                            alias = con.lastName.substring(0, lengthAlias).toLowerCase();
                        }

                        newUser = createDistributorUser (con, currentAccount, alias);
                        listUsers.add(newUser);
                    }

                    try {
                        if(listUsers.size() > 0 && listUsers != null) {
                            insert listUsers;
                        }
                    }
                    catch(Exception e) {
                        system.debug(e.getLineNumber() + ': '+ e.getMessage());
                    }
                }
                return JSON.serialize(orderResponse, true);
            } catch(Exception e) {
                system.debug('Create subscription error ' + e.getLineNumber() + ' : ' + e.getMessage() );
                throw new AuraHandledException(e.getMessage());
            }
        } else {
            return System.label.Empty_contact;
        }
    }
    public static user createDistributorUser (contact contact, account currentAccount, string alias){
        Profile distributorProfile = [SELECT Id FROM Profile WHERE Name = :System.label.Distributor_Profile].get(0);
        User newUser = new User(
            alias = alias,//CreateUserHandler.setUserAlias(listContacts[0].FirstName, listContacts[0].LastName),
            email = contact.Email == null?system.label.NOEMAIL_GVA_AFRICA : contact.Email,
            Street = contact.MailingStreet,
            City = contact.MailingCity,
            State = contact.MailingState,
            PostalCode = contact.MailingPostalCode,
            emailencodingkey = 'UTF-8',
            // Suffix = acct.suffix,
            firstname = contact.FirstName,
            lastname = contact.LastName,
            // middleName = acct.middleName,
            languageLocaleKey = UserCreateUpdateUtils.setLanguageLocaleKey(contact.MailingCountryCode),
            localeSidKey = UserCreateUpdateUtils.setLocalSideKey(contact.MailingCountryCode),
            TimeZoneSidKey = UserCreateUpdateUtils.setTimeZoneSidKey(contact.MailingCountryCode),
            country = contact.MailingCountry,
            countryCode = contact.MailingCountryCode,
            contactId = contact.Id,
            username = contact.FirstName.replaceAll(' ', '') + '.' + contact.LastName.replaceAll(' ', '') + '@distributeur.com',
            ProfileId = distributorProfile.Id,
            DefaultCurrencyIsoCode = contact.CurrencyIsoCode,
            // MobilePhone = userMobilePhone,
            //Phone = UserCreateUpdateUtils.setPhone(acct.PersonMobilePhone, acct.Phone, acct.ACC_Indicatif__c),
            Pays_Mapbox__c = contact.MailingCountryCode,
            UserRoleId = null,
            IsActive = true,
            USR_DistributeurID__c = currentAccount.ACC_Distributor_Number__c
        );
        return newUser;
    }

    /**
     * Méthode pour récuperer tous les sous distributeur d'un grossiste
     * @param distName nom du sous distributeur
     * @param distributorId current Distributor Id
     */
    @AuraEnabled
    public static list<Account> getListDistributors(string distName, id distributorId){
        try {
            string searchKey = '%' + distName + '%';
            //string search = '%' + distName;

            return [SELECT Name, Id, ACC_Distributor_Number__c, parentId FROM Account WHERE (Name like: searchKey OR ACC_Distributor_Number__c LIKE: searchKey) AND parentId = : distributorId ];
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * Méthode pour récuperer le grossiste d'un sous distributeur
     * @param distName nom du sous distributeur
     * @param distributorId current Distributor Id
    */
    @AuraEnabled
    public static list<Account> getListParentDistributors(string distName, id distributorId){
        try {
            string searchKey = '%' + distName + '%';

            return [SELECT Parent.Name, Parent.ACC_Distributor_Number__c, Name, Id, parentId FROM Account WHERE (parent.Name like: searchKey OR Parent.ACC_Distributor_Number__c LIKE: searchKey) AND id = : distributorId  ];
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Methode pour valider le montant le grossiste peut transfere un montant
     * <p>
     * @param wholesalerId id du grossiste,s
     * @param amountToTransfer le montant à transférer
     * @return boolean
     * */
    @AuraEnabled
    public static string checkAvailableAmount(string wholesalerId, double amountToTransfer){

        list<Zuora__CustomerAccount__c> listBillingAccount = [SELECT Zuora__Account__c, Zuora__Zuora_Id__c, name
                                                              FROM Zuora__CustomerAccount__c
                                                              WHERE Zuora__Account__c  = :wholesalerId];
        if(listBillingAccount.size() > 0 && listBillingAccount != null) {
            //get Account payments Info
            HttpResponse accountResponse = ZuoraManager.getAccountSummary(listBillingAccount[0].Zuora__Zuora_Id__c);
            ZuoraResponseObjects.ZuoraGetAccount accountInfo = (ZuoraResponseObjects.ZuoraGetAccount) System.JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
            if(accountInfo.success) {
                // check if balance greater than the actual amount
                // Account Balance is a negative number
                if(math.abs(integer.valueOf(accountInfo.basicInfo.balance)) >= amountToTransfer) {
                    accountInfo.basicInfo.remainedBalance = math.abs(integer.valueOf(accountInfo.basicInfo.balance)) - integer.valueOf(amountToTransfer);
                } else {
                    accountInfo.basicInfo.remainedBalance = 0;
                }

                return JSON.serialize(accountInfo);
            } else {
                return accountResponse.getBody();
            }
        } else {
            return null;
        }

    }
    /**
     * Méthode pour transefer les credits entre le grossite et le sous-distributeur
     * @param distributorId id du distributor
     * @param wholesalerId id du grossiste,
     * @param amountToTransfer le montant à transférer
     */
    @AuraEnabled
    public static string handleCreditTransfer(id transferFrom, id transferTo, double amountToTransfer){
        try {
            Set<Log__c> setLogs = new Set<Log__c>();
            List<Log__c> listLog = new list<Log__c>();
            // get the Id of the distributor Account and the wholesaler
            list<Zuora__CustomerAccount__c> listBillingAccount = [SELECT Zuora__Account__c, Zuora__Parent__r.Zuora__Account__c, Zuora__Zuora_Id__c, Zuora__Account__r.currencyISOcode, Zuora__Parent__r.Zuora__Zuora_Id__c, Zuora__Parent__r.Zuora__Account__r.currencyISOcode
                                                                  FROM Zuora__CustomerAccount__c
                                                                  WHERE (Zuora__Account__c = :transferTo AND Zuora__Parent__r.Zuora__Account__c =:transferFrom) OR (Zuora__Account__c = : transferFrom AND Zuora__Parent__r.Zuora__Account__c = : transferTo)];

            //get Account payments the acount who wants to transfer
            string zaccountId;
            string payTo;
            if(listBillingAccount[0].Zuora__Parent__r.Zuora__Account__c == transferFrom) {
                zaccountId = listBillingAccount[0].Zuora__Parent__r.Zuora__Zuora_Id__c;
                payTo = listBillingAccount[0].Zuora__Zuora_Id__c;
            } else {
                zaccountId = listBillingAccount[0].Zuora__Zuora_Id__c;
                payTo = listBillingAccount[0].Zuora__Parent__r.Zuora__Zuora_Id__c;
            }
            HttpResponse accountResponse = ZuoraManager.getAccountSummary(zaccountId);
            ZuoraResponseObjects.ZuoraGetAccount accountInfo = (ZuoraResponseObjects.ZuoraGetAccount) System.JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
            double paymentAmount = amountToTransfer;
            string paymentId;
            string paymentNumber;
            double maxAmount = 0;
            boolean canTransfer = false;

            for(ZuoraResponseObjects.ZuoraPayment payment : accountInfo.payments) {
                if(payment.status != 'Cancelled') {
                    // check if the amount to be transfered should be transfered from one or many payments
                    for(ZuoraResponseObjects.ZuoraPaymentInvoice invoicePayment : payment.paidInvoices) {
                        if(amountToTransfer > 0 && (invoicePayment.invoiceId == null || invoicePayment.invoiceId == 'null') && invoicePayment.appliedPaymentAmount > 0) {
                            //check if the refund will be from one or many payment
                            if(invoicePayment.appliedPaymentAmount >= amountToTransfer) {
                                paymentNumber = payment.paymentNumber;
                                paymentId = payment.id;
                                canTransfer =  true;
                            } else {
                                if(invoicePayment.appliedPaymentAmount > maxAmount) {
                                    maxAmount = invoicePayment.appliedPaymentAmount;
                                }
                            }
                        }
                    }
                }
            }
            system.debug('canTransfer '+canTransfer+' //// '+maxAmount);
            if(canTransfer) {
                HttpResponse getPaymentResponse = ZuoraManager.getPayment(paymentId);
                ZuoraResponseObjects.ZuoraPayment currentPaymentInfo = (ZuoraResponseObjects.ZuoraPayment) System.JSON.deserialize(getPaymentResponse.getBody().replaceAll('__c', '_Reserved'), ZuoraResponseObjects.ZuoraPayment.class);
                if(currentPaymentInfo.success) {
                    ZuoraResponseObjects.ZuoraRefund refundInfo = new ZuoraResponseObjects.ZuoraRefund();
                    HttpResponse refundResponse;

                    //create refund for the wholesaler Account
                    ZuoraObjects.ZuoraRefundPayment refundPayment = ZuoraMapper.fillCreateRefund(amountToTransfer, null, null, null, currentPaymentInfo.DistributorOriginalPaymentSource_Reserved, paymentNumber, true);
                    refundResponse = ZuoraManager.createRefundPayment(refundPayment, paymentId);
                    refundInfo = (ZuoraResponseObjects.ZuoraRefund) System.JSON.deserialize(refundResponse.getBody(), ZuoraResponseObjects.ZuoraRefund.class);
                    setLogs.add (ZuoraSubscriptionActions.createZuoraLog (json.serialize(refundPayment, true), listBillingAccount[0].Zuora__Account__c, null, null, ZuoraObjects.paymentAPIUrl + paymentId + '/refunds', refundResponse.getBody(),
                                                                          refundInfo.success, refundInfo.reasons == null?null : refundInfo.reasons[0].message, ZuoraObjects.post, false));

                    if(refundInfo.success) {
                        // create Payment on the distributor Account
                        ZuoraObjects.ZuoraPayment paymentInfo =  ZuoraMapper.fillCreateTransferedPayment(payTo, amountToTransfer, listBillingAccount[0].Zuora__Account__r.currencyISOcode, paymentNumber, currentPaymentInfo.DistributorOriginalPaymentSource_Reserved);
                        HttpResponse response = ZuoraManager.createPayment(paymentInfo);

                        ZuoraResponseObjects.ZuoraPayment paymentResponse = new ZuoraResponseObjects.ZuoraPayment();
                        paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraPayment.class);

                        setLogs.add(ZuoraSubscriptionActions.createZuoraLog(json.serialize(paymentInfo, true), listBillingAccount[0].Zuora__Account__c, null, null, ZuoraObjects.paymentAPIUrl, response.getBody(),
                                                                            paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true));
                        if(setLogs.size() > 0) {
                            listLog.addAll(setLogs);
                            insert listLog;
                        }

                        return response.getBody();
                    } 
                    else {
                        if(setLogs.size() > 0) {
                            listLog.addAll(setLogs);
                            insert listLog;
                        }

                        return refundResponse.getBody();
                    }
                } else {
                    return getPaymentResponse.getBody();
                }
            } 
            else {
                return 'For technical issue you can transfer maximum ' + maxAmount;
            }

        } catch(Exception e) {
            system.debug(e.getMessage() + ' ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * update credit field on account when the balance is changed on Customer Account
     */
    public static void updateAccountBalance(map<id, Zuora__CustomerAccount__c> mapOld, map<id, Zuora__CustomerAccount__c> mapNew){
        list<Account> listAccountToUpdate = new list<Account>();
        for(Zuora__CustomerAccount__c zAccount : mapNew.values() ) {

            if(mapOld == null || (zAccount.Zuora__Balance__c != mapOld.get(zAccount.Id).Zuora__Balance__c && zAccount.Zuora__Balance__c != null)) {

                Account acc = new Account();
                acc.Id = zAccount.Zuora__Account__c;
                acc.ACC_Credit_Actuel__c = -double.valueOf(zAccount.Zuora__Balance__c);
                listAccountToUpdate.add(acc);
            }
        }
        if(listAccountToUpdate.size() > 0 && listAccountToUpdate != null) {
            update listAccountToUpdate;
        }
    }
    /**
     * Méthode pour récuperer l'abonnement en se basant sur une valeur
     * @param searchKey valeur chechée
     */
    @AuraEnabled
    public static list<Zuora__Subscription__c> getListSubscription(string searchKey){
        searchKey = '%' + searchKey + '%';

        string countryCode  = [SELECT CountryCode FROM user WHERE Id = :UserInfo.getUserId()].countryCode;

        try {
            return [SELECT Name, Id, BoxNumber__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__Account__r.Name, SUB_T_Produit_De_Base__c, Zuora__Account__r.QU_Quartier__c
                    FROM Zuora__Subscription__c
                    WHERE (Name LIKE: searchKey OR Zuora__Account__r.PersonEmail LIKE: searchKey OR BoxNumber__c LIKE: searchKey OR Zuora__CustomerAccount__r.Zuora__AccountNumber__c LIKE: searchKey OR Zuora__Account__r.Name LIKE: searchKey OR Zuora__Account__r.PersonMobilePhone LIKE: searchKey )
                    AND Zuora__Status__c IN ('Active', 'Suspended') AND Zuora__Account__r.BillingCountryCode = : countryCode];
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}