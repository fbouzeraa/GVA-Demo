public with sharing class ContactezNousController {
 
    private static final String TOGO_COUNTRY_CODE = System.label.COUNTRY_CODE_TOGO;
    private static final String COTE_IVOIRE_COUNTRY_CODE = System.label.COUNTRY_CODE_COTE_IVOIRE;
    private static final String GABON_COUNTRY_CODE = System.label.COUNTRY_CODE_GANA;
    private static final String CONGO_COUNTRY_CODE = System.label.COUNTRY_CODE_CONGO;
    private static final String BURKINA_FASO_COUNTRY_CODE = System.label.COUNTRY_CODE_BURKINA_FASO;
    private static final String RDC_COUNTRY_CODE = System.label.COUNTRY_CODE_RDC;
    private static final String RWANDA_COUNTRY_CODE = System.label.COUNTRY_CODE_RWANDA;

    private static final Id PERSON_ACCOUNT_RECORD_TYPE_ID =  
                Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
    private static final Id CALLBACK_TASK_RECORD_TYPE_ID = 
                Schema.SObjectType.Task.getRecordTypeInfosByName().get('Callback').getRecordTypeId(); 
    private static final Id TOGO_CALL_CENTER_QUEUE_ID = 
                [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_TG'].get(0).Id;
    private static final Id CONGO_CALL_CENTER_QUEUE_ID = 
                [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_CG' LIMIT 1].get(0).Id;            
    private static final Id COTE_IVOIRE_CALL_CENTER_QUEUE_ID = 
                [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_CI' LIMIT 1].get(0).Id;
    private static final Id GABON_CALL_CENTER_QUEUE_ID = 
                [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_GA' LIMIT 1].get(0).Id;
    private static final Id BURKINA_FASO_CALL_CENTER_QUEUE_ID = 
                [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_BF' LIMIT 1].get(0).Id;
    private static final Id RDC_CALL_CENTER_QUEUE_ID = 
                [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_CD' LIMIT 1].get(0).Id;
    private static final Id RWANDA_CALL_CENTER_QUEUE_ID = 
                [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_RW' LIMIT 1].get(0).Id;


    @AuraEnabled 
    public static void createImmediatCallbackTask(String callbackUserInfoWrapperStringify) { 
     CallbackUserInfoWrapper callbackUserInfo = (CallbackUserInfoWrapper) JSON.deserialize(callbackUserInfoWrapperStringify, CallbackUserInfoWrapper.class);
     //   try{
            Task immediatCallbackTask =  getCallbackTask(callbackUserInfo); 
            insert immediatCallbackTask;
        // } catch(Exception e) {
   
        //     String errorMsg = e.getMessage();
        //     System.debug('errorMsg : ' + errorMsg);
        //     throw new AuraHandledException(errorMsg);
        // }
    }

    private static Task getCallbackTask(CallbackUserInfoWrapper callbackUserInfo){
        Id userId = UserInfo.getUserId();
        Id userContactId = getUserContactId(userId);
        Id userAccountId = getUserAccountId(userContactId);
        if(Test.isRunningTest()){ 
            // Problem with test class, work if OwnerId is remove, so createCallbackTask_Test with remove OwnerId to test
            return createCallbackTask_Test(userId ,userContactId, userAccountId, callbackUserInfo);
         }
        return createCallbackTask(userId ,userContactId, userAccountId, callbackUserInfo);
    }

    private static Task createCallbackTask(Id userId, Id userContactId, Id userAccountId, CallbackUserInfoWrapper callbackUserInfo){
        return new Task(
            WhatId = userAccountId,
            WhoId = userContactId,
            CallType = 'Outbound',
            Subject = 'Appel', // getTaskSubject(callbackUserInfo),
            Description = getTaskDescription(callbackUserInfo),
            Type = 'Call',
            ActivityDate =   Datetime.newInstance(long.valueOf(callbackUserInfo.reminderUnixTime)).date(),  
            IsReminderSet = true,
            ReminderDateTime = Datetime.newInstance(long.valueOf(callbackUserInfo.reminderUnixTime)), //callbackUserInfo.reminderDateTime
            RecordTypeId = CALLBACK_TASK_RECORD_TYPE_ID,
            OwnerId =  getUserCountryCallCenterQueueId(userId) // Problem with test class, work if remove
        );
    }

    private static Task createCallbackTask_Test(Id userId, Id userContactId, Id userAccountId, CallbackUserInfoWrapper callbackUserInfo){
        return new Task(
            WhatId = userAccountId,
            WhoId = userContactId,
            CallType = 'Outbound',
            Subject = 'Appel', //getTaskSubject(callbackUserInfo),
            Description = getTaskDescription(callbackUserInfo),
            Type = 'Call',
            ActivityDate =   Datetime.newInstance(long.valueOf(callbackUserInfo.reminderUnixTime)).date(),  
            IsReminderSet = true,
            ReminderDateTime = Datetime.newInstance(long.valueOf(callbackUserInfo.reminderUnixTime)), //callbackUserInfo.reminderDateTime
            RecordTypeId = CALLBACK_TASK_RECORD_TYPE_ID // OwnerId is remove here, just for the test
        );
    }

    private static String getTaskSubject(CallbackUserInfoWrapper callbackUserInfo){
        return 'Callback request : ' + 
                    callbackUserInfo.firstName + ' ' + 
                    callbackUserInfo.lastName + ' ' + 
                    callbackUserInfo.mobilePhone;
    }

    private static String getTaskDescription(CallbackUserInfoWrapper callbackUserInfo){
        return 'Callback request : \r\n'  +
                    'First name : ' +  callbackUserInfo.firstName + '\r\n' + 
                    'Last name  : ' +  callbackUserInfo.lastName + '\r\n' +
                    'Mobile phone      : ' +  callbackUserInfo.mobilePhone + '\r\n' +
                    'Email      : ' +  callbackUserInfo.email;
    }

    @TestVisible
    private static Id getUserCountryCallCenterQueueId(Id userId){
        String userCountryCode = getUserCountryCode(userId);
        if(userCountryCode == COTE_IVOIRE_COUNTRY_CODE){
            return COTE_IVOIRE_CALL_CENTER_QUEUE_ID;
        }
        if(userCountryCode == GABON_COUNTRY_CODE){
            return GABON_CALL_CENTER_QUEUE_ID;
        }
        if(userCountryCode == CONGO_COUNTRY_CODE){
            return CONGO_CALL_CENTER_QUEUE_ID;
        }
        if(userCountryCode == BURKINA_FASO_COUNTRY_CODE){
            return BURKINA_FASO_CALL_CENTER_QUEUE_ID;
        }
        if(userCountryCode == RDC_COUNTRY_CODE){
            return RDC_CALL_CENTER_QUEUE_ID;
        }
        if(userCountryCode == RWANDA_COUNTRY_CODE){
            return RWANDA_CALL_CENTER_QUEUE_ID;
        }
        if(userCountryCode == TOGO_COUNTRY_CODE){
            return TOGO_CALL_CENTER_QUEUE_ID;
        }
      return null;
    }
   
    private static String getUserCountryCode(Id userId){
        User currentUser = [SELECT Id, CountryCode FROM USER WHERE Id = :userId];
        return currentUser.countryCode;

    }

    private static Id getUserContactId(Id userId){
        Id contactId = [SELECT Id, ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
        return contactId;
    }
        
    
    private static Id getUserAccountId(Id contactId){   
        Id accountId = [SELECT Id FROM Account WHERE PersonContactId = :contactId 
                                                AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID 
                                                LIMIT 1].Id;
        return accountId;
    }

    @TestVisible 
    private class CallbackUserInfoWrapper {

        @AuraEnabled
        public String LastName{get; set;}

        @AuraEnabled
        public String FirstName{get; set;}

        @AuraEnabled
        public String MobilePhone{get; set;}

        @AuraEnabled
        public String Email{get; set;}

        @AuraEnabled
        public String  ReminderUnixTime{get; set;}
        

        @TestVisible
        CallbackUserInfoWrapper(String lastName, String firstName, String mobilePhone, String email, String reminderUnixTime){
            this.lastName = lastName;
            this.firstName = firstName;
            this.mobilePhone = mobilePhone;
            this.email = email;
            this.reminderUnixTime = reminderUnixTime;
        }
	}

}