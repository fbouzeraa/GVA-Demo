@isTest
public with sharing class FaqController_Test {

    @testSetup
    static void makeData(){
        User adminUser = TestDataFactory.createAdminUser('TG');
        insert adminUser;
        System.runAs(adminUser){
            List<KnowledgeFaqSection__c> knowledgeFaqSections = TestDataFactory.createKnowledgeFaqSections();
            insert(knowledgeFaqSections);
            List<Knowledge__kav> articles = TestDataFactory.createKnowledegeArticles(knowledgeFaqSections);
            insert articles; 
            List<Integer> articlesToPublish  = new List<Integer>{0,1,2,4,5,6,7};
            TestDataFactory.publishArticles(articles, articlesToPublish);
            Test.setMock(HttpCalloutMock.class, new SMSMock());
            User togoClientPortalUser = TestDataFactory.createClientPortalUser(adminUser, 'TG');
            insert togoClientPortalUser;
        }
    }

    @isTest
     static void shouldGetAListOfFrenchFaqRecordTypeOfPublishedArticles(){
        String frenchLanguage = 'fr';
        List<User> togoClientPortalUsers = [SELECT Id FROM User WHERE countryCode='TG'];
        User togoClientPortalUser = togoClientPortalUsers[0];

        System.runAs(togoClientPortalUser){
            test.startTest();
                    List<Knowledge__kav> knowledgeArticles = FaqController.getFaqPublishedKnowledgeArticles(frenchLanguage,'');
            test.stopTest();
            System.assertEquals(3, knowledgeArticles.size());
            System.assertEquals('Online', knowledgeArticles[0].PublishStatus);
            System.assertNotEquals(null, knowledgeArticles[0].question__c);
            System.assertNotEquals(null, knowledgeArticles[0].answer__c);
            System.assertNotEquals(null, knowledgeArticles[0].faqSectionName__c);
            System.assertNotEquals(null, knowledgeArticles[0].faqSectionName__r.Name);
            System.assertNotEquals(null, knowledgeArticles[0].faqSectionName__r.KnowledgeFaqSectionOrder__c);
            System.assertNotEquals(null, knowledgeArticles[0].faqArticleOrderInSection__c);
            System.assert(knowledgeArticles[0].question__c.containsNone('<'));

    }
        
    }


    @isTest
    static void shouldGetAListOfEnglishUsFaqRecordTypeOfPublishedArticles(){
        String englishUsLanguage = 'en_US';
        List<User> togoClientPortalUsers = [SELECT Id FROM User WHERE countryCode='TG'];
        User togoClientPortalUser = togoClientPortalUsers[0];

        System.runAs(togoClientPortalUser){
            test.startTest();
            List<Knowledge__kav> knowledgeArticles = FaqController.getFaqPublishedKnowledgeArticles(englishUsLanguage,'');
            test.stopTest();

            System.assertEquals(1, knowledgeArticles.size());
            System.assertEquals('Online', knowledgeArticles[0].PublishStatus);
            System.assertNotEquals(null, knowledgeArticles[0].question__c);
            System.assertNotEquals(null, knowledgeArticles[0].answer__c);
            System.assertNotEquals(null, knowledgeArticles[0].faqSectionName__c);
            System.assertNotEquals(null, knowledgeArticles[0].faqSectionName__r.Name);
            System.assertNotEquals(null, knowledgeArticles[0].faqSectionName__r.KnowledgeFaqSectionOrder__c);
            System.assertNotEquals(null, knowledgeArticles[0].faqArticleOrderInSection__c);
            System.assert(knowledgeArticles[0].question__c.containsNone('<'));
        }
        
    }


    @isTest
    static void shouldGetAListOfFrenchFaqRecordTypeOfPublishedArticlesWhereArticleAnswerContainsSearchTerm(){
        String frLanguage = 'fr';
        String answerSearchTerm = 'Answ';
        String questionSearchTerm = 'ques';
        List<User> togoClientPortalUsers = [SELECT Id FROM User WHERE countryCode='TG'];
        User togoClientPortalUser = togoClientPortalUsers[0];

        System.runAs(togoClientPortalUser){
            test.startTest();
                List<Knowledge__kav> knowledgeArticlesSearchTermInAnswer = FaqController.getFaqPublishedKnowledgeArticles(frLanguage, answerSearchTerm);
                List<Knowledge__kav> knowledgeArticlesSearchTermInQuestion = FaqController.getFaqPublishedKnowledgeArticles(frLanguage, questionSearchTerm);
            test.stopTest();

            System.assertEquals(1, knowledgeArticlesSearchTermInAnswer.size());
            System.assertEquals('Online', knowledgeArticlesSearchTermInAnswer[0].PublishStatus);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInAnswer[0].question__c);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInAnswer[0].answer__c);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInAnswer[0].faqSectionName__c);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInAnswer[0].faqSectionName__r.Name);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInAnswer[0].faqSectionName__r.KnowledgeFaqSectionOrder__c);
            System.assert(knowledgeArticlesSearchTermInAnswer[0].answer__c.contains('My <span>Answ</span>er 1.0 and my <span>aNsw</span>er 2.0 and mt <span>answ</span>er 3.0 test <a href="https://www.w3schools.com" target="_blank">Visit W3Schools</a>'));

            System.assertEquals(1, knowledgeArticlesSearchTermInQuestion.size());
            System.assertEquals('Online', knowledgeArticlesSearchTermInQuestion[0].PublishStatus);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInQuestion[0].question__c);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInQuestion[0].answer__c);
            System.assertNotEquals(null, knowledgeArticlesSearchTermInQuestion[0].faqSectionName__c);
            System.assert(knowledgeArticlesSearchTermInQuestion[0].question__c.contains('My <span>ques</span>tions 1 My <span>Ques</span>tions 1 My <span>quES</span>tions 1.'));
        }
    }    
}