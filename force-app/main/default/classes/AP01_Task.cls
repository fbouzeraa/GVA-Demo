/**
 * Classe contenant les méthodes pour enrichir les données sur la Tâche à partir de l'API GVA
 *
 * @author Maroun Yazbeck
 * @date 15 décembre 2020
 */
public with sharing class AP01_Task {
    /**
     * Methode utilisée pour  enrichir les données sur la Tâche à partir de l'API GVA pour le BuildingID en question
     * @param newOrUpdatedTasks ensemble des Tâches nouvellement créées ou modifiées
     * @param oldMap ensemble des anciennes versions des Tâches nouvellement créées
     *
     */
    public static void triggerHandler(List<Task> newOrUpdatedTasks, Map<Id, Task> oldMap){
        List<Id> taskIds = new List<Id>();
        for(Task tsk : newOrUpdatedTasks) {
            // Getting all Tasks that are new or where the Building ID was updated
            if(oldMap == null || !oldMap.containsKey(tsk.Id) || (oldMap.get(tsk.id).TSK_BuildingID__c != tsk.TSK_BuildingID__c && !String.isBlank(tsk.TSK_BuildingID__c))) {
                // Check if all fields are still null, meaning it's not a clone of an existing Task
                if(tsk.TSK_Nb_Foyers_A__c == null && tsk.TSK_Nb_Foyers_B__c == null && tsk.TSK_Nb_Foyers_C__c == null && tsk.TSK_Nb_Foyers_D__c == null && !String.isBlank(tsk.TSK_BuildingID__c) && tsk.TSK_BuildingID__c != null) {
                    taskIds.add(tsk.Id);
                }
            }
        }

        if(taskIds != null && taskIds.size() > 0) {
            enrichTaskData(taskIds);
        }
    }

    @future(callout = true)
    public static void enrichTaskData(List<Id> taskIds){
        List<Task> updatedTasks = new List<Task>();
        List<Task> newTasks;
        Integer nbAdressables = 0;

        // Calling API for just these Tasks supplying the Building ID as parameter
        for(Task tsk : [SELECT Id, Subject, ActivityDate, Priority, Status, OwnerId, TSK_BuildingID__c, TSK_Nb_Foyers_A__c, TSK_Nb_Foyers_B__c, TSK_Nb_Foyers_C__c, TSK_Nb_Foyers_D__c, TSK_Nb_Etages__c FROM Task WHERE Id IN : taskIds]) {
            HttpResponse response = EligibilityManager.doCallout(EligibilityObjects.buildingsAPIUrl + tsk.TSK_BuildingID__c, EligibilityObjects.get, '');
            string jsonObj = response.getBody().replace('\n', ''); // Removing unescaped character if present

            nbAdressables = 0;
            newTasks = new List<Task>();

            // If the request is successful, parse the JSON response.
            if(response.getStatusCode() == 200) {
                // Deserialize the JSON string
                EligibilityObjects.BuildingsAPIResponse taskInfo = (EligibilityObjects.BuildingsAPIResponse) System.JSON.deserialize(jsonObj, EligibilityObjects.BuildingsAPIResponse.class);
                if(taskInfo != null) {
                    // Remove Foyer suffix if present
                    string currentBuildingID = String.valueOf(tsk.TSK_BuildingID__c);
                    string cleanedBuildingID = currentBuildingID.countMatches('_') > 1 ? currentBuildingID.substring(0, currentBuildingID.lastIndexOf('_')) : currentBuildingID;

                    tsk.TSK_BuildingID__c = cleanedBuildingID;
                    tsk.TSK_Nb_Foyers_A__c = taskInfo.nb_flat_a;
                    tsk.TSK_Nb_Foyers_B__c = taskInfo.nb_flat_b;
                    tsk.TSK_Nb_Foyers_C__c = taskInfo.nb_flat_c;
                    tsk.TSK_Nb_Foyers_D__c = taskInfo.nb_flat_d;
                    tsk.TSK_Nb_Etages__c = taskInfo.nb_floors;

                    nbAdressables = taskInfo.nb_flat_a + taskInfo.nb_flat_b + taskInfo.nb_flat_c + taskInfo.nb_flat_d;
                }
            } else {
                // Deserialize the error
                EligibilityObjects.BuildingsAPIError taskError = (EligibilityObjects.BuildingsAPIError) System.JSON.deserialize(jsonObj, EligibilityObjects.BuildingsAPIError.class);
                // Clear the Task info fields
                tsk.TSK_Nb_Foyers_A__c = null;
                tsk.TSK_Nb_Foyers_B__c = null;
                tsk.TSK_Nb_Foyers_C__c = null;
                tsk.TSK_Nb_Foyers_D__c = null;
                tsk.TSK_Nb_Etages__c = null;
            }

            // Check if the nbAdressables is > 0, then clone as much as needed to other tasks (including this one)
            if(nbAdressables > 0 && tsk.Subject == System.label.TSK_Building_Visit) {
                // Current Task is the first one
                tsk.TSK_BuildingID__c = tsk.TSK_BuildingID__c;//+'_1';

                for(Integer i = 2; i <= nbAdressables; i++) {
                    Task clonedTask = tsk.clone(false, false, false, false);
                    clonedTask.TSK_BuildingID__c = clonedTask.TSK_BuildingID__c;//.substringBeforeLast('_') + '_' + String.valueOf(i);
                    clonedTask.OwnerId = tsk.OwnerId;
                    clonedTask.ActivityDate = tsk.ActivityDate;
                    newTasks.add(clonedTask);
                }
            }

            updatedTasks.add(tsk);
        }

        // Updating the modified Tasks in the database
        if(updatedTasks.size() > 0) {
            update updatedTasks;
        }
        system.debug('newTasks ' + newTasks);
        if(newTasks != null && newTasks.size() > 0) {
            try {
                insert newTasks;
            } catch(Exception e) {
                system.debug('e ' + e);
            }

        }
    }
    /**
     * Methode utilisée pour ajouter l'Id du Bâtiment sur la Tâche à partir de l'Id du Bâtiment du compte associé
     * @param listNewTask liste des Tâches nouvellement créées
     */
    public static void addBuildingId(list<task> listNewTask){

        map<Task, id> mapTaskRelatedAccount = new map<Task, id>();
        // obtenir l'objet lié à la tâche
        for(task tsk : listNewTask) {

            if(tsk.whatId != null) {
                mapTaskRelatedAccount.put(tsk, tsk.whatId);
            }
        }

        if(mapTaskRelatedAccount != null && mapTaskRelatedAccount.size() > 0) {

            // obtenir l'id du bâtiment de chaque compte
            Map<Id, Account> mapRelatedAccount = new Map<id, Account>( [SELECT ACC_BuildingID__c, id
                                                                        FROM Account
                                                                        WHERE id IN: mapTaskRelatedAccount.values()]);

            if(mapRelatedAccount != null && mapRelatedAccount.size() > 0) {
                // ajouter l'id du bâtiment du compte à la tache crée
                for(task newTask : mapTaskRelatedAccount.keySet()) {
                    newTask.TSK_BuildingID__c = mapRelatedAccount.get(mapTaskRelatedAccount.get(newTask)).ACC_BuildingID__c;//acc.ACC_BuildingID__c;
                }
            }
        }
    }

    /**
     * Méthode utiliser pour récuperer valeur du champ Sujet
     */
    @AuraEnabled
    public static list<string> getTaskSubject(){
        try {
            List<String> listSubjectValues = new List<String>();
            Schema.DescribeFieldResult fieldResult = Task.Subject.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry pickListVal : ple) {
                listSubjectValues.add(pickListVal.getLabel());
            }

            return listSubjectValues;

        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * Méthode pour récupérer les taches de chaque utilisateur
     */
    @AuraEnabled
    public static list<Task> getRequestedTasks(string filter){
        try {
            if(filter == null || string.isBlank(filter) || filter == 'My Tasks') {
                return [SELECT Subject, Account.Name, ActivityDate, Status, Priority, Owner.Name, TSK_BuildingID__c
                        FROM task
                        WHERE OwnerId = : UserInfo.getUserId() AND status = 'Ouverte'
                        ORDER BY CreatedDate DESC
                        LIMIT 49999];
            } else {
                return [SELECT Subject, Account.Name, ActivityDate, Status, Priority, Owner.Name, TSK_BuildingID__c
                        FROM task
                        WHERE Subject = : filter AND status = 'Ouverte'
                        ORDER BY CreatedDate DESC
                        LIMIT 49999];
            }

        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Méthode pour récuperer tous les utilisateurs VAD et les fils d'attente
     */
    @AuraEnabled
    public static list<User> getListUsers(string name){
        try {
            // get country of current user
            user currentUser = [SELECT CountryCode, City FROM User WHERE Id =: UserInfo.getUserId()];
            string searchName = name + '%';
            list<User> listUsers = [SELECT Name, Id FROM User WHERE Name like :searchName AND isActive = true];

            return listUsers;

        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * Méthode pour récuperer le compte d'une tache
     */
    @AuraEnabled
    public static Id getTaskRecords(id taskId ){
        return [SELECT AccountId, id FROM Task WHERE Id = : taskId].AccountId;

    }
    /**
     * Méthode pour changer le propriétaire en masse
     */
    @AuraEnabled
    public static void handleBulkActions(string selectedJSON, string owner, date dueDate, boolean bulkDelete){
        try {
            list<Task> listTasks = new list<Task>();
            set<Task> setTask = new set<Task>();
            List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(selectedJSON);
            for(Object fld : fieldList) {

                Task tsk = new Task();
                tsk.id = id.valueOf(string.valueOf(fld));
                if(owner != null) {
                    tsk.OwnerId = owner;
                }
                if(dueDate != null) {
                    tsk.ActivityDate = dueDate;
                }
                setTask.add(tsk);
            }
            if(setTask.size() > 0 && setTask != null) {
                listTasks.addAll(setTask);
                if(bulkDelete) {
                    delete listTasks;
                } else {
                    update listTasks;
                }
            }
        } catch(Exception e) {
            throw new CustomException(e.getMessage());
        }
    }

    public class CustomException extends Exception {}

}