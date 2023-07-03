/**
 * Classe fournissant les méthodes APEX pour la page VFP01_MapboxMap.
 *
 * @author Maroun Yazbeck
 * @date 28 Novembre 2020
 */
public with sharing class VFC01_MapboxMap {
    public VFC01_MapboxMap() {
        // Empty constructor
    }

    /**
     * Methode utilisée pour obtenir les utilisateurs dans Salesforce.
     * <p>
     * La méthode cherche tous les utilisateurs Actifs.
     */
    @RemoteAction
    public static List<User> getUsers(){
        user currentUser = [SELECT CountryCode FROM User WHERE Id =:UserInfo.getUserId() ];

        return [SELECT Id, Name
                FROM User
                WHERE IsActive = true AND CountryCode = : currentUser.CountryCode
                AND (Profile.Name = : System.label.Vendeurs_Terrain OR Profile.Name = : System.label.Responsable_Vendeurs )
                ORDER BY Name ASC];
    }

    /**
     * Methode utilisée pour obtenir le lien carte de l'utilisateur courant.
     * 
     */
    @RemoteAction
    public static Carte_Ville__mdt getLienCarte(){

        User currentUser = [SELECT ID, Villes_Mapbox__c, Pays_Mapbox__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<String> userCities = String.valueOf(currentUser.Villes_Mapbox__c).split(';');
        Carte_Ville__mdt theCarte = [SELECT ID, Lien_Carte__c, Latitude_Centre__c, Longitude_Centre__c FROM Carte_Ville__mdt WHERE Ville__c IN :userCities LIMIT 1];

        return theCarte;
    }
    /**
     * Methode utilisée pour les Building IDs à l'utilisateur indiqué en créant des tâches dans Salesforce.
     *
     * @param buildingIDs Une liste de Building IDs à affecter
     * @param userID ID de l'utilisateur en question
     */
    @RemoteAction
    public static string assignToUser(List<String> buildingIDs, String userID, String dueDate){
        List<Task> newTasks = new List<Task>();
        List<Task> updateTasks = new List<Task>();
        Boolean nullDueDateValue = false;
        String subjectVisite = System.label.TSK_Building_Visit;
        user currentuser = [SELECT Profile.Name FROM User WHERE id = :UserInfo.getUserId()];
        map<String, list<Task>> mapOfOldTskBID = new map<String, list<Task>>();

        if(buildingIDs != null) {
            list<Task> oldTasks = [SELECT id, Subject, TSK_BuildingID__c, Status, ActivityDate, OwnerId, TSK_StatutDomicile__c
                                   FROM Task
                                   WHERE Subject =:subjectVisite AND TSK_BuildingID__c IN :buildingIDs /*AND ActivityDate >= Today*/];

            if(oldTasks != null && oldTasks.size() > 0) {
                for(Task tsk : oldTasks) {
                    // add old tasks of each BID
                    if(!mapOfOldTskBID.containskey(tsk.TSK_BuildingID__c)) {
                        mapOfOldTskBID.put(tsk.TSK_BuildingID__c, new list<Task>());
                    }
                    mapOfOldTskBID.get(tsk.TSK_BuildingID__c).add(tsk);
                }
            }
        }

        try {
            if(dueDate == null || String.isEmpty(dueDate)) {
                dueDate = string.valueOf(Date.today());
                nullDueDateValue = true;
            }

            if(Date.valueOf(dueDate) >= Date.today() && (currentuser.Profile.Name == system.label.Responsable_Vendeurs ||
                                                         currentuser.Profile.Name == system.label.Responsable_Back_Office ||
                                                         currentuser.Profile.Name == 'System Administrator' ||
                                                         currentUser.Profile.Name == 'Administrateur Système') ) {
                if(buildingIDs != null && userID != null) {

                    for(String buildingID : buildingIDs) {
                        // new Task created for a Building Id
                        if(mapOfOldTskBID.containskey(buildingID) == false) {
                            Task tsk = new Task();
                            tsk.ActivityDate = Date.valueOf(dueDate); // dueDate should be in the format YYYY-MM-DD ex: 2020-12-31
                            tsk.OwnerId = userID;
                            tsk.Subject = subjectVisite;
                            tsk.TSK_BuildingID__c = buildingID;
                            tsk.Priority = 'Normale';
                            tsk.Status = 'Ouverte';
                            newTasks.add(tsk);
                            // old Task for a specific BID assigned to a new owner
                        } else {
                            for(Task oldTsk : mapOfOldTskBID.get(buildingID)) {
                                // if no date specified in the mapBox / else if a Date is specified update the activityDate
                                if(nullDueDateValue == true) {
                                    oldTsk.ActivityDate = oldTsk.ActivityDate;
                                } else {
                                    oldTsk.ActivityDate = Date.valueOf(dueDate); // dueDate should be in the format YYYY-MM-DD ex: 2020-12-31
                                }
                                oldTsk.OwnerId = userID;
                                updateTasks.add(oldTsk);
                            }
                        }
                    }
                }

                if(newTasks.size() > 0 || updateTasks.size() > 0) {
                    if(newTasks.size() > 0) {
                        insert newTasks;
                    }
                    if(updateTasks.size() > 0) {
                        update updateTasks;
                    }

                    return String.format(System.Label.MAPBOX_New_Tasks_Success, new List<String> {String.valueOf(newTasks.size() + updateTasks.size())});
                } else {
                    return System.Label.MAPBOX_New_Tasks_Error;
                }
            } else {
                return System.Label.MAPBOX_New_Tasks_Error;
            }
        } catch(Exception ex) {
            system.debug('erreur ligne ' + ex.getLineNumber() + ': ' + ex.getMessage());

            return System.Label.MAPBOX_New_Tasks_Error;
        }
    }

    /**
     * Methode utilisée pour obtenir les Building IDs affectés dans Salesforce.
     * <p>
     * La méthode cherche tous les Building IDs sur les Tâches.
     */
    @RemoteAction
    public static Set<String> getBookedBuildingIDs(){
        Set<String> bookedBuildingIDs = new Set<String>();
        user currentUser = [SELECT CountryCode FROM User WHERE id = : UserInfo.getUserId()];
        set<string> setBID = new set<string>();

        for(task tsk : [SELECT TSK_BuildingID__c
                        FROM Task
                        WHERE OwnerId != : UserInfo.getUserId() AND TSK_BuildingID__c<> ''AND CreatedBy.CountryCode = : currentUser.CountryCode AND Subject = : System.label.TSK_Building_Visit
                        LIMIT 49999]) {

            bookedBuildingIDs.add(tsk.TSK_BuildingID__c);
        }

        return bookedBuildingIDs;
    }

    /**
     * Methode utilisée pour modifier le Building ID sur Compte ou Piste à partir du Mapbox.
     *
     * @param buildingID La valeur du Building ID
     * @param recordId Id de l'enregistrement Salesforce
     * @param objectName Nom API de l'objet Salesforce
     */
    @RemoteAction
    public static string setBuildingID(String buildingID, String recordId, String objectName){
        if(!String.isBlank(buildingID) && !String.isBlank(recordId) && !String.isBlank(objectName)) {

             try {
                // Remove Foyer suffix if present
                string currentBuildingID = String.valueOf(buildingID);
                string cleanedBuildingID = currentBuildingID.countMatches('_') > 1 ? currentBuildingID.substring(0, currentBuildingID.lastIndexOf('_')) : currentBuildingID;
                boolean eligible;
                system.debug(objectName);
                if(objectName == 'Account') {

                    Account updatedAccount = new Account();
                    updatedAccount.Id = recordId;
                    updatedAccount.ACC_BuildingID__c = cleanedBuildingID;
					ZuoraSubscriptionActions.updateAccountAndSubscriptionMove(recordId);
                    update updatedAccount;

                    return 'Success';
                } else if(objectName == 'Lead') {
                    Lead updatedLead = new Lead();
                    updatedLead.Id = recordId;
                    updatedLead.LEA_IDBatiment__c = cleanedBuildingID;
                    system.debug(updatedLead);
                    update updatedLead;

                    return 'Success';
                } else {
                    return 'Error: Unsupported objectName received';
                }
            }           
            catch(Exception ex) {
                return 'Error: ' + ex.getMessage();
            }
        } else {
            return 'Error: Required field(s) empty';
        }
    }

    /**
     * Methode utilisée pour obtenir la Ville du User et la carte associée.
     * <p>
     * La méthode cherche tous les Building IDs sur les Tâches.
     */
    @RemoteAction
    public static List<Carte_Ville__mdt> getCurrentUserMap(){
        User currentUser = [SELECT ID, Villes_Mapbox__c, Pays_Mapbox__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Carte_Ville__mdt> filteredMaps = new List<Carte_Ville__mdt>();

        if(currentUser != null && currentUser.Villes_Mapbox__c != null) {
            List<String> userCities = String.valueOf(currentUser.Villes_Mapbox__c).split(';');

            // Get all metadata records where Ville is same as the ones selected at User level
            List<Carte_Ville__mdt> mcs = Carte_Ville__mdt.getAll().values();

            for(Integer i = 0; i < mcs.size(); i++) {
                if(userCities.indexOf(mcs[i].Ville__c) > -1) {
                    filteredMaps.add(mcs[i]);
                }
            }

            return filteredMaps;
        } else {
            return null;
        }
    }

    /**
     * Methode utilisée pour obtenir les Villes du User et les cartes associées.
     * <p>
     * La méthode cherche tous les Building IDs sur les Tâches.
     */
    @RemoteAction
    public static List<Carte_Ville__mdt> getMaps(){
        // Get User selected cities
        Id currentUserID = UserInfo.getUserId();
        User currentUser = [SELECT ID, Villes_Mapbox__c, Pays_Mapbox__c FROM User WHERE Id = :currentUserID];

        String objectName = 'User';

        //Get the type being dealt with
        Schema.SObjectType objType = Schema.getGlobalDescribe( ).get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        //Get controlling field values
        Schema.DescribeFieldResult depend = describeResult.fields.getMap().get('Villes_Mapbox__c').getDescribe ( );


        //Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();

        if(controlToken == null) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries = (control.getType() == Schema.DisplayType.Boolean?   null :   control.getPicklistValues());

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object, List<String>> dependentPicklistValues = new Map<Object, List<String>>();


        for(Schema.PicklistEntry entry : depend.getPicklistValues() ) if(entry.isActive() ) {

            List<String> base64chars = String.valueOf(((Map<String, Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )).split( '' );

            for(Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {

                Object controlValue =
                (controlEntries == null?   (Object) (index == 1) : (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getValue() : null));
                Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                // if( controlValue == null ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                //     continue;
                if(!dependentPicklistValues.containsKey( controlValue ) ) {
                    dependentPicklistValues.put( controlValue, new List<String>() );
                }
                dependentPicklistValues.get(controlValue).add(entry.getValue());
            }
        }

        List<Carte_Ville__mdt> filteredMaps = new List<Carte_Ville__mdt>();
        List<String> userCities = new List<String>();

        if(dependentPicklistValues.get(currentUser.Pays_Mapbox__c) != null && dependentPicklistValues.get(currentUser.Pays_Mapbox__c).size() > 0) {

            for(string city : dependentPicklistValues.get(currentUser.Pays_Mapbox__c)) {
                userCities.add(city);
            }

            // Get all metadata records where Ville is same as the ones selected at User level
            List<Carte_Ville__mdt> mcs = Carte_Ville__mdt.getAll().values();

            for(Integer i = 0; i < mcs.size(); i++) {
                if(userCities.indexOf(mcs[i].Ville__c) > -1) {
                    filteredMaps.add(mcs[i]);
                }
            }

            return filteredMaps;
        } else {
            return null;
        }
    }
    /**
     * Methode utilisée pour obtenir le profil et le pays de l'utilisateur.
     */
    @RemoteAction
    public static Boolean isRBOuser(){
        user currentUser = [SELECT Profile.Name, Country FROM User WHERE id = :UserInfo.getUserId()];
        if(currentUser.Profile.Name == system.label.Responsable_Back_Office || currentUser.Profile.Name == 'System Administrator'  || currentUser.Profile.Name == 'Administrateur Système')
            return true;
        else {
            return false;
        }
    }

    /**
     * Methode utilisée pour obtenir le profil l'utilisateur.
     */
    @RemoteAction
    public static Boolean showGPSButton(){
        user currentUser = [SELECT Profile.Name, Country FROM User WHERE id = :UserInfo.getUserId()];
        if(currentUser.Profile.Name == system.label.Responsable_Vendeurs || currentUser.Profile.Name == system.label.Vendeurs_Terrain || currentUser.Profile.Name == 'System Administrator' || currentUser.Profile.Name == 'Administrateur Système')
            return true;
        else {
            return false;
        }
    }

    /**
     * Methode utilisée pour rendre la section attribué invisible
     */
    @RemoteAction
    public static Boolean showUsersSection(){
        user currentUser = [SELECT Profile.Name, Country FROM User WHERE id = :UserInfo.getUserId()];
        if(currentUser.Profile.Name == system.label.Vendeurs_Terrain) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * Methode utilisée pour récupérer les BID attribué à chaque utilisateur.
     */
    @RemoteAction
    public static set<string> getAssignedBID(){

        user currentUser = [SELECT CountryCode FROM User WHERE id = : UserInfo.getUserId()];
        set<string> setBID = new set<string>();

        for(task tsk : [SELECT TSK_BuildingID__c
                        FROM Task
                        WHERE OwnerId = : UserInfo.getUserId() AND TSK_BuildingID__c<> ''AND CreatedBy.CountryCode = : currentUser.CountryCode]) {
            setBID.add(tsk.TSK_BuildingID__c);
        }

        return setBID;
    }

    @RemoteAction
    public static Boolean checkMapBoxEligibility(String BuildingID){

        Boolean eligible;
        HttpResponse response = EligibilityManager.doCallout(EligibilityObjects.rawFeasibilityAPIUrl, EligibilityObjects.post, '{"building_id":"' + BuildingID + '"}');
        string jsonObj = response.getBody();

        // If the request is successful, parse the JSON response.
        if(response.getStatusCode() == 200) {
            // Deserialize the JSON string
            EligibilityObjects.FeasibilityAPIResponse feasibilityInfo = (EligibilityObjects.FeasibilityAPIResponse) System.JSON.deserialize(jsonObj, EligibilityObjects.FeasibilityAPIResponse.class);
            if(feasibilityInfo != null && feasibilityInfo.feasible == true) {
                eligible = true;
            } else {
                eligible = false;
            }
        } else {
            // Deserialize the error
            EligibilityObjects.FeasiblityError feasibilityError = (EligibilityObjects.FeasiblityError) System.JSON.deserialize(jsonObj, EligibilityObjects.FeasiblityError.class);
            eligible = false;
        }

        return eligible;
    }
}