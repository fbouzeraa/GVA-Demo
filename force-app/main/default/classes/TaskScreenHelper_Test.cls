@isTest
public with sharing class TaskScreenHelper_Test {
    @isTest
    public static Void getMapBIDTasks_Test() {

        list<Task> listOfTasks = new List<Task>();
        Test.setMock(HttpCalloutMock.class, new EligMock());
        Task anyTask = new Task();
        anyTask.Status = 'Ouverte';
        anyTask.TSK_BuildingID__c = 'KIG_97341';
        anyTask.Subject = 'Visite Bâtiment';
        anyTask.TaskSubtype = 'Task';
        anyTask.ActivityDate = Date.valueOf('2020-12-10');
        anyTask.Priority = 'Normale';
        anyTask.OwnerId = UserInfo.getUserId();
        listOfTasks.add(anyTask);

        Task anyTask2 = new Task();
        anyTask2.Status = 'Ouverte';
        anyTask2.TSK_BuildingID__c = 'KIG_97341';
        anyTask2.Subject = 'Visite Bâtiment';
        anyTask2.TaskSubtype = 'Task';
        anyTask2.ActivityDate = Date.valueOf('2020-12-14');
        anyTask2.Priority = 'Normale';
        anyTask2.OwnerId = UserInfo.getUserId();
        listOfTasks.add(anyTask2);

        Task anyTask3 = new Task();
        anyTask3.Status = 'Ouverte';
        anyTask3.TSK_BuildingID__c = 'LOM_43412';
        anyTask3.Subject = 'Visite Bâtiment';
        anyTask3.TaskSubtype = 'Task';
        anyTask3.ActivityDate = Date.valueOf('2020-12-10');
        anyTask3.Priority = 'Normale';
        anyTask3.OwnerId = UserInfo.getUserId();
        listOfTasks.add(anyTask3);

        try {
            insert listOfTasks;
        } catch (Exception e) {
            system.debug('insert task '+e);
        }

        Test.startTest();
        Map<String, List<Task>> mapOfBIDTAsks = TaskScreenHelper.getMapBIDTasks();
        List<Task> listOfAllTasks = TaskScreenHelper.getTasks('All');
        List<Task> listOfBIDTasks = TaskScreenHelper.getTasks('KIG_97341');
        Test.stopTest();
        System.assertEquals(1, mapOfBIDTAsks.size(), '1 BID removed');
        System.assertEquals(2, listOfAllTasks.size(), '2 diff. Task');
        System.assertEquals(2, listOfBIDTasks.size(), '2 task with same BID');
    }
}