@isTest
public with sharing class KnowledgeTriggerHandler_Test {
  
    @testSetup
    static void makeData(){
            List<Knowledge__kav> articles = TestDataFactory.createCountriesKnowledegeArticles();
            insert articles; 
    }

    @isTest
    static void togoArticleCurrencyShouldBeXOF(){
            List<Knowledge__kav> togoKnowledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'TG'];
            System.assertEquals('XOF', togoKnowledgeArticles[0].CurrencyIsoCode, 'Togo article currency should be XOF');
    }

    @isTest
    static void rdcArticleCurrencyShouldBeXAF(){
            List<Knowledge__kav> rdcKnowledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'CD'];
            System.assertEquals('USD', rdcKnowledgeArticles[0].CurrencyIsoCode, 'RDC article currency should be USD');
    }

    @isTest
    static void rwandaArticleCurrencyShouldBeXAF(){
            List<Knowledge__kav> rwandaKnowledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'RW'];
            System.assertEquals('RWF', rwandaKnowledgeArticles[0].CurrencyIsoCode, 'RDC article currency should be RWF');
    }

    @isTest
    static void burkinaFasoArticleCurrencyShouldBeXAF(){
            List<Knowledge__kav> rwandaKnowledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'BF'];
            System.assertEquals('XOF', rwandaKnowledgeArticles[0].CurrencyIsoCode, 'Burkina Faso article currency should be XOF');
    }

    @isTest
    static void franceArticleCurrencyShouldBeEUR(){
            List<Knowledge__kav> franceKnowledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'FR'];
            System.assertEquals('EUR', franceKnowledgeArticles[0].CurrencyIsoCode, 'France article currency should be EUR');
    }


    // @isTest
    // static void gabonArticleCurrencyShouldBeXAF(){
    //         List<Knowledge__kav> gabonKnowledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'GA'];
    //         System.assertEquals('XAF', gabonKnowledgeArticles[0].CurrencyIsoCode, 'Gabon article currency should be XAF');
    // }

    // @isTest
    // static void congoArticleCurrencyShouldBeXAF(){
    //         List<Knowledge__kav> congoKnowledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'CG'];
    //         System.assertEquals('XAF', congoKnowledgeArticles[0].CurrencyIsoCode, 'Congo article currency should be XAF');
    // }

    // @isTest
    // static void coteIvoireArticleCurrencyShouldBeXAF(){
    //         List<Knowledge__kav> coteIvoireledgeArticles = [SELECT Id, CurrencyIsoCode FROM Knowledge__kav WHERE CountryCode__c = 'CI'];
    //         System.assertEquals('XOF', coteIvoireledgeArticles[0].CurrencyIsoCode, 'Côte d'ivoire article currency should be XOF');
    // }

}