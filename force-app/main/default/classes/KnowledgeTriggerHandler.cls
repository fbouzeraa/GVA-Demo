public with sharing class KnowledgeTriggerHandler {
    


    public static void setArticlesCurrency(List<Knowledge__kav>  knowledgeArticles){
        
        for(Knowledge__kav article : knowledgeArticles){
            article.currencyIsoCode = getCountryCurrencyIsoCode(article.countryCode__c);
        }
    }

    private static String getCountryCurrencyIsoCode(String countryCode){
        if (countryCode == System.label.COUNTRY_CODE_TOGO 
            || countryCode == System.label.COUNTRY_CODE_BURKINA_FASO 
            || countryCode == System.label.COUNTRY_CODE_COTE_IVOIRE){
            return System.label.CURRENCY_ISO_CODE_FRANC_CFA;
        }
        if (countryCode == System.label.COUNTRY_CODE_RDC){
            return System.label.CURRENCY_ISO_CODE_US_DOLLAR;
        }
        if (countryCode == System.label.COUNTRY_CODE_RWANDA){
            return System.label.CURRENCY_ISO_CODE_RWANDAN_FRANC;
        }
        if (countryCode == System.label.COUNTRY_CODE_FRANCE){
            return System.label.CURRENCY_ISO_CODE_EURO;
        }
        if (countryCode == System.label.COUNTRY_CODE_GANA
            || countryCode == System.label.COUNTRY_CODE_CONGO ){  
            return System.label.CURRENCY_ISO_CODE_CENTRAL_AFRICAN_CFA_FRANC;
        }
        return null;
    }
    

}