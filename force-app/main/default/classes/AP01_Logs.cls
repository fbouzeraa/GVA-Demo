/**
 * Classe pour retenter les logs erronées
 */
public with sharing class AP01_Logs {
    @AuraEnabled
    public static string retryLog(id logId){
        try {
            list<Log__c> listLog = [SELECT LG_Method_Type__c, LG_Method_URL__c, LG_Body__c, LG_Error_Solved__c,
                                    LG_Account__c, LG_Subscription_Number__c, LG_Subscription__c, LG_Interface__c
                                    FROM log__c
                                    WHERE Id = :logId AND LG_Error_Solved__c = false];

            if(listLog.size() > 0 && listLog != null) {
                string body = listLog[0].LG_Body__c.replaceAll('&quot;', '"');
                HttpResponse response = new HttpResponse();
                if(listLog[0].LG_Interface__c == 'Zuora') {
                    response = ZuoraManager.doCallout(listLog[0].LG_Method_URL__c, listLog[0].LG_Method_Type__c, body);
                }
                if(listLog[0].LG_Interface__c == 'Bundle C+') {
                    response = BundleCManager.doCallout(listLog[0].LG_Method_URL__c, listLog[0].LG_Method_Type__c, body);
                }
                boolean isSucceed = response.getBody().toLowerCase().contains('"success" : true');
                Log__c newLog = new Log__c();
                newLog.LG_Body__c = body;
                newLog.LG_Account__c = listLog[0].LG_Account__c;
                newLog.LG_Subscription__c = listLog[0].LG_Subscription__c;
                newLog.LG_Method_URL__c = listLog[0].LG_Method_URL__c;
                newLog.LG_Subscription_Number__c = listLog[0].LG_Subscription_Number__c;
                newLog.LG_Response__c = response.getBody();
                newLog.LG_Interface__c = 'Zuora';
                newLog.LG_Method_Type__c = listLog[0].LG_Method_Type__c;
                newLog.LG_Success__c = isSucceed;
                insert newLog;

                return response.getBody();
            } else {
                return null;
            }
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}