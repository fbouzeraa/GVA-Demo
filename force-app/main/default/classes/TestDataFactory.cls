public with sharing class TestDataFactory {

    public static User createAdminUser(String userCountryCode){
        UserRole userRole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'DMCFilialeBF' Limit 1];
        Profile systemAdministratorProfile = [SELECT id, Name FROM Profile WHERE name = 'System Administrator' ].get(0);  
        return new User(firstname= 'Admin',
                        lastname='User',
                        Alias='auser',
                        email = 'admin.user@gmail.fr',
                        username= 'test.admin.user@mail.fr', 
                        profileId= systemAdministratorProfile.id, 
                        emailencodingkey='UTF-8',
                        languagelocalekey='en_US',
                        localesidkey='en_US',
                        timezonesidkey='America/Los_Angeles',
                        UserRoleId = userRole.Id,
                        isActive = true,
                        userPermissionsKnowledgeUser=true,
                        countryCode=userCountryCode);      
    }


    public static List<KnowledgeFaqSection__c> createKnowledgeFaqSections(){
        KnowledgeFaqSection__c knowledgeFaqSection1 = new KnowledgeFaqSection__c(
            Name = 'Section 1',
            KnowledgeFaqSectionOrder__c = 1
            );

        KnowledgeFaqSection__c knowledgeFaqSection2 = new KnowledgeFaqSection__c(
            Name = 'Section 2',
            KnowledgeFaqSectionOrder__c = 2
            );  
            
        return new List<KnowledgeFaqSection__c>{
                    knowledgeFaqSection1,
                    knowledgeFaqSection2
                    };
    }

    public static List<Knowledge__kav> createKnowledegeArticles(List<KnowledgeFaqSection__c> knowledgeFaqSections){

        Id faqKnowledgeRecordTypeId = 
                    Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();

        Id procedureKnowledgeRecordTypeId = 
                    Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('Procedure').getRecordTypeId();

        Knowledge__kav article1 = new Knowledge__kav(
            title='<h4>Test  article 1</h4>',
            urlName='Test-article-1',
            question__c='<h4>My questions 1 My Questions 1 My quEStions 1.</h4>',
            answer__c='<p>My Answer 1.0 and my aNswer 2.0 and mt answer 3.0 test</p> <a href="https://www.w3schools.com">Visit W3Schools</a>',
            faqSectionName__c = knowledgeFaqSections[0].Id,
            RecordTypeId=faqKnowledgeRecordTypeId,
            isVisibleInCsp=true,
            language='fr',
            faqArticleOrderInSection__c=1,
            countryCode__c = 'TG'  //TOGO
            );

        Knowledge__kav article2 = new Knowledge__kav(
                    title='Test  article 2',
                    urlName='Test-article-2',
                    question__c='My quetions 2',
                    answer__c='<p>My anwer 2</p> <a href="https://www.w3schools.com">Visit W3Schools</a>',
                    faqSectionName__c = knowledgeFaqSections[1].Id,
                    RecordTypeId=faqKnowledgeRecordTypeId,
                    isVisibleInCsp=true,
                    language='fr',
                    faqArticleOrderInSection__c=2,
                    countryCode__c = 'TG' 
                    );


        Knowledge__kav article3 = new Knowledge__kav(
                    title='Test  article 3',
                    urlName='Test-article-3',
                    question__c='My questions 3',
                    answer__c='My answer 3',
                    faqSectionName__c = knowledgeFaqSections[0].Id,
                    RecordTypeId=procedureKnowledgeRecordTypeId,
                    isVisibleInCsp=true,
                    language='fr',
                    faqArticleOrderInSection__c=3,
                    countryCode__c = 'TG' 
                    ); 
                    
        Knowledge__kav article4 = new Knowledge__kav(
                    title='Test  article 4',
                    urlName='Test-article-4',
                    question__c='My questions 4',
                    answer__c='My answer 4',
                    faqSectionName__c = knowledgeFaqSections[0].Id,
                    RecordTypeId=faqKnowledgeRecordTypeId,
                    isVisibleInCsp=true,
                    language='fr',
                    faqArticleOrderInSection__c=4,
                    countryCode__c = 'TG' 
                    ); 
                    
        Knowledge__kav article5 = new Knowledge__kav(
                        title='Test  article 5',
                        urlName='Test-article-5',
                        question__c='<h4>My questions 5</h4>',
                        answer__c='<p>My answer 5</p>',
                        faqSectionName__c = knowledgeFaqSections[0].Id,
                        RecordTypeId=faqKnowledgeRecordTypeId,
                        isVisibleInCsp=false,
                        language='fr',
                        faqArticleOrderInSection__c=5,
                        countryCode__c = 'TG' 
                        );

        Knowledge__kav article6 = new Knowledge__kav(
                            title='Test  article 6',
                            urlName='Test-article-6',
                            question__c='My questions 6',
                            answer__c='My answer 6',
                            faqSectionName__c = knowledgeFaqSections[0].Id,
                            RecordTypeId=faqKnowledgeRecordTypeId,
                            isVisibleInCsp=true,
                            language='en_US',
                            faqArticleOrderInSection__c=6,
                            countryCode__c = 'TG',
                            IsArticleForAllCountries__c	= true
                            );


        Knowledge__kav article7 = new Knowledge__kav(
                            title='Test  article 7',
                            urlName='Test-article-7',
                            question__c='My questions 7',
                            answer__c='My answer 7',
                            faqSectionName__c = knowledgeFaqSections[0].Id,
                            RecordTypeId=faqKnowledgeRecordTypeId,
                            isVisibleInCsp=true,
                            language='fr',
                            faqArticleOrderInSection__c=7,
                            countryCode__c = 'CD'
                            );

        Knowledge__kav article8 = new Knowledge__kav(
                                title='Test  article 8',
                                urlName='Test-article-8',
                                question__c='My uestions 8',
                                answer__c='My nswer 8',
                                faqSectionName__c = knowledgeFaqSections[0].Id,
                                RecordTypeId=faqKnowledgeRecordTypeId,
                                isVisibleInCsp=true,
                                language='fr',
                                faqArticleOrderInSection__c=8,
                                countryCode__c = 'CD',
                                IsArticleForAllCountries__c	= true
                                );
    
    return  new List<Knowledge__kav>{
                                    article1, 
                                    article2,
                                    article3,
                                    article4,
                                    article5,
                                    article6,
                                    article7,
                                    article8
                                };
    }


    public static void publishArticles(List<Knowledge__kav> articles, List<Integer> articlesToPublish){
        for(Integer articleNumber : articlesToPublish){
            Knowledge__kav articleToPublish = [SELECT KnowledgeArticleId, Language 
                                            FROM knowledge__kav 
                                            WHERE id =: articles[articleNumber].Id];
            KbManagement.PublishingService.publishArticle(articleToPublish.KnowledgeArticleId, true);
        }
    }

    public static User createClientPortalUser(User adminUser, String countryCode){
        Account personAccount = createPersonAccount(adminUser, countryCode);
        insert personAccount;
        User clientPortalUser = createClientPortalUser(personAccount, countryCode);
        return clientPortalUser;

    }


    // public static User createFranceClientPortalUser(User adminUser){
    //     Account personAccount = createPersonAccount(adminUser);
    //     insert personAccount;
    //     User clientPortalUser = createFranceClientPortalUser(personAccount);
    //     return clientPortalUser;
    // }


    public static Account createPersonAccount(User adminUser, String countryCode){
        Id personAccountRecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
        Account personAccount = new Account(
            RecordTypeID=personAccountRecordTypeId ,
            OwnerId=adminUser.Id ,
            FirstName='Person' + countryCode,
            LastName='Account ' + countryCode,
            PersonMailingStreet='person.account@yahoo.com',
            PersonMailingPostalCode='1234512',
            PersonMailingCity='SFO12',
            PersonEmail= countryCode +'.person.account@yahoo.com',
            PersonHomePhone='12345671',
            Phone='123456',
            PersonMobilePhone='123456781');
        return personAccount;
    }

    public static User createClientPortalUser(Account personAccount, String countryCode){
        System.debug('personAccount : ' + personAccount);
        List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :personAccount.Id];
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0); 
        System.debug('contacts : ' + contacts);
        System.debug('contacts[0].Id : ' + contacts[0].Id);
        User clientPortalUser = new User(Alias = 'cport', 
                            Email='client.portal.user@testorg.com', 
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing' + countryCode, 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = clientPortalProfile.Id, 
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName= countryCode + '.client.portal.user@testorg.com',
                            ContactId = contacts[0].Id,
                            CountryCode = countryCode,
                            MobilePhone = personAccount.PersonMobilePhone
                            );
        return clientPortalUser;
    }


    private static User createFranceClientPortalUser(Account personAccount){
        List<Contact> contacts = [SELECT Id FROM Contact];
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0); 
        User clientPortalUser = new User(Alias = 'cport', 
                            Email='france.client.portal.user@testorg.com', 
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = clientPortalProfile.Id, 
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='client.portal.user@testorg.com',
                            ContactId = contacts[0].Id,
                            Country = 'France'
                            );
        return clientPortalUser;
    }



    public static List<Knowledge__kav> createCountriesKnowledegeArticles(){

        Knowledge__kav togoArticle = new Knowledge__kav(
                                    title='Togo article',
                                    urlName='togo-article',
                                    countryCode__c = 'TG'
                                );
    
        Knowledge__kav rdcArticle = new Knowledge__kav(
                                    title='RDC article',
                                    urlName='rdc-article',
                                    countryCode__c = 'CD' 
                                   );
    
        Knowledge__kav rwandaArticle = new Knowledge__kav(
                                    title='Rwanda article',
                                    urlName='rwanda-article',
                                    countryCode__c = 'RW' 
                                   );

        Knowledge__kav burkinaFasoArticle = new Knowledge__kav(
                                    title='Burkina faso article',
                                    urlName='burkina-faso-article',
                                    countryCode__c = 'BF' 
                                   );  
                                   
        Knowledge__kav franceArticle = new Knowledge__kav(
                                    title='France article',
                                    urlName='france-article',
                                    countryCode__c = 'FR' 
                                   );

        Knowledge__kav gabonArticle = new Knowledge__kav(
                                    title='Gabon article',
                                    urlName='gabon-article',
                                    countryCode__c = 'GA' 
                                   );

        Knowledge__kav congoArticle = new Knowledge__kav(
                                    title='Congo article',
                                    urlName='congo-article',
                                    countryCode__c = 'CG' 
                                   );
                                   
        Knowledge__kav coteIvoireArticle = new Knowledge__kav(
                                    title='Côte ivoire article',
                                    urlName='cote-ivoire-article',
                                    countryCode__c = 'CI' 
                                   );
                                   
        return  new List<Knowledge__kav>{
                                    togoArticle, 
                                    rdcArticle,
                                    rwandaArticle,
                                    burkinaFasoArticle,
                                    franceArticle
                                 // gabonArticle,
                                 // congoArticle,
                                 // coteIvoireArticle
                                }; 

    }

    public static Id createPriceBook(String countryCode){
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Price Book', isActive = true, Pays__c = countryCode);
        insert customPB;

        return customPB.Id;
    }



    public static Zuora__Subscription__c createSub(Account acc){

        Id customPriceBookId = createPriceBook(acc.BillingCountryCode);

        id distributorAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(system.label.Distributor_RecordType).getRecordTypeId();

        // Account acc = TestUtils.createPersonAccount('TEST');
        // insert acc;

        Account comptePartenaireMain = new Account (Name = 'Test Test1', currencyIsoCode = 'XOF', recordtypeId = distributorAccountId, phone = '+01212121', ACC_PresencePTO_cc__c = 'Non');
        insert comptePartenaireMain;

        Account comptePartenaire = new Account (Name = 'Test Test2', currencyIsoCode = 'XOF', recordtypeId = distributorAccountId, ParentId = comptePartenaireMain.Id, phone = '+01212121', ACC_PresencePTO_cc__c = 'Non');
        insert comptePartenaire;
        Zuora__CustomerAccount__c zMainDistAccount = TestUtils.createCustomerAccount('zDistributorAccount', comptePartenaire.Id, '0123');
        insert zMainDistAccount;
        Zuora__CustomerAccount__c zDistAccount = TestUtils.createCustomerAccount('zDistributorAccount', comptePartenaireMain.Id, '0123');
        insert zDistAccount;

        Zuora__CustomerAccount__c zAccount = TestUtils.createCustomerAccount('zAccount', acc.Id, system.label.Distributor_Id);
        insert zAccount;
        // contact con = createContact(acc.Id,'conTest');
        // insert con;
        Opportunity opp = TestUtils.createOpportunity('OppTest', acc.Id, customPriceBookId);
        insert opp;
        Product2 pr = TestUtils.createProduct('CanalBox - Togo');
        insert pr;
        Product2 prSME = TestUtils.createProduct('CanalBox - Togo SME');
        insert prSME;

        // Create two PBEs on standard and on custom pricebooks. Use custom PBE in the line items
        PriceBookEntry pbeStandard = TestUtils.createPriceBookEntry(Test.getStandardPricebookId(), pr.Id);
        insert pbeStandard;
        PriceBookEntry pbeStandardSME = TestUtils.createPriceBookEntry(Test.getStandardPricebookId(), prSME.Id);
        insert pbeStandardSME;
        PriceBookEntry pbe = TestUtils.createPriceBookEntry(customPriceBookId, pr.Id);
        insert pbe;
        PriceBookEntry pbeSME = TestUtils.createPriceBookEntry(customPriceBookId, prSME.Id);
        insert pbeSME;
        zqu__ZProduct__c zProd = TestUtils.createZProduct('CanalBox - Togo');
        insert ZProd;
        zqu__ProductRatePlan__c PRP = TestUtils.createProductRatePlan('Premium', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9b', 'Base', 'offer');
        insert PRP;
        zqu__ProductRatePlan__c PRP2 = TestUtils.createProductRatePlan(system.label.Rate_Plan_Timbre_Fiscal, zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9', 'addOn', 'other');
        insert PRP2;
        zqu__ProductRatePlan__c PRP3 = TestUtils.createProductRatePlan('start', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9c', 'Base', 'offer');
        insert PRP3;
        zqu__ProductRatePlan__c PRP4 = TestUtils.createProductRatePlan('canalBox', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9d', 'addOn', 'equipment');
        insert PRP4;
        zqu__ProductRatePlan__c PRP5 = TestUtils.createProductRatePlan('canalBox1', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9u', 'addOn', 'Installation Service');
        insert PRP5;
        zqu__productrateplancharge__c prpCharge = TestUtils.createPRPCharge(PRP2.Id, system.label.Rate_Plan_Timbre_Fiscal, '8adc8f9975c030080175c0877657858');
        insert prpCharge;
        OpportunityLineItem OLI = TestUtils.createOpportunityLineItem(opp.Id, pr.Id, PRP.Id, pbe.id);
        insert OLI;
        Quote newQuote = TestUtils.createQuote(opp.Id, 'qName', opp.priceBook2Id);
        insert newQuote;
        QuoteLineItem QLI = TestUtils.createQuoteLineItem(newQuote.Id, pr.Id, PRP.Id, pbe.id);
        insert QLI;
        Zuora__Subscription__c sub = TestUtils.createSubscription(acc.Id, newQuote.Id, zAccount.Id,'A-S00000400');
      

        return sub;
    }


    public static Zuora__Subscription__c createSecondSub(Account acc, String subscriptionNumber){

        //Id customPriceBookId = TestUtils.createPriceBook();
        Id customPriceBookId  = [SELECT Id FROM Pricebook2 WHERE Name='Test Price Book'].get(0).Id;

        id distributorAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(system.label.Distributor_RecordType).getRecordTypeId();

        // Account acc = TestUtils.createPersonAccount('TEST');
        // insert acc;

        // Account comptePartenaireMain = new Account (Name = 'Test Test1', currencyIsoCode = 'XOF', recordtypeId = distributorAccountId, phone = '+01212121', ACC_PresencePTO_cc__c = 'Non');
        // insert comptePartenaireMain;

        // Account comptePartenaire = new Account (Name = 'Test Test2', currencyIsoCode = 'XOF', recordtypeId = distributorAccountId, ParentId = comptePartenaireMain.Id, phone = '+01212121', ACC_PresencePTO_cc__c = 'Non');
        // insert comptePartenaire;
        // Zuora__CustomerAccount__c zMainDistAccount = TestUtils.createCustomerAccount('zDistributorAccount', comptePartenaire.Id, '0123');
        // insert zMainDistAccount;
        // Zuora__CustomerAccount__c zDistAccount = TestUtils.createCustomerAccount('zDistributorAccount', comptePartenaireMain.Id, '0123');
        // insert zDistAccount;

        Zuora__CustomerAccount__c zAccount = TestUtils.createCustomerAccount('zAccount', acc.Id, System.label.Distributor_Id);
        insert zAccount;
        
        // contact con = createContact(acc.Id,'conTest');
        // insert con;
        Opportunity opp = TestUtils.createOpportunity('OppTest2', acc.Id, customPriceBookId);
        insert opp;
        // Product2 pr = TestUtils.createProduct('CanalBox - Togo');
        // insert pr;
        Product2 pr = [SELECT Id, Name, IsActive FROM Product2 WHERE Name='CanalBox - Togo'].get(0);
        // Product2 prSME = TestUtils.createProduct('CanalBox - Togo SME');
        // insert prSME;

        // Create two PBEs on standard and on custom pricebooks. Use custom PBE in the line items
        // PriceBookEntry pbeStandard = TestUtils.createPriceBookEntry(Test.getStandardPricebookId(), pr.Id);
        // insert pbeStandard;
        // PriceBookEntry pbeStandardSME = TestUtils.createPriceBookEntry(Test.getStandardPricebookId(), prSME.Id);
        // insert pbeStandardSME;
        // PriceBookEntry pbe = TestUtils.createPriceBookEntry(customPriceBookId, pr.Id);
        // insert pbe;
            PriceBookEntry pbe = [SELECT Id, priceBook2Id, product2Id, UnitPrice, isActive 
                                    FROM PriceBookEntry 
                                    WHERE priceBook2Id = :customPriceBookId].get(0);  
        // PriceBookEntry pbeSME = TestUtils.createPriceBookEntry(customPriceBookId, prSME.Id);
        // insert pbeSME;
        // zqu__ZProduct__c zProd = [SELECT Id, zqu__ZuoraId__c FROM zqu__ZProduct__c WHERE Name ='CanalBox - Togo'].get(0);
        // zqu__ZProduct__c zProd = TestUtils.createZProduct('CanalBox - Togo');
        // insert ZProd;
        // zqu__ProductRatePlan__c PRP = TestUtils.createProductRatePlan('Premium', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9b', 'Base', 'offer');
        // insert PRP;
        zqu__ProductRatePlan__c PRP = [SELECT Name, zqu__ZProduct__c, zqu__ZuoraId__c,
                                                zqu__Product__c, WarrantyDurationInMonth__c, Type__c, category__c,
                                                zqu__EffectiveStartDate__c, zqu__EffectiveEndDate__c,
                                                SellingEffectiveEndDate__c, SellingEffectiveStartDate__c 
                                                FROM zqu__ProductRatePlan__c 
                                                WHERE Name = 'Premium'].get(0);
        // zqu__ProductRatePlan__c PRP2 = TestUtils.createProductRatePlan(system.label.Rate_Plan_Timbre_Fiscal, zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9', 'addOn', 'other');
        // insert PRP2;
        // zqu__ProductRatePlan__c PRP3 = TestUtils.createProductRatePlan('start', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9c', 'Base', 'offer');
        // insert PRP3;
        // zqu__ProductRatePlan__c PRP4 = TestUtils.createProductRatePlan('canalBox', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9d', 'addOn', 'equipment');
        // insert PRP4;
        // zqu__ProductRatePlan__c PRP5 = TestUtils.createProductRatePlan('canalBox1', zProd.Id, pr.Id, '8adc8f9975c030080175c0e3a49c7f9u', 'addOn', 'Installation Service');
        // insert PRP5;
        // zqu__productrateplancharge__c prpCharge = TestUtils.createPRPCharge(PRP2.Id, system.label.Rate_Plan_Timbre_Fiscal, '8adc8f9975c030080175c0877657858');
        // insert prpCharge;
        OpportunityLineItem OLI = TestUtils.createOpportunityLineItem(opp.Id, pr.Id, PRP.Id, pbe.id);
        insert OLI;
        Quote newQuote = TestUtils.createQuote(opp.Id, 'qName2', opp.priceBook2Id);
        insert newQuote;
        QuoteLineItem QLI = TestUtils.createQuoteLineItem(newQuote.Id, pr.Id, PRP.Id, pbe.id);
        insert QLI;
          Zuora__Subscription__c sub = TestUtils.createSubscription(acc.Id, newQuote.Id, zAccount.Id, subscriptionNumber);  
     

        return sub;
    }

    public static Account createPersonAccount(String accName, String countryCode){
        id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
        Account acc = new Account ( firstName = accName, 
                                    lastName = accName, 
                                    ACC_BuildingID__c = 'KIG_12343', 
                                    ACC_LatLong__Latitude__s = 2, 
                                    ACC_Eligible__c = false,
                                    ACC_LatLong__Longitude__s = 1.2, 
                                    ACC_NumeroDEtage__c = 2, 
                                    PersonMobilePhone = '0673994428', 
                                    phone = '01212121', 
                                    ACC_PresencePTO_cc__c = 'non',
                                    ACC_MaturiteProspect__c = 'Chaud', 
                                    ACC_CategorisationProspect__c = 'prix',
                                    BillingCountryCode = countryCode,
                                    CurrencyIsoCode = 'XOF', 
                                    recordtypeId = personAccountId, 
                                    PersonEmail =  accName + '.example@test.com', 
                                    ACC_Escalier__c = 'Esc-12', 
                                    ACC_Indicatif__c = '+33');

        return acc;
    }

}