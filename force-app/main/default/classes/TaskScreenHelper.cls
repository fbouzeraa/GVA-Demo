public with sharing class TaskScreenHelper {

    @AuraEnabled(cacheable = true)
    public static Map<String, List<Task>> getMapBIDTasks() {

        // map of Building Id and taks
        Map<String, List<Task>> mapOfBIDTAsks = new Map<String, List<Task>>();

        for(Task tsk : [SELECT Id,Status,TSK_BuildingID__c,Subject,TaskSubtype,ActivityDate,Priority,Owner.Name,Who.Name
                        FROM TASK WHERE TSK_BuildingID__c != null])
        {
            // add tasks of each BID
            if(!mapOfBIDTAsks.containskey(tsk.TSK_BuildingID__c)){
                mapOfBIDTAsks.put(tsk.TSK_BuildingID__c, new list<Task>());
            }
            mapOfBIDTAsks.get(tsk.TSK_BuildingID__c).add(tsk);
        }

        if(mapOfBIDTasks != null && mapOfBIDTasks.keySet().size() > 0){
            for(String bldgId : mapOfBIDTAsks.keySet()){
                // remove task if a BID has 1 task (pas un tâche en doublons) 
                if(mapOfBIDTasks.get(bldgId).size() <= 1){
                    mapOfBIDTasks.remove(bldgId);
                }
            }
        }
        return mapOfBIDTAsks;
    }

    @AuraEnabled(cacheable = true)
    public static List<Task> getTasks(String buildingId) {

        Set<String> listOfBID = getMapBIDTasks().keySet();

        String query = 'SELECT Id,Status,TSK_BuildingID__c,Subject,TaskSubtype,ActivityDate,Priority,Owner.Name,Who.Name,WhoId ';
                query += 'FROM TASK ';
        // query All tasks
        if(buildingId == null || buildingId == 'All'){
            query += 'WHERE TSK_BuildingID__c IN :listOfBID  ';
            query += 'ORDER BY TSK_BuildingID__c';
        }
        // query only filtered tasks of a BID
        else{
            query += 'WHERE TSK_BuildingID__c =: buildingId';
        }
        system.debug('query '+query);
        List<Task> listOfTasks = Database.query(query);
        system.debug('listOfTasks '+listOfTasks);
        return listOfTasks;
    }

}