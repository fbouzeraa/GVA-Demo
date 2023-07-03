/**
 * @author      Nicolas Brosse
 * @date         16-03-2022
 *
 * @description  Class to create community user
 * with profile "Utilisateur du portail client"
 */

public class CreateUserHandler {

    private static final Id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
    private static final Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name = 'Utilisateur du Portail Client'].get(0);

    /*******************************************************************************************************
     * @descriptiion Create a community user from the person account related to the subscription
     *  if it is the first subscrtion that is create on the person account
     * @param   List of subscriptions
     * @return  void
     */
    public static void createCommunityUser (List<Zuora__Subscription__c> newSubscriptions){
        try {
            Set<Id> accountIds = getAccountIdsWithANewSubscription(newSubscriptions);
            if(accountIds.size() > 0 && accountIds != null) {
                List<Account> accts = getPersonAccountsWithNewASubcription(accountIds, personAccountId);
                Map<Id, Set<Zuora__Subscription__c>> accountToZuoraSubscription = getAccountToZuoraSubscription(accts);
                Set<Account> acctsWithSingleSubscription = getAccountsWithASingleSubscription(accts, accountToZuoraSubscription);
                List<user> users = createUsers(acctsWithSingleSubscription);
                try {
                    insert users;
                } catch(DmlException e) {
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
                system.debug(e.getLineNumber()+'  '+ e.getMessage());
        }

    }

    public static List<User> createUsers(Set<Account> acctsWithSingleSubscription){
        List<user> users = new List<user>();
        try {
            for(Account acct : acctsWithSingleSubscription) {
                User newUser = createACommunityUser(acct);
                users.add(newUser);
            }
        } catch (Exception e) {
            system.debug(e.getLineNumber()+' >>> '+e.getMessage());
        }
        return users;
    }

    private static Set<Id> getAccountIdsWithANewSubscription(List<Zuora__Subscription__c> newSubscriptions){
        Set<Id> accountIds = new Set<Id>();

        list<Zuora__Subscription__c> listSub = [SELECT Zuora__Account__r.BillingCountryCode, Zuora__Account__c
                                                FROM Zuora__Subscription__c
                                                WHERE Id IN :newSubscriptions];

        for(Zuora__Subscription__c sub : listSub) {
            if(sub.Zuora__Account__r.BillingCountryCode == 'BF' || sub.Zuora__Account__r.BillingCountryCode == 'CI' || sub.Zuora__Account__r.BillingCountryCode == 'RW') {
                accountIds.add(sub.Zuora__Account__c);
            }

        }

        return accountIds;
    }

    private static Set<Account> getAccountsWithASingleSubscription(List<Account> accts, Map<Id, Set<Zuora__Subscription__c>> accountToZuoraSubscription){
        Set<Account> acctsWithSingleSubscription = new Set<Account>();
        for(Account acct : accts) {
            Set<Zuora__Subscription__c> zuoraSubscriptions = accountToZuoraSubscription.get(acct.Id);
            if(zuoraSubscriptions.size() == 1) {
                acctsWithSingleSubscription.add(acct);
            }
        }

        return acctsWithSingleSubscription;
    }

    public static Map<Id, Set<Zuora__Subscription__c>> getAccountToZuoraSubscription(List<Account> accts){
        Map<Id, Set<Zuora__Subscription__c>> accountToZuoraSubscription = new Map<Id, Set<Zuora__Subscription__c>>();
        for(Zuora__Subscription__c zuoraSubscription : [SELECT Id, Zuora__Account__c FROM Zuora__Subscription__c WHERE Zuora__Account__c IN : accts]) {
            if(!accountToZuoraSubscription.containsKey(zuoraSubscription.Zuora__Account__c)) {
                accountToZuoraSubscription.put(zuoraSubscription.Zuora__Account__c, new Set<Zuora__Subscription__c>());
            }
            accountToZuoraSubscription.get(zuoraSubscription.Zuora__Account__c).add(zuoraSubscription);
        }

        return accountToZuoraSubscription;
    }

    private static List<Account> getPersonAccountsWithNewASubcription(Set<Id> accountIds, Id personAccountId){
        return [SELECT id, PersonEmail, Suffix, FirstName, PersonContactId, LastName, MiddleName, Phone, BillingStreet,
                BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingCountryCode,
                CurrencyIsoCode, ACC_Indicatif__c, PersonMobilePhone, ACC_LatLong__Latitude__s,
                ACC_LatLong__Longitude__s
                FROM Account
                WHERE RecordTypeId = : personAccountId
                AND id in : accountIds];
    }

    private static String setUserDistributeurId(String billingCity){
        if(billingCity == null) {
            return null;
        }
        String billingCityApiName = billingCity.replaceAll(' ', '_');
        Carte_Ville__mdt carteVille = Carte_Ville__mdt.getInstance(billingCityApiName);
        String userDistributeurId = carteVille == null? null : carteVille.Distributor_Id__c;

        return userDistributeurId;
    }

    private static String setUserAlias(String firstName, String lastName){
        if(String.isNotBlank(firstName) && String.isNotBlank(lastName)) {
            Integer lengthAlias = Math.min(lastName.length(), 7);

            return firstName.substring(0, 1).toLowerCase() + lastName.substring(0, lengthAlias).toLowerCase();
        }
        if(String.isBlank(firstName) && String.isNotBlank(lastName)) {
            Integer lengthAlias = Math.min(lastName.length(), 8);

            return lastName.substring(0, lengthAlias).toLowerCase();
        }

        return 'noAlias';
    }

    private static String  setUserEmail(String email){
        Boolean isValidEmail = (String.isNotBlank(email) && LoginUtils.isValidEmail(email));
        if(isValidEmail) {
            return email;
        }

        return System.label.NOEMAIL_GVA_AFRICA;
    }

    /*******************************************************************************************************
     * @descriptiion Create a community user from the person account
     * @param   Account
     * @return  User
     */
    public static User createACommunityUser(Account acct){
        String userMobilePhone = UserCreateUpdateUtils.setMobilePhone(acct.PersonMobilePhone, acct.Phone, acct.ACC_Indicatif__c);

        User newUser = new User(
            alias = setUserAlias(acct.FirstName, acct.LastName),
            email = setUserEmail(acct.PersonEmail),
            Street = acct.BillingStreet,
            City = acct.BillingCity,
            State = acct.BillingState,
            PostalCode = acct.BillingPostalCode,
            emailencodingkey = 'UTF-8',
            Suffix = acct.suffix,
            firstname = acct.FirstName,
            lastname = acct.LastName,
            middleName = acct.middleName,
            languageLocaleKey = UserCreateUpdateUtils.setLanguageLocaleKey(acct.BillingCountryCode),
            localeSidKey = UserCreateUpdateUtils.setLocalSideKey(acct.BillingCountryCode),
            TimeZoneSidKey = UserCreateUpdateUtils.setTimeZoneSidKey(acct.BillingCountryCode),
            country = acct.BillingCountry,
            countryCode = acct.BillingCountryCode,
            contactId = acct.PersonContactId,
            username = UserCreateUpdateUtils.setUsername(userMobilePhone),
            CommunityNickname = UserCreateUpdateUtils.setCommunityNickname(userMobilePhone),
            ProfileId = clientPortalProfile.Id,
            DefaultCurrencyIsoCode = acct.CurrencyIsoCode,
            MobilePhone = userMobilePhone,
            Phone = UserCreateUpdateUtils.setPhone(acct.PersonMobilePhone, acct.Phone, acct.ACC_Indicatif__c),
            Latitude = acct.ACC_LatLong__Latitude__s,
            Longitude = acct.ACC_LatLong__Longitude__s,
            Pays_Mapbox__c = acct.BillingCountryCode,
            UserRoleId = null,
            IsActive = true,
            USR_DistributeurID__c = setUserDistributeurId(acct.BillingCity),
            USR_BypassVR__c = true);

        return newUser;
    }

}