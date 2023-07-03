/**
 * Classe fournissant les méthodes communes pour les classes de Test.
 *
 * @author Maroun Yazbeck
 * @date 30 Novembre 2020
 */
public class TestUtils {
    public static User createUser(string email, string lastName, string userName, string distId, id profileId){
        //Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' OR Name = 'Administrateur système'];
        User u = new User(Alias = 'systadm', Email = email,
                          EmailEncodingKey = 'UTF-8', LastName = lastName, LanguageLocaleKey = 'en_US',
                          LocaleSidKey = 'en_US', ProfileId = profileId,
                          TimeZoneSidKey = 'America/Los_Angeles', UserName = userName, CountryCode = 'TG', City = 'Lome', Pays_Mapbox__c = 'TG', USR_DistributeurId__c = distId);

        return u;
    }
    public static Account createPersonAccount(string accName){
        id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
        Account acc = new Account ( firstName = accName, lastName = accName, ACC_BuildingID__c = 'KIG_12343', ACC_LatLong__Latitude__s = 2, ACC_Eligible__c = false, ACC_Entreprise__c = 'GVA TOGO',
                                    ACC_LatLong__Longitude__s = 1.2, ACC_NumeroDEtage__c = 2, PersonMobilePhone = '36963', phone = '1212121', ACC_PresencePTO_cc__c = 'non',
                                    ACC_MaturiteProspect__c = 'Chaud', ACC_CategorisationProspect__c = 'prix', BillingCountry = 'Togo', BillingCountryCode = 'TG', BillingCity = 'Lome',
                                    CurrencyIsoCode = 'XOF', recordtypeId = personAccountId, PersonEmail = 'example@test.com', ACC_Escalier__c = 'Esc-12', ACC_Indicatif__c = '+228');

        return acc;
    }
    public static Contact createContact(Id accId, string conName){
        Contact con = new Contact(AccountId = accId, firstName = conName, LastName = conName, CON_Role__c = 'dir;adm', Phone = '09909090', Email = 'test@example.com', MailingCountryCode = 'BF');

        return con;
    }
    public static Opportunity createOpportunity(string oppName, Id accID, Id pricebookID){
        Opportunity opp = new Opportunity ( AccountId = accID, Name = oppName, StageName = 'Négociation', CloseDate = Date.today(), priceBook2Id = pricebookID);

        return opp;
    }
    Public static Product2 createProduct(string prName){
        Product2 pr = new Product2(Name = prName, IsActive = true);

        return pr;
    }
    Public static OpportunityLineItem createOpportunityLineItem(Id oppId, Id prID, Id prpID, Id pricebookEntryId){
        OpportunityLineItem OLI = new OpportunityLineItem(OpportunityId = oppId, Product2Id = prID, Quantity = 1, UnitPrice = 0, priceBookEntryId = pricebookEntryId, Product_Rate_Plan__c = prpID);

        return OLI;
    }
    public static zqu__ZProduct__c createZProduct(string zPrName){
        zqu__ZProduct__c zuoraZProduct = new zqu__ZProduct__c ( Name = zPrName, zqu__ZuoraId__c = '123321');

        return zuoraZProduct;
    }

    public static zqu__ProductRatePlan__c createProductRatePlan(string ratePlanName, Id ZProductID, Id ProdId, string zId, string type, string categorie){

        zqu__ProductRatePlan__c zuoraProductRatePlan = new zqu__ProductRatePlan__c ( Name = ratePlanName, zqu__ZProduct__c = ZProductID, zqu__ZuoraId__c = zId,
                                                                                     zqu__Product__c = prodId, WarrantyDurationInMonth__c = '3', Type__c = type, category__c = categorie,
                                                                                     zqu__EffectiveStartDate__c = date.today().addYears(-2), zqu__EffectiveEndDate__c = date.today().addYears(2),
                                                                                     SellingEffectiveEndDate__c = date.today().addYears(2), SellingEffectiveStartDate__c = date.today().addYears(-2));

        return zuoraProductRatePlan;
    }
    public static Quote createQuote( Id oppId, string quoteName, id priceBookId){
        Quote newQuote = new Quote (Name = quoteName, OpportunityId = oppId, priceBook2Id = priceBookId,
                                    QUO_Periodes_Prepayees__c = '2', QUO_T_Numero_De_Commande__c = 'O-0000100', QUO_PTO__c = 'PTO01', QUO_T_Numero_du_Box__c = 'ALCL:B3B9C216');

        return newQuote;
    }

