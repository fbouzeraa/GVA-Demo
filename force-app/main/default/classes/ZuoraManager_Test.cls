/**
* Classe test pour zuora Manager
* Couverture: 93%
* @author Yara Bourdoukan
* @date 30 Novembre 2020
*/
@isTest
public class ZuoraManager_Test {
    /**
* Methode utilisée pour Créer un compte a travers un web service.
*/
    @isTest
    public static void testCreateAccount()
    {
        Test.startTest();
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        //Prepare the request 
        ZuoraObjects.ZuoraAccount newAccount = new ZuoraObjects.ZuoraAccount();
        newAccount.autoPay = true;
        newAccount.existingID = '122121';
        newAccount.billCycleDay = 5;
        newAccount.currency_toReplace = 'EUR';
        newAccount.name = 'Test_newAccountname';
        newAccount.billToContact = getBillToContact();
        newAccount.soldToContact = getBillToContact();
        ZuoraManager.createOrUpdateAccount(newAccount);
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.createOrUpdateAccount(newAccount);
        //Catch error
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(false,true,200));
        ZuoraManager.createOrUpdateAccount(newAccount);
        Test.stopTest();
    }
     @isTest
    public static void testcreateOrUpdateAccount()
    {
        Test.startTest();
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        //Prepare the request 
        ZuoraObjects.ZuoraAccount newAccount = new ZuoraObjects.ZuoraAccount();
        newAccount.autoPay = true;
        newAccount.billCycleDay = 5;
        newAccount.currency_toReplace = 'EUR';
        newAccount.name = 'Test_newAccountname';
        newAccount.billToContact = getBillToContact();
        newAccount.soldToContact = getBillToContact();
        ZuoraManager.createOrUpdateAccount(newAccount);
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.createOrUpdateAccount(newAccount);
        //Catch error
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(false,true,200));
        ZuoraManager.createOrUpdateAccount(newAccount);
        Test.stopTest();
    }
    @isTest
    public static void testUpdateAccount()
    {    
        //Prepare the request 
        ZuoraObjects.ZuoraUpdateAccount updateAccount = new ZuoraObjects.ZuoraUpdateAccount();
        updateAccount.billCycleDay = 0;
        updateAccount.DefaultPaymentMethodId='98677656564efr4344';
        Test.startTest();
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.updateZuoraAccount(updateAccount,'12334321');
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.updateZuoraAccount(updateAccount,'12334321');
        Test.stopTest();
    }
    /**
* Methode utilisée pour Créer une Souscription a travers un web service.
*/
    @isTest
    public static void testCreateSubscription()
    {
        Test.startTest();
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        //Prepare the request         
        
        ZuoraObjects.ZuoraRenewalTerm renewalTerms = new ZuoraObjects.ZuoraRenewalTerm();
        renewalTerms.period = 12;
        renewalTerms.periodType = 'Month';
        
        ZuoraObjects.ZuoraInitialTerm initialTerm = new ZuoraObjects.ZuoraInitialTerm();
        initialTerm.period = 12;
        initialTerm.periodType = 'Month';
        initialTerm.termType = 'TERMED';
        
        ZuoraObjects.ZuoraTerms terms = new ZuoraObjects.ZuoraTerms();
        terms.autoRenew = true;
        terms.initialTerm = initialTerm;
        terms.renewalSetting = 'RENEW_WITH_SPECIFIC_TERM';
        terms.renewalTerms = new List<ZuoraObjects.ZuoraRenewalTerm>{renewalTerms};
            
            ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlans = new ZuoraObjects.ZuorasubscribeToRatePlans();
        subscribeToRatePlans.productRatePlanId = 'efbff07e6290dfb8016291003bd00dda';
        
        ZuoraObjects.ZuoraCreateSubscription createSubscription = new ZuoraObjects.ZuoraCreateSubscription();
        createSubscription.subscribeToRatePlans = new List<ZuoraObjects.ZuorasubscribeToRatePlans>{subscribeToRatePlans};
            createSubscription.terms = terms;
        
        ZuoraObjects.ZuoraOrderAction orderActions = new ZuoraObjects.ZuoraOrderAction();
        orderActions.createSubscription = createSubscription;
        orderActions.type = 'CreateSubscription';
        
        ZuoraObjects.ZuoraOrderSubscription subscriptions = new ZuoraObjects.ZuoraOrderSubscription();
        subscriptions.orderActions = new List<ZuoraObjects.ZuoraOrderAction>{orderActions};
            subscriptions.subscriptionNumber = '4153156';   
        
        ZuoraObjects.ZuoraAccount newAccount = new ZuoraObjects.ZuoraAccount();
        newAccount.autoPay = true;
        newAccount.billCycleDay = 5;
        newAccount.currency_toReplace = 'EUR';
        newAccount.name = 'Test_newAccountname';
        newAccount.billToContact = getBillToContact();
        newAccount.soldToContact = getBillToContact();
        
        ZuoraObjects.ZuoraOrder request = new ZuoraObjects.ZuoraOrder();
        request.existingAccountNumber = 'A00000001';
        request.orderDate = '2017-01-01';
        request.subscriptions = new List<ZuoraObjects.ZuoraOrderSubscription>{subscriptions};
            request.newAccount =newAccount;
        
        ZuoraManager.createOrder(request,ZuoraObjects.OrderType.NEW_SUBSCRIPTION);
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.createOrder(request,ZuoraObjects.OrderType.NEW_SUBSCRIPTION);
        Test.stopTest();
    }
    /**
* Methode utilisée pour Créer un contact a travers un web service.
*/
    @isTest
    public static void testCreateContact()
    { 
        Test.startTest();
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraObjects.ZuoraContact retVal = new ZuoraObjects.ZuoraContact();
        retVal.country = 'Test_Country';
        retVal.firstName = 'Test_FirstName';
        retVal.lastName = 'Test_LastName';
        retVal.AccountId = '12332112331333333333132';
        
        ZuoraManager.createOrUpdateContact(retVal);
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.createOrUpdateContact(retVal);
        Test.stopTest();
        
    }
    @isTest
    public static void testUpdateContact()
    {
        Test.startTest();
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        //Prepare the request 
        ZuoraObjects.ZuoraContact updateContact = new ZuoraObjects.ZuoraContact();
        updateContact.country = 'Lebanon';
        updateContact.existingID='C00001';
        ZuoraManager.createOrUpdateContact(updateContact);
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.createOrUpdateContact(updateContact);
        Test.stopTest();
    }
    
    private static ZuoraObjects.ZuoraContact getBillToContact(){
        
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraObjects.ZuoraContact retVal = new ZuoraObjects.ZuoraContact();
        retVal.country = 'Test_Country';
        retVal.firstName = 'Test_FirstName';
        retVal.lastName = 'Test_LastName';
        
        return retVal;
    }
    @isTest
    public static void testCreatePayment()
    {
        Test.startTest();
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraObjects.ZuoraPayment paymentInfo = new ZuoraObjects.ZuoraPayment();
        paymentInfo.accountId='123654123';
        paymentInfo.amount = 40; 
        paymentInfo.currency_toReplace = 'XAF';
        paymentInfo.effectiveDate = string.valueOf(date.today());
        paymentInfo.type = 'External'; 
        ZuoraManager.createPayment(paymentInfo);
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.createPayment(paymentInfo);
        Test.stopTest();
    }
    @isTest
    public static void testUpdateTriggerDates()
    {
        Test.startTest();
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraObjects.ZuoraTriggerDate activationDate = new ZuoraObjects.ZuoraTriggerDate();
        list<ZuoraObjects.ZuoraTriggerDate> listTriggerDate = new list<ZuoraObjects.ZuoraTriggerDate>();
        activationDate.name = 'ServiceActivation';
        activationDate.triggerDate = string.valueOf(date.today());
        listTriggerDate.add(activationDate);
        
        ZuoraObjects.ZuoraOrderAction zuoraOrder =new ZuoraObjects.ZuoraOrderAction();
        ZuoraOrder.sequence = 0;
        ZuoraOrder.triggerDates=listTriggerDate;
        
        list<ZuoraObjects.ZuoraOrderAction> listZuoraOrder = new list<ZuoraObjects.ZuoraOrderAction>();
        listZuoraOrder.add(ZuoraOrder);
        
        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        subscription.orderActions=listZuoraOrder;
        subscription.subscriptionNumber ='A0001';
        list<ZuoraObjects.ZuoraOrderSubscription> listSubscriptions = new list<ZuoraObjects.ZuoraOrderSubscription>();
        listSubscriptions.add(subscription);
        
        ZuoraObjects.ZuoraOrder zSub = new ZuoraObjects.ZuoraOrder();  
        zSub.subscriptions=listSubscriptions;
        
        ZuoraManager.updateTriggerOrder(zsub,'O-00120');
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.updateTriggerOrder(zsub,'O-00120');
        Test.stopTest();
    }
    @isTest
    public static void testUpdateSubscriptionCustomFields()
    {
        Test.startTest();       
        ZuoraObjects.ZuoraOrderSubscription subscription = new ZuoraObjects.ZuoraOrderSubscription();
        ZuoraObjects.ZuoraSubscriptionCustomFields subCustomField = new ZuoraObjects.ZuoraSubscriptionCustomFields();
        subCustomField.ExpectedRenewalDate_Reserved = date.today();
        subscription.customFields = subCustomField;
        
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.updateSubscriptionCustomFields(subscription,'A-S00120');
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.updateSubscriptionCustomFields(subscription,'A-S00120');
        Test.stopTest();
    }
    @isTest
    public static void testApplyPayment()
    {
        Test.startTest();       
        ZuoraObjects.ZuoraPayment paymentInfo = new ZuoraObjects.ZuoraPayment();
        ZuoraObjects.ZuoraBilling invoiceInfo = new ZuoraObjects.ZuoraBilling();
        list<ZuoraObjects.ZuoraBilling> listInvoiceInfo = new List<ZuoraObjects.ZuoraBilling>();
        invoiceInfo.invoiceId = 'INV-0001';
        invoiceInfo.amount = 123;
        listInvoiceInfo.add(invoiceInfo);
        paymentInfo.effectiveDate = '2021-12-02';
        paymentInfo.Invoices = listInvoiceInfo;
        
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.applyPayment(paymentInfo,'98745321');
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.applyPayment(paymentInfo,'98745321');
        Test.stopTest();
    }
    @isTest
    public static void testCreateBillByAccount()
    {
        Test.startTest();       
        ZuoraObjects.ZuoraBilling zBill = new ZuoraObjects.ZuoraBilling();
        zBill.autoPost = true;
        zBill.effectiveDate = '2021-01-02';
        zBill.targetDate = '2021-01-02';
        zBill.subscriptionIds = new list<string>{'123221'};
            
            //Get a successful response
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.CreateBillByAccount(zBill,'98745321');
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.CreateBillByAccount(zBill,'98745321');
        Test.stopTest();
    }
    @isTest
    public static void testGetInvoiceBody()
    {
        Test.startTest(); 
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.getInvoiceBody('98745321');
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.getInvoiceBody('98745321');
        Test.stopTest();  
    }
    @isTest
    public static void testGetAccountSummary()
    {
        Test.startTest(); 
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.getAccountSummary('98745321');
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.getAccountSummary('98745321');
        Test.stopTest();  
    }
    
    @isTest
    public static void testGetZuoraAccount()
    {
        Test.startTest(); 
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.getZuoraAccount('98745321');
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.getZuoraAccount('98745321');
        Test.stopTest();  
    }
    @isTest
    public static void testPreviewOrder()
    {
        ZuoraObjects.ZuoraPreviewAccount accountInfo = new ZuoraObjects.ZuoraPreviewAccount();
        
        accountInfo.currency_toReplace = 'XAF';
        accountInfo.billCycleDay = 0;
        ZuoraObjects.ZuoraContact soldToContactInfo = new ZuoraObjects.ZuoraContact();
        soldToContactInfo.country = 'Lebanon';
        accountInfo.soldToContact = soldToContactInfo;
        
        ZuoraObjects.ZuoraInitialTerm initialTerms = new ZuoraObjects.ZuoraInitialTerm();
        initialTerms.termType = System.label.B2C_Subscription_Term_Type;
        
        ZuoraObjects.ZuoraTerms term = new ZuoraObjects.ZuoraTerms();
        term.initialTerm = initialTerms;
        
        ZuoraObjects.ZuorasubscribeToRatePlans subscribeToRatePlan = new ZuoraObjects.ZuorasubscribeToRatePlans();
        list<ZuoraObjects.ZuorasubscribeToRatePlans> listSubscribeToRatePlans = new List<ZuoraObjects.ZuorasubscribeToRatePlans>();
        
        subscribeToRatePlan.productRatePlanId = '8s8844746fd';
        listSubscribeToRatePlans.add(subscribeToRatePlan);
        
        
        ZuoraObjects.ZuoraCreateSubscription subscription = new ZuoraObjects.ZuoraCreateSubscription();
        //add term to subscription
        subscription.terms = term;
        subscription.subscribeToRatePlans = listSubscribeToRatePlans;
        
        list<string> listPreviewType = new List<string>();
        listPreviewType.add('BillingDocs');
        
        ZuoraObjects.ZuoraPreviewOptions option = new ZuoraObjects.ZuoraPreviewOptions();
        option.previewTypes = listPreviewType;
        option.previewThruType = 'SpecificDate';
        option.specificPreviewThruDate = '2020-12-01';
        
        //add subscription to order action
        ZuoraObjects.ZuoraOrderAction zuoraOrder = new ZuoraObjects.ZuoraOrderAction();
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
        
        Test.startTest(); 
        //Get a successful response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ZuoraManager.previewOrder(zSub);
        //Get an error response
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(true,false,401));
        ZuoraManager.previewOrder(zSub);
        Test.stopTest();  
    }
    
}