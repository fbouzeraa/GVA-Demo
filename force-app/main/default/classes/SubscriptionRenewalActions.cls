public without sharing class SubscriptionRenewalActions {

    public static Set<Log__c> createUsageAndBill( Boolean isUpgrade, Boolean isDowngrade, string distributorId, double currentAmount, string chargeNumber, string distSubNumber, string subNumber,
                                                  string paymentNumber, string invoiceNumber, string minimumThreshold, string distributorSubId, string AccountId, string subscriptionId){
        Set<Log__c> setLog = new Set<Log__c>();

        string renewType;
        if(isUpgrade) {
            renewType = 'Upgrade';
        } else if(isDowngrade) {
            renewType = 'Downgrade';
        } else {
            renewType = 'Simple renew';
        }

        ZuoraObjects.ZuoraUsage usageInfo = ZuoraMapper.fillCreateUsage(chargeNumber, renewType, distributorId, currentAmount, distSubNumber, subNumber, paymentNumber, invoiceNumber);//paymentResponse.number_toReplace, zinvoiceNumber);
        HttpResponse postUsageresponse = ZuoraManager.doCallout(zuoraObjects.usageAPIURL, zuoraObjects.post, json.serialize(usageInfo, true));
        ZuoraResponseObjects.ZuoraUsage usageResponse = (ZuoraResponseObjects.ZuoraUsage) JSON.deserialize(postUsageresponse.getBody(), ZuoraResponseObjects.ZuoraUsage.class);
        
        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(usageInfo, true), AccountId, subscriptionId, null, ZuoraObjects.usageAPIURL, postUsageresponse.getBody(),
                                                           usageResponse.success, usageResponse.reasons == null?null : usageResponse.reasons[0].message, ZuoraObjects.post, true));
        //get Account payments Info
        HttpResponse accountResponse = ZuoraManager.getAccountSummary(distributorId);
        ZuoraResponseObjects.ZuoraGetAccount accountInfo = (ZuoraResponseObjects.ZuoraGetAccount) System.JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
        
        if(accountInfo.success) {
            if(minimumThreshold == null || string.isBlank(minimumThreshold)) {
                minimumThreshold = '0';
            }
            if(-(double.valueOf(accountInfo.basicInfo.balance)) - currentAmount < double.valueOf(minimumThreshold)) {

                ZuoraObjects.ZuoraBilling zBillRun = zuoraMapper.fillGenerateBillRun(new list<string> {distributorSubId});
                HttpResponse billResponse = ZuoraManager.CreateBillByAccount(zBillRun, distributorId);
                ZuoraResponseObjects.ZuoraBill invoiceResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(billResponse.getBody(), ZuoraResponseObjects.ZuoraBill.class);
                
                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zBillRun, true), AccountId, subscriptionId, null, ZuoraObjects.accountAPIUrl + distributorSubId + ZuoraObjects.billAPIUrl, billResponse.getBody(),
                                                                   invoiceResponse.success, invoiceResponse.reasons == null?null : invoiceResponse.reasons[0].message, ZuoraObjects.post, true));
            }
        }

        return setLog;
    }
    /**
     * Method pour mettre à jour les champs custom d'une facture
     * <p>
     * @param onCreate boolean création,
     * @param invoiceId l'id du facture,
     * @param perpaidPeriods nombre de periodes prepayées
     * @return resultat de l'appel API
     * */
    public static string updateBillCustomFields(boolean onCreate, string invoiceId, string perpaidPeriods, Zuora__Subscription__c sub, string conversionRate, id AccountId){

        set<Log__c> setLog = new set<Log__c>();
        // fill fields to update the generate bill custom fields
        ZuoraObjects.ZuoraBilling zBill = ZuoraMapper.fillInvoiceCustomFields(onCreate, perpaidPeriods, sub, conversionRate, AccountId);

        try {
            HttpResponse billResponse = ZuoraManager.updateInvoice(invoiceId, zBill);

            ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(billResponse.getBody(), ZuoraResponseObjects.ZuoraBill.class);

            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zBill, true), null, sub?.Id, sub?.Zuora__SubscriptionNumber__c, ZuoraObjects.invoiceAPIUrl + invoiceId, billResponse.getBody(),
                                                               invoiceUpdateResponse.success, invoiceUpdateResponse.reasons == null?null : invoiceUpdateResponse.reasons[0].message, ZuoraObjects.put, true));

            return billResponse.getBody();
        } catch(exception e) {
            ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
            error.message = e.getMessage();
            error.zuoraLog = setLog;
            system.debug(e.getLineNumber());
            throw new CustomException(json.serialize(error, true));
        }
    }

    /**
     * @param nbPeriodes
     * @param isUpgrade
     * @param isDowngrade
     * @param subscriptionId
     * @param boxNumber
     * @param country
     * @param PTO
     * @param con contact
     */
    public static void createRenewFollowUp(integer nbPeriodes, boolean isUpgrade, boolean isDowngrade, id subscriptionId, string boxNumber, string country,
                                           list<contact> con, Account acc, string oldOffer, string newOffer,
                                           string newOfferUL, string newOfferDL, string oldOfferUL, string oldOfferDL, string paymentMode, Date oldExpectedRenewalDate){
        // suivi pour reabo avec upgrade
        if(nbPeriodes != null && isUpgrade) {
            // it's required to insert the first suivi before the second one
            insert ZuoraSubscriptionActions.createSuivi(
                boxNumber, 'ACT003', Datetime.now(),
                'DST001', subscriptionId, country, null, 'STA001', null, null, null, oldOffer, oldOffer, SuiviMapper.fillSuiviRenew(acc, con, null), paymentMode);

            Suivi_de_Souscription__c suiviRenew =
            ZuoraSubscriptionActions.createSuivi(
                boxNumber, 'ACT004', Datetime.now(), oldExpectedRenewalDate == date.today()?'DST001' : 'DST002',
                subscriptionId, country, null, 'STA001', null, null, null, oldOffer, newOffer, SuiviMapper.fillSuiviUpgradeDowngrade(acc, con, null, newOfferUL, newOfferDL, oldOfferUL, oldOfferDL), paymentMode);
            suiviRenew.Product_effective_start_date__c = oldExpectedRenewalDate;
            insert suiviRenew;

        }
        // suivi pour reabo avec downgrade
        else if(nbPeriodes != null && isDowngrade) {
            insert ZuoraSubscriptionActions.createSuivi(
                boxNumber, 'ACT003', Datetime.now(),
                'DST001', subscriptionId, country, null, 'STA001', null, null, null, oldOffer, oldOffer, SuiviMapper.fillSuiviRenew(acc, con, null), paymentMode);

            Suivi_de_Souscription__c suiviRenew =
            ZuoraSubscriptionActions.createSuivi(
                boxNumber, 'ACT004', Datetime.now(), oldExpectedRenewalDate == date.today()?'DST001' : 'DST002',
                subscriptionId, country, null, 'STA001', null, null, null, oldOffer, newOffer, SuiviMapper.fillSuiviUpgradeDowngrade(acc, con, null, newOfferUL, newOfferDL, oldOfferUL, oldOfferDL), paymentMode);
            suiviRenew.Product_effective_start_date__c = oldExpectedRenewalDate;
            insert suiviRenew;
        }
        // suivi pour reabo simple
        else {
            insert ZuoraSubscriptionActions.createSuivi(
                boxNumber, 'ACT003', Datetime.now(),
                'DST001', subscriptionId, country, null, 'STA001', null, null, null, oldOffer, newOffer, SuiviMapper.fillSuiviRenew(acc, con, null), paymentMode);
        }
    }

    /**
     * Methode pour cree le paiement d'un reabo et applique ce paiement sur la facture
     * <p>
     * @param nbPeriodes nombre de periodes a reabonné,
     * @param currentAmount le montant a encaissé,
     * @param orderNumber numero de commande,
     * @param zinvoiceNumber numero de la facture,
     * @param isUpgrade boolean pour indiquer le cas upgrade,
     * @param isDowngrade boolean pour indiquer le cas downgrade,
     * @param paymentMode mode du paiementcreateRenewPayment
     * @param transactionNumber Numéro de transaction
     * @param operator operateur MM
     * @param dollarPayment Montant payée en dollar
     * @param CDFPayment Montant payée en CDF
     * @param dollarRefund Montant rendu en dollar
     * @param CDFRefund Montant rendu en CDF
     * @param oldOffer Nom de l'ancienne offre
     * @param newOffer Nom de du nouvelle offre
     * @return resultat de l'appel API
     */
    public static string createRenewPayment(Zuora__SubscriptionProductCharge__c prpCharge, integer nbPeriodes, double currentAmount, string zinvoiceNumber,
                                            string InvoiceId, boolean isUpgrade, boolean isDowngrade, string paymentMode, string transactionNumber, string operator,
                                            double dollarPayment, integer CDFPayment, integer dollarRefund, integer CDFRefund, string oldOffer, string newOffer,
                                            set<Log__c> setLogz, string distributorId, id grossisteId, Date oldExpectedRenewalDate, string offer, list<string> options){
       
        // list and set to handle the logs
        list<Log__c> listLog = new list<Log__c>();
        set<Log__c> setLog = new set<Log__c>();

        list<zuora__SubscriptionProductCharge__c> listDistributorSubProducts = new list<zuora__SubscriptionProductCharge__c>();
        list<Account> listAccountContacts = new list<Account>();

        // Boolean to mark the subscription for activation in C Bundle in the batch11_SubscribeToBundleC
        Boolean createcBundleSub = false;
        string offerOptions = '';

        // concatinate all selected options to send it to Canal plus
        if(options != null && options.size() > 0) {
            for(string option : options) {
                offerOptions = offerOptions + option + ';';
            }
            // remove last character ';'
            offerOptions = offerOptions.substring(0, offerOptions.length() - 1);
        }

        
        if(distributorId != null) {
            listDistributorSubProducts = [SELECT Zuora__OriginalProductRatePlanChargeId__c, Zuora__ChargeNumber__c, Zuora__Subscription__r.Name, Zuora__Subscription__r.Zuora__Account__c,
                                        Zuora__Subscription__r.Zuora__CustomerAccount__r.DistributorOperationBillingMinThreshold__c, Zuora__Subscription__r.Zuora__Zuora_Id__c
                                        FROM zuora__SubscriptionProductCharge__c
                                        WHERE Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c = :distributorId];
        }


        if(setLogz != null && setLogz.size() > 0) {setLog.addAll(setLogz);}
            
        //get account and related contact info to create a suivi
        listAccountContacts = [SELECT Id, FirstName, Name, LastName, ACC_Entreprise__c, RecordType.DeveloperName, ACC_AccountNumber__c,
                                ACC_ChampCompteParent__r.FirstName, ACC_ChampCompteParent__r.LastName,
                                ACC_ChampCompteParent__r.RecordType.DeveloperName, ACC_ChampCompteParent__r.ACC_Entreprise__c,
                                ACC_ChampCompteParent__r.ACC_AccountNumber__c, ACC_ChampCompteParent__c,
                                (SELECT id, FirstName, LastName, Email, MobilePhone, Phone, CON_Role__c FROM Contacts WHERE AccountId = :prpCharge.Zuora__Subscription__r.Zuora__Account__c)
                                FROM Account
                                WHERE id = :prpCharge.Zuora__Subscription__r.Zuora__Account__c];


        if((InvoiceId == null) || (zinvoiceNumber == null && listDistributorSubProducts.size() > 0 && invoiceId != null)) {
            // get invoice Id from an account  ////// API Call to Zuora 1 //////
            HttpResponse accountResponse = ZuoraManager.getAccountSummary(prpCharge.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
            ZuoraResponseObjects.ZuoraGetAccount getAccountInfoResponse = new ZuoraResponseObjects.ZuoraGetAccount();
            getAccountInfoResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
            
            
            if(getAccountInfoResponse.success) {

                // get invoice id of the request invoice number
                for(ZuoraResponseObjects.ZuoraInvoices zInvoice : getAccountInfoResponse.invoices) {
                    if(zinvoiceNumber != null && zInvoice.InvoiceNumber == zinvoiceNumber) {
                        invoiceId = zInvoice.id;
                        break;
                    }
                    if(InvoiceId != null && zInvoice.id == InvoiceId) {
                        zinvoiceNumber = zInvoice.InvoiceNumber;
                        break;
                    }
                }
            }
        }   
                                                            /////////////////////////////////////////////////////////////////////////////////
        if(invoiceId != null) {
            try {
                
                list<Product_BandWidth__mdt> listProdBw = [SELECT BW_DL__c, BW_UL__c, DeveloperName
                                                           FROM Product_BandWidth__mdt
                                                           WHERE country_Code__c = : prpCharge.Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode];

                map<string, Product_BandWidth__mdt> mapBwName = new map<string, Product_BandWidth__mdt>();

                for(Product_BandWidth__mdt prodBw : listProdBw) {
                    mapBwName.put(prodBw.DeveloperName.substring(0, prodBw.DeveloperName.lastIndexOf('_')), prodBw);
                }
    
                list<CurrencyType> currencyRate;

                //add invoice custom fields on renew sub ////// API Call to Zuora 2 //////
                String currencyConversionRate = null;
                string invoiceCustomFields;
                ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse = new ZuoraResponseObjects.ZuoraBill();
                sleepAfterBCD();
                if(prpCharge.Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode == 'CD') 
                {
                    currencyRate = [SELECT Id, ConversionRate, IsoCode FROM CurrencyType WHERE IsoCode = 'USD'];
                    currencyConversionRate = string.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR));
                }
                
                invoiceCustomFields = updateBillCustomFields(false, invoiceId, string.valueOf(nbPeriodes), null, currencyConversionRate, prpCharge.Zuora__Subscription__r.Zuora__Account__c);
                invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(invoiceCustomFields, ZuoraResponseObjects.ZuoraBill.class);
                if(invoiceUpdateResponse.zuoraLogs != null && invoiceUpdateResponse.zuoraLogs.size() > 0) { setLog.addAll(invoiceUpdateResponse.zuoraLogs); }

                if(!invoiceUpdateResponse.success){ // if the first API call was not successful because of the Lock Competion Zuora error retry the request
                    sleepAfterBCD();
                    invoiceCustomFields = updateBillCustomFields(false, invoiceId, string.valueOf(nbPeriodes), null, currencyConversionRate, prpCharge.Zuora__Subscription__r.Zuora__Account__c);
                    invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(invoiceCustomFields, ZuoraResponseObjects.ZuoraBill.class);
                    if(invoiceUpdateResponse.zuoraLogs != null && invoiceUpdateResponse.zuoraLogs.size() > 0) { setLog.addAll(invoiceUpdateResponse.zuoraLogs); }
                }
                
                boolean fromDistributor = false;
                if(listDistributorSubProducts != null && listDistributorSubProducts.size() > 0) {
                    fromDistributor = true;
                }

                // create payment for renew action
                ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreateRenewPayment(prpCharge.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, nbPeriodes, currentAmount, transactionNumber,
                                                                                           operator, prpCharge.Zuora__Subscription__r.Quote__r.QUO_T_Numero_De_Commande__c, invoiceId, prpCharge.Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode, paymentMode,
                                                                                           string.valueOf(CDFPayment), string.valueOf(dollarPayment),
                                                                                           currencyRate == null?null : String.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR)),
                                                                                           string.valueOf(dollarRefund), string.valueOf(CDFRefund), fromDistributor, prpCharge.Zuora__Subscription__r.Zuora__Account__c);
                
                log__c lg = new Log__c(LG_Body__c = JSON.serialize(paymentInfo, true), LG_Account__c = prpCharge.Zuora__Subscription__r.Zuora__Account__c, 
                    LG_Subscription__c = prpCharge.Zuora__Subscription__c, LG_Method_URL__c =  ZuoraObjects.paymentAPIUrl,LG_Interface__c = 'Zuora', LG_Method_Type__c = ZuoraObjects.post);

                // Create the payment in Zuora ////// API Call to Zuora 3 //////
                httpResponse response = ZuoraManager.createPayment(paymentInfo);
                string responseAdjustment = response.getBody().replaceAll('number', 'number_toReplace');
                ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                
                if(!paymentResponse.success) { // if the first API call was not successful because of the Lock Competion Zuora error retry
                    sleepAfterBCD();
                    response = ZuoraManager.createPayment(paymentInfo);
                    responseAdjustment = response.getBody().replaceAll('number', 'number_toReplace');
                    paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(responseAdjustment, ZuoraResponseObjects.ZuoraPayment.class);
                }

                // fill log info
                lg.LG_Success__c = paymentResponse.success;
                lg.LG_Response__c = response.getBody();
                setLog.add(Lg);

                Zuora__Subscription__c subToupdate = new Zuora__Subscription__c();
                if(paymentResponse.success) {
                    
                    if(listDistributorSubProducts != null && listDistributorSubProducts.size() > 0) {

                                    ////// API Call to Zuora 4,5 and 6 //////
                        set<Log__c> setUsageLog = createUsageAndBill( isUpgrade, isDowngrade,  distributorId, currentAmount, listDistributorSubProducts[0].Zuora__ChargeNumber__c, listDistributorSubProducts[0].Zuora__Subscription__r.Name, prpCharge.Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                        paymentResponse.number_toReplace, zinvoiceNumber, listDistributorSubProducts[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.DistributorOperationBillingMinThreshold__c, listDistributorSubProducts[0].Zuora__Subscription__r.Zuora__Zuora_Id__c, prpCharge.Zuora__Subscription__r.Zuora__Account__c, prpCharge.Zuora__Subscription__c);
                        if(setUsageLog != null && setUsageLog.size() > 0) {
                            setLog.addALL(setUsageLog);
                        }
                    }

                    // if current subscription is already subscribed once to Bundle --> renew the subscription  if not create a new subscription C+
                    if(offer != null && !string.isBlank(offer)) // in Bundle migration case don't get the method enter this condition
                    {
                        // if no status for the Bundle subscription means it should be created in CGA not renewed
                        if(prpCharge.Zuora__Subscription__r.SUB_Status__c == null || prpCharge.Zuora__Subscription__r.SUB_Status__c == ''){
                            createcBundleSub = true;
                        }else{      ////// API Call to CGA 7 //////
                            string sub = BundleCSubscription.renewBundleC(prpCharge.Zuora__Subscription__c, nbPeriodes, offer, options, true);
                            if(sub != null) {
                                subToupdate = (Zuora__Subscription__c)json.deserialize(sub, Zuora__Subscription__c.class);
                            }
                        }   
                    }

                    // if it's an RDC subscription
                    if(dollarRefund != null && CDFRefund != null && currencyRate != null) 
                    {
                        Decimal refundAmount = dollarRefund + ((CDFRefund * currencyRate[0].ConversionRate));
                        ZuoraObjects.ZuoraRefundPayment refundPayment = ZuoraMapper.fillCreateRefund(double.valueOf(refundAmount.setScale(2, RoundingMode.HALF_UP)), CDFRefund,
                                                                                                        string.valueOf(dollarRefund), string.valueOf((1 / currencyRate[0].ConversionRate).round()), null, null, false);
                            ////// API Call to Zuora 8 //////
                        HttpResponse refundResponse = ZuoraManager.createRefundPayment(refundPayment, paymentResponse.id);
                        ZuoraResponseObjects.ZuoraRefund refundInfo = (ZuoraResponseObjects.ZuoraRefund) System.JSON.deserialize(refundResponse.getBody(), ZuoraResponseObjects.ZuoraRefund.class);

                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(refundPayment, true), prpCharge.Zuora__Subscription__r.Zuora__Account__c, prpCharge.Zuora__Subscription__c, null, ZuoraObjects.paymentAPIUrl + paymentResponse.id + '/refunds', refundResponse.getBody(),
                                                                            refundInfo.success, refundInfo.reasons == null?null : refundInfo.reasons[0].message, ZuoraObjects.post, true));

                        if(setLog.size() > 0 && setLog != null) {
                            listLog.AddAll(setLog);
                            insert listLog;
                        }

                        if(refundInfo.success) {

                            Zuora__Subscription__c sub = new zuora__Subscription__c();
                            sub.Id = prpCharge.Zuora__Subscription__c;
                            sub.Coupon__c = null;
                            if(subToupdate.SUB_End_Date__c != null){ sub.SUB_End_Date__c = subToupdate.SUB_End_Date__c; }
                            if(offer != null && !string.isBlank(offer)){ sub.SUB_Offer__c = offer; }
                            sub.SUB_Options__c = offerOptions;
                            sub.Create_Bundle_C_subscription__c = createcBundleSub;
                            if(distributorId != null) {
                                sub.SUB_Grossiste__c = grossisteId == null?UserInfo.getUserId() : grossisteId;
                                sub.SUB_Distributor__c = grossisteId == null?null : UserInfo.getUserId();
                                sub.SUB_Renewed_by_Distributor_on__c = date.today();
                            }
                            if(transactionNumber != null) {
                                sub.SUB_Numero_de_transaction__c = transactionNumber;
                            }
                            update sub;
                            

                            // check compensation days on the sub
                            if(prpCharge.Zuora__Subscription__r.CompensationDaysAtNextRenewal__c != null && nbPeriodes != null && integer.valueOf(prpCharge.Zuora__Subscription__r.CompensationDaysAtNextRenewal__c) > 0) {
                                // suivi pour dedomagement
                                insert ZuoraSubscriptionActions.createSuivi(prpCharge.Zuora__Subscription__r.BoxNumber__c, 'ACT014', Datetime.now(), 'DST001',
                                    prpCharge.Zuora__Subscription__c, prpCharge.Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode, null,  'STA001', null, null, null, null, null, null, null);
                            }

                            createRenewFollowUp(nbPeriodes, isUpgrade, isDowngrade, prpCharge.Zuora__Subscription__c, prpCharge.Zuora__Subscription__r.BoxNumber__c, prpCharge.Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode, listAccountContacts != null ? listAccountContacts[0].contacts : null,
                                                listAccountContacts != null ? listAccountContacts[0] :null, oldOffer, newOffer, mapBwName.get(newOffer)?.BW_UL__c, mapBwName.get(newOffer)?.BW_DL__c,
                                                mapBwName.get(oldOffer)?.BW_UL__c, mapBwName.get(oldOffer)?.BW_DL__c, paymentMode, oldExpectedRenewalDate);

                            return response.getBody();
                        } else {
                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, paymentResponse.reasons[0].message, prpCharge.Zuora__Subscription__c, ZuoraObjects.paymentAPIUrl + paymentResponse.id + '/refunds');

                            return refundResponse.getBody();
                        }
                    } // Other then RDC subscriptions
                    else {
                        if(setLog.size() > 0 && setLog != null) {
                            listLog.AddAll(setLog);
                            insert listLog;
                        }

                        // transaction Number of CBundle subscription
                        Zuora__Subscription__c sub = new zuora__Subscription__c();
                        sub.Id = prpCharge.Zuora__Subscription__c;
                        sub.Coupon__c = null;
                        if(subToupdate.SUB_End_Date__c != null){ sub.SUB_End_Date__c = subToupdate.SUB_End_Date__c; }
                        if(offer != null && !string.isBlank(offer)){ sub.SUB_Offer__c = offer; }
                        sub.SUB_Options__c = offerOptions;
                        sub.Create_Bundle_C_subscription__c = createcBundleSub;
                        if(distributorId != null) {
                            sub.SUB_Grossiste__c = grossisteId == null?UserInfo.getUserId() : grossisteId;
                            sub.SUB_Distributor__c = grossisteId == null?null : UserInfo.getUserId();
                            sub.SUB_Renewed_by_Distributor_on__c = date.today();
                        }
                        if(transactionNumber != null) {
                            sub.SUB_Numero_de_transaction__c = transactionNumber;
                        }
                        update sub;

                        // check compensation days on the sub
                        if(prpCharge.Zuora__Subscription__r.CompensationDaysAtNextRenewal__c != null && nbPeriodes != null && integer.valueOf(prpCharge.Zuora__Subscription__r.CompensationDaysAtNextRenewal__c) > 0) {
                            // suivi pour dedomagement
                            insert ZuoraSubscriptionActions.createSuivi(prpCharge.Zuora__Subscription__r.BoxNumber__c, 'ACT014', Datetime.now(), 'DST001',
                                prpCharge.Zuora__Subscription__c, prpCharge.Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode, null, 'STA001', null, null, null, null, null, null, null);
                        }

                        createRenewFollowUp(nbPeriodes, isUpgrade, isDowngrade, prpCharge.Zuora__Subscription__c, prpCharge.Zuora__Subscription__r.BoxNumber__c, prpCharge.Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode, listAccountContacts != null ? listAccountContacts[0].contacts : null,
                                            listAccountContacts != null ? listAccountContacts[0] : null, oldOffer, newOffer, mapBwName.get(newOffer)?.BW_UL__c, mapBwName.get(newOffer)?.BW_DL__c,
                                            mapBwName.get(oldOffer)?.BW_UL__c, mapBwName.get(oldOffer)?.BW_DL__c, paymentMode, oldExpectedRenewalDate);

                        return response.getBody();
                    }
                } // if payment response is not success create Bundle c Subscription and payment will be recreated in the batch
                else {
                    // if current subscription is already subscribed once to Bundle --> renew the subscription  if not create a new subscription C+
                    if(offer != null && !string.isBlank(offer))   // in migration case don't get the method enter this condition
                    {
                        // if no status for the Bundle subscription means it should be created in CGA not renewed
                        if(prpCharge.Zuora__Subscription__r.SUB_Status__c == null || prpCharge.Zuora__Subscription__r.SUB_Status__c == ''){
                            createcBundleSub = true;
                        }else{      ////// API Call to CGA 7 //////
                            string sub = BundleCSubscription.renewBundleC(prpCharge.Zuora__Subscription__c, nbPeriodes, offer, options, true);
                            if(sub != null) {
                                subToupdate = (Zuora__Subscription__c)json.deserialize(sub, Zuora__Subscription__c.class);
                            }
                        }   
                    }

                    setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(paymentInfo, true), prpCharge.Zuora__Subscription__r.Zuora__Account__c, prpCharge.Zuora__Subscription__c, null, ZuoraObjects.paymentAPIUrl, response.getBody(),
                                                                        paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true));

                    // update the subscription info
                    Zuora__Subscription__c sub = new Zuora__Subscription__c();
                    sub.Id = prpCharge.Zuora__Subscription__c;
                    sub.Coupon__c = null;
                    if(subToupdate.SUB_End_Date__c != null){ sub.SUB_End_Date__c = subToupdate.SUB_End_Date__c; }
                    if(offer != null && !string.isBlank(offer)){ sub.SUB_Offer__c = offer; }
                    sub.SUB_Options__c = offerOptions;
                    sub.Create_Bundle_C_subscription__c = createcBundleSub;
                    if(distributorId != null) {
                        sub.SUB_Grossiste__c = grossisteId == null?UserInfo.getUserId() : grossisteId;
                        sub.SUB_Distributor__c = grossisteId == null?null : UserInfo.getUserId();
                        sub.SUB_Renewed_by_Distributor_on__c = date.today();
                    }
                    
                    set<Log__c> setUsageLog = new set<Log__c>();
                    if(listDistributorSubProducts != null && listDistributorSubProducts.size() > 0) {
                        setUsageLog.addALL(createUsageAndBill( isUpgrade, isDowngrade,  distributorId, currentAmount, listDistributorSubProducts[0].Zuora__ChargeNumber__c, listDistributorSubProducts[0].Zuora__Subscription__r.Name,  prpCharge.Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                null, zinvoiceNumber, listDistributorSubProducts[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.DistributorOperationBillingMinThreshold__c, listDistributorSubProducts[0].Zuora__Subscription__r.Zuora__Zuora_Id__c, prpCharge.Zuora__Subscription__r.Zuora__Account__c, prpCharge.Zuora__Subscription__c));
                    }
                    if(setUsageLog != null && setUsageLog.size() > 0) { setLog.addALL(setUsageLog); }

                    createRenewFollowUp(nbPeriodes, isUpgrade, isDowngrade, prpCharge.Zuora__Subscription__c, prpCharge.Zuora__Subscription__r.BoxNumber__c, prpCharge.Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode,  listAccountContacts != null ? listAccountContacts[0].contacts : null,
                                        listAccountContacts != null ? listAccountContacts[0] : null, oldOffer, newOffer, mapBwName.get(newOffer)?.BW_UL__c, mapBwName.get(newOffer)?.BW_DL__c,
                                        mapBwName.get(oldOffer)?.BW_UL__c, mapBwName.get(oldOffer)?.BW_DL__c, paymentMode, oldExpectedRenewalDate);

                    update sub;
                    
                    if(setLog.size() > 0 && setLog != null) {
                        listLog.AddAll(setLog);
                        insert listLog;
                    }

                    ZuoraResponseObjects.retryPayment retry = new ZuoraResponseObjects.retryPayment();
                    retry.accountCurrency = prpCharge.Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode;
                    retry.AccountId = prpCharge.Zuora__Subscription__r.Zuora__Account__c;
                    retry.CDFPayment = string.valueOf(CDFPayment);
                    retry.CDFRefund = string.valueOf(CDFRefund);
                    retry.currencyRate = currencyRate == null?null : String.valueOf((1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR));
                    retry.currentAmount = currentAmount;
                    retry.dollarPayment = string.valueOf(dollarPayment);
                    retry.dollarRefund = string.valueOf(dollarRefund);
                    retry.fromDistributor = fromDistributor;
                    retry.invoiceId = InvoiceId;
                    retry.nbPeriodes = nbPeriodes;
                    retry.operator = operator;
                    retry.orderNumber = prpCharge.Zuora__Subscription__r.Quote__r.QUO_T_Numero_De_Commande__c;
                    retry.paymentMode = paymentMode;
                    retry.transactionNumber = transactionNumber;
                    retry.zuoraAccountId = prpCharge.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c;
                    paymentResponse.paymentParam = retry;

                    return json.serialize(paymentResponse, true);
                }
            }
            catch(Exception e) {

                Log__c newLog = new Log__c();
                newLog.LG_Body__c = e.getLineNumber()+' >>> '+e.getMessage();
                newLog.LG_Account__c = listAccountContacts != null ? listAccountContacts[0].Id : null;
                newLog.LG_Method_URL__c = 'CustomException';
                newLog.LG_Interface__c = 'Apex';
                newLog.LG_Success__c = false;
                newLog.LG_Method_Type__c = 'Create payment exception 2';
                newLog.LG_Retry__c = false;
                insert newLog;

                ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
                error.message = e.getMessage() + e.getCause()+ ' /// '+ e.getLineNumber();
                error.zuoraLog = setLog;
                system.debug(e.getMessage() + ' ' + e.getLineNumber());
                throw new CustomException(json.serialize(error, true));
            }
        } 
        else {

            if(setLog.size() > 0 && setLog != null) {
                listLog.AddAll(setLog);
                insert listLog;
            }

            return null;
        }
    }

                                      ///////////////////////////////////////////////////////////////////////////////////////

    /**
     * Methode pour cree l'apercu d'un upgrade
     * <p>
     * @param accountNumber numero du compte,
     * @param subNumber numero de la souscription,
     * @param prodToAddId id du produit a ajouter,
     * @param prodToRemoveId id du produit a annuler,
     * @param expectedRenewalDate la date de renouvellement d'un abo,
     * @param triggerDate date du debut du reabo,
     * @param isActive boolean pour indiquer si l'abonnement est active ou suspendu,
     * @param fiscalId id du timbre fiscal,
     * @param chargeId id du de la charge produit timbre fiscal,
     * @param totalAmount prix total des produits
     * @return resultat de l'appel API
     */
    public static string upgradeSubProductPreview(string accountNumber, string subNumber, string prodToAddId, string CollabProdToAddId,
                                                  string prodToRemoveId, string CollabProdToRemoveId, date expectedRenewalDate, date triggerDate, boolean isActive,
                                                  string fiscalId, string ratePlanId, double totalAmount, String bandwidth, zqu__ProductRatePlanCharge__c coupon, double couponValue, list<string> listBundleId, list<string> listBundleToRemove) {

        set<Log__c> setLog = new set<Log__c>();
        string previewResult;
        // fill upgrade preview order fields
        ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillUpgradePreviewSubscription(
            accountNumber, subNumber, prodToAddId, CollabProdToAddId, prodToRemoveId, CollabProdToRemoveId, expectedRenewalDate, triggerDate, isActive,
            fiscalId, ratePlanId, totalAmount, coupon, couponValue, listBundleId, listBundleToRemove);

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
                system.debug('chargeNameInfo '+chargeNameInfo);

                list<ZuoraResponseObjects.ZuoraInvoiceItems> listZInvoice = new list<ZuoraResponseObjects.ZuoraInvoiceItems>();
                for(AggregateResult subProduct : [SELECT  count(id), Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c
                                                  FROM zuora__subscriptionProductCharge__c
                                                  WHERE Zuora__RatePlanName__c != null AND Zuora__ProductRatePlanChargeId__c IN : chargeNameInfo.keyset() GROUP BY Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c]) 
                {
                    String productId = (String) subProduct.get('Zuora__ProductRatePlanChargeId__c');
                    String ratePlanName = (String) subProduct.get('Zuora__RatePlanName__c');
                    chargeNameInfo.get(productId).ratePlanName = ratePlanName;
                    chargeNameInfo.get(productId).bandwidth = bandwidth;
                }
                listZInvoice.addAll(chargeNameInfo.Values());

                if(orderResponse.previewResult.invoices.size() > 0 && orderResponse.previewResult.invoices != null){
                    orderResponse.previewResult.invoices[0].invoiceItems = listZInvoice;
                }

                //add conversion rate to the response
                list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                                   FROM CurrencyType
                                                   WHERE IsoCode = 'USD'];

                orderResponse.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);
                orderResponse.zuoraLogs = setLog;
                orderResponse.previewResult.invoices[0].invoiceItems[0].subscriptionNumber = subNumber;

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
            error.message = e.getMessage() + ' /// '+ e.getLineNumber();
            error.zuoraLog = setLog;
            system.debug(e.getLineNumber()+': '+e.getMessage());
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
    public static string upgradeSubscriptionProduct(id subscriptionId, integer nbPeriodes, boolean isPreview,
                                                    boolean withRenew, boolean immediateUpgrade, string modeDePaiement, string transactionNumber,
                                                    string operator, double dollarPayment, integer CDFPayment, integer dollarRefund, integer CDFRefund, 
                                                    string bizaOrderId, string offer, list<string> options, string category){
        boolean isActive = true;
        boolean haveCredit = false;
        string invoiceNumber;
        list<Log__c> listLog = new list<Log__c>();
        set<Log__c> setLog = new set<Log__c>();

        user currentUser = [SELECT USR_DistributeurID__c, Profile.Name
                            FROM User
                            WHERE id = :UserInfo.getUserId()];

        //get distributor having account in Zuora
        list<Zuora__Subscription__c> listDistributorSub = new List<Zuora__Subscription__c>();

        if(currentUser.Profile.Name != 'Utilisateur du Portail Client' &&  currentUser.USR_DistributeurID__c != null) {
            listDistributorSub =  [SELECT Zuora__Account__r.parentId, Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.DistributorOperationBillingMinThreshold__c
                                   FROM Zuora__Subscription__c
                                   WHERE Zuora__CustomerAccount__r.Zuora__Account__r.ACC_Distributor_Number__c  = : currentUser.USR_DistributeurID__c];

        }

        if((withRenew && nbPeriodes != null) || !withRenew) {
            list<Zuora__SubscriptionProductCharge__c> listStartSubProduct = [ SELECT Zuora__RatePlanName__c, Name, Zuora__Zuora_Id__c, Zuora__RatePlanId__c,
                                                                              Zuora__Subscription__r.ExpectedRenewalDate__c, Zuora__Subscription__r.Zuora__Status__c,
                                                                              Zuora__Subscription__r.CompensationDaysAtNextRenewal__c, Zuora__Subscription__r.Zuora__ServiceActivationDate__c,
                                                                              Zuora__Subscription__r.Zuora__SubscriptionNumber__c, Zuora__Subscription__r.Zuora__Account__r.BillingCountry,
                                                                              Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode, Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode,
                                                                              Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                                                              Zuora__Subscription__r.Coupon__c, Zuora__Subscription__r.SUB_Status__c,
                                                                              Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                                              Zuora__Subscription__r.Quote__c, Zuora__Subscription__r.Zuora__Account__c,
                                                                              Zuora__Subscription__r.Quote__r.QUO_Periodes_Prepayees__c,
                                                                              Zuora__Subscription__r.Quote__r.CreatedBy.Country, Zuora__Subscription__r.isCollaborator__c,
                                                                              Zuora__Subscription__r.Quote__r.QUO_T_Numero_De_Commande__c, Zuora__Subscription__r.C_Migration_Date__c,
                                                                              Zuora__Subscription__r.Quote__r.QUO_Mode_de_paiement__c, Zuora__Subscription__r.Quote__r.QUO_PTO__c,
                                                                              Zuora__Subscription__r.BoxNumber__c, Zuora__Subscription__r.Zuora__Zuora_Id__c,
                                                                              Zuora__Subscription__r.RenewalSequenceNumber__c, Zuora__Product__r.Zuora__External_Id__c, Zuora__Product__r.Name,
                                                                              Zuora__Subscription__c, Zuora__Subscription__r.Create_Bundle_C_subscription__c,
                                                                              Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c
                                                                              FROM Zuora__SubscriptionProductCharge__c
                                                                              WHERE Zuora__Type__c = 'Recurring' 
                                                                                AND Zuora__RatePlanName__c =: System.Label.Start_BaseProduct 
                                                                                AND Zuora__Subscription__c =: subscriptionId 
                                                                                AND Zuora__Subscription__r.SuspensionReason__c != 'Move-Requested'];
            //check if the subscription have product of charge 'start'
            if(listStartSubProduct != null && listStartSubProduct.size() > 0) {

                // if the BCD is not aligned with the expected renewal date block the renewal
                string expectedRenewalDay = string.valueof(listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.day());
                string billCycleDay = listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c;
                billCycleDay = billCycleDay != null ? billCycleDay : 'null';
                // if the migration is scheduled in the future block the renewal 
                Date migrationDate = Date.valueOf(listStartSubProduct[0].Zuora__Subscription__r.C_Migration_Date__c);
                if(migrationDate != null && (migrationDate > Date.today() || (migrationDate == Date.today() && !System.isBatch()))){
                    return System.Label.Sub_InMigration_Message +' '+String.valueOf(migrationDate);               
                }else if(!billCycleDay.contains(expectedRenewalDay) && listStartSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active && !Test.isRunningTest()){
                    return System.Label.BCD_error_message;
                }
                
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                                
                list<string> listBundleToRemove = getBundleProductToRemove(subscriptionId, listStartSubProduct[0].Zuora__Product__r.Name);
                list<string> listBundleId = new list<String>();

                //set quote payment method for null paymentmethod
                if(modeDePaiement == null) {
                    modeDePaiement = listStartSubProduct[0].Zuora__Subscription__r.Quote__r.QUO_Mode_de_paiement__c;
                }

                // check if sub is activated or suspended
                if(listStartSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active || listStartSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Suspended) 
                {
                    //get product of charge 'Premium' related to the same product of charge 'start'
                    list<zqu__productRatePlan__c> listPremuimProduct = [SELECT zqu__ZuoraId__c, Name, bandwidth__c
                                                                        FROM zqu__productRatePlan__c
                                                                        WHERE Name =: System.Label.Premium_BaseProduct 
                                                                            AND zqu__Product__r.Name =: listStartSubProduct[0].Zuora__Product__r.Name 
                                                                            AND (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) 
                                                                            AND (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) 
                                                                            AND zqu__Deleted__c = FALSE];
                    // Bundle info
                    string access = null;
                    if(category != null && !string.isBlank(category)) {
                        access = listPremuimProduct[0].Name + ' ' + category;
                    }
                    if((options != null && options.size() > 0) || category != null) {
                        listBundleId =  getBundleToAdd ( options, listStartSubProduct[0].Zuora__Product__r.Name, access);
                    }

                    if(listPremuimProduct.size() > 0 && listPremuimProduct != null) 
                    {
                        list<Zuora__SubscriptionProductCharge__c> listSubProductCharges = [ SELECT Zuora__OriginalProductRatePlanChargeId__c, Zuora__Product__r.Zuora__External_Id__c, Zuora__RatePlanId__c
                                                                                            FROM Zuora__SubscriptionProductCharge__c
                                                                                            WHERE Zuora__Subscription__c = : subscriptionId];

                        list<zqu__ProductRatePlanCharge__c> listCollabAndCoupon = [ SELECT name, zqu__ProductRatePlan__r.Category__c, zqu__ZuoraId__c, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                                    FROM zqu__ProductRatePlanCharge__c
                                                                                    WHERE (zqu__ProductRatePlan__r.Category__c = 'Collaborator' OR zqu__ProductRatePlan__r.Category__c = 'Coupon')
                                                                                    AND zqu__ProductRatePlan__r.zqu__Product__r.Name = : listStartSubProduct[0].Zuora__Product__r.Name AND
                                                                                        (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                        (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE];
                        // discount productId of a collaborator
                        map<string, zqu__ProductRatePlanCharge__c> mapCategoryPRPCharge = new map<string, zqu__ProductRatePlanCharge__c>();
                        if(listCollabAndCoupon.size() > 0 && listCollabAndCoupon != null) {
                            for(zqu__ProductRatePlanCharge__c PRPCharge : listCollabAndCoupon) {
                                mapCategoryPRPCharge.put(PRPCharge.zqu__ProductRatePlan__r.Category__c, PRPCharge);
                            }
                        }
                        string PRPChargeId = getCollaboratorCharge(subscriptionId); // get the discount product of a collaborator

                        string PRPId; 
                        string ratePlanId;
                        string ratePlanChargeId;

                        if(listStartSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'Y' && PRPChargeId != null) {
                            PRPId = PRPChargeId.substring (0, PRPChargeId.indexOf(','));
                        }

                        if(PRPChargeId != null) { ratePlanChargeId = PRPChargeId.substring (PRPChargeId.indexOf(',') + 1, PRPChargeId.length()); }

                        if((listStartSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'N' && ratePlanChargeId == null) ||
                           (listStartSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'Y' && ratePlanChargeId != null)) {
                            PRPChargeId = null;
                        }
                        if(listStartSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'N' && PRPChargeId != null) {
                            ratePlanId = ratePlanChargeId;
                        }
                        if(mapCategoryPRPCharge.keyset().size() > 0 && mapCategoryPRPCharge.get('Collaborator') != null) {
                            for(Zuora__SubscriptionProductCharge__c subCharge : listSubProductCharges) {
                                if(subCharge.Zuora__OriginalProductRatePlanChargeId__c == mapCategoryPRPCharge.get('Collaborator').zqu__ZuoraId__c && listStartSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'Y') {
                                    PRPId = null;
                                    break;
                                }
                            }
                        }
                        // End of discount productId of a collaborator part

                        date endDate, triggerDate, previewTriggerDate, previewEndDate;
                        // for active sub
                        if(listStartSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active) 
                        {
                            //set trigger date, preview trigger date, end date and preview end date for different type of update
                            //in case of Upgrade without renew
                            if(nbPeriodes == null) {
                                date ratePlanStartDate = getStartRatePlanEffectiveDate(listStartSubProduct[0].Zuora__Subscription__r.Zuora__Zuora_Id__c);
                                if(ratePlanStartDate != null) {
                                    if(ratePlanStartDate > date.today()) {
                                        triggerDate = ratePlanStartDate;
                                    } else {
                                        triggerDate = date.today();
                                    }
                                }
                                previewTriggerDate = triggerDate;
                                endDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                                previewEndDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(-1);
                            } //in case of immediat upgrade + renew
                            else if(withRenew && immediateUpgrade) {

                                triggerDate = date.today();
                                previewTriggerDate = triggerDate;
                                endDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes);
                                previewEndDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes - 1);
                            } //in case of upgrade + renew
                            else {
                                triggerDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                                previewTriggerDate = triggerDate;
                                endDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes - 1);
                                previewEndDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes - 1);
                            }
                        } // renew for suspeded Sub
                        else 
                        {
                            //Resume Non Active Sub
                            triggerDate = date.today();
                            previewTriggerDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                            endDate = Date.today().addMonths(nbPeriodes - 1);
                            previewEndDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes - 1);
                            isActive = false;
                        }
                        //get Tax rate Plan name (based on country && type of the sub example: SME or person)
                        string productName = listStartSubProduct[0].Zuora__Product__r.Name;

                        //string userCountry = '%'+listStartSubProduct[0].Zuora__Subscription__r.Quote__r.CreatedBy.Country;
                        list<zqu__productrateplancharge__c> listTimbreFiscal = [SELECT zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                                FROM zqu__productrateplancharge__c
                                                                                WHERE Name = : system.label.Rate_Plan_Timbre_Fiscal AND
                                                                                zqu__ProductRatePlan__r.zqu__ZProduct__r.Name like : productName AND
                                                                                    (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                    (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                                                zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                                                                LIMIT 1];
                        // call preview sub to get the needed amount for this action
                        string previewResult;
                        double nonTaxableAmount;
                        zqu__productrateplancharge__c timbreFiscal = new zqu__productrateplancharge__c();

                        // mode de paiement = cash with timbre fiscale
                        if(modeDePaiement == 'Cash' && listTimbreFiscal.size() > 0 && listTimbreFiscal != null && currentUser.Profile.Name !=  System.Label.Distributor_Profile) {
                            timbreFiscal = listTimbreFiscal[0];
                            previewResult  = upgradeSubProductPreview(
                                listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                listPremuimProduct[0].zqu__ZuoraId__c, PRPId, listStartSubProduct[0].Zuora__RatePlanId__c, ratePlanId,
                                previewEndDate, previewTriggerDate, isActive, null, null, null, listPremuimProduct[0].bandwidth__c, ((listStartSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), double.ValueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);
                            // fisrt preview API call
                            ZuoraResponseObjects.ZuoraPreviewResponse firstPreview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                            if(firstPreview.success) 
                            {
                                previewResult = upgradeSubProductPreview(
                                    listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                    listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                    listPremuimProduct[0].zqu__ZuoraId__c, PRPId, listStartSubProduct[0].Zuora__RatePlanId__c, ratePlanId,
                                    previewEndDate, previewTriggerDate, isActive,
                                    listTimbreFiscal[0].zqu__ProductRatePlan__r.zqu__ZuoraId__c, listTimbreFiscal[0].zqu__ZuoraId__c, firstPreview.previewResult.invoices[0].amount, listPremuimProduct[0].bandwidth__c,
                                    ((listStartSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), Double.ValueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);
                                // second preview API call
                                ZuoraResponseObjects.ZuoraPreviewResponse secondPreview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                                if(secondPreview.zuoraLogs.size() > 0 && secondPreview.zuoraLogs != null) { setLog.addAll(secondPreview.zuoraLogs); }
                                    
                                if(secondPreview.success) {
                                    nonTaxableAmount = firstPreview.previewResult.invoices[0].amount;
                                    firstPreview.previewResult.invoices[0].amount = secondPreview.previewResult.invoices[0].amount;
                                    //add conversion rate to the response
                                    list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode FROM CurrencyType WHERE IsoCode = 'USD'];

                                    firstPreview.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);
                                    previewResult = JSON.serialize(firstPreview, true);
                                }
                            }
                        } // mode de paiement != cash or = cash without timbre fiscale
                        else {
                            previewResult = upgradeSubProductPreview(
                                listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                listPremuimProduct[0].zqu__ZuoraId__c, PRPId, listStartSubProduct[0].Zuora__RatePlanId__c, ratePlanId,
                                previewEndDate, previewTriggerDate, isActive, null, null, null, listPremuimProduct[0].bandwidth__c,
                                ((listStartSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), double.valueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);

                            timbreFiscal = null;
                            nonTaxableAmount = null;
                        }

                        ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                        if(preview.success) {
                            double currentAmount = preview.previewResult.invoices[0].amount;
                            if(isPreview) 
                            {
                                listLog.addAll(preview.zuoraLogs);
                                insert listLog;

                                return previewResult;
                            } 
                            else {
                                // Check the credit if it's a renew by a distributor
                                user grosssiste = null;
                                if(listDistributorSub.size() > 0 && listDistributorSub != null) {

                                    if(listDistributorSub[0].Zuora__Account__r.parentId != null) {
                                        grosssiste = [SELECT ID FROM User WHERE AccountId = :listDistributorSub[0].Zuora__Account__r.parentId LIMIT 1];
                                    }
                                    //get Account payments Info
                                    HttpResponse accountResponse = ZuoraManager.getAccountSummary(listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                    ZuoraResponseObjects.ZuoraGetAccount accountInfo = (ZuoraResponseObjects.ZuoraGetAccount) System.JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);

                                    if(accountInfo.success) {
                                        // check if the current balance greater than the the account threshold
                                        // this step to prevent renew for distributor haven't enough credits
                                        if(-(double.valueOf(accountInfo.basicInfo.balance))  >= double.valueOf (currentAmount)) {
                                            haveCredit = true;
                                        } else {
                                            haveCredit = false;
                                        }
                                    }
                                } else {
                                    haveCredit = false;
                                }

                                if((!haveCredit && listDistributorSub.size() == 0) || (haveCredit && listDistributorSub.size() > 0)) {
                                    date nextBillDate = null;
                                    //adjust BCD for suspeded sub
                                    if(!isActive) 
                                    {
                                        nextBillDate = calculateNewRenewalDate(date.today(), nbPeriodes, date.today().day());

                                        //adjust BCD on account
                                        // create the body // send the request //deserialize the response // create logs
                                        ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(date.today().day());
                                        HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                        sleepAfterBCD();
                                        ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBDCResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                        
                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), null, listStartSubProduct[0].Zuora__Subscription__c, listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                           ZuoraObjects.updateAccountAPIUrl + listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                           adjustBDCResponse.success, adjustBDCResponse.reasons == null?null : adjustBDCResponse.reasons[0].message, ZuoraObjects.put, false));
                                    } 
                                    else{
                                         // send the request //deserialize the response // create logs
                                        HttpResponse res = ZuoraManager.getZuoraAccount(listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                        ZuoraResponseObjects.ZuoraGetAccount accountResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(res.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                                        
                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(null, null, listStartSubProduct[0].Zuora__Subscription__c, listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                            ZuoraObjects.accountAPIUrl + listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, res.getBody() != null ? res.getBody() : null,
                                                                                            accountResponse.success, accountResponse.reasons == null?null : accountResponse.reasons[0].message, ZuoraObjects.get, false));

                                        nextBillDate = calculateNewRenewalDate(listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c, nbPeriodes, accountResponse.billingAndPayment.billCycleDay);
                                    }

                                    //fill order fields to upgrade sub product // create the body // send the request //deserialize the response // create logs
                                    ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillUpgradeProduct(
                                        listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                        listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                        listStartSubProduct[0].Zuora__Subscription__r.Quote__c,
                                        listPremuimProduct[0].zqu__ZuoraId__c, PRPId, listStartSubProduct[0].Zuora__RatePlanId__c, ratePlanId,
                                        listStartSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c,
                                        triggerDate, endDate, nextBillDate, nbPeriodes, withRenew, isActive, timbreFiscal, nonTaxableAmount, subscriptionId,
                                        listStartSubProduct[0].Zuora__Subscription__r.RenewalSequenceNumber__c, ((listStartSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), Double.ValueOf(listStartSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);
                                    
                                    try {

                                        HttpResponse response;
                                        response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.ADD_PRODUCT );
                                        ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                                        orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                                        if(!orderResponse.success)
                                        {
                                            string responseBody =  sleep(500, zSub); // send create order API request one more time
                                            orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(responseBody, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                        }

                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), null, listStartSubProduct[0].Zuora__Subscription__c, listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, response.getBody(),
                                                                                           orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                                        if(orderResponse.success)
                                        {
                                            // check if the sub have free days
                                            if(listStartSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c != null && integer.valueOf(listStartSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c) > 0)
                                            {
                                                //adjust BCD on account
                                                // create the body // send the request //deserialize the response // create logs
                                                ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(nextBillDate.addDays(integer.valueOf(listStartSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c)).day());
                                                HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                                sleepAfterBCD();
                                                ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBDCResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                                
                                                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), null, listStartSubProduct[0].Zuora__Subscription__c, listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                                   ZuoraObjects.updateAccountAPIUrl + listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                                   adjustBDCResponse.success, adjustBDCResponse.reasons == null?null : adjustBDCResponse.reasons[0].message, ZuoraObjects.put, false));
                                            }
                                            
                                            Date oldExpectedRenewalDate;
                                            if(listStartSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active) {
                                                oldExpectedRenewalDate = listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                                            } else {
                                                oldExpectedRenewalDate = Date.today();
                                            }
                                            sleepAfterBCD();

                                            //create payment for the upgrade action
                                            return createRenewPayment(listStartSubProduct[0], nbPeriodes,
                                                                      currentAmount, orderResponse.invoiceNumbers.size() > 0?orderResponse.invoiceNumbers[0] : null, null,
                                                                      true, false, modeDePaiement, transactionNumber, operator, dollarPayment, CDFPayment, dollarRefund, CDFRefund, 'Start', 'Premium', setLog,
                                                                      haveCredit?listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c : null, grosssiste?.Id, oldExpectedRenewalDate, offer, options);
                                        } 
                                        else { // create order is failed
                                            if(!isActive) // re adjusted the BCD since the order is failed
                                            {
                                                //adjust BCD on account
                                                // create the body // send the request //deserialize the response // create logs
                                                ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(listStartSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.day());

                                                HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);

                                                ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBDCResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize( updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                                
                                                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), null, listStartSubProduct[0].Zuora__Subscription__c, listStartSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                                   ZuoraObjects.updateAccountAPIUrl + listStartSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                                   adjustBDCResponse.success, adjustBDCResponse.reasons == null?null : adjustBDCResponse.reasons[0].message, ZuoraObjects.put, false));
                                            }

                                            if(setLog.size() > 0 && setLog != null) 
                                            {
                                                listLog.AddAll(setLog);
                                                insert listLog;
                                            }

                                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, subscriptionId, ZuoraObjects.ordersAPIUrl);

                                            return response.getBody();
                                        }
                                    }
                                    catch(Exception e) {
                                        ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
                                        error.message = e.getMessage()+ ' /// '+ e.getLineNumber();
                                        error.zuoraLog = setLog;
                                        system.debug(e.getLineNumber());
                                        throw new CustomException(json.serialize(error, true));
                                    }
                                } else {
                                    return System.label.No_Credit;
                                }
                            }
                        } else {
                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, preview.reasons[0].message, subscriptionId, 'upgradeSubscriptionProduct');

                            return previewResult;
                        }
                    } else {
                        return system.label.Impossible_Action;
                    }
                } else {
                    return system.label.Impossible_Action;
                }
            } else {
                return System.label.Upgrade_Product_Failure;
            }
        } else {
            return System.label.Empty_Number_Of_Periodes;
        }
    }

    /**
     * Methode pour downgrade un produit sur la souscription
     * <p>
     * @param subscriptionId  id de la souscription,
     * @param newQuoteID id du devis,
     * @param nbPeriodes nombre de periodes a reabonner,
     * @param isPreview choix du preview
     * @param modeDePaiement mode de paiement
     * @param transactionNumber Numéro de transaction
     * @param operator operateur de MM
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string downgradeSubscriptionProduct(id subscriptionId, string newQuoteID, integer nbPeriodes, boolean isPreview, string modeDePaiement, string transactionNumber,
                                                      string operator, double dollarPayment, integer CDFPayment, integer dollarRefund, integer CDFRefund, string bizaOrderId, string offer, 
                                                      list<string> options, string category){
        Set<Log__c> setLog = new set<Log__c>();
        list<Log__c> listLog = new list<Log__c>();
        boolean isActive = true;
        boolean haveCredit = false;
        string invoiceNumber;
        user currentUser = [SELECT USR_DistributeurID__c, Profile.Name
                            FROM User
                            WHERE id = :UserInfo.getUserId()];
        //get distributor having account in Zuora

        list<Zuora__Subscription__c> listDistributorSub = new List<Zuora__Subscription__c>();

        if(currentUser.Profile.Name != 'Utilisateur du Portail Client' &&  currentUser.USR_DistributeurID__c != null) {
            listDistributorSub =  [SELECT Zuora__Account__r.parentId, Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.DistributorOperationBillingMinThreshold__c
                                   FROM Zuora__Subscription__c
                                   WHERE Zuora__CustomerAccount__r.Zuora__Account__r.ACC_Distributor_Number__c  = : currentUser.USR_DistributeurID__c];
        }
        if(nbPeriodes != null) {
            list<Zuora__SubscriptionProductCharge__c> listPremiumSubProduct = [SELECT Zuora__RatePlanName__c, Name, Zuora__Zuora_Id__c, Zuora__Subscription__r.BoxNumber__c,
                                                                               Zuora__RatePlanId__c, Zuora__Subscription__r.ExpectedRenewalDate__c,
                                                                               Zuora__Subscription__r.Zuora__Status__c, Zuora__Subscription__r.CompensationDaysAtNextRenewal__c,
                                                                               Zuora__Subscription__r.Zuora__ServiceActivationDate__c, Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                               Zuora__Subscription__r.Zuora__Account__c, Zuora__Subscription__r.isCollaborator__c,
                                                                               Zuora__Subscription__r.Zuora__Account__r.BillingCountry,
                                                                               Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode,
                                                                               Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode, Zuora__Subscription__r.Coupon__c,
                                                                               Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                                                               Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                                               Zuora__Subscription__r.Quote__c, Zuora__Subscription__r.Quote__r.CreatedBy.Country,
                                                                               Zuora__Subscription__r.Quote__r.QUO_PTO__c, Zuora__Subscription__r.SUB_Status__c,
                                                                               Zuora__Subscription__r.Quote__r.QUO_Periodes_Prepayees__c, Zuora__Subscription__r.C_Migration_Date__c,
                                                                               Zuora__Subscription__r.Quote__r.QUO_T_Numero_De_Commande__c, Zuora__Subscription__r.Create_Bundle_C_subscription__c,
                                                                               Zuora__Subscription__r.Quote__r.QUO_Mode_de_paiement__c, Zuora__Product__r.Zuora__External_Id__c,
                                                                               Zuora__Product__r.Name, Zuora__Subscription__c, Zuora__Subscription__r.RenewalSequenceNumber__c,
                                                                               Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c
                                                                               FROM Zuora__SubscriptionProductCharge__c
                                                                               WHERE Zuora__Type__c = 'Recurring' AND Zuora__RatePlanName__c = 'Premium' AND Zuora__Subscription__c = : subscriptionId AND Zuora__Subscription__r.SuspensionReason__c != 'Move-Requested'];

            // check if the product charge is 'Premium'
            if(listPremiumSubProduct != null && listPremiumSubProduct.size() > 0) 
            {
                // if the BCD is not aligned with the expected renewal date block the renewal
                string expectedRenewalDay = string.valueof(listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.day());
                string billCycleDay = listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c;
                billCycleDay = billCycleDay != null ? billCycleDay : 'null';
                // if the migration is scheduled in the future block the renewal
                Date migrationDate = Date.valueOf(listPremiumSubProduct[0].Zuora__Subscription__r.C_Migration_Date__c);
                if(migrationDate != null && (migrationDate > Date.today() || (migrationDate == Date.today() && !System.isBatch()))){
                    return System.Label.Sub_InMigration_Message +' '+String.valueOf(migrationDate);               
                }else if(!billCycleDay.contains(expectedRenewalDay) && listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active && !Test.isRunningTest()){
                    return System.Label.BCD_error_message;
                }

                ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                list<string> listBundleToRemove = getBundleProductToRemove(subscriptionId, listPremiumSubProduct[0].Zuora__Product__r.Name);

                // set quote payment methode if null
                if(modeDePaiement == null) {
                    modeDePaiement = listPremiumSubProduct[0].Zuora__Subscription__r.Quote__r.QUO_Mode_de_paiement__c;
                }


                // check if sub is active or suspended
                if(listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active || listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Suspended) 
                {
                    list<zqu__productRatePlan__c> listStartSubProduct = [ SELECT zqu__ZuoraId__c, Name, bandwidth__c
                                                                          FROM zqu__productRatePlan__c
                                                                          WHERE Name =: System.Label.Start_BaseProduct AND
                                                                          zqu__Product__r.Name = : listPremiumSubProduct[0].Zuora__Product__r.Name AND
                                                                              (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                              (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                                                                          zqu__Deleted__c = FALSE];

                    if(listStartSubProduct.size() > 0 && listStartSubProduct != null) 
                    {
                        // Bundle info
                        string access = null;
                        if(category != null && !string.isBlank(category)) {
                            access = listStartSubProduct[0].Name + ' ' + category;
                        }
                        list<string> listBundleId = new list<String>();
                        if((options != null && options.size() > 0) || category != null) {
                            listBundleId =  getBundleToAdd ( options, listPremiumSubProduct[0].Zuora__Product__r.Name, access);
                        }

                        list<Zuora__SubscriptionProductCharge__c> listSubProductCharges = [ SELECT Zuora__OriginalProductRatePlanChargeId__c, Zuora__Product__r.Zuora__External_Id__c, Zuora__RatePlanId__c
                                                                                            FROM Zuora__SubscriptionProductCharge__c
                                                                                            WHERE Zuora__Subscription__c = : subscriptionId];
                        list<zqu__ProductRatePlanCharge__c> listCollabAndCoupon = [ SELECT name, zqu__ProductRatePlan__r.Category__c, zqu__ZuoraId__c, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                                    FROM zqu__ProductRatePlanCharge__c
                                                                                    WHERE (zqu__ProductRatePlan__r.Category__c = 'Collaborator' OR zqu__ProductRatePlan__r.Category__c = 'Coupon')
                                                                                    AND zqu__ProductRatePlan__r.zqu__Product__r.Name = : listPremiumSubProduct[0].Zuora__Product__r.Name AND (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                        (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE];
                        // get collab or coupon product
                        map<string, zqu__ProductRatePlanCharge__c> mapCategoryPRPCharge = new map<string, zqu__ProductRatePlanCharge__c>();
                        if(listCollabAndCoupon.size() > 0 && listCollabAndCoupon != null) {
                            for(zqu__ProductRatePlanCharge__c PRPCharge : listCollabAndCoupon) {
                                mapCategoryPRPCharge.put(PRPCharge.zqu__ProductRatePlan__r.Category__c, PRPCharge);
                            }
                        }
                        string PRPChargeId = getCollaboratorCharge(subscriptionId);
                        string PRPId;
                        string ratePlanId;
                        string ratePlanChargeId;
                        if(listPremiumSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'Y' && PRPChargeId != null) {
                            PRPId = PRPChargeId.substring (0, PRPChargeId.indexOf(','));
                        }

                        if(PRPChargeId != null)
                            ratePlanChargeId = PRPChargeId.substring (PRPChargeId.indexOf(',') + 1, PRPChargeId.length());

                        if((listPremiumSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'N' && ratePlanChargeId == null) ||
                           (listPremiumSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'Y' && ratePlanChargeId != null)) {
                            PRPChargeId = null;
                        }
                        if(listPremiumSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'N' && PRPChargeId != null) {
                            ratePlanId = ratePlanChargeId;
                        }
                        if(mapCategoryPRPCharge.keyset().size() > 0 && mapCategoryPRPCharge.get('Collaborator') != null) {
                            for(Zuora__SubscriptionProductCharge__c subCharge : listSubProductCharges) {
                                if(subCharge.Zuora__OriginalProductRatePlanChargeId__c == mapCategoryPRPCharge.get('Collaborator').zqu__ZuoraId__c && listPremiumSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'Y') {
                                    PRPId = null;
                                    break;
                                }
                            }
                        }
                        // end of this step

                        // downgrade 
                        // set endDate,triggerDate,previewTriggerDate and previewEndDate for downgrade 
                        date endDate, triggerDate, previewTriggerDate, previewEndDate;
                        if(listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active) // ACTIVE SUB
                        {
                            triggerDate = listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                            previewTriggerDate = triggerDate;
                            endDate = listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes - 1);
                            previewEndDate = listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes - 1);
                        } 
                        else { // SUSpended SUB
                            triggerDate = date.today();
                            previewTriggerDate = listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                            endDate = date.today().addMonths(nbPeriodes - 1);
                            previewEndDate = listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.addMonths(nbPeriodes - 1);
                            isActive = false;
                        }

                        //get Tax rate Plan product name (Based on the country and sub type SME or Person)
                        string productName = listPremiumSubProduct[0].Zuora__Product__r.Name;

                        list<zqu__productrateplancharge__c> listTimbreFiscal = [SELECT zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                                                FROM zqu__productrateplancharge__c
                                                                                WHERE Name = : system.label.Rate_Plan_Timbre_Fiscal AND
                                                                                zqu__ProductRatePlan__r.zqu__ZProduct__r.Name like : productName AND
                                                                                    (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                    (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                                                zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                                                                LIMIT 1];
                        
                                                                                // call preview sub to get the needed amount for this action
                        string previewResult;
                        double nonTaxableAmount;
                        zqu__productrateplancharge__c timbreFiscal = new zqu__productrateplancharge__c();

                        // Add tax if payment is by cash and renew not by Distributor
                        if(modeDePaiement == 'Cash' && listTimbreFiscal.size() > 0 && listTimbreFiscal != null && currentUser.Profile.Name !=  System.Label.Distributor_Profile) 
                        {
                            timbreFiscal = listTimbreFiscal[0];

                            previewResult  = upgradeSubProductPreview(
                                listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                listStartSubProduct[0].zqu__ZuoraId__c, PRPId, listPremiumSubProduct[0].Zuora__RatePlanId__c, ratePlanId,
                                previewEndDate, previewTriggerDate, isActive, null, null, null, listStartSubProduct[0].bandwidth__c, ((listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), double.ValueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);

                            ZuoraResponseObjects.ZuoraPreviewResponse firstPreview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                            if(firstPreview.zuoraLogs != null && firstPreview.zuoraLogs.size() > 0) { setLog.addAll(firstPreview.zuoraLogs); }
                                
                            if(firstPreview.success) 
                            {
                                previewResult = upgradeSubProductPreview(
                                    listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                    listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                    listStartSubProduct[0].zqu__ZuoraId__c, PRPId, listPremiumSubProduct[0].Zuora__RatePlanId__c, ratePlanId,
                                    previewEndDate, previewTriggerDate, isActive, timbreFiscal.zqu__ProductRatePlan__r.zqu__ZuoraId__c,
                                    timbreFiscal.zqu__ZuoraId__c, firstPreview.previewResult.invoices[0].amount, listStartSubProduct[0].bandwidth__c, ((listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), double.ValueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);

                                ZuoraResponseObjects.ZuoraPreviewResponse secondPreview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                                
                                if(secondPreview.zuoraLogs != null && secondPreview.zuoraLogs.size() > 0) { setLog.addAll(secondPreview.zuoraLogs); }
                                    
                                if(secondPreview.success) {
                                    nonTaxableAmount = firstPreview.previewResult.invoices[0].amount;
                                    firstPreview.previewResult.invoices[0].amount = secondPreview.previewResult.invoices[0].amount;
                                    //add conversion rate to the response
                                    list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode FROM CurrencyType WHERE IsoCode = 'USD'];
                                    firstPreview.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);
                                    previewResult = JSON.serialize(firstPreview, true);
                                }
                            }
                        } // paiement other then cash or cash without timbre fiscal
                        else 
                        {
                            previewResult = upgradeSubProductPreview(
                                listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                listStartSubProduct[0].zqu__ZuoraId__c, PRPId, listPremiumSubProduct[0].Zuora__RatePlanId__c, ratePlanId,
                                previewEndDate, previewTriggerDate, isActive, null, null, null, listStartSubProduct[0].bandwidth__c, ((listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), double.ValueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);

                            nonTaxableAmount = null;
                            timbreFiscal = null;
                        }

                        ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                        if(preview.success) {

                            double currentAmount = preview.previewResult.invoices[0].amount;

                            if(isPreview) {
                                if(setLog.size() > 0 && setLog != null) {
                                    listLog.addAll(setLog);
                                    insert listLog;
                                }

                                return previewResult;
                            } 
                            else {
                                user grosssiste = null;
                                if(listDistributorSub.size() > 0 && listDistributorSub != null) {

                                    if(listDistributorSub[0].Zuora__Account__r.parentId != null) {
                                        grosssiste = [SELECT ID FROM User WHERE AccountId = :listDistributorSub[0].Zuora__Account__r.parentId LIMIT 1];
                                    }
                                    //get Account payments Info
                                    HttpResponse accountResponse = ZuoraManager.getAccountSummary(listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                    ZuoraResponseObjects.ZuoraGetAccount accountInfo = (ZuoraResponseObjects.ZuoraGetAccount) System.JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                                    
                                    if(accountInfo.success) {
                                        // check if the current balance greater than the account threshold
                                        // this step to prevent renew for distributor haven't enough credits
                                        if(-(double.valueOf(accountInfo.basicInfo.balance))  >= double.valueOf (currentAmount)) {
                                            haveCredit = true;
                                        } else {
                                            haveCredit = false;
                                        }
                                    }
                                } else {
                                    haveCredit = false;
                                }

                                if((!haveCredit && listDistributorSub.size() == 0) || (haveCredit && listDistributorSub.size() > 0)) {
                                    date nextBillDate = null;

                                    if(!isActive) //Resume Non Active Sub and adjust the bcd on the account
                                    {
                                        nextBillDate = calculateNewRenewalDate(date.today(), nbPeriodes, date.today().day());
                                        
                                        ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(date.today().day());
                                        HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                        sleepAfterBCD();
                                        ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBDCResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);

                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Account__c, listPremiumSubProduct[0].Zuora__Subscription__c, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                           ZuoraObjects.updateAccountAPIUrl + listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                           adjustBDCResponse.success, adjustBDCResponse.reasons == null?null : adjustBDCResponse.reasons[0].message, ZuoraObjects.put, false));
                                    } 
                                    else {
                                        // send the request //deserialize the response // create logs
                                        HttpResponse res = ZuoraManager.getZuoraAccount(listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                        ZuoraResponseObjects.ZuoraGetAccount accountResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(res.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                                        
                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(null, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Account__c, listPremiumSubProduct[0].Zuora__Subscription__c, 
                                                                                            listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                           ZuoraObjects.accountAPIUrl + listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, res.getBody() != null ? res.getBody() : null,
                                                                                           accountResponse.success, accountResponse.reasons == null?null : accountResponse.reasons[0].message, ZuoraObjects.get, false));

                                        nextBillDate = calculateNewRenewalDate(listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c, nbPeriodes, accountResponse.billingAndPayment.billCycleDay);
                                    }

                                    //fill downgrade order fields
                                    ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillDowngradeProduct(
                                        listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                        listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                        listPremiumSubProduct[0].Zuora__Subscription__r.Quote__c, listStartSubProduct[0].zqu__ZuoraId__c, PRPId,
                                        listPremiumSubProduct[0].Zuora__RatePlanId__c, ratePlanId, listPremiumSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c,
                                        triggerDate, endDate, nextBillDate, nbPeriodes, isActive, timbreFiscal, nonTaxableAmount, subscriptionId, listPremiumSubProduct[0].Zuora__Subscription__r.RenewalSequenceNumber__c, ((listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c == null || string.isBlank(string.valueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c))) && mapCategoryPRPCharge.keyset().size() == 0)?null : mapCategoryPRPCharge.get('Coupon'), double.ValueOf(listPremiumSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId, listBundleToRemove);

                                    try {
                                        HttpResponse response;
                                        response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.ADD_PRODUCT);

                                        ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse  = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                                        if(!orderResponse.success) {
                                            string responseBody =  sleep(500, zSub);
                                            orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(responseBody, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                        }

                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Account__c, listPremiumSubProduct[0].Zuora__Subscription__c, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl,
                                                                                           response.getBody(), orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));

                                        if(orderResponse.success) 
                                        {
                                            if(listPremiumSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c != null && integer.valueOf(listPremiumSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c) > 0) 
                                            {
                                                //adjust BCD on account
                                                // create the body // send the request //deserialize the response // create logs
                                                ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(nextBillDate.addDays(integer.valueOf(listPremiumSubProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c)).day());
                                                HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                                sleepAfterBCD();
                                                ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBCDResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                                
                                                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Account__c, listPremiumSubProduct[0].Zuora__Subscription__c, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                                   ZuoraObjects.updateAccountAPIUrl + listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                                   adjustBCDResponse.success, adjustBCDResponse.reasons == null?null : adjustBCDResponse.reasons[0].message, ZuoraObjects.put, true));
                                            }

                                            Date oldExpectedRenewalDate;
                                            if(listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == 'Active') {
                                                oldExpectedRenewalDate = listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c;
                                            } else {
                                                oldExpectedRenewalDate = Date.today();
                                            }
                                            return createRenewPayment( listPremiumSubProduct[0], nbPeriodes, currentAmount, orderResponse.invoiceNumbers.size() > 0?orderResponse.invoiceNumbers[0] : null, null,
                                                                       false, true, modeDePaiement, transactionNumber, operator, dollarPayment, CDFPayment, dollarRefund, CDFRefund, 'Premium', 'Start', setLog,
                                                                       haveCredit?listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c : null, grosssiste?.Id, oldExpectedRenewalDate, offer, options);
                                        } 
                                        else { // if order is failed re adjut the BCD for suspended sub
                                            if(!isActive) {
                                                //adjust BCD on account
                                                // create the body // send the request //deserialize the response // create logs
                                                ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(listPremiumSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.day());
                                                
                                                HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                                
                                                ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBCDResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                                
                                                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), null, listPremiumSubProduct[0].Zuora__Subscription__c, listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                                                   ZuoraObjects.updateAccountAPIUrl + listPremiumSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                                   adjustBCDResponse.success, adjustBCDResponse.reasons == null?null : adjustBCDResponse.reasons[0].message, ZuoraObjects.put, true));
                                            }
                                            if(setLog.size() > 0 && setLog != null) {
                                                listLog.addAll(setLog);
                                                insert listLog;
                                            }
                                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, subscriptionId, ZuoraObjects.ordersAPIUrl);

                                            return response.getBody();
                                        }
                                    } catch(Exception e) {

                                        ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
                                        error.message = e.getMessage() + ' /// '+ e.getLineNumber();
                                        error.zuoraLog = setLog;
                                        system.debug(e.getLineNumber());
                                        throw new CustomException(json.serialize(error, true));
                                    }
                                } else {
                                    return System.label.No_Credit;
                                }

                            }
                        } else {
                            if(setLog.size() > 0 && setLog != null) {
                                listLog.addAll(setLog);
                                insert listLog;
                            }
                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, preview.reasons[0].message, subscriptionId, ZuoraObjects.previewOrdersAPIUrl);

                            return previewResult;
                        }
                    } else {
                        return system.label.Impossible_Action;
                    }
                } else {
                    return system.label.Impossible_Action;
                }
            } else {
                return System.label.Upgrade_Product_Failure;
            }
        } else {
            return System.label.Empty_Number_Of_Periodes;
        }
    }

    /**
     * Methode pour afficher l'apercu d'un reabo
     * <p>
     * @param subId  ID de la souscription,
     * @param nbPeriodes nombre de periodes prepayes
     * @param withoutTax boolean pour calculer le prix total sans ajouter les fiscaux
     * @param paymentMode mode de paiement du réabo
     * @return resultat de l'aperçu
     * */
    @AuraEnabled
    public static string renewSubPreview(id subId, integer nbPeriodes, boolean withoutTax, string paymentMode, boolean fromUI, string PRPId, string offer, list<string> options, string category) {
        set<Log__c> setLog = new set<Log__c>();
        list<Log__c> listLog = new list<Log__c>();
        user currentUser = [SELECT USR_DistributeurID__c, Profile.Name
                            FROM User
                            WHERE id = :UserInfo.getUserId()];
        if(nbPeriodes != null) {
            list<zqu__ProductRatePlan__c> listBasePRP = [SELECT Id, Name, bandwidth__c
                                                         FROM zqu__ProductRatePlan__c
                                                         WHERE (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                                             (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                                                         zqu__Deleted__c = FALSE AND Type__c = 'Base' ];
            set<string> setBaseProducts = new set<string>();
            if(listBasePRP.size() > 0 && listBasePRP != null) {
                for(zqu__ProductRatePlan__c prod : listBasePRP) {
                    setBaseProducts.add(prod.Name);
                }
            }
            // get needed info to show the preview of a renew sub
            List<Zuora__SubscriptionProductCharge__c> currentSubProduct = [ SELECT Zuora__RatePlanName__c, Name, Zuora__Zuora_Id__c, Zuora__Subscription__r.Zuora__Status__c,
                                                                            Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__Subscription__r.Name,
                                                                            Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__Subscription__r.isCollaborator__c,
                                                                            Zuora__Subscription__r.Quote__c, Zuora__Subscription__r.ExpectedRenewalDate__c, Zuora__Product__r.Zuora__External_Id__c,
                                                                            Zuora__Subscription__r.Zuora__SubscriptionNumber__c, Zuora__Subscription__r.Zuora__Account__c, Zuora__RatePlanId__c,
                                                                            Zuora__Subscription__r.Quote__r.CreatedBy.Country, Zuora__ProductName__c, Zuora__Product__r.Name, 
                                                                            Zuora__Subscription__r.Coupon__c,Zuora__Subscription__r.C_Migration_Date__c, Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c
                                                                            FROM Zuora__SubscriptionProductCharge__c
                                                                            WHERE Zuora__Subscription__c = : subId AND Zuora__RatePlanName__c IN : setBaseProducts AND Zuora__Type__c = 'Recurring' ];

            //check if Sub product is not empty
            if(currentSubProduct.size() > 0 && currentSubProduct != null) {

                boolean isActive = false;
                if(currentSubProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active) { isActive = true; }

                // if the BCD is not aligned with the expected renewal date block the renewal
                string expectedRenewalDay = string.valueof(currentSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.day());
                string billCycleDay = currentSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c;
                billCycleDay = billCycleDay != null ? billCycleDay : 'null';
                // if the migration is scheduled in the future block the renewal
                Date migrationDate = Date.valueOf(currentSubProduct[0].Zuora__Subscription__r.C_Migration_Date__c);
                if(migrationDate != null && (migrationDate > Date.today() || (migrationDate == Date.today() && !System.isBatch()))){
                    return System.Label.Sub_InMigration_Message +' '+String.valueOf(migrationDate);               
                }else if(!billCycleDay.contains(expectedRenewalDay) && isActive && !Test.isRunningTest()){
                    return System.Label.BCD_error_message;
                }

                ///////////////////////////////////////////////////////////////////////////////////////////

                if(fromUI) {
                    string PRPChargeId = getCollaboratorCharge(subId);                
                    if(currentSubProduct[0].Zuora__Subscription__r.isCollaborator__c == 'Y'){
                        PRPId = PRPChargeId.substring (0, PRPChargeId.indexOf(','));
                    }
                }

                String fibreName = currentSubProduct[0].Zuora__RatePlanName__c.containsWhitespace() ? currentSubProduct[0].Zuora__RatePlanName__c.substringBefore(' ') : currentSubProduct[0].Zuora__RatePlanName__c;
                //get product rate plan id of the reteived fiber products 
                list<zqu__productrateplan__c> PRP = [ SELECT zqu__ZuoraId__c, Name, bandwidth__c
                                                      FROM zqu__productrateplan__c
                                                      WHERE Name = : fibreName AND
                                                      zqu__Product__r.Name = : currentSubProduct[0].Zuora__ProductName__c AND
                                                          (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                                          (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                                                      zqu__Deleted__c = FALSE];

                list<string> listBundleId = new list<String>();
                string access = null;
                if(category != null && !string.isBlank(category)) {
                    access = PRP[0].Name + ' ' + category;
                }
                if((options != null && options.size() > 0) || category != null) {
                    listBundleId =  getBundleToAdd ( options, currentSubProduct[0].Zuora__ProductName__c, access);
                }

                //get Tax rate Plan
                string productName = currentSubProduct[0].Zuora__Product__r.Name;

                list<zqu__productrateplancharge__c> listTimbreFiscal = new list<zqu__productRatePlanCharge__c>();
                list<zqu__ProductRatePlanCharge__c> listCoupon = new list<zqu__ProductRatePlanCharge__c>();
                if(currentSubProduct[0].Zuora__Subscription__r.Coupon__c != null && !string.isBlank(string.valueof(currentSubProduct[0].Zuora__Subscription__r.Coupon__c))) {
                    listCoupon = [ SELECT name, zqu__ProductRatePlan__r.Category__c, zqu__ZuoraId__c, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                   FROM zqu__ProductRatePlanCharge__c
                                   WHERE zqu__ProductRatePlan__r.Category__c = 'Coupon' AND zqu__ProductRatePlan__r.zqu__Product__r.Name = :productName AND
                                       (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                       (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE];

                }

                zqu__productrateplancharge__c timbreFiscal = new zqu__productrateplancharge__c();
                if(paymentMode == 'Cash'   && currentUser.Profile.Name !=  System.Label.Distributor_Profile) {

                    listTimbreFiscal = [SELECT zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                        FROM zqu__productrateplancharge__c
                                        WHERE Name = : system.label.Rate_Plan_Timbre_Fiscal AND
                                        zqu__ProductRatePlan__r.zqu__ZProduct__r.Name like : productName AND
                                            (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                            (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                        zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                        LIMIT 1];
                    if(listTimbreFiscal != null && listTimbreFiscal.size() > 0) {
                        timbreFiscal = listTimbreFiscal[0];
                    }
                } else {
                    timbreFiscal = null;
                }

                ZuoraObjects.ZuoraOrder previewOrder = new ZuoraObjects.ZuoraOrder();
                string previewResult;
                if(withoutTax == null) {
                    withoutTax = false;
                }

                if(timbreFiscal == null || withoutTax || listTimbreFiscal.size() == 0) {

                    //fill the prview order for renew sub
                    previewOrder = zuoraMapper.fillRenewPreviewSubscription(
                        nbPeriodes, PRP[0].zqu__ZuoraId__c,
                        currentSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                        currentSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c, null, null, PRPId,
                        (currentSubProduct[0].Zuora__Subscription__r.Coupon__c == null || (string.isBlank(string.valueOf(currentSubProduct[0].Zuora__Subscription__r.Coupon__c))) && listCoupon.size() == 0)?null : (listCoupon.size() > 0?listCoupon[0] : null),
                        currentSubProduct[0].Zuora__Subscription__r.Coupon__c == null?null : double.valueOf(currentSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId);
                    HttpResponse response = ZuoraManager.previewOrder(previewOrder);
                    previewResult = response.getBody();
                    ZuoraResponseObjects.ZuoraPreviewResponse previewResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraPreviewResponse.class);

                    setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(previewOrder, true), currentSubProduct[0].Zuora__Subscription__r.Zuora__Account__c, currentSubProduct[0].Zuora__Subscription__c, currentSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.previewOrdersAPIUrl, previewResult,
                                                                       previewResponse.success, previewResponse.reasons == null?null : previewResponse.reasons[0].message, ZuoraObjects.post, false));
                } 
                else {

                    //fill the prview order for renew sub
                    previewOrder = zuoraMapper.fillRenewPreviewSubscription(
                        nbPeriodes, PRP[0].zqu__ZuoraId__c,currentSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                        currentSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c, null, null, PRPId, (currentSubProduct[0].Zuora__Subscription__r.Coupon__c == null || (string.isBlank(string.valueOf(currentSubProduct[0].Zuora__Subscription__r.Coupon__c))) && listCoupon.size() == 0)?null : (listCoupon.size() > 0?listCoupon[0] : null), currentSubProduct[0].Zuora__Subscription__r.Coupon__c == null?null : double.valueOf(currentSubProduct[0].Zuora__Subscription__r.Coupon__c), listBundleId);

                    HttpResponse response = ZuoraManager.previewOrder(previewOrder);
                    ZuoraResponseObjects.ZuoraPreviewResponse previewResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraPreviewResponse.class);
                    
                    setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(previewOrder, true), currentSubProduct[0].Zuora__Subscription__r.Zuora__Account__c, currentSubProduct[0].Zuora__Subscription__c, currentSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.previewOrdersAPIUrl, response.getBody(),
                                                                       previewResponse.success, previewResponse.reasons == null?null : previewResponse.reasons[0].message, ZuoraObjects.post, false));

                    if(setLog.size() > 0 && setLog != null) {previewResponse.zuoraLogs = setLog;}
                        
                    if(previewResponse.success) {

                        ZuoraObjects.ZuoraOrder sencondPreviewOrder = zuoraMapper.fillRenewPreviewSubscription(
                            nbPeriodes, null, currentSubProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                            currentSubProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c,
                            timbreFiscal, previewResponse.previewResult.invoices[0].Amount, PRPId, (currentSubProduct[0].Zuora__Subscription__r.Coupon__c == null || (string.isBlank(string.valueOf(currentSubProduct[0].Zuora__Subscription__r.Coupon__c))) && listCoupon.size() == 0)?null : (listCoupon.size() > 0?listCoupon[0] : null), currentSubProduct[0].Zuora__Subscription__r.Coupon__c == null?null : double.valueOf(currentSubProduct[0].Zuora__Subscription__r.Coupon__c), null);

                        response = ZuoraManager.previewOrder(sencondPreviewOrder);
                        previewresult = response.getBody();

                        ZuoraResponseObjects.ZuoraPreviewResponse secondPreviewResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraPreviewResponse.class);
                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(previewOrder, true), currentSubProduct[0].Zuora__Subscription__r.Zuora__Account__c, currentSubProduct[0].Zuora__Subscription__c, currentSubProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.previewOrdersAPIUrl, previewResult,
                                                                           secondPreviewResponse.success, secondPreviewResponse.reasons == null?null : secondPreviewResponse.reasons[0].message, ZuoraObjects.post, false));

                        if(secondPreviewResponse.success) {
                            previewResponse.previewResult.invoices[0].amount = previewResponse.previewResult.invoices[0].amount +
                            double.valueof(secondPreviewResponse.previewResult.invoices.size() == 0?0 : secondPreviewResponse.previewResult.invoices[0].amount);
                            //add conversion rate to the response
                            list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                                               FROM CurrencyType
                                                               WHERE IsoCode = 'USD'];
                            previewResponse.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);
                            previewResult = JSON.serialize(previewResponse, true);
                            if(setLog.size() > 0 && setLog != null)
                                previewResponse.zuoraLogs = setLog;
                        }
                    }
                }

                try {
                    ZuoraResponseObjects.ZuoraPreviewResponse orderResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewresult, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                    
                    if(orderResponse.success) {
                        map<string, ZuoraResponseObjects.ZuoraInvoiceItems> chargeNameInfo = new map<string, ZuoraResponseObjects.ZuoraInvoiceItems>();
                        // add charge name to the preview result
                        if(orderResponse.previewResult.invoices.size() > 0 && orderResponse.previewResult.invoices != null) {
                            for(ZuoraResponseObjects.ZuoraInvoiceItems zInvoice : orderResponse.previewResult.invoices[0].invoiceItems) {
                                chargeNameInfo.put(zInvoice.productRatePlanChargeId, zInvoice);
                            }
                        }

                        list<ZuoraResponseObjects.ZuoraInvoiceItems> listZInvoice = new list<ZuoraResponseObjects.ZuoraInvoiceItems>();
                        for(AggregateResult subProduct : [SELECT  count(id), Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c
                                                          FROM zuora__subscriptionProductCharge__c
                                                          WHERE Zuora__RatePlanName__c != null AND Zuora__ProductRatePlanChargeId__c IN : chargeNameInfo.keyset() GROUP BY Zuora__ProductRatePlanChargeId__c, Zuora__RatePlanName__c]) {
                            String productId = (String) subProduct.get('Zuora__ProductRatePlanChargeId__c');
                            String ratePlanName = (String) subProduct.get('Zuora__RatePlanName__c');
                            chargeNameInfo.get(productId).ratePlanName = ratePlanName;
                            chargeNameInfo.get(productId).bandwidth = PRP[0].bandwidth__c;
                        }
                        listZInvoice.addAll(chargeNameInfo.Values());
                        orderResponse.previewResult.invoices[0].invoiceItems = listZInvoice;

                        //add conversion rate to the response
                        list<CurrencyType> currencyRate = [SELECT Id, ConversionRate, IsoCode
                                                           FROM CurrencyType
                                                           WHERE IsoCode = 'USD'];
                        orderResponse.conversionRate = (1 / currencyRate[0].ConversionRate).round(System.RoundingMode.FLOOR);
                        orderResponse.zuoraLogs = setLog;
                        orderResponse.previewResult.invoices[0].invoiceItems[0].subscriptionNumber = currentSubProduct[0].Zuora__Subscription__r.Name;

                        if(setLog.size() > 0 && setLog != null && fromUI) {
                            listLog.addAll(setLog);
                            insert listLog;
                        }

                        return JSON.serialize(orderResponse, true);
                    } else {
                        if(setLog.size() > 0 && setLog != null) {
                            listLog.addAll(setLog);
                            insert listLog;
                        }
                        insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, subId, ZuoraObjects.previewOrdersAPIUrl);

                        return previewresult;
                    }
                } 
                catch(Exception e) {

                    ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
                    error.message = e.getLineNumber() + ': ' + e.getMessage();
                    error.zuoraLog = setLog;
                    system.debug(error.message);
                    throw new CustomException(json.serialize(error, true));
                }
            }
            else {
                return system.label.Empty_Subscription_Product;
            }
        } else {
            return system.label.Empty_Number_Of_Periodes;
        }
    }

    /**
     * Methode pour faire faire un reabo simple
     * <p>
     * @param subscriptionId id de la souscription,
     * @param nbPeriodes le nombre de periode a reabonner
     * @param modeDePaiement mode de paiement
     * @param transactionNumber Numéro de transaction
     * @param operator operateur de MM
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static string renewSubscription(id subscriptionId, integer nbPeriodes, string modeDePaiement, string transactionNumber,
                                           string operator, double dollarPayment, integer CDFPayment, integer dollarRefund, integer CDFRefund, 
                                           string bizaOrderId, string offer, list<string> options, string category) {

        user currentUser = [SELECT USR_DistributeurID__c, Profile.Name, contactId
                            FROM User
                            WHERE id = :UserInfo.getUserId()];
        //get distributor having account in Zuora
        list<Zuora__Subscription__c> listDistributorSub = new List<Zuora__Subscription__c>();

        if(currentUser.Profile.Name != 'Utilisateur du Portail Client' &&  currentUser.USR_DistributeurID__c != null) {
            listDistributorSub =  [SELECT Zuora__Account__r.parentId, Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.DistributorOperationBillingMinThreshold__c
                                   FROM Zuora__Subscription__c
                                   WHERE Zuora__CustomerAccount__r.Zuora__Account__r.ACC_Distributor_Number__c  = : currentUser.USR_DistributeurID__c];
        }

        boolean isActive = true;
        boolean haveCredit = false;
        string invoiceNumber;
        string invoiceId;

        set<Log__c> setLog = new set<Log__c>();
        list<Log__c> listLog = new list<Log__c>();

        // Prepaid period should always be set
        if(nbPeriodes != null) {

            list<Zuora__Subscription__c> listSubscription = [ SELECT ExpectedRenewalDate__c, Zuora__Status__c, Quote__c, CompensationDaysAtNextRenewal__c, Zuora__SubscriptionNumber__c,
                                                              Zuora__ServiceActivationDate__c, RenewalSequenceNumber__c, isCollaborator__c, C_Migration_Date__c,
                                                              Coupon__c, Zuora__Account__c, BoxNumber__c, Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                                                              FROM Zuora__Subscription__c
                                                              WHERE Id = :subscriptionId AND SuspensionReason__c != 'Move-Requested'];
            // get offre product of the current subscription
            list<zuora__subscriptionProductCharge__c> listSubscriptionProduct = [SELECT Zuora__Product__r.Name, Zuora__RatePlanName__c, Zuora__Subscription__r.Zuora__Account__c, Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c,
                                                                                 Zuora__Subscription__r.Zuora__SubscriptionNumber__c, Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, Zuora__Subscription__r.Quote__c, Zuora__Subscription__c,
                                                                                 Zuora__Subscription__r.Quote__r.QUO_T_Numero_De_Commande__c, Zuora__Subscription__r.CompensationDaysAtNextRenewal__c, Zuora__Subscription__r.Zuora__Account__r.BillingCountryCode,
                                                                                 Zuora__Subscription__r.Zuora__Account__r.CurrencyIsoCode, Zuora__Subscription__r.BoxNumber__c, Zuora__Subscription__r.Coupon__c, Zuora__Subscription__r.SUB_Status__c, 
                                                                                 Zuora__Subscription__r.Create_Bundle_C_subscription__c, Zuora__Subscription__r.C_Migration_Date__c, Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c,
                                                                                 Zuora__Subscription__r.ExpectedRenewalDate__c, Zuora__Subscription__r.Zuora__Status__c
                                                                                 FROM zuora__subscriptionProductCharge__c
                                                                                 WHERE Zuora__Type__c = 'Recurring' AND Zuora__Subscription__c = :subscriptionId AND (Zuora__RatePlanName__c = 'Start' OR Zuora__RatePlanName__c = 'Premium')
                                                                                 LIMIT 1];

            // check if any subscription is selected
            if(listSubscriptionProduct.size() > 0 && listSubscriptionProduct != null && listSubscription.size() > 0) {

                // if the BCD is not aligned with the expected renewal date block the renewal
                string expectedRenewalDay = string.valueof(listSubscriptionProduct[0].Zuora__Subscription__r.ExpectedRenewalDate__c.day());
                string billCycleDay = listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__BillCycleDay__c;
                billCycleDay = billCycleDay != null ? billCycleDay : 'null';
                // if the migration is scheduled in the future block the renewal
                Date migrationDate = Date.valueOf(listSubscriptionProduct[0].Zuora__Subscription__r.C_Migration_Date__c);
                if(migrationDate != null && (migrationDate > Date.today() || (migrationDate == Date.today() && !System.isBatch()))){
                    return System.Label.Sub_InMigration_Message +' '+String.valueOf(migrationDate);               
                }else if(!billCycleDay.contains(expectedRenewalDay) && listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__Status__c == System.Label.Sub_Status_Active && !Test.isRunningTest()){
                    return System.Label.BCD_error_message;
                }

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                //set endDate,triggerDate, previewTriggerDate and previewEndDate for simple renew sub
                date endDate, triggerDate, previewTriggerDate, previewEndDate;

                // subscription can be renewed only if it's status is Active or suspended
                if(listSubscription[0].Zuora__Status__c == System.Label.Sub_Status_Active || listSubscription[0].Zuora__Status__c == System.Label.Sub_Status_Suspended) {

                    try {
                        // get a list of old product of the canal+ Subscription
                        list<string> listBundleToRemove = getBundleProductToRemove(subscriptionId, listSubscriptionProduct[0].Zuora__Product__r.Name);
                        string access = null;
                        if(category != null && !string.isBlank(category)) {
                            access = listSubscriptionProduct[0].Zuora__RatePlanName__c + ' ' + category;
                        }
                        //get canal+ Bundle Products from the selected offers and options
                        list<string> listBundleId = new list<String>();
                        if((options != null && options.size() > 0) || category != null) {
                            listBundleId =  getBundleToAdd ( options, listSubscriptionProduct[0].Zuora__Product__r.Name, access);
                        }


                        //get Tax rate Plan
                        string productName = listSubscriptionProduct[0].Zuora__Product__r.Name;
                        list<zqu__productrateplancharge__c> listTimbreFiscal = new list<zqu__productrateplancharge__c>();
                        list<zqu__ProductRatePlanCharge__c> listCoupon = new list<zqu__ProductRatePlanCharge__c>();

                        // Check if any coupon exist on the current subscription
                        if(listSubscriptionProduct[0].Zuora__Subscription__r.Coupon__c != null && !string.isBlank(string.valueof(listSubscriptionProduct[0].Zuora__Subscription__r.Coupon__c))) {
                            listCoupon = [ SELECT name, zqu__ProductRatePlan__r.Category__c, zqu__ZuoraId__c, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                           FROM zqu__ProductRatePlanCharge__c
                                           WHERE zqu__ProductRatePlan__r.Category__c = 'Coupon' AND zqu__ProductRatePlan__r.zqu__Product__r.Name = : productName AND
                                               (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                               (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE];
                        }

                        string PRPId;
                        string ratePlanId;
                        string ratePlanChargeId;
                        string PRPChargeId = getCollaboratorCharge(subscriptionId);
                        string collaboratorProd = PRPChargeId;

                        if(PRPChargeId != null)
                            ratePlanChargeId = PRPChargeId.substring (PRPChargeId.indexOf(',') + 1, PRPChargeId.length());

                        if((listSubscription[0].isCollaborator__c == 'N' && string.valueOf(ratePlanChargeId) == 'null') ||
                           (listSubscription[0].isCollaborator__c == 'Y' && string.valueOf(ratePlanChargeId) != 'null'))
                            collaboratorProd = null;

                        if(listSubscription[0].isCollaborator__c == 'N' && collaboratorProd != null)
                            ratePlanId = ratePlanChargeId;
                        if(listSubscription[0].isCollaborator__c == 'Y' && collaboratorProd != null)
                            PRPId = collaboratorProd.substring (0, collaboratorProd.indexOf(','));

                        if(listSubscription[0].Zuora__Status__c == 'Active') {
                            isActive = true;
                            endDate = listSubscription[0].ExpectedRenewalDate__c.addMonths(nbPeriodes);
                        } 
                        else {
                            //renew for suspeded sub
                            endDate = Date.today().addMonths(nbPeriodes);
                            isActive = false;
                        }

                        zqu__productrateplancharge__c timbreFiscal = new zqu__productrateplancharge__c();
                        // If it's a renew made by a distributor don't charge the Tax(Timbre fiscal)
                        if(modeDePaiement == 'Cash' && currentUser.Profile.Name != System.Label.Distributor_Profile) {
                            listTimbreFiscal = [SELECT zqu__ZuoraId__c, Name, zqu__ProductRatePlan__r.zqu__ZuoraId__c
                                                FROM zqu__productrateplancharge__c
                                                WHERE Name = : system.label.Rate_Plan_Timbre_Fiscal AND
                                                zqu__ProductRatePlan__r.zqu__ZProduct__r.Name like: productName AND
                                                    (zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                    (zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY)) AND
                                                zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE
                                                LIMIT 1];
                            if(listTimbreFiscal.size() > 0 && listTimbreFiscal != null) {
                                timbreFiscal = listTimbreFiscal[0];
                            }
                        } 
                        else {
                            timbreFiscal = null;
                            listTimbreFiscal = new list<zqu__productrateplancharge__c>();
                        }

                        // call preview sub to get the needed amount for this action without tax
                        string previewResult = renewSubPreview(subscriptionId, nbPeriodes, true, modeDePaiement, false, listSubscription[0].isCollaborator__c == 'Y'?PRPChargeId.substring (0, PRPChargeId.indexOf(',')) : null, offer, options, category);
                        ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                        if(preview.zuoraLogs != null && preview.zuoraLogs.size() > 0) { setLog.addAll(preview.zuoraLogs); }
                           

                        double currentAmount = preview.previewResult.invoices[0].amount;

                        // call preview request a seconde time to add the tax
                        previewResult = renewSubPreview(subscriptionId, nbPeriodes, false, modeDePaiement, false, listSubscription[0].isCollaborator__c == 'Y'?PRPChargeId.substring (0, PRPChargeId.indexOf(',')) : null, offer, options, category);
                        preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize( previewResult, ZuoraResponseObjects.ZuoraPreviewResponse.class);

                        if(preview.zuoraLogs != null && preview.zuoraLogs.size() > 0) { setLog.addAll(preview.zuoraLogs); }
                            
                        double taxableAmount = preview.previewResult.invoices[0].amount;

                        // for distributor portal check the credit
                        user grosssiste = null;
                        if(listDistributorSub.size() > 0 && listDistributorSub != null) {

                            if(listDistributorSub[0].Zuora__Account__r.parentId != null) {
                                grosssiste = [SELECT ID FROM User WHERE AccountId = : listDistributorSub[0].Zuora__Account__r.parentId LIMIT 1];
                            }
                            //get Account payments Info
                            HttpResponse accountResponse = ZuoraManager.getAccountSummary(listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                            ZuoraResponseObjects.ZuoraGetAccount accountInfo = (ZuoraResponseObjects.ZuoraGetAccount) System.JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                            
                            if(accountInfo.success) {
                                // check if the current balance greater than the account threshold
                                // this step to prevent renew for distributor haven't enough credits
                                if(-(double.valueOf(accountInfo.basicInfo.balance)) >= double.valueOf(taxableAmount)) {
                                    haveCredit = true;
                                } else {
                                    haveCredit = false;
                                }
                            }
                        } 
                        else {
                            haveCredit = false;
                        }


                        if((!haveCredit && listDistributorSub.size() == 0) || (haveCredit && listDistributorSub.size() > 0)) {
                            date nextBillDate = null;

                            //renew for suspeded sub
                            if(!isActive) {

                                nextBillDate = calculateNewRenewalDate(date.today(), nbPeriodes, date.today().Day());
                                //adjust BCD on account
                                // create the body // send the request //deserialize the response // create logs
                                ZuoraObjects.ZuoraUpdateAccount zAccount = ZuoraMapper.fillAdjustAccount(date.today().day());
                                HttpResponse updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBCDResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                
                                setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__Account__c, listSubscription[0].id, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.updateAccountAPIUrl + listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                   adjustBCDResponse.success, adjustBCDResponse.reasons == null?null : adjustBCDResponse.reasons[0].message, ZuoraObjects.put, false));
                                if(adjustBCDResponse.success) {
                                    //fill order fields to create a renew
                                    ZuoraObjects.ZuoraOrder zSub = ZuoraMapper.fillRenewSubscription(
                                        listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                        listSubscription[0].CompensationDaysAtNextRenewal__c, listSubscription[0].Quote__c, isActive,
                                        date.today(), nextBillDate, nbPeriodes, listTimbreFiscal.size() == 0?null : timbreFiscal, currentAmount, subscriptionId, listSubscription[0].RenewalSequenceNumber__c, PRPId, ratePlanId,
                                        (listSubscription[0].Coupon__c == null || string.isBlank(string.valueOf(listSubscription[0].Coupon__c)))?null : (listCoupon.size() > 0?listCoupon[0] : null), Double.valueOf(listSubscription[0].Coupon__c), listBundleId, listBundleToRemove);

                                    sleepAfterBCD();
                                    HttpResponse response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.ADD_PRODUCT );
                                    ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                                    orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                                    // retry the callout if it isn't success from the first time
                                    if(!orderResponse.success) {
                                        string responseBody =  sleep(500, zSub);
                                        orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(responseBody, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                    }

                                    setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zSub, true), listSubscription[0].Zuora__Account__c, listSubscription[0].id, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, response.getBody(),
                                                                                       orderResponse.success, orderResponse.reasons == null?null : orderResponse.reasons[0].message, ZuoraObjects.post, false));
                                    if(orderResponse.success) {

                                        // create order to generate a bill and add compensation days
                                        if(listSubscription[0].CompensationDaysAtNextRenewal__c != null && integer.valueOf(listSubscription[0].CompensationDaysAtNextRenewal__c) > 0) {
                                            
                                            //adjust BCD on account
                                            ZuoraObjects.ZuoraUpdateAccount zInactiveAccount = ZuoraMapper.fillAdjustAccount(nextBillDate.addDays(integer.valueOf(listSubscription[0].CompensationDaysAtNextRenewal__c)).day());
                                            HttpResponse updateInactiveAccount = ZuoraManager.updateZuoraAccount(zInactiveAccount, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                            adjustBCDResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize( updateInactiveAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                            
                                            sleepAfterBCD();
                                            setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zInactiveAccount, true), listSubscription[0].Zuora__Account__c, listSubscription[0].id, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.updateAccountAPIUrl + listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateInactiveAccount.getBody(),
                                                                                               adjustBCDResponse.success, adjustBCDResponse.reasons == null?null : adjustBCDResponse.reasons[0].message, ZuoraObjects.put, false));
                                        }

                                        invoiceNumber = orderResponse.invoiceNumbers.size() > 0?orderResponse.invoiceNumbers[0] : null;
                                        sleepAfterBCD();

                                        // create payment for this simple renew sub
                                        return createRenewPayment(listSubscriptionProduct[0], nbPeriodes, taxableAmount, invoiceNumber, invoiceId, false, false, modeDePaiement, transactionNumber,
                                                                  operator, dollarPayment, CDFPayment, dollarRefund, CDFRefund, listSubscriptionProduct[0].Zuora__RatePlanName__c,
                                                                  listSubscriptionProduct[0].Zuora__RatePlanName__c, setLog, haveCredit?listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c : null,
                                                                  grosssiste?.Id, null, offer, options);
                                    } 
                                    else {
                                        // re adjust the BCD
                                        zAccount = ZuoraMapper.fillAdjustAccount(listSubscription[0].ExpectedRenewalDate__c.day());
                                        updateAccount = ZuoraManager.updateZuoraAccount(zAccount, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                        adjustBCDResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                        
                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zAccount, true), listSubscription[0].Zuora__Account__c, listSubscription[0].id, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.updateAccountAPIUrl + listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateAccount.getBody(),
                                                                                           adjustBCDResponse.success, adjustBCDResponse.reasons == null?null : adjustBCDResponse.reasons[0].message, ZuoraObjects.put, false));

                                        if(setLog.size() > 0 && setLog != null) {
                                            listLog.addAll(setLog);
                                            insert listLog;
                                        }
                                        insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderResponse.reasons[0].message, subscriptionId, ZuoraObjects.ordersAPIUrl);

                                        return response.getBody();
                                    }
                                } 
                                else {
                                    if(setLog.size() > 0 && setLog != null) {
                                        listLog.addAll(setLog);
                                        insert listLog;
                                    }

                                    return updateAccount.getBody();
                                }
                            }//for active sub
                            else {
                                HttpResponse res = ZuoraManager.getZuoraAccount(listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                ZuoraResponseObjects.ZuoraGetAccount accountResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(res.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
                                
                                nextBillDate = calculateNewRenewalDate(listSubscription[0].ExpectedRenewalDate__c, nbPeriodes, accountResponse.billingAndPayment.billCycleDay);

                                // create order to generate a bill and add compensation days
                                if((listSubscription[0].CompensationDaysAtNextRenewal__c != null && integer.valueOf(listSubscription[0].CompensationDaysAtNextRenewal__c) > 0) 
                                    || PRPId != null || ratePlanId != null 
                                    || (!string.isBlank(string.valueOf(listSubscription[0].Coupon__c)) && listSubscription[0].Coupon__c != null) 
                                    || (listBundleId != null && listBundleId.size() > 0) 
                                    || (listBundleToRemove != null && listBundleToRemove.size() > 0) 
                                    || category != null) 
                                {
                                    //fill order fields to create a renew
                                    ZuoraObjects.ZuoraOrder zActiveSub = ZuoraMapper.fillRenewSubscription(
                                        listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                        listSubscriptionProduct[0].Zuora__Subscription__r.CompensationDaysAtNextRenewal__c, listSubscription[0].Quote__c, isActive,
                                        listSubscription[0].ExpectedRenewalDate__c, nextBillDate, nbPeriodes, listTimbreFiscal.size() == 0?null : timbreFiscal, currentAmount, subscriptionId,
                                        listSubscription[0].RenewalSequenceNumber__c, PRPId, ratePlanId,  (listSubscription[0].Coupon__c == null || string.isBlank(string.valueOf(listSubscription[0].Coupon__c)))?null : (listCoupon.size() > 0?listCoupon[0] : null), Double.valueOf(listSubscription[0].Coupon__c), listBundleId, listBundleToRemove);
                                    
                                    // create the body // send the request //deserialize the response // create logs
                                    HttpResponse activeResponse = ZuoraManager.createOrder(zActiveSub, ZuoraObjects.OrderType.ADD_PRODUCT );
                                    ZuoraResponseObjects.ZuoraCreateOrderResponse orderActiveResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                                    orderActiveResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(activeResponse.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                    
                                    // if order isn't success retry callout 3 times
                                    if(!orderActiveResponse.success) {
                                        string responseBody =  sleep(500, zActiveSub);
                                        orderActiveResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(responseBody, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                    }
                                    setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zActiveSub, true), listSubscription[0].Zuora__Account__c, listSubscription[0].id, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.ordersAPIUrl, activeResponse.getBody(),
                                                                                       orderActiveResponse.success, orderActiveResponse.reasons == null?null : orderActiveResponse.reasons[0].message, ZuoraObjects.post, false));
                                    //
                                    if(orderActiveResponse.success) {

                                        invoiceNumber = orderActiveResponse.invoiceNumbers.size() > 0 ? orderActiveResponse.invoiceNumbers[0] : null;
                                        //adjust BCD on account !!!!!!!!!!!!
                                        ZuoraObjects.ZuoraUpdateAccount zActiveAccount = ZuoraMapper.fillAdjustAccount(nextBillDate.addDays(integer.valueOf(listSubscription[0].CompensationDaysAtNextRenewal__c)).day());

                                        HttpResponse updateActiveAccount = ZuoraManager.updateZuoraAccount(zActiveAccount, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                        ZuoraResponseObjects.ZuoraUpdateAccountResponse adjustBCDResponse = (ZuoraResponseObjects.ZuoraUpdateAccountResponse) JSON.deserialize(updateActiveAccount.getBody(), ZuoraResponseObjects.ZuoraUpdateAccountResponse.class);
                                        
                                        setLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(zActiveAccount, true), listSubscription[0].Zuora__Account__c, listSubscription[0].id, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c, ZuoraObjects.updateAccountAPIUrl + listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, updateActiveAccount.getBody(),
                                                                                           adjustBCDResponse.success, adjustBCDResponse.reasons == null?null : adjustBCDResponse.reasons[0].message, ZuoraObjects.put, false));

                                        if(adjustBCDResponse.success) {
                                            sleepAfterBCD();
                                            // create payment for this simple renew sub
                                            return createRenewPayment(listSubscriptionProduct[0], nbPeriodes, taxableAmount, invoiceNumber, invoiceId, false, false, modeDePaiement, transactionNumber,
                                                                      operator, dollarPayment, CDFPayment, dollarRefund, CDFRefund, listSubscriptionProduct[0].Zuora__RatePlanName__c,
                                                                      listSubscriptionProduct[0].Zuora__RatePlanName__c, setLog, haveCredit?listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c : null,
                                                                      grosssiste?.Id, null, offer, options);
                                        } 
                                        else {
                                            if(setLog.size() > 0 && setLog != null) {
                                                listLog.addAll(setLog);
                                                insert listLog;
                                            }
                                            insert AP01_ErreurInterface.insertError('Erreur API', null, null, adjustBCDResponse.reasons[0].message, subscriptionId, ZuoraObjects.updateAccountAPIUrl + listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);

                                            return updateActiveAccount.getBody();
                                        }
                                    } 
                                    else {
                                        if(setLog.size() > 0 && setLog != null) {
                                            listLog.addAll(setLog);
                                            insert listLog;
                                        }
                                        insert AP01_ErreurInterface.insertError('Erreur API', null, null, orderActiveResponse.reasons[0].message, subscriptionId, ZuoraObjects.ordersAPIUrl);

                                        return activeResponse.getBody();
                                    }
                                } // if Timbre product is calculated and no coupon or Bundle or Free days or collaborator
                                else if(listTimbreFiscal.size() > 0 && listTimbreFiscal != null) 
                                {
                                    //fill order fields to create a renew
                                    ZuoraObjects.ZuoraOrder zActiveSub = ZuoraMapper.fillRenewSubscriptionWithTax(
                                        listSubscription[0].Zuora__CustomerAccount__r.Zuora__AccountNumber__c, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                        listSubscription[0].Quote__c, listSubscription[0].ExpectedRenewalDate__c, nbPeriodes, listTimbreFiscal.size() == 0?null : timbreFiscal,
                                        currentAmount, subscriptionId, listSubscription[0].RenewalSequenceNumber__c);

                                    HttpResponse activeResponse = ZuoraManager.createOrder(zActiveSub, ZuoraObjects.OrderType.ADD_PRODUCT );

                                    ZuoraResponseObjects.ZuoraCreateOrderResponse orderActiveResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
                                    orderActiveResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(activeResponse.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                    
                                    if(orderActiveResponse.success) {

                                        invoiceNumber = orderActiveResponse.invoiceNumbers.size() > 0?orderActiveResponse.invoiceNumbers[0] : null;
                                        sleepAfterBCD();

                                        // create payment for this simple renew sub
                                        return createRenewPayment(listSubscriptionProduct[0], nbPeriodes, taxableAmount, invoiceNumber, invoiceId, false, false,  modeDePaiement, transactionNumber, operator,
                                                                  dollarPayment, CDFPayment, dollarRefund, CDFRefund, listSubscriptionProduct[0].Zuora__RatePlanName__c, listSubscriptionProduct[0].Zuora__RatePlanName__c,
                                                                  setLog, haveCredit?listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c : null, grosssiste?.Id, null, offer, options);
                                    } 
                                    else {
                                        if(setLog.size() > 0 && setLog != null) {
                                            listLog.addAll(setLog);
                                            insert listLog;
                                        }
                                        return activeResponse.getBody();
                                    }
                                } // if none of the above
                                else {
                                    // generate bill for the prepaid periods
                                    ZuoraObjects.ZuoraBilling zBill = ZuoraMapper.fillGenerateBill(new list<string> {listSubscription[0].Zuora__Zuora_Id__c}, listSubscription[0].ExpectedRenewalDate__c, nbPeriodes);
                                    HttpResponse billResponse = ZuoraManager.CreateBillByAccount(zBill, listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                                    ZuoraResponseObjects.ZuoraBill invoiceResponse = new ZuoraResponseObjects.ZuoraBill();
                                    invoiceResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(billResponse.getBody(), ZuoraResponseObjects.ZuoraBill.class);
                                    
                                    Log__c newLog = new Log__c(LG_Body__c = JSON.serialize(zBill, true),
                                                               LG_Subscription__c = subscriptionId, LG_Method_URL__c = ZuoraObjects.accountAPIUrl + listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c + ZuoraObjects.billAPIUrl, LG_Response__c = billResponse.getBody(), LG_Interface__c = 'Zuora', LG_Success__c = invoiceResponse.success, LG_Error_Message__c = invoiceResponse.reasons == null?null : invoiceResponse.reasons[0].message, LG_Method_Type__c = ZuoraObjects.post, LG_Error_Solved__c = true);

                                    setLog.add(newLog);

                                    if(invoiceResponse.success) {

                                        invoiceId = invoiceResponse.invoices.size() > 0?invoiceResponse.invoices[0].id : null;
                                        invoiceNumber = invoiceResponse.invoices.size() > 0?invoiceResponse.invoices[0].InvoiceNumber : null;
                                        // add expected renewal date
                                        string customFieldsResponse = ZuoraSubscriptionActions.addCustomFieldsToSubscription(listSubscription[0], null, null, nextBillDate, listSubscription[0].RenewalSequenceNumber__c);
                                        if(customFieldsResponse != null) {
                                            ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(customFieldsResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
                                            
                                            if(orderResponse.zuoraLogs != null && orderResponse.zuoraLogs.size() > 0)
                                                setLog.addAll(orderResponse.zuoraLogs);
                                            sleepAfterBCD();

                                            // create payment for this simple renew sub
                                            return createRenewPayment(listSubscriptionProduct[0], nbPeriodes, taxableAmount, invoiceNumber, invoiceId, false, false, modeDePaiement, transactionNumber,
                                                                      operator, dollarPayment, CDFPayment, dollarRefund, CDFRefund, listSubscriptionProduct[0].Zuora__RatePlanName__c,
                                                                      listSubscriptionProduct[0].Zuora__RatePlanName__c, setLog, haveCredit?listDistributorSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c : null,
                                                                      grosssiste?.Id, null, offer, options);
                                        } 
                                        else {
                                            if(setLog.size() > 0 && setLog != null) {
                                                listLog.addAll(setLog);
                                                insert listLog;
                                            }

                                            return customFieldsResponse;
                                        }
                                    } 
                                    else {
                                        if(setLog.size() > 0 && setLog != null) {
                                            listLog.addAll(setLog);
                                            insert listLog;
                                        }
                                        insert AP01_ErreurInterface.insertError('Erreur API', null, null, invoiceResponse.reasons[0].message, subscriptionId, ZuoraObjects.accountAPIUrl + listSubscriptionProduct[0].Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c + ZuoraObjects.billAPIUrl);

                                        return billResponse.getBody();
                                    }
                                }
                            }
                        } else {
                            return System.label.No_Credit;
                        }
                    }
                    catch(Exception e) {

                        ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
                        error.message = e.getLineNumber() + ': ' + e.getMessage();
                        error.zuoraLog = setLog;
                        system.debug(e.getLineNumber() + ': ' + e.getMessage());
                        throw new CustomException(json.serialize(error, true));
                    }
                } else {
                    return System.label.Impossible_Action;
                }
            }
            else {
                return System.label.Empty_Subscription_Product;
            }
        } else {
            return System.label.Empty_Number_Of_Periodes;
        }
    }

                                               /////////////////////////////////////////////////////////////////////////////

    /**
     * methode pour ajouter le numero du payment sur l'abonnement
     * <p>
     * @param subscriptionId id de l'abonnement,
     * @param paymentNumber le numero du paiement dans zuora
     * */
    @AuraEnabled
    public static void addPaymentNumberToSubscription(id subscriptionId, string paymentNumber){
        list<Zuora__Subscription__c> currentSubscription = [ SELECT SUB_T_Payment_Number__c,SUB_Tech_Material__c, Create_Bundle_C_subscription__c
                                                             FROM Zuora__Subscription__c
                                                             WHERE Id = :subscriptionId];
        //add the payment number to the sub for renew subs
        if(currentSubscription.size() > 0 && currentSubscription != null) {
            currentSubscription[0].SUB_T_Payment_Number__c = paymentNumber;
            
            // if the material field is not null reserve  the equipment related to Bundle
            if(currentSubscription[0].SUB_Tech_Material__c != null && currentSubscription[0].Create_Bundle_C_subscription__c == true)
            {
                List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(currentSubscription[0].SUB_Tech_Material__c);
                list<equipment__c> listEquipment = new list<equipment__c>();
                if(fieldList != null && fieldList.size() > 0){
                    for(Object fld : fieldList) {

                        Map<String, Object> data = (Map<String, Object>) fld;

                        equipment__c eq = new equipment__c( id = (String)data.get('Id'), Equipment_Type__c = (String)data.get('Equipment_Type__c'), Equipment_Id__c = (String)data.get('Equipment_Id__c'), Already_Used__c = true );
                        listEquipment.add(eq);
                    }
                }

                if(listEquipment != null && listEquipment.Size() > 0){
                    update listEquipment;
                }
                update currentSubscription;
            }    
        }
    }

    /**
     * Methode pour obtenir la date du début du rate plan 'Start'
     * <p>
     * @param subscriptionId ID de l'abonnement
     * @return Id du Pricebook
     * */
    public static date getStartRatePlanEffectiveDate(string subscriptionId){
        date ratePlanStartDate;
        //get subscription preview
        httpResponse response = ZuoraManager.susbcriptionPreview(subscriptionId);
        ZuoraResponseObjects.ZuoraPreviewSubscription previewResponse = (ZuoraResponseObjects.ZuoraPreviewSubscription) JSON.deserialize(
            response.getBody(), ZuoraResponseObjects.ZuoraPreviewSubscription.class);

        if(previewResponse.success) {
            //search start rate plan in all rate plans
            for(ZuoraResponseObjects.ZuoraRatePlans ratePlan : previewResponse.ratePlans) {

                if(ratePlan.ratePlanName.startsWith('Start')) {
                    for(ZuoraResponseObjects.ZuoraRatePlanCharges charge : ratePlan.ratePlanCharges) {
                        //check end date of start rate plan
                        if(charge.processedThroughDate >= date.today()) {
                            //get start date
                            ratePlanStartDate = charge.effectiveStartDate;
                            break;
                        }
                    }
                    break;
                }
            }
        }

        return ratePlanStartDate;
    }

    /**
     * Méthode pour récupérer les abonnements collaborateur traités de l'action échange de mteriel
     * @param mapOld
     * @param mapNew
     */
    public static void checkCompensationsonSub(map<id, Zuora__Subscription__c> mapOld, map<id, Zuora__Subscription__c> mapNew){

        set<Id> setSubId = new set<Id>();
        for(Zuora__Subscription__c sub : mapNew.Values()) {
            // check if suivi is treated and related to change box action
            if(mapOld.get(sub.Id).CompensationDaysAtNextRenewal__c != sub.CompensationDaysAtNextRenewal__c) {
                setSubId.add(sub.Id);
            }
        }
        if(setSubId.size() > 0 && setSubId != null) {
            changeCompensationInZuora(setSubId);
        }
    }

    /**
     * Méthode pour changer le champ CompensationDaysAtNextRenewal sur l'abonnement
     * @param setSuiviId
     */
    @future(callout = true)
    public static void changeCompensationInZuora(set<Id> setSubId){
        list<Log__c> listLog = new list<Log__c>();
        list<Zuora__Subscription__c> listSub = [SELECT CompensationDaysAtNextRenewal__c, Zuora__SubscriptionNumber__c, id
                                                FROM Zuora__Subscription__c
                                                WHERE id IN :setSubId];

        if(listSub.size() > 0 && listSub != null) {
            for(Zuora__Subscription__c sub : listSub) {

                //update custom fields of an existing sub
                ZuoraObjects.ZuoraOrderSubscription subCustomFields = ZuoraMapper.updateSubscriptionCompensationCustomField(sub);
                HttpResponse response = ZuoraManager.updateSubscriptionCustomFields(subCustomFields, sub.Zuora__SubscriptionNumber__c);
                ZuoraResponseObjects.ZuoraSubscriptions updateSubResponse = (ZuoraResponseObjects.ZuoraSubscriptions) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraSubscriptions.class);
                listLog.add(ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(subCustomFields, true), null, sub.Id, null,  ZuoraObjects.subscriptionAPIUrl +  sub.Zuora__SubscriptionNumber__c + '/customFields', response.getBody(),
                                                                    updateSubResponse.success, updateSubResponse.reasons == null?null : updateSubResponse.reasons[0].message, ZuoraObjects.put, true));
            }
            if(listLog.size() > 0 && listLog != null)
                insert listLog;

        }
    }

    /**
     * method pour ajouter le nom du produit de base sur l'abo
     * @param listProd list des produits
     */
    public static void addProductBaseName(list<Zuora__SubscriptionProductCharge__c> listProd){
        list<Zuora__SubscriptionProductCharge__c> listSubProd = [SELECT Zuora__RatePlanName__c, Zuora__Subscription__c, Zuora__OriginalProductRatePlanChargeId__c
                                                                 FROM Zuora__SubscriptionProductCharge__c
                                                                 WHERE id IN :listProd AND Zuora__Type__c = 'Recurring'];
        // get charge of base Product rate plan
        list<zqu__ProductRatePlanCharge__c> listOfferCharge = [SELECT name, zqu__ZuoraId__c, zqu__ProductRatePlan__r.bandwidth__c
                                                               FROM zqu__ProductRatePlanCharge__c
                                                               WHERE zqu__ProductRatePlan__r.Category__c = 'Offer'];
        // get Name of these charges
        set<String> setBaseProducts = new set<String>();
        list<String> listBaseProducts = new list<String>();
        map<String, string> mapChargeBandwidth = new map<String, string>();
        if(listOfferCharge.size() > 0 && listOfferCharge != null) {
            for(zqu__ProductRatePlanCharge__c charge : listOfferCharge) {
                setBaseProducts.add(charge.Name);
                mapChargeBandwidth.put(charge.zqu__ZuoraId__c, charge.zqu__ProductRatePlan__r.bandwidth__c);
            }
        }
        // check if any base charge is added
        List<Zuora__Subscription__c> listSub = new list<Zuora__Subscription__c>();
        set<Zuora__Subscription__c> setSub = new set<Zuora__Subscription__c>();
        listBaseProducts.addAll(setBaseProducts);
        for(Zuora__SubscriptionProductCharge__c subProd : listSubProd) {
            if(listBaseProducts.contains(subProd.Zuora__RatePlanName__c)) {
                Zuora__Subscription__c sub = new Zuora__Subscription__c();
                sub.id = subProd.Zuora__Subscription__c;
                sub.SUB_T_Produit_de_Base__c = subProd.Zuora__RatePlanName__c;
                sub.SUB_Bandwidth__c = mapChargeBandwidth.get(subProd.Zuora__OriginalProductRatePlanChargeId__c);
                setSub.add(sub);
            }
        }
        if(setSub.size() > 0 && setSub != null) {
            listSub.addALL(setSub);
            update listSub;
        }
    }

    /**
     * Method pour récuperer les charges des rate plan ayant la catégorie 'Collaborator'
     */
    public static string getCollaboratorCharge(id subscriptionId){
        //get All Subscription Charges
        list<Zuora__SubscriptionProductCharge__c> listSubProductCharges = [ SELECT Zuora__OriginalProductRatePlanChargeId__c, Zuora__Product__r.Zuora__External_Id__c,
                                                                            Zuora__Subscription__r.isCollaborator__c, Zuora__RatePlanId__c
                                                                            FROM Zuora__SubscriptionProductCharge__c
                                                                            WHERE Zuora__Subscription__c = :subscriptionId];

        map<String, string> mapChargeIdSubProdId = new map<String, string>();
        for(Zuora__SubscriptionProductCharge__c subCharge : listSubProductCharges)
        {
            mapChargeIdSubProdId.put(subCharge.Zuora__OriginalProductRatePlanChargeId__c, subCharge.Zuora__RatePlanId__c);
        }

        // call get Product rate plan Api to get rate plans of specific product
        string url = ZuoraObjects.ratePlanAPIUrl + listSubProductCharges[0].Zuora__Product__r.Zuora__External_Id__c + ZuoraObjects.prpAPIUrl;

        HttpResponse response = ZuoraManager.doCallout(url, ZuoraObjects.get, '');
        ZuoraResponseObjects.ZuoraPRPResponse getPRPInfoResponse = new ZuoraResponseObjects.ZuoraPRPResponse();
        getPRPInfoResponse = (ZuoraResponseObjects.ZuoraPRPResponse) JSON.deserialize(response.getBody().replaceAll('__c', '_Reserved'), ZuoraResponseObjects.ZuoraPRPResponse.class);
        
        // search of collaborator PRP and it's charge
        string collaboratorRPChargeId = null;

        if(getPRPInfoResponse.success)
        {
            for(ZuoraResponseObjects.ZuoraProductRatePlan currentPrp : getPRPInfoResponse.productRatePlans)
            {
                if(currentPrp.Category_Reserved == 'Collaborator' && currentPrp.effectiveEndDate > date.today()) {
                    for(ZuoraResponseObjects.ZuoraproductRatePlanCharge charge : currentPrp.productRatePlanCharges) {
                        collaboratorRPChargeId = currentPrp.id + ',' + charge.Id;
                    }
                    break;
                }
            }
        }

        if(collaboratorRPChargeId != null) {
            string ratePlanId = mapChargeIdSubProdId.get(collaboratorRPChargeId.substring(collaboratorRPChargeId.indexOf(',') + 1, collaboratorRPChargeId.length()));
            /*if((listSubProductCharges[0].Zuora__Subscription__r.isCollaborator__c == 'N' && ratePlanId == null) ||
               (listSubProductCharges[0].Zuora__Subscription__r.isCollaborator__c == 'Y' && ratePlanId != null)) {
                collaboratorRPChargeId = null;
               } else {*/
            collaboratorRPChargeId = collaboratorRPChargeId.substring(0, collaboratorRPChargeId.indexOf(',')) + ',' + ratePlanId;
            //  }
            if(string.isBlank(listSubProductCharges[0].Zuora__Subscription__r.isCollaborator__c))
                collaboratorRPChargeId = null;
        }

        return collaboratorRPChargeId;
    }

    @AuraEnabled(Cacheable = false)
    public static void createErrorLog(string zuoraResponse){
        try {
            Set<Log__c> setLog = new set<Log__c>();
            if(zuoraResponse != null) {
                Map<String, Object> responseMap =   (Map<String, Object>) JSON.deserializeUntyped(zuoraResponse);
                for(object obj : (list<object>)responseMap.get('zuoraLog')) {
                    Map<String, Object> data = (Map<String, Object>) obj;
                    Log__c lg = new log__c();
                    lg.LG_Body__c = (string)data.get('LG_Body__c');
                    lg.LG_Account__c = (string)data.get('LG_Account__c');
                    lg.LG_Subscription__c = (string)data.get('LG_Subscription__c');
                    lg.LG_Method_URL__c = (string)data.get('LG_Method_URL__c');
                    lg.LG_Subscription_Number__c = (string)data.get('LG_Subscription_Number__c');
                    lg.LG_Response__c = (string)data.get('LG_Response__c');
                    lg.LG_Interface__c = (string)data.get('LG_Interface__c');
                    lg.LG_Success__c = (boolean)data.get('LG_Success__c') == null?false : (boolean)data.get('LG_Success__c');
                    lg.LG_Error_Message__c = (string)data.get('LG_Error_Message__c');
                    lg.LG_Method_Type__c = (string)data.get('LG_Method_Type__c');
                    setLog.add(lg);
                }
            }
            if(setLog.size() > 0 && setLog != null) {
                list<Log__c> listLog = new list<Log__c>();
                listLog.addALL(setLog);
                system.debug(listLog.size());
                insert listLog;
            }

        } catch(Exception e) {
            ZuoraResponseObjects.handleError error = new ZuoraResponseObjects.handleError();
            error.message = e.getMessage();
            system.debug(e.getMessage() + ' ' + e.getLineNumber());
            throw new CustomException(json.serialize(error, true));
        }
    }

    /**
     * Method to calculate expected renewal Date
     */
    public static date calculateNewRenewalDate(date expectedRenewalDate, integer renewalPeriod, integer bcd){

        date ctd = expectedRenewalDate;
        date nextBillDate = null;

        for(integer period = 1; period <= renewalPeriod; period++) {
            if(period > 1) {
                ctd = nextBillDate;
            }
            date ctdP1M = ctd.addMonths(1);
            integer ctd_lastDayOfMonth_Day = Date.newInstance(ctdP1M.Year(), ctdP1M.month(), 01).addDays(-1).Day();
            date ctdP2M = ctdP1M.addMOnths(1);
            integer ctdP1M_lastDayOfMonth_Day = Date.newInstance(ctdP2M.Year(), ctdP2M.month(), 01).addDays(-1).Day();
            nextBillDate = null;
            if(bcd >= 1 && bcd <= 28) {
                if(bcd == ctd.Day()) {
                    nextbilldate = ctdP1M;
                } else {
                    if(bcd > ctd.Day()) {
                        nextBillDate = Date.newInstance(ctd.Year(), ctd.month(), bcd);
                    } else {
                        nextBillDate = Date.newInstance(ctdP1M.Year(), ctdP1M.month(), bcd);
                    }
                }
            } else {
                if(bcd == ctd.Day()) {
                    nextbilldate = ctdP1M;
                } else {
                    if(bcd > ctd.Day()) {
                        if(ctd_lastDayOfMonth_Day == ctd.Day()) {
                            if(ctdP1M_lastDayOfMonth_Day < bcd) {
                                nextBillDate = Date.newInstance(ctdP1M.Year(), ctdP1M.month(), ctdP1M_lastDayOfMonth_Day);
                            } else {
                                nextBillDate = Date.newInstance(ctdP1M.Year(), ctdP1M.month(), bcd);
                            }
                        } else {
                            if(ctd_lastDayOfMonth_Day < ctd.Day()) {
                                nextBillDate = Date.newInstance(ctd.Year(), ctd.month(), ctd_lastDayOfMonth_Day);
                            } else {
                                nextBillDate = Date.newInstance(ctd.Year(), ctd.month(), bcd);
                            }
                        }
                    } else {
                        if(ctd_lastDayOfMonth_Day == ctd.Day()) {
                            if(ctdP1M_lastdayofmonth_day < bcd) {
                                nextBillDate = Date.newInstance(ctdP1M.Year(), ctdP1M.month(), ctdP1M_lastdayofmonth_day);
                            } else {
                                nextBillDate = Date.newInstance(ctdP1M.Year(), ctdP1M.month(), bcd);
                            }
                        } else {
                            if(ctd_lastDayOfMonth_Day < bcd) {
                                nextBillDate = null;
                            } else {
                                nextBillDate = Date.newInstance(ctd.Year(), ctd.month(), bcd);
                            }
                        }
                    }
                }
            }
        }

        return nextBillDate;

    }
    /**
     * Method to retry payment callout if the initial callout is failed due to 'Lock competition' error
     */
    @AuraEnabled
    public static string retryPayment(String zuoraAccountId, integer nbPeriodes, double currentAmount, string transactionNumber,
                                      string operator, string orderNumber, string invoiceId, string accountCurrency, string paymentMode,
                                      string CDFPayment, string dollarPayment, string currencyRate, string dollarRefund, string CDFRefund, boolean fromDistributor, string AccountId){

        try {
            // create payment for renew action
            ZuoraObjects.ZuoraPayment paymentInfo = ZuoraMapper.fillCreateRenewPayment(zuoraAccountId, nbPeriodes, currentAmount, transactionNumber, operator, orderNumber, invoiceId, accountCurrency, paymentMode,
                                                                                       CDFPayment, dollarPayment, currencyRate, dollarRefund, CDFRefund, fromDistributor, AccountId);
            httpResponse response = ZuoraManager.createPayment(paymentInfo);

            ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(response.getBody(), ZuoraResponseObjects.ZuoraPayment.class);

            insert ZuoraSubscriptionActions.createZuoraLog(JSON.serialize(paymentInfo, true), AccountId, null, null, ZuoraObjects.paymentAPIUrl, response.getBody(),
                                                           paymentResponse.success, paymentResponse.reasons == null?null : paymentResponse.reasons[0].message, ZuoraObjects.post, true);

            return response.getBody();
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * method to wait 0.5 and recreate failed order,
     * this method retry api callout 2 times in case of failure
     */
    public static string sleep(integer sleepTime, ZuoraObjects.ZuoraOrder zSub){
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while((finishTime - startTime) < sleepTime) {
            //sleep for parameter 0.5s
            finishTime = DateTime.now().getTime();
        }

        httpResponse response  = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.ADD_PRODUCT );
        ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
            response.getBody(), ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
        if(!orderResponse.success) {
            //retry Number 2
            Long startTime1 = DateTime.now().getTime();
            Long finishTime1 = DateTime.now().getTime();
            while((finishTime1 - startTime1) < sleepTime) {
                //sleep for parameter 0.5s
                finishTime1 = DateTime.now().getTime();
            }
            response = ZuoraManager.createOrder(zSub, ZuoraObjects.OrderType.ADD_PRODUCT );

            return response.getBody();
        } else {
            return response.getBody();
        }
    }
    /**
     * method to wait 0.5s
     * as Zuora support recommendation, it's preferred to wait 0.5s between api calls if we are updating an account before creating an order in zuora
     *
     * support message: An account update call triggers a short backend job to recalculate billing charges.In some cases, this can take 1 - 2 seconds,
       and in these cases the POST Orders call for the same account will fail with lock competition.
       I suggest looking into any integrations that trigger multiple calls at the same time and introduce delays between these steps,
       and a graceful retry logic
     */
    public static void sleepAfterBCD(){
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while((finishTime - startTime) < 500) {
            //sleep for parameter 0.5s
            finishTime = DateTime.now().getTime();
        }
    }
    // get Zuora Id of C Bundle Product existing on subscription
    public static list<string> getBundleProductToRemove(id subId, string productName){
        list<string> listBundleRatePlanId = new list<string>();
        list<zqu__productrateplanchargetier__c> listPRPCharges = [SELECT zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Product__r.Name
                                                                  FROM zqu__productrateplanchargetier__c
                                                                  WHERE zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Category__c = 'Bundle C' AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Product__r.Name = : productName];
        if(listPRPCharges != null && listPRPCharges.size() > 0) {
            list<string> listChargeId = new list<string>();
            for(zqu__productrateplanchargetier__c subChargeTier : listPRPCharges) {
                listChargeId.add(subChargeTier.zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c);
            }
            list<Zuora__SubscriptionProductCharge__c> listRecurringCharges = [SELECT Zuora__RatePlanId__c, Zuora__OriginalProductRatePlanChargeId__c, Zuora__ProductRatePlanChargeId__c
                                                                              FROM Zuora__SubscriptionProductCharge__c
                                                                              WHERE Zuora__Type__c = 'Recurring' AND Zuora__Subscription__c = :subId AND Zuora__OriginalProductRatePlanChargeId__c IN :listChargeId];

            if(listRecurringCharges.size() > 0 && listRecurringCharges != null) {
                for(Zuora__SubscriptionProductCharge__c subCharge : listRecurringCharges) {
                    listBundleRatePlanId.add(subCharge.Zuora__RatePlanId__c);
                }
            }
        }

        return listBundleRatePlanId;
    }
    // get Bundle product that does exist in Zuora
    public static list<string> getBundleToAdd (list<string> listOption, string productName, string category){

        list<string> listBundleId = new list<string>();
        list<string> listOfName = new list<String>();
        if(listOption != null){ listOfName.addALL(listOption); }
        listOfName.add(category);

        list<zqu__ProductRatePlan__c> listBundleProducts = [SELECT id, name, zqu__Product__r.name, Category__c, zqu__ZuoraId__c
                                                            FROM zqu__ProductRatePlan__c
                                                            WHERE Category__c = 'Bundle C' AND zqu__Product__r.Name = : productName AND name IN :listOfName AND
                                                                (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                                                            zqu__Deleted__c = FALSE ];
        if(listBundleProducts.size() > 0 && listBundleProducts != null) {
            for(zqu__ProductRatePlan__c bundlePrp : listBundleProducts) {
                listBundleId.add(bundlePrp.zqu__ZuoraId__c);
            }
        }

        return listBundleId;
    }
    @AuraEnabled(cacheable = true)
    public static boolean isPartnerUser(){
        user currentUser = [SELECT Id, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()];
        if(currentUser.Profile.Name == 'Utilisateur du Portail Distributeurs') {
            return true;
        } else {
            return false;
        }
    }
    public class CustomException extends Exception {}
}