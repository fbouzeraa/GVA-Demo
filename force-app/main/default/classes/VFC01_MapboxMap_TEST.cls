/**
 * Classe permettant de tester les fonctionnalités de VFC01_MapboxMap.
 *
 * @author Maroun Yazbeck
 * @date 28 Novembre 2020
 */
@isTest
public with sharing class VFC01_MapboxMap_TEST {

    @isTest
    public static void testGetUsersAndMaps() {

        Profile p = [SELECT Id FROM Profile WHERE Name = :System.label.Vendeurs_Terrain];
        User u = new User(Alias = 'systadm', Email = 'Jackie2@test.com',
                          EmailEncodingKey = 'UTF-8', LastName = 'Abi Nassif', LanguageLocaleKey = 'en_US',
                          LocaleSidKey = 'en_US', ProfileId = p.Id,
                          TimeZoneSidKey = 'America/Los_Angeles', UserName = 'Jackie2@academy.com', CountryCode = 'TG', Pays_Mapbox__c = 'TG');

        try {
            insert u;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        System.assertEquals(true, VFC01_MapboxMap.getUsers().size() > 0, 'Incorrect number of Users returned');
        System.assertEquals(true, VFC01_MapboxMap.getMaps().size() > 0, 'Incorrect number of Cities returned');
        System.assertEquals(true, VFC01_MapboxMap.getCurrentUserMap().size() > 0, 'Incorrect number of Cities returned');
        System.assertEquals(true, VFC01_MapboxMap.showGPSButton(), 'Incorrect User profile');
        System.assertEquals(true, VFC01_MapboxMap.isRBOuser(), 'Incorrect User profile');
        System.assertEquals(true, VFC01_MapboxMap.showUsersSection(), 'Incorrect User profile');

    }

    @isTest
    public static void testAssignToUser() {
        Test.startTest();
        //Get a successful response from mock
        Test.setMock(HttpCalloutMock.class, new EligMock());

        //Assigning Building IDs and checking result
        List<String> buildingIDsList = new List<String> {'KIG_123456', 'KIG_546874', 'KIG_441554'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Responsable Vendeurs'];
        User testUser = TestUtils.createUser('test@test.com', 'YAZBECK', 'm.yazbeck@gvadev.invalid', 'User123', p.Id);
        insert testUser;
        system.runAs(testUser){
            // Checking initial results
            List<Task> existingTasksList = [SELECT Id, Subject FROM TASK];
            String message = VFC01_MapboxMap.assignToUser(null, null, null);
            System.assertEquals(0, existingTasksList.size(), 'Incorrect number of initial Tasks');
            System.assertEquals(System.Label.MAPBOX_New_Tasks_Error, message, 'Incorrect error message received');

            VFC01_MapboxMap.assignToUser(buildingIDsList, testUser.Id, string.valueOf(date.today()));
            List<Task> newTasksList = [SELECT Id, Subject FROM TASK];
            System.assertEquals(3, newTasksList.size(), 'Incorrect number of Tasks created');

            // Test Exception by giving retroactive Date
            System.assertEquals(true, VFC01_MapboxMap.assignToUser(buildingIDsList, testUser.Id, '2020-12-31').contains('err'));

            // Test Exception by giving wrong Date
            System.assertEquals(true, VFC01_MapboxMap.assignToUser(buildingIDsList, testUser.Id, '2020-12-31').contains('err'));

        }
        Test.stopTest();
    }
    @isTest
    public static void testUpdateAssignToUser(){
        //Get a successful response from mock
        Test.setMock(HttpCalloutMock.class, new EligMock());

        //Assigning Building IDs and checking result
        List<String> buildingIDsList = new List<String> {'KIG_123456'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Responsable Vendeurs'];

        User testUser = TestUtils.createUser('test@test.com', 'YAZBECK', 'm.yazbeck@gvadev.invalid', 'User123', p.Id);
        User testOtherUser = TestUtils.createUser('test2@test.com', 'Jackie', 'j.Abinassif@gvadev.invalid', 'User1234', p.Id);
        list<User> allUser = new list<User> {testUser, testOtherUser};
        try {
            insert allUser;
        } catch(Exception e) {
            system.debug('e1 ' + e);
        }
        system.runAs(testOtherUser){
            String message = VFC01_MapboxMap.assignToUser(buildingIDsList, testUser.Id, null);
            system.debug('message ' + message);

            // Test change Owner from the mapbox
            Test.startTest();
            VFC01_MapboxMap.assignToUser(buildingIDsList, testOtherUser.Id, null);
            Test.stopTest();

            List<Task> newTasksList2 = [SELECT Id, Subject, Owner.Name FROM TASK];
            System.assertEquals('Jackie', newTasksList2[0].Owner.Name, 'Owner updated');
        }
    }

    @isTest
    public static void testGetBookedBuildingIDs() {
        Test.startTest();
        //Get a successful response from mock
        Test.setMock(HttpCalloutMock.class, new EligMock());
        List<String> buildingIDsList = new List<String> {'KIG_123456', 'KIG_546874', 'KIG_441554'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Responsable Vendeurs'];
        User testUser = TestUtils.createUser('test@test.com', 'YAZBECK', 'm.yazbeck@gvadev.invalid', 'User123', p.Id);
        insert testUser;
        //system.runAs(testUser){
        VFC01_MapboxMap.assignToUser(buildingIDsList, testUser.Id, string.valueOf(date.today()));

        Set<String> bookedBuildingIDs = VFC01_MapboxMap.getBookedBuildingIDs();
        System.assertEquals(3, bookedBuildingIDs.size(), 'Incorrect number of booked Building IDs');
        // }
        Test.stopTest();
    }
    @isTest
    public static void testGgetAssignedBID() {
        Test.startTest();
        //Get a successful response from mock
        Test.setMock(HttpCalloutMock.class, new EligMock());
        List<String> buildingIDsList = new List<String> {'KIG_123456', 'KIG_546874', 'KIG_441554'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Responsable Vendeurs'];
        User testUser = TestUtils.createUser('test@test.com', 'YAZBECK', 'm.yazbeck@gvadev.invalid', 'User123', p.Id);
        insert testUser;
        system.runAs(testUser){
            VFC01_MapboxMap.assignToUser(buildingIDsList, testUser.Id, string.valueOf(date.today()));

            set<String> bookedBuildingIDs = VFC01_MapboxMap.getAssignedBID();
            System.assertEquals(3, bookedBuildingIDs.size(), 'Incorrect number of booked Building IDs');
        }
        Test.stopTest();
    }

    @isTest
    public static void testSetBuildingID() {
        //Get a successful response from mock
        Test.setMock(HttpCalloutMock.class, new EligMock());

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Lead ld = new Lead();
        ld.FirstName = 'John';
        ld.LastName = 'Smith';
        insert ld;

        // Test blank
        System.assertEquals('Error: Required field(s) empty', VFC01_MapboxMap.setBuildingID(null, null, null));
        // Test unsupported objectName
        System.assertEquals('Error: Unsupported objectName received', VFC01_MapboxMap.setBuildingID('KIG_123456', acc.Id, 'Contact'));
        // Test if all Ok for Account
        System.assertEquals('Success', VFC01_MapboxMap.setBuildingID('KIG_123456', acc.Id, 'Account'));
        // Test if all Ok for Lead
        System.assertEquals('Success', VFC01_MapboxMap.setBuildingID('KIG_123456', ld.Id, 'Lead'));
        // Test Exception by giving wrong object ID
        System.assertEquals(true, VFC01_MapboxMap.setBuildingID('KIG_123456', acc.Id, 'Lead').contains('Error'));
    }

    @isTest
    public static void checkMapBoxEligibility_Test(){
        Test.startTest();
        //Get a successful response from mock
        Test.setMock(HttpCalloutMock.class, new EligMock());
        Boolean eligible = VFC01_MapboxMap.checkMapBoxEligibility('LOM_9624');
        System.assertEquals(true, eligible, 'Success');

        //Get a unSuccessful response from mock
        Test.setMock(HttpCalloutMock.class, new notEligMock());
        Boolean eligible2 = VFC01_MapboxMap.checkMapBoxEligibility('LOM_10108');
        Test.stopTest();
    }
}