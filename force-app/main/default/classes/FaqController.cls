public with sharing class FaqController {

    private static final String PUBLISH_STATUS_ONLINE = 'Online';
    
    private static final Id FAQ_KNOWLEDGE_RECORD_TYPE_ID = 
        Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('FAQ').getRecordTypeId();
    
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getFaqPublishedKnowledgeArticles(String articleLanguage, String searchTerm) {
        List<Knowledge__kav> knowledgeArticles = queryKnowledgeArticles(articleLanguage);
        knowledgeArticles = transformRichTextToLongTextInQuestionAndAnswerFields(knowledgeArticles); 
        if(String.isNotBlank(searchTerm)){
            knowledgeArticles = handleSearchTerm(knowledgeArticles, searchTerm);
        } 
        return knowledgeArticles;
    }

    private static List<Knowledge__kav> handleSearchTerm(List<Knowledge__kav> knowledgeArticles, String searchTerm){
        knowledgeArticles = getKnowledgeArticlesThatContainsSearchTerm(knowledgeArticles, searchTerm);
        return addSpanTagAroundSearchTermInQuestionAndAnswerFields(knowledgeArticles, searchTerm);
    }

    private static String queryUserCountryCode(){
        User currentUser = [SELECT Id, CountryCode FROM USER WHERE Id = :UserInfo.getUserId()];
        return currentUser.CountryCode;
    }

    private static List<Knowledge__kav> queryKnowledgeArticles(String articleLanguage) {
        String userCountryCode = queryUserCountryCode();
        return [SELECT Id, Title, KnowledgeArticleId , PublishStatus, question__c, answer__c, 
                faqSectionName__r.Name, faqSectionName__r.KnowledgeFaqSectionOrder__c, 
                faqArticleOrderInSection__c, Language 
                FROM knowledge__kav 
                WHERE PublishStatus = :PUBLISH_STATUS_ONLINE 
                AND RecordTypeId = :FAQ_KNOWLEDGE_RECORD_TYPE_ID
                AND isVisibleInCsp = true
                AND language = :articleLanguage
                AND (countryCode__c = :userCountryCode OR IsArticleForAllCountries__c = true)]; 
    }


    private static List<Knowledge__kav> getKnowledgeArticlesThatContainsSearchTerm(List<Knowledge__kav> knowledgeArticles, String searchTerm){
        List<Knowledge__kav> containSearchTermknowledgeArticles = new  List<Knowledge__kav>() ;
        for(Knowledge__kav article : knowledgeArticles){
            if(article.answer__c.containsIgnoreCase(searchTerm) || article.question__c.containsIgnoreCase(searchTerm)){
                containSearchTermknowledgeArticles.add(article);
            }
        }
        return containSearchTermknowledgeArticles;
    }

    private static List<Knowledge__kav> transformRichTextToLongTextInQuestionAndAnswerFields(List<Knowledge__kav> knowledgeArticlesToTransform) {
        for(Integer  i = 0; i < knowledgeArticlesToTransform.size(); i++){
            knowledgeArticlesToTransform[i].question__c = knowledgeArticlesToTransform[i].question__c.replaceAll('<[^>]+>',' ');
            knowledgeArticlesToTransform[i].answer__c = knowledgeArticlesToTransform[i].answer__c.replaceAll('<br>','\n');
            knowledgeArticlesToTransform[i].answer__c = knowledgeArticlesToTransform[i].answer__c.replaceAll('<\\/?(?!a)(?!img)(?!strong)\\w*\\b[^>]*>',''); //[^a][^/a]
        } 
        return knowledgeArticlesToTransform;
    }
   

    private static List<Knowledge__kav> addSpanTagAroundSearchTermInQuestionAndAnswerFields(List<Knowledge__kav> knowledgeArticles, String searchTerm){
        for(Integer  i = 0; i < knowledgeArticles.size(); i++){
            knowledgeArticles[i].question__c = addSpanTagAroundSearchTerm(knowledgeArticles[i].question__c, searchTerm);
            knowledgeArticles[i].answer__c = addSpanTagAroundSearchTerm(knowledgeArticles[i].answer__c, searchTerm);
        }
        return knowledgeArticles;
    }

    private static String addSpanTagAroundSearchTerm(String textToTag, String searchTerm){
        Integer startPosition = 0;
        Integer searchTermLength = searchTerm.length();
        Boolean isAnSearchTermLeft = textToTag.indexOfIgnoreCase(searchTerm, startPosition) != -1;
        while(startPosition <= textToTag.length() && isAnSearchTermLeft){

            Integer indexSearchTermStart = textToTag.indexOfIgnoreCase(searchTerm, startPosition);
            String searchTermConserveCase = textToTag.substring(indexSearchTermStart, indexSearchTermStart + searchTermLength);
            String replaceSearchTerm = '<span>' + searchTermConserveCase + '</span>';
            String firstStringPart = textToTag.substring(0, indexSearchTermStart);
            String lastStringPart = textToTag.substring(indexSearchTermStart + searchTermLength, textToTag.length());
            textToTag =  firstStringPart + replaceSearchTerm + lastStringPart;
            startPosition = indexSearchTermStart + replaceSearchTerm.length();
            isAnSearchTermLeft = textToTag.indexOfIgnoreCase(searchTerm, startPosition) != -1;
        }
        return textToTag;
    }

}