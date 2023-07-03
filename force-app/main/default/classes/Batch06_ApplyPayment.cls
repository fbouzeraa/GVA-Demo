/*
 * Classe Batch pour appliqué les paiements sur la facture
 * pour vérifier si les log de payment ont ete creer
 */
global class Batch06_ApplyPayment implements Database.Batchable<sObject>, Database.AllowsCallouts {
/**
 * Start Method to filter Batch records
 */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        string subType = 'Standard';
        string activeSubStatus = 'Active';
        string pendingSubStatus = 'Pending Activation';
        string limitation = Test.isRunningTest()?' LIMIT 1' : '';
        String distribrecordType = 'Compte Distributeur';

        // Get all activated subscription with expected renewal date = null or paymentId = null
        // expected renewal date = null ==> bill not generated or payment not applied
        // payment Id = null on related quote means that the payment isn't created when the sub is created
        return Database.getQueryLocator('SELECT Id, Zuora__Zuora_Id__c,Zuora__ServiceActivationDate__c, Zuora__SubscriptionNumber__c, BoxNumber__c, Zuora__ContractEffectiveDate__c,' +
                                        'SUB_T_Original_InvoiceId__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__CustomerAccount__r.Zuora__BcdSettingOption__c,Zuora__Status__c, ' +
                                        'Quote__r.QUO_Periodes_Prepayees__c, Quote__r.QUO_Grand_Total__c, Quote__r.CreatedBy.Name, Quote__r.CreatedBy.USR_DistributeurID__c,Quote__c, ' +
                                        'Quote__r.QUO_T_SubscriptionId__c, Quote__r.QUO_T_PaymentID__c, Quote__r.QUO_PTO__c, Quote__r.QUO_Taux_De_Change__c, Zuora__Account__c,Quote__r.Name, ' +
                                        ' Zuora__Account__r.BillingCountryCode ' +
                                        ' FROM Zuora__Subscription__c ' +
                                        ' WHERE ((ExpectedRenewalDate__c = null AND Zuora__Status__c = \'' + String.escapeSingleQuotes(activeSubStatus) + '\' AND Type__c= \'' + String.escapeSingleQuotes(subType) + '\')' +
                                        ' OR (createdDate = TODAY AND Quote__r.QUO_T_PaymentID__c = null AND Zuora__Status__c = \'' + String.escapeSingleQuotes(pendingSubStatus) + '\' )) ' +
                                        ' AND Zuora__Account__r.RecordType.Name != \'' + String.escapeSingleQuotes(distribrecordType) + '\' ' +  limitation);
    }

    global void execute(Database.BatchableContext bc, List<Zuora__Subscription__c> listSubscriptions){
        list<Quote> listQuoteToUpdate = new list<Quote>();
        list<Suivi_de_Souscription__c> listOfSuiviToInsert = new list<Suivi_de_Souscription__c>();
        if(listSubscriptions != null && listSubscriptions.size() > 0) {
            ZuoraResponseObjects.ZuoraBill invoiceUpdateResponse = new ZuoraResponseObjects.ZuoraBill();
            // get zuora id of related account
            for(Zuora__Subscription__c sub : listSubscriptions) {
                HttpResponse accountResponse = ZuoraManager.getAccountSummary(sub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                ZuoraResponseObjects.ZuoraGetAccount getAccountInfoResponse = new ZuoraResponseObjects.ZuoraGetAccount();
                getAccountInfoResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(accountResponse.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);

                if(getAccountInfoResponse.success) {
                    // for activated Sub with error on the generated invoice or payment
                    if(sub.Zuora__Status__c == 'Active') {
                        //if invoices != null ==> apply payment and add expected renewal Date or just add renewal Date
                        if(getAccountInfoResponse.invoices != null && getAccountInfoResponse.invoices.size() > 0) {
                            // balance = 0 ==> payment is already applied,
                            // balance != 0 ==> payment not applied
                            if(getAccountInfoResponse.invoices[0].balance != 0) {
                                string invoiceCustomFields = ZuoraSubscriptionActions.updateBillCustomFields(true, getAccountInfoResponse.invoices[0].id, string.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c), sub, string.valueOf(sub.Quote__r.QUO_Taux_De_Change__c));
                                System.debug('invoice custom fields ' + invoiceCustomFields);
                                invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(invoiceCustomFields, ZuoraResponseObjects.ZuoraBill.class);

                                if(invoiceUpdateResponse.success) {

                                    boolean isApplied = applyPayment(getAccountInfoResponse.invoices[0].amount, getAccountInfoResponse.payments.size() > 0?getAccountInfoResponse.payments[0].id : sub.Quote__r.QUO_T_PaymentID__c,
                                                                     getAccountInfoResponse.invoices[0].id);
                                    if(isApplied) {
                                        boolean CheckResponse = addRenewalDate(sub.Zuora__ServiceActivationDate__c, sub.Zuora__SubscriptionNumber__c, string.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c));
                                        if(CheckResponse == true) {
                                            listOfSuiviToInsert.add(ZuoraSubscriptionActions.createSuivi(
                                                                        sub.BoxNumber__c, 'ACT011', Datetime.now(),
                                                                        'DST001', sub.id, sub.Zuora__Account__r.BillingCountryCode,
                                                                        sub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, null, null));
                                        }
                                    }
                                }
                            } else {
                                boolean CheckResponse = addRenewalDate(sub.Zuora__ServiceActivationDate__c, sub.Zuora__SubscriptionNumber__c, string.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c));
                                if(CheckResponse == true) {
                                    listOfSuiviToInsert.add(ZuoraSubscriptionActions.createSuivi(
                                                                sub.BoxNumber__c, 'ACT011', Datetime.now(),
                                                                'DST001', sub.id, sub.Zuora__Account__r.BillingCountryCode,
                                                                sub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, null, null));
                                }
                            }

                        } else {
                            //create invoice, apply payment, add expected renewal date
                            string billResponse = ZuoraSubscriptionActions.generateBill(new list<string> {sub.Zuora__Zuora_Id__c}, sub.Zuora__ServiceActivationDate__c, integer.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c),
                                                                                        sub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
                            ZuoraResponseObjects.ZuoraBill invoiceResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(
                                billResponse, ZuoraResponseObjects.ZuoraBill.class);
                            if(invoiceResponse.success) {
                                string invoiceCustomFields = ZuoraSubscriptionActions.updateBillCustomFields(true, invoiceResponse.invoices[0].id, string.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c), sub, string.valueOf(sub.Quote__r.QUO_Taux_De_Change__c));
                                System.debug('invoice custom fields ' + invoiceCustomFields);
                                invoiceUpdateResponse = (ZuoraResponseObjects.ZuoraBill) JSON.deserialize(invoiceCustomFields, ZuoraResponseObjects.ZuoraBill.class);

                                if(invoiceUpdateResponse.success) {
                                    boolean isApplied = applyPayment(double.valueOf(sub.Quote__r.QUO_Grand_Total__c), getAccountInfoResponse.payments[0].id,
                                                                     invoiceResponse.invoices[0].id);
                                    if(isApplied) {
                                        boolean CheckResponse = addRenewalDate(sub.Zuora__ServiceActivationDate__c, sub.Zuora__SubscriptionNumber__c, string.valueOf(sub.Quote__r.QUO_Periodes_Prepayees__c));
                                        if(CheckResponse == true) {
                                            listOfSuiviToInsert.add(ZuoraSubscriptionActions.createSuivi(
                                                                        sub.BoxNumber__c, 'ACT011', Datetime.now(),
                                                                        'DST001', sub.id, sub.Zuora__Account__r.BillingCountryCode,
                                                                        sub.Quote__r.QUO_PTO__c, 'STA001', null, null, null, null, null, null, null));
                                        }
                                    }
                                }

                            }
                        }
                    }
                    // Create payment for pending Sub
                    else {
                        //check if the payment is created
                        if(getAccountInfoResponse.payments.size() == 0) {
                            string payment = ZuoraSubscriptionActions.createPayment(null, sub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, sub.Quote__c, sub.Quote__r.Name);
                            ZuoraResponseObjects.ZuoraPayment paymentResponse = new ZuoraResponseObjects.ZuoraPayment();
                            paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(
                                payment, ZuoraResponseObjects.ZuoraPayment.class);
                            if(paymentResponse.success) {
                                Quote currentQuote = new Quote();
                                currentQuote.QUO_T_PaymentID__c = paymentResponse.id;
                                currentQuote.Id = sub.Quote__c;
                                listQuoteToUpdate.add(currentQuote);
                            }
                        } else {
                            Quote currentQuote = new Quote();
                            currentQuote.QUO_T_PaymentID__c = getAccountInfoResponse.payments[0].Id;
                            currentQuote.Id = sub.Quote__c;
                            listQuoteToUpdate.add(currentQuote);
                        }
                    }
                }
            }
            if(listQuoteToUpdate.size() > 0 && listQuoteToUpdate != null) {
                update listQuoteToUpdate;
            }
            if(listOfSuiviToInsert.size() > 0 && listOfSuiviToInsert != null) {
                try {
                    insert listOfSuiviToInsert;
                } catch(Exception e) {
                    system.debug(e.getMessage());
                }
            }
        }
    }
    public static boolean applyPayment(double invoiceAmount, string paymentId, string invoiceId){
        string applyResponse = ZuoraSubscriptionActions.applyPaymentToBill(invoiceAmount, paymentId, invoiceId);
        ZuoraResponseObjects.ZuoraPayment paymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(applyResponse, ZuoraResponseObjects.ZuoraPayment.class);

        return paymentResponse.success;
    }
    public static boolean addRenewalDate(date activationDate, string subNumber, string prepaidPeriod){

        boolean successfulResponse = false;

        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomField = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomField.ExpectedRenewalDate_Reserved = activationDate.addMonths(integer.valueOf(prepaidPeriod));
        subscription.customFields = subCustomField;

        HTTPResponse response  = ZuoraManager.updateSubscriptionCustomFields(subscription, subNumber);

        ZuoraResponseObjects.ZuoraSubscriptions updateSubResponse = new ZuoraResponseObjects.ZuoraSubscriptions();
        updateSubResponse = (ZuoraResponseObjects.ZuoraSubscriptions) JSON.deserialize(
            response.getBody(), ZuoraResponseObjects.ZuoraSubscriptions.class);

        if(updateSubResponse.Success == true) {
            successfulResponse = true;
        }

        return successfulResponse;
    }
    global void finish(Database.BatchableContext bc){}
}