    public static Id createPriceBook(){
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Price Book', isActive = true, Pays__c = 'TG');
        insert customPB;

        return customPB.Id;
    }

    public static PriceBookEntry createPriceBookEntry(Id pb2Id, Id prId){
        PriceBookEntry pbe = new PriceBookEntry(priceBook2Id = pb2Id, product2Id = prId, UnitPrice = 200, isActive = true);

        return pbe;
    }

    public static QuoteLineItem createQuoteLineItem(Id quoteId, Id prId, Id prpId, Id pbeId){

        QuoteLineItem QLI = new QuoteLineItem(QuoteId = quoteId, Product2Id = prId, Quantity = 1, UnitPrice = 0, Product_Rate_Plan__c = prpId, PricebookEntryId = pbeId);

        return QLI;
    }

    public static Zuora__CustomerAccount__c createCustomerAccount(string Name, ID accId, string distId){
        Zuora__CustomerAccount__c billingAccount = new Zuora__CustomerAccount__c(Name = Name, Zuora__Account__c = accId, Zuora__Zuora_Id__c = '1234554321', DistributorOperationBillingMinThreshold__c = '100000',
                                                                                 Zuora__AccountNumber__c = 'A00000600', DistributorId__c = distId, Zuora__BillToWorkEmail__c = 'test@test.com');

        return billingAccount;
    }

    public static Zuora__Subscription__c createSubscription(Id accID, Id quoteID, Id billingAccountId, String SubscriptionNumber){
        Zuora__Subscription__c zuoraSubscription = new Zuora__Subscription__c (Name = 'SUB1', Zuora__Account__c = accID, Zuora__SubscriptionNumber__c = SubscriptionNumber, Quote__c = quoteID, Type__c = 'Standard',
                                                                               SF_QuoteID__c = string.valueOf(quoteId), Zuora__Status__c = 'Pending Activation', Zuora__ServiceActivationDate__c = date.today().addMonths(-2),
                                                                               ExpectedRenewalDate__c = date.today(), Zuora__CustomerAccount__c = billingAccountId, BoxNumber__c = 'ALCL:B34AF4A3', RenewalSequenceNumber__c = '1');

        return zuoraSubscription;
    }

    public static zqu__ProductRatePlanCharge__c createPRPCharge(Id prpId, string chargeName, string zId){
        zqu__ProductRatePlanCharge__c prpCharge = new zqu__ProductRatePlanCharge__c(zqu__ProductRatePlan__c = prpId, Name = chargeName, zqu__ZuoraId__c = zId);

        return prpCharge;
    }

    public static zqu__productrateplanchargetier__c createPRPChargePrice( Id prpChargeId){
        zqu__productrateplanchargetier__c prpPrice = new zqu__productrateplanchargetier__c(zqu__Price__c = 909, zqu__ProductRatePlanCharge__c = prpChargeId, zqu__ZuoraId__c = '123321123' );

        return prpPrice;
    }
    public static Zuora__Product__c createZuoraProduct(){
        Zuora__Product__c zpr = new Zuora__Product__c (Name = 'CanalBox - Togo');

        return zpr;
    }
    public static Zuora__SubscriptionProductCharge__c createSubscriptionProduct(id subId, id accId, string ratePlanName, id PrId, string prodChargeName){

        Zuora__SubscriptionProductCharge__c subProduct = new Zuora__SubscriptionProductCharge__c(Zuora__Account__c = accId, Zuora__Subscription__c = subId,
                                                                                                 Zuora__RatePlanName__c = ratePlanName, Zuora__RatePlanId__c = '12332123232',
                                                                                                 Zuora__Product__c = prId, Name = prodChargeName, Zuora__ProductName__c = 'CanalBox - Togo',
                                                                                                 Zuora__Type__c = 'Recurring', Zuora__EndDateCondition__c = 'Subscription End Date');

        return subProduct;
    }
    public static id createSub(){

        Id customPriceBookId = createPriceBook();

        id distributorAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(system.label.Distributor_RecordType).getRecordTypeId();

        Account acc = createPersonAccount('TEST');
        insert acc;

        Account comptePartenaireMain = new Account (Name = 'Test Test1', currencyIsoCode = 'XOF', recordtypeId = distributorAccountId, phone = '+01212121', ACC_PresencePTO_cc__c = 'Non', ACC_Distributor_Number__c = system.label.Distributor_Id);
        insert comptePartenaireMain;

        Account comptePartenaire = new Account (Name = 'Test Test2', currencyIsoCode = 'XOF', recordtypeId = distributorAccountId, ParentId = comptePartenaireMain.Id, phone = '+01212121', ACC_PresencePTO_cc__c = 'Non');
        insert comptePartenaire;
        Zuora__CustomerAccount__c zMainDistAccount = createCustomerAccount('zDistributorAccount', comptePartenaire.Id, '0123');
        insert zMainDistAccount;
        Zuora__CustomerAccount__c zDistAccount = createCustomerAccount('zDistributorAccount', comptePartenaireMain.Id, system.label.Distributor_Id);
        insert zDistAccount;

        Zuora__CustomerAccount__c zAccount = createCustomerAccount('zAccount', acc.Id, '0134');
        insert zAccount;

        // contact con = createContact(comptePartenaireMain.Id,'conTest');
        // insert con;
        Opportunity opp = createOpportunity('OppTest', acc.Id, customPriceBookId);
        insert opp;
        Product2 pr = createProduct('CanalBox - Togo');
        insert pr;
        Product2 prSME = createProduct('CanalBox - Togo SME');
        insert prSME;

        // Create two PBEs on standard and on custom pricebooks. Use custom PBE in the line items
        PriceBookEntry pbeStandard = createPriceBookEntry(Test.getStandardPricebookId(), pr.Id);
        insert pbeStandard;
        PriceBookEntry pbeStandardSME = createPriceBookEntry(Test.getStandardPricebookId(), prSME.Id);
        insert pbeStandardSME;
        PriceBookEntry pbe = createPriceBookEntry(customPriceBookId, pr.Id);
        insert pbe;
        PriceBookEntry pbeSME = createPriceBookEntry(customPriceBookId, prSME.Id);
        insert pbeSME;
        zqu__ZProduct__c zProd = createZProduct('CanalBox - Togo');
        insert ZProd;
        zqu__ProductRatePlan__c PRP = createProductRatePlan('Premium', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9b', 'Base', 'offer');
        insert PRP;
        zqu__ProductRatePlan__c PRP2 = createProductRatePlan(system.label.Rate_Plan_Timbre_Fiscal, zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9', 'addOn', 'other');
        insert PRP2;
        zqu__ProductRatePlan__c PRP3 = createProductRatePlan('start', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9c', 'Base', 'offer');
        insert PRP3;
        zqu__ProductRatePlan__c PRP4 = createProductRatePlan('canalBox', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9d', 'addOn', 'equipment');
        insert PRP4;
        zqu__ProductRatePlan__c PRP5 = createProductRatePlan('canalBox1', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9u', 'addOn', 'Installation Service');
        insert PRP5;
        zqu__ProductRatePlan__c prp6 = createProductRatePlan('CanalBox - Togo', zProd.Id, pr.Id, '8adc8f9975c011180175c0e3a50c7f9u', 'addOn', 'Collaborator');
        insert prp6;
        zqu__productrateplancharge__c prpCharge = createPRPCharge(PRP2.Id, system.label.Rate_Plan_Timbre_Fiscal, '8adc8f9975c030080175c0877657858');
        insert prpCharge;
        OpportunityLineItem OLI = createOpportunityLineItem(opp.Id, pr.Id, PRP.Id, pbe.id);
        insert OLI;
        Quote newQuote = createQuote(opp.Id, 'qName', opp.priceBook2Id);
        insert newQuote;
        QuoteLineItem QLI = createQuoteLineItem(newQuote.Id, pr.Id, PRP.Id, pbe.id);
        insert QLI;
        Zuora__Subscription__c sub = createSubscription(acc.Id, newQuote.Id, zAccount.Id, 'A-S00000400');
        insert sub;
        Zuora__Subscription__c DistSub = createSubscription(comptePartenaireMain.Id, newQuote.Id, zDistAccount.Id, 'A-S00000401');
        insert distSub;
        Zuora__Product__c prod = createZuoraProduct();
        insert prod;
        Zuora__SubscriptionProductCharge__c subProd = createSubscriptionProduct( DistSub.Id, comptePartenaireMain.Id, 'Canal', prod.Id, 'prodChargeName');
        insert subProd;
        Zuora__SubscriptionProductCharge__c subProd2 = createSubscriptionProduct( DistSub.Id, comptePartenaireMain.Id, 'Start', prod.Id, 'prodChargeName');
        insert subProd2;
        Zuora__SubscriptionProductCharge__c subProd3 = createSubscriptionProduct( DistSub.Id, comptePartenaireMain.Id, 'Premium', prod.Id, 'prodChargeName');
        insert subProd3;

        return sub.id;
    }
}