public with sharing class UserTriggerHandler {
    //public static List<Log__c> listLog = new List<Log__c>();
    public static void sendNewPasswordBySmsToUser(String userId) {
        User user = [SELECT Id, ProfileId, Phone,mobilePhone FROM User WHERE Id = :userId];
        Profile clientPortalUserProfile = [SELECT Id FROM Profile WHERE Name = 'Utilisateur du Portail Client'].get(0);
        if(user.profileId == clientPortalUserProfile.Id) {
            String userPassword = setUserPassword(userId);
            // String userPassword = 'Test from UAT, no password change';
            String textMessage = getSmsTextMessage(user.Phone, userPassword);
            allMySmsCallout(user.Phone, textMessage);
        }
    }
    private static String setUserPassword(String userId){
        Integer len = 6;
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        String letterChar = generateRandomLetter();
        String numberChar = generateRandomNumber();
        String userPassword = key.substring(0, len) + numberChar + letterChar;
        System.setPassword(userId, userPassword);
        return userPassword;

    }
    private static String setRandomPassword(){
        Integer len = 6;
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(blobKey);
        String letterChar = generateRandomLetter();
        String numberChar = generateRandomNumber();
        String userPassword = key.substring(0, len) + numberChar + letterChar;
        return userPassword;

    }
    private static String getSmsTextMessage(String userMobilePhone, String userPassword){
        return System.label.ALL_MY_SMS_SEND_NEW_PASSWORD_MESSAGE_PART_1 +
               ' ' + userPassword +
               ' ' + System.label.ALL_MY_SMS_SEND_NEW_PASSWORD_MESSAGE_PART_2 +
               ' ' + userMobilePhone;
    }
    @future(callout = true)
    private static void allMySmsCallout(String mobilePhone, String textMessage){
        User user = [select AccountId,id FROM user where user.Phone=:mobilePhone][0];
        Id accid = user.AccountId;
        //Zuora__Subscription__c  sub = user.Account.Subscription__r;
        //Zuora__Subscription__c sub = [select id FROM Zuora__Subscription__c where Zuora__Account__c=:accid][0];
        String formattedMobilePhone  = mobilePhone.replace('+', '');
        formattedMobilePhone = formattedMobilePhone.replace(' 0', '');
        formattedMobilePhone = formattedMobilePhone.replace(' ', '');
        System.debug('formattedMobilePhone : ' + formattedMobilePhone);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:All_My_Sms/sms/send/');
        req.setMethod('POST');
        // Specify the required user name and password to access the endpoint
        // As well as the header and header information
        String senderName =  System.label.SMS_Sender;
        String username = System.label.ALLMYSMS_UserName;
        String password = System.label.ALLMYSMS_AUTH_TOKEN;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        system.debug(' AAAAA authorizationHeader '+authorizationHeader);
        system.debug('AAAAAA body ' +'{\n' +
                        '"from": "' + senderName + '",\n' +
                        '"to": "' + formattedMobilePhone + '",\n' +
                        '"text": "' + textMessage + '"\n' +
                        '}');
        req.setBody('{\n' +
                    '"from": "' + senderName + '",\n' +
                    '"to": "' + formattedMobilePhone + '",\n' +
                    '"text": "' + textMessage + '"\n' +
                    '}');
        // Create a new http object to send the request object
        // A response object is generated as a result of the request
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if(res != null && !String.isBlank(res.getBody())) {
        system.debug('ASA3'+res.getStatusCode());
        } 
        //webhook
         /*HttpRequest request = new HttpRequest();
                                request.setEndpoint('callout:All_My_Sms/webhook/');
                                request.setHeader('Authorization', authorizationHeader);
                                request.setHeader('cache-control', 'no-cache');
                                request.setMethod('GET');
                                Http http1 = new Http();
                                HTTPResponse response1 = http1.send(request);
                                System.debug('response1'+response1.getBody());
                                System.debug('getStatusCode'+response1.getStatusCode());
                                System.debug('getStatusCode'+response1.getStatus());*/
        
         //Log__c lg =createSMSLog();
         Log__c lg =createSMSLog('{\n' +
                    '"from": "' + senderName + '",\n' +
                    '"to": "' + formattedMobilePhone + '",\n' +
                    '"text": "' + textMessage + '"\n' +
                    '}'
         ,'https://api.allmysms.com',res.getBody(), (res.getStatusCode() == 100 || res.getStatusCode() == 101)?true : false, 'POST',accid);
		 insert lg;
        System.debug('mylog'+lg);
    }
    //souscription et compte
        public static Log__c createSMSLog(string body, string URL,
                                         string reponse, boolean success, string type,Id acc){

        Log__c newLog = new Log__c();
        newLog.LG_Body__c = body;
        newLog.LG_Method_URL__c = URL;
        newLog.LG_Response__c = reponse;
        newLog.LG_Interface__c = 'ALLMYSMS';
        newLog.LG_Success__c = success;
        newLog.LG_Method_Type__c = type;                                          
		newLog.LG_Account__c=acc;
        //newLog.LG_Subscription__c=sub;                                     
        return newLog;
    }
    private static String generateRandomLetter(){
        final String selectionString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        Integer idNum = Math.mod(Math.abs(Crypto.getRandomInteger()), selectionString.length());
        String randomChar = selectionString.substring(idNum, idNum + 1);
        return randomChar;
    }
    
    private static String generateRandomNumber(){
        final String selectionString = '0123456789';
        Integer idNum = Math.mod(Math.abs(Crypto.getRandomInteger()), selectionString.length());
        String randomChar = selectionString.substring(idNum, idNum + 1);
        return randomChar;
    }
    public static void sendWelcomeSmsToClientPortalUsers(List<User> users){
        Set<Id> clientPortalUserIds = getClientPortalUserIds(users);
        String userPassword = '';
        if(clientPortalUserIds != null && clientPortalUserIds.size() > 0) {
            if(System.isBatch() == false) {
                allMySmsBulkCalloutFuture(clientPortalUserIds);
            }
            if(System.isBatch() == true) {
                allMySmsBulkCallout(clientPortalUserIds);
            }
        }
    }
    private static Set<Id> getClientPortalUserIds(List<User> users){
        Profile clientPortalUserProfile = [SELECT Id FROM Profile WHERE Name = 'Utilisateur du Portail Client' LIMIT 1];
        Set<Id> userIds = new Set<Id>();
        for(User user : users) {
            userIds.add(user.Id);
        }
        Set<Id> clientPortalUserIds = new Set<Id>();
        for(User user : [SELECT Id FROM User WHERE Id = : userIds AND ProfileId = : clientPortalUserProfile.Id]) {
            clientPortalUserIds.add(user.Id);
        }
        return clientPortalUserIds;
    }
    private static String fomatPhoneNumber(String mobilePhone){
        String formattedMobilePhone  = mobilePhone.replace('+', '');
        formattedMobilePhone = formattedMobilePhone.replace(' 0', '');
        formattedMobilePhone = formattedMobilePhone.replace(' ', '');
        return formattedMobilePhone;
    }

    private static String fomatPhoneNumberCiv(String mobilePhone){
        String formattedMobilePhone  = mobilePhone.replace('+', '');
        formattedMobilePhone = formattedMobilePhone.replace(' ', '');
        return formattedMobilePhone;
    }
    @future(callout = true)
    private static void allMySmsBulkCalloutFuture(Set<Id> userIds){
        // allMySmsBulkCallout(userIds);
        User user = [select AccountId,id,CountryCode FROM user where user.id in :userIds][0];
        Id accid = user.AccountId;
        String countryCode = user.CountryCode;
        //Zuora__Subscription__c sub = [select id FROM Zuora__Subscription__c where Zuora__Account__c=:accid][0];
        //Zuora__Subscription__c  sub = user.Account.Subscription__r;
        String senderName =  System.label.SMS_Sender;
        String generatedPassword = '';
        String recipientsJSON = generateRecipientsJson(userIds);
        generatedPassword = setRandomPassword();
        String welcomeTextMessage = '';
        if (countryCode == 'RW'){
             welcomeTextMessage = System.label.ALL_MY_SMS_WELCOME_MESSAGE_ENGLISH + generatedPassword;

        }

        else{
             welcomeTextMessage = System.label.ALL_MY_SMS_WELCOME_TEXT_MESSAGE + generatedPassword;

        }
        System.debug('welcomeTextMessage'+welcomeTextMessage);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:All_My_Sms/sms/send/bulk/');
        req.setMethod('POST');
        // Specify the required user name and password to access the endpoint
        // As well as the header and header information
        String username = System.label.ALLMYSMS_UserName;
        String password = System.label.ALLMYSMS_AUTH_TOKEN;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        system.debug(' AAAAA authorizationHeader '+authorizationHeader);
        req.setHeader('Authorization', authorizationHeader);
        system.debug(' AAAA '+generateBulkSmsRequestBody(senderName, recipientsJSON, welcomeTextMessage));
        req.setBody(generateBulkSmsRequestBody(senderName, recipientsJSON, welcomeTextMessage));
        Http http = new Http();
        HTTPResponse res = http.send(req);
       
        if (userIds.size() == 1) {
            for(Id userId : userIds) {
        System.setPassword(userId, generatedPassword);}}
        system.debug('ASA2'+generateBulkSmsRequestBody(senderName, recipientsJSON, welcomeTextMessage));

        Log__c lg =createSMSLog(generateBulkSmsRequestBody(senderName, recipientsJSON, welcomeTextMessage),
                                'https://api.allmysms.com',res.getBody(), (res.getStatusCode() == 100 || res.getStatusCode() == 101)?true : false, 'POST',accid);
        insert lg;
    }

    public static void allMySmsBulkCallout(Set<Id> userIds){
        User user = [select AccountId,id,CountryCode FROM user where user.id in :userIds][0];
        Id accid = user.AccountId;
        String countrycode = user.CountryCode;
        //Zuora__Subscription__c sub = [select id FROM Zuora__Subscription__c where Zuora__Account__c=:accid][0];
        //Zuora__Subscription__c  sub = user.Account.Subscription__r;
        String senderName =  System.label.SMS_Sender;
        String recipientsJSON = generateRecipientsJsonForBatch(userIds);
        system.debug('RECIPIENT ------------->  '+ recipientsJSON);
        String userIdPasswords = JSON.serialize(recipientsJSON.split(';')[1].replaceAll( ' ', ''));
        String userIdPassword = userIdPasswords.substring(2, userIdPasswords.length()-2);

        String welcomeTextMessage = '';
        if(countrycode == 'RW'){
            welcomeTextMessage = System.label.ALL_MY_SMS_WELCOME_MESSAGE_BATCH_ENGLISH;

        }
        else{
            welcomeTextMessage = System.label.ALL_MY_SMS_WELCOME_TEXT_MESSAGE_BATCH;
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:All_My_Sms/sms/send/bulk/');
        req.setMethod('POST');
        // Specify the required user name and password to access the endpoint
        // As well as the header and header information
        String username = System.label.ALLMYSMS_UserName;
        String password = System.label.ALLMYSMS_AUTH_TOKEN;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        system.debug(' AAAAA authorizationHeader '+authorizationHeader);
        system.debug('AAAAAA Body '+generateBulkSmsRequestBody(senderName, recipientsJSON.split(';')[0], welcomeTextMessage));
        req.setBody(generateBulkSmsRequestBody(senderName, recipientsJSON.split(';')[0], welcomeTextMessage));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug(' AAAA response '+res);
        for(Integer i=0;i<userIdPassword.split(',').size();i++){
            System.debug('ARE WE HERE ?  -------------> '+ userIdPassword.split(',')[i].split('=')[0] + ' ET    ' + userIdPassword.split(',')[i].split('=')[1]);
            System.setPassword(userIdPassword.split(',')[i].split('=')[0], userIdPassword.split(',')[i].split('=')[1]);
        }
        system.debug('ASA1'+res.getStatus());
        system.debug('getBody'+res.getBody());
        system.debug('ASA1status'+res.getStatusCode());
        system.debug('ASA1'+res.getStatus());
        Log__c lg =createSMSLog(generateBulkSmsRequestBody(senderName, recipientsJSON.split(';')[0], welcomeTextMessage),'https://api.allmysms.com',res.getBody(), (res.getStatusCode() == 100 || res.getStatusCode() == 101)?true : false, 'POST',accid);
        insert lg;
        System.debug('mylog3'+lg);
        
        //sendSMSRequest(authorizationHeader,senderName,recipientsJSON,welcomeTextMessage);
        // il faut veifier es
    }

    @future(callout = true)
    private static void allMySmsBulkCalloutFutureRattrapage(Set<Id> userIds){
        String senderName =  System.label.SMS_Sender;
        String recipientsJSON = generateRecipientsJsonForBatch(userIds);
        String userIdPasswords = JSON.serialize(recipientsJSON.split(';')[1].replaceAll( ' ', ''));
        String userIdPassword = userIdPasswords.substring(2, userIdPasswords.length()-2);
        String welcomeTextMessage = System.label.ALL_MY_SMS_WELCOME_TEXT_MESSAGE_BATCH_RATTRAPAGE;
        HttpRequest req = new HttpRequest();
        system.debug('req '+req);
        req.setEndpoint('callout:All_My_Sms/sms/send/bulk/');
        req.setMethod('POST');
        // Specify the required user name and password to access the endpoint
        // As well as the header and header information
        String username = System.label.ALLMYSMS_UserName;
        String password = System.label.ALLMYSMS_AUTH_TOKEN;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        system.debug(' AAAAA authorizationHeader '+authorizationHeader);
        req.setHeader('Authorization', authorizationHeader);
        system.debug('AAAA Bodu '+generateBulkSmsRequestBody(senderName, recipientsJSON.split(';')[0], welcomeTextMessage));
        req.setBody(generateBulkSmsRequestBody(senderName, recipientsJSON.split(';')[0], welcomeTextMessage));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        //sendSMSRequest(authorizationHeader,senderName,recipientsJSON,welcomeTextMessage);
    }      
    

    private static String generateBulkSmsRequestBody(String senderName, String recipientsJSON, String textMessage){
        return '{\n' +
               '"from": "' + senderName + '",\n' +
               '"text": "' + textMessage + '",\n' +
               '"to": ' + recipientsJSON + '\n' +
               '}';
    }

    private static String generateRecipientsJson(Set<Id> userIds){
        List<Recipient> recipients = new List<Recipient>();
        for(User user : [SELECT Id, FirstName, LastName,mobilePhone, Phone,countryCode FROM User WHERE Id IN : userIds]) {
            String Phone = '';
            if(user.Phone!=null){
             if(user.countryCode == 'CI'){
                Phone = fomatPhoneNumberCiv(user.Phone);
            }
            else{
                Phone = fomatPhoneNumber(user.Phone);
            }
            }else{
                 if(user.countryCode == 'CI'){
                Phone = fomatPhoneNumberCiv(user.mobilePhone);
            }
            else{
                Phone = fomatPhoneNumber(user.mobilePhone);
            }
            }
           
            // String userPassword = setUserPassword(user.Id);  
            // String userPassword = 'password123';  
            Recipient recipient = new Recipient(Phone, user.firstName, user.lastName, user.Phone);
            recipients.add(recipient);
        }
        String recipientsJSON = JSON.serializePretty(recipients);
        recipientsJSON = recipientsJSON.left(recipientsJSON.length()-2) + recipientsJSON.right(1);
        return recipientsJSON;
    }
    private static String generateRecipientsJsonForBatch(Set<Id> userIds){
        List<RecipientForBatch> recipients = new List<RecipientForBatch>();
        Map<Id, String> mapUseridAndPassword = new Map<Id, String>();
        for(User user : [SELECT Id, FirstName, LastName, Phone,mobilePhone, countryCode FROM User WHERE Id IN : userIds]) {
            String userPassword = '';
            String Phone = '';
            if(user.countryCode == 'CI'){
                if(user.Phone!=null){
                    Phone = fomatPhoneNumberCiv(user.Phone);
                }
                else{
                    Phone = fomatPhoneNumberCiv(user.mobilePhone);
                }
            }
            else{
                if(user.Phone!=null){
                    Phone = fomatPhoneNumber(user.Phone);
                }
                else{
                    Phone = fomatPhoneNumber(user.mobilePhone);
                }
            }
            userPassword = setRandomPassword();
            mapUseridAndPassword.put(user.Id, userPassword);
            RecipientForBatch recipient = new RecipientForBatch(Phone, user.firstName, user.lastName, user.Phone, userPassword);
            recipients.add(recipient);
        }
        String recipientsJSON = JSON.serializePretty(recipients);
        recipientsJSON = recipientsJSON.left(recipientsJSON.length()-2) + recipientsJSON.right(1);
        return recipientsJSON +';'+String.valueOf(mapUseridAndPassword);
    }
    private class Recipient{
        public String mobilePhone;
        public String param1;
        public String param2;
        public String param3;
        public String param4;

    
        public Recipient(String mobilePhone, String param1, String param2, String param3){
            this.mobilePhone = mobilePhone;
            this.param1 = param1;
            this.param2 = param2;
            this.param3 = param3;
        }
    }
        private class RecipientForBatch{
            public String mobilePhone;
            public String param1;
            public String param2;
            public String param3;
            public String param4;
    
        
            public RecipientForBatch(String mobilePhone, String param1, String param2, String param3, String param4){
                this.mobilePhone = mobilePhone;
                this.param1 = param1;
                this.param2 = param2;
                this.param3 = param3;
                this.param4 =  param4;
            }

    }
    
}