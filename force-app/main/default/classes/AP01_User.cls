/**
 * Class contient tous les actions faites sur les utilisateurs
 */
public without sharing class AP01_User {

    /**
     * Cette Methode est utilisée pour donner aux utilisateurs d'un pays l'accès à tous les abo de son pays
     * en ajoutant les utilisateurs dans des groups
     */
    public static void addUsersToGroup(map<id, user> oldMap, map<id, user> newMap){
        id distributorProfileId = [SELECT Id FROM Profile WHERE Name = :System.label.Distributor_Profile].Id;
        list<Group> listDistributorGroup = [SELECT id, DeveloperName
                                            FROM Group
                                            WHERE DeveloperName like 'Distributeur%' AND type = 'Regular'];
        map<string, id> mapCountryGoup = new map<string, id>();
        for(group distGroup : listDistributorGroup) {
            mapCountryGoup.put(distGroup.DeveloperName.substringAfter('_'), distGroup.id);
        }

        list<GroupMember> listNewPartner = new list<GroupMember>();
        //in case of new partner user, and the user to the related group
        if(oldMap == null) {
            for(user currentUser : newMap.values()) {
                if(currentUser.ProfileId == distributorProfileId) {
                    if(mapCountryGoup.get(currentUser.CountryCode) != null) {
                        GroupMember gm = new GroupMember();
                        gm.groupId = mapCountryGoup.get(currentUser.CountryCode);
                        gm.UserOrGroupId = currentUser.Id;
                        listNewPartner.add(gm);
                    }

                }
            }
        }//In case of update remove user from old group and added it to a new group
        else {
            list<id> listUsers = new list<Id>();
            for(user currentUser : newMap.values()) {
                if(currentUser.Country != null && currentUser.Country != oldMap.get(currentUser.Id).country) {
                    if(currentUser.ProfileId == distributorProfileId) {
                        if(mapCountryGoup.get(currentUser.CountryCode) != null) {
                            GroupMember gm = new GroupMember();
                            gm.groupId = mapCountryGoup.get(currentUser.CountryCode); gm.UserOrGroupId = currentUser.Id; listNewPartner.add(gm); listUsers.add(currentUser.Id);

                        }

                    }
                }
            }
            list<GroupMember> listGM = [SELECT id, UserOrGroupId
                                        FROM GroupMember
                                        WHERE UserOrGroupId IN :listUsers ];
            if(listGm.size() > 0 && listGm != null) {
                delete listGm;
            }
        }
        if(listNewPartner.size() > 0 && listNewPartner != null) {
            insert listNewPartner;
        }

    }
}