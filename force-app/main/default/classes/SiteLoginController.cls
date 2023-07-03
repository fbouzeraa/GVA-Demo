/**
 * An apex page controller that exposes the site login functionality
 */
global  without sharing class SiteLoginController {
     global String mobilePhone {get; set;}
     global String password {get; set;}

    global PageReference login() { //

        String personAccountRecordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe()
                                            .getRecordTypeInfosByName().get('Compte personnel').getRecordTypeId();
        System.debug('personAccountRecordTypeId : ' + personAccountRecordTypeId);
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
        System.debug('clientPortalProfile : ' + clientPortalProfile);
        Account acct = [SELECT id, PersonEmail, FirstName, PersonContactId, LastName, PersonMobilePhone, BillingCountry
                                FROM Account
                                 WHERE RecordTypeId= :personAccountRecordTypeId
                                 AND PersonMobilePhone = '+33 0673994431'].get(0);
        System.debug('acct : '+ acct);
        // 

        User newUser = new User(
            alias = acct.FirstName,
            email = acct.PersonEmail,
            // Street = acct.BillingStreet,
            // City = acct.BillingCity,
            // State = acct.BillingState,
            // PostalCode = acct.BillingPostalCode,
            emailencodingkey = 'UTF-8',
            firstname = acct.FirstName,
            lastname = acct.LastName,
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            TimeZoneSidKey = 'GMT',
         //   Country = acct.BillingCountry,
            contactId = acct.PersonContactId,
            username = acct.PersonEmail,
            CommunityNickname = acct.FirstName + acct.LastName,
            ProfileId ='00e5r000000I4KpAAK',
            IsActive = true);
          //  insert newUser;
       //      String id = System.UserManagement.initSelfRegistration​(Auth.VerificationMethod.SMS, user);
             String id = System.UserManagement.initSelfRegistration(Auth.VerificationMethod.SMS, newUser);
      //  PageReference pageRef = new PageReference('partialURL');
      //  String startUrl = System.currentPageReference().getParameters().get('startURL');
        return null;
        // return Site.login(username, password, startUrl);
    }
    
   	 global SiteLoginController () {}
}