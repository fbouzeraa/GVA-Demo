public with sharing class BizaoResponse_Test {

   @AuraEnabled(cacheable=true)
   public static string mobileMoneyPaymentSuccessfulResponse(){
       try {
        return  '{"meta" : {"type" : "payment","source" : "bf_orange_mm","channel" : "web"},"status" : "Successful","amount" : "100","order-id" : "M-S24359658001-202233154","currency" : "XOF","reference" : "GVA_BF","date" : "2022-03-03 15:05:03.0","country-code" : "bf","state" : "Processing","user_msisdn" : "","intTransaction-id" : "","extTransaction-id" : ""}';
       } catch (Exception e) {
           throw new AuraHandledException(e.getMessage());
       }
   } 
 
}