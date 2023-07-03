@isTest
public with sharing class ContactezNousController_Test {


    private static final Id callbackTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Callback').getRecordTypeId();

   // private static final Id togoCallCenterQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Call Center TG' LIMIT 1].get(0).Id;

    @testSetup
    static void makeData(){

        // Group testGroup = new Group(Name='Call Center TG', Type='Queue');
        // insert testGroup;

        User adminUser = TestDataFactory.createAdminUser('TG');
        insert adminUser;
        System.runAs(adminUser){
            // QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Task');
            // insert testQueue;
            Test.setMock(HttpCalloutMock.class, new SMSMock());
            User togoClientPortalUser = TestDataFactory.createClientPortalUser(adminUser, 'TG');
            togoClientPortalUser.USR_BypassVR__c = true;
            togoClientPortalUser.MobilePhone = '+339999999';
            insert togoClientPortalUser;
        }

    }

    @isTest
     static void shouldCreateAnImmediatCallbackTask(){
        ContactezNousController.CallbackUserInfoWrapper callbackUserInfoWrapper = createCallbackUserInfoWrapper();
        String callbackUserInfoWrapperStringify = JSON.serialize(callbackUserInfoWrapper);
        System.debug('callbackUserInfoWrapperStringify' + callbackUserInfoWrapperStringify);
        List<User> togoClientPortalUsers = [SELECT Id FROM User WHERE Username = 'TG.client.portal.user@testorg.com'];
        User togoClientPortalUser = togoClientPortalUsers[0];
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();

        Id contactId = [SELECT Id, ContactId FROM User WHERE Id = :togoClientPortalUser.Id LIMIT 1].ContactId;
        Id accountId = [SELECT Id FROM Account WHERE PersonContactId = :contactId 
                                            AND RecordTypeId = :personAccountRecordTypeId 
                                            LIMIT 1].Id;

 
        
        Id togoCallCenterQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_TG' LIMIT 1].get(0).Id;
         List<Group> togoCallCenterQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Call_Center_TG'];
        // System.debug('togoCallCenterQueue : ' + togoCallCenterQueue);
        System.runAs(togoClientPortalUser){
            Test.startTest();
                     ContactezNousController.createImmediatCallbackTask(callbackUserInfoWrapperStringify);
            Test.stopTest();
        // //    System.debug('result' + result);
            List<Task> tasks = [SELECT Id, CallType, AccountId, WhatId, 
                                WhoId, Subject, Description, Type, ActivityDate,
                                IsReminderSet, ReminderDateTime, RecordTypeId
                                 FROM Task];
            System.debug('tasks' + tasks);                      
             Task task =  tasks.get(0); 
        //     System.debug('task' + task); 

            System.assertNotEquals(null, task);
            System.assertEquals(accountId, task.whatId,  'The what Id should be the account id of the current user');
            System.assertEquals(accountId, task.accountId, 'The account Id should be the account id of the current user');
            System.assertEquals('Outbound', task.callType, 'Task should be outbound call');
            System.assertEquals(contactId, task.whoId, 'The whoId should be the contact Id of the current user');
            System.assertEquals('Appel',task.subject, 'The task subject should contains be Appel');
            System.assert(task.description.contains('Callback request'), 'The task description should contains Immediat callback request');
            System.assertEquals('Call', task.type);
            System.assertEquals(date.today(), task.ActivityDate, 'The task activity date (due date) should be today');
            System.assertEquals(true, task.IsReminderSet, 'The task isReminderSet should be true');
            System.assert(task.ReminderDateTime < datetime.now() , 'The task activity date (due date) should be before date time now');
            System.assert(task.ReminderDateTime > datetime.now().addSeconds(-10) , 'The task activity date (due date) should be after date time now minus five seconds');
            System.assertEquals(callbackTaskRecordTypeId, task.recordTypeId, 'The record type should be Callback record type Id');
            // System.assertEquals(callbackTaskRecordTypeId, task.recordTypeId, 'The record type should be Callback record type Id');
        // //    System.assertEquals(togoCallCenterQueueId, task.ownerId, 'The owner Id should be the Togo Queue Call Center Id');
        }
    }


    @isTest
    static void shouldGetUserCountryCallCenterQueueId(){
        List<User> togoClientPortalUsers = [SELECT Id FROM User WHERE Username = 'TG.client.portal.user@testorg.com'];
        User togoClientPortalUser = togoClientPortalUsers[0];
        ContactezNousController.getUserCountryCallCenterQueueId(togoClientPortalUser.Id);
    }



    private static ContactezNousController.CallbackUserInfoWrapper createCallbackUserInfoWrapper(){
       // Long nowDateTime = datetime.now().getTime();
        String nowDateTime = String.valueOf(datetime.now().getTime());
        return new ContactezNousController.CallbackUserInfoWrapper(
            'Bross',
            'Mario',
            '07821812',
            'test@test.com',
            nowDateTime
            );
    }
}