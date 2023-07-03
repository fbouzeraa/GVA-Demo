/**
 * Classe contenant les méthodes pour updater un user lorsque le contact (person Account) est update

 * Nicolas Brosse
 * @date 15 mai 2022
 * 
 * Changes/Optimisation on 30/1/2023 by Jackie Abi Nassif
 */

 public with sharing class UpdateUserHandler {

    private static final Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(System.Label.Personal_Account_RecordType).getRecordTypeId();

  
    public static void updateCommunityUser(List<Account> accounts, Map<Id,Account> idToOldAccount){

        // create maps between contact and Account of new and old version
        Map<Id, Account> contactToAccount = new Map<Id, Account>();
        Map<Id, Account> contactToOldAccount = new Map<Id, Account>();
        List<User> updatedUsers = new List<User>();
        
        try {
            
            for(Account account : accounts){

                // verifier si le changement est relie a l'un des champs specifique
                Boolean isChanged = hasFieldChanged(account, idToOldAccount.get(account.Id));

                if(isChanged)
                {
                    if (account.RecordTypeId == personAccountRecordTypeId && account.personContactId != null && !contactToAccount.containsKey(account.personContactId))
                    {
                        contactToAccount.put(account.personContactId, account);
                    }        
                    if(idToOldAccount.get(account.id).RecordTypeId == personAccountRecordTypeId && idToOldAccount.get(account.id).personContactId != null && !contactToOldAccount.containsKey(idToOldAccount.get(account.id).personContactId))
                    {
                        contactToOldAccount.put(idToOldAccount.get(account.id).personContactId, idToOldAccount.get(account.id));
                    } 
                }                       
            }

            // si un enregistrement est ajoute dans les maps suivant continuer le processus
            if(contactToAccount != null && contactToAccount.keyset().Size() > 0)
            {
                List<User> users = [SELECT Id, ContactId FROM USER WHERE ContactId IN :contactToAccount.keyset()];

                for(User user : users){
                    
                    Account relatedAccount = contactToAccount.get(user.ContactId);
                    user.firstName = relatedAccount.firstName != null? relatedAccount.firstName : null;
                    user.lastName = relatedAccount.lastName != null? relatedAccount.lastName : null;
                    user.middleName = relatedAccount.middleName != null? relatedAccount.middleName : null;
                    user.email = relatedAccount.PersonEmail != null? relatedAccount.PersonEmail : null;
                    user.street = relatedAccount.billingStreet != null? relatedAccount.billingStreet : null;
                    user.city = relatedAccount.billingCity != null? relatedAccount.billingCity : null;
                    user.suffix = relatedAccount.suffix != null? relatedAccount.suffix : null;
                    user.countryCode = relatedAccount.billingCountryCode != null? relatedAccount.billingCountryCode : null;
                    user.defaultCurrencyIsoCode = relatedAccount.currencyIsoCode != null? relatedAccount.currencyIsoCode : null;
                    // user.latitude = relatedAccount.ACC_LatLong__Latitude__s != null? relatedAccount.ACC_LatLong__Latitude__s : null;
                    // user.longitude = relatedAccount.ACC_LatLong__Longitude__s != null? relatedAccount.ACC_LatLong__Longitude__s : null;
                    user.postalCode = relatedAccount.BillingPostalCode != null? relatedAccount.BillingPostalCode : null;
                    user.pays_Mapbox__c = relatedAccount.billingCountryCode != null? relatedAccount.billingCountryCode : null;
                    user.stateCode = relatedAccount.billingStateCode != null? relatedAccount.billingStateCode : null;
                    if(relatedAccount.BillingCountryCode != null)
                    {
                        user.languageLocaleKey = UserCreateUpdateUtils.setLanguageLocaleKey(relatedAccount.BillingCountryCode);
                        user.localeSidKey = UserCreateUpdateUtils.setLocalSideKey(relatedAccount.BillingCountryCode);
                        user.timeZoneSidKey = UserCreateUpdateUtils.setTimeZoneSidKey(relatedAccount.BillingCountryCode);
                    }
                    if(relatedAccount.PersonMobilePhone != null || relatedAccount.Phone != null)
                    {
                        user.phone =  UserCreateUpdateUtils.setPhone(relatedAccount.PersonMobilePhone, relatedAccount.Phone, relatedAccount.ACC_Indicatif__c);
                        user.mobilePhone =  UserCreateUpdateUtils.setMobilePhone(relatedAccount.PersonMobilePhone, relatedAccount.Phone, relatedAccount.ACC_Indicatif__c);
                    }
                    if(user.mobilePhone != null)
                    {
                        user.communityNickname =  UserCreateUpdateUtils.setCommunityNickname(user.mobilePhone);
                    }
                    
                    updatedUsers.add(user);

                    if(user.Id == UserInfo.getUserId()){
                        relatedAccount.personEmail = idToOldAccount.get(relatedAccount.id).personEmail;
                    }
                }
            }
        } catch (Exception e) {
            system.debug('Update user handler exception '+e.getLineNumber()+' >>> '+ e.getMessage());
        }

        // update the users if list updatedUsers not null
        if(updatedUsers != null && updatedUsers.size() > 0)
        {
            String usersJson = JSON.serialize(updatedUsers);
            doUpdateCommunityUser(usersJson);
        }
    }

    // check if any fields has changed
    private static Boolean hasFieldChanged(Account acct, Account oldAcct){
        return acct.firstName != oldAcct.firstName 
            ||  acct.lastName != oldAcct.lastName
            ||  acct.middleName != oldAcct.middleName
            ||  acct.PersonEmail != oldAcct.PersonEmail
            ||  acct.billingStreet != oldAcct.billingStreet
            ||  acct.billingCity != oldAcct.billingCity
            ||  acct.suffix != oldAcct.suffix
            ||  acct.billingCountryCode != oldAcct.billingCountryCode
            ||  acct.currencyIsoCode != oldAcct.currencyIsoCode
            // ||  acct.ACC_LatLong__Latitude__s != oldAcct.ACC_LatLong__Latitude__s
            // ||  acct.ACC_LatLong__Longitude__s != oldAcct.ACC_LatLong__Longitude__s
            ||  acct.BillingPostalCode != oldAcct.BillingPostalCode
            ||  acct.billingStateCode != oldAcct.billingStateCode
            ||  acct.PersonMobilePhone != oldAcct.PersonMobilePhone
            ||  acct.Phone != oldAcct.Phone
            ||  acct.ACC_Indicatif__c != oldAcct.ACC_Indicatif__c;
    }

    @future
    private static void doUpdateCommunityUser(String usersJson){

        List<User> users = (List<User>) JSON.deserialize(usersJson, List<User>.class);
        Boolean isUpdateableAccount = Schema.getGlobalDescribe().get('User').getDescribe().isUpdateable();

        try {
            if(isUpdateableAccount){
                update users;
            }
        } catch(Exception e) {
            System.debug('Update User Handler exception ' + e.getLineNumber()+' ==> '+e.getMessage());

            String errorMessage = e.getMessage();
            if(errorMessage.contains('DUPLICATE_COMM_NICKNAME')){
                errorMessage =  errorMessage.replace('DUPLICATE_COMM_NICKNAME','DUPLICATE_PHONE_OR_MOBILE_PHONE');
            }
            throw new CustomException(e.getLineNumber()+' ==> '+errorMessage);
        }
    }

    public class CustomException extends Exception {}
}