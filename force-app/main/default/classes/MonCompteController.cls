/**
 * @author      Salah Mansour Akridiss
 * @date         16-02-2022
 * @description  Controleur qui fait toute la logique derrière la page Mon Compte
 */
public with sharing class MonCompteController {

    private static final Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();

    private static Id getAccountFromUserId(Id userId){
        Id contactId = [SELECT Id, ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
        Id accountId = [SELECT Id FROM Account WHERE PersonContactId = :contactId
                        AND RecordTypeId = :personAccountRecordTypeId
                        LIMIT 1].Id;

        return accountId;
    }

    private static String getAccountNumber(Id accountId){
        Zuora__CustomerAccount__c zuoraCustomerAccount =  [SELECT Zuora__AccountNumber__c
                                                           FROM Zuora__CustomerAccount__c
                                                           WHERE Zuora__Account__c = :accountId
                                                           LIMIT 1];
        if(zuoraCustomerAccount != null) {
            return zuoraCustomerAccount.Zuora__AccountNumber__c;
        }

        return null;

    }

    // private static Id getContactIdFromUserId(Id userId){
    //     Id contactId = [SELECT Id, ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
    //     return contactId;
    // }

    private static List<Zuora__SubscriptionProductCharge__c> getListeDesAbonnements(Id accountId) {
        List<Zuora__SubscriptionProductCharge__c> listAbonnements = new List<Zuora__SubscriptionProductCharge__c>();
        listAbonnements = [SELECT Id, Zuora__SubscriptionRatePlanChargeName__c, Zuora__Price__c,
                           Zuora__Type__c, Zuora__Account__c, Zuora__Account__r.Id, CurrencyIsoCode,
                           Zuora__EffectiveStartDate__c,
                           Zuora__Subscription__r.Id,
                           Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                           Zuora__Subscription__r.Zuora__Status__c,
                           Zuora__Subscription__r.BoxNumber__c,
                           Zuora__Subscription__r.SUB_Bandwidth__c,
                           Zuora__Subscription__r.NbrJoursRestants__c,
                           Zuora__Subscription__r.ExpectedRenewalDate__c,
                           Zuora__Subscription__r.SUB_T_Due_Date__c
                           FROM Zuora__SubscriptionProductCharge__c
                           WHERE Zuora__Account__r.Id = :accountId
                           AND Zuora__Type__c = 'Recurring'
                           AND (Zuora__Subscription__r.Zuora__Status__c = 'Active'
                                OR Zuora__Subscription__r.Zuora__Status__c = 'Suspended'
                                OR Zuora__Subscription__r.Zuora__Status__c = 'Pending Activation')
                           AND Zuora__Model__c != 'Discount-Percentage'
                           AND Zuora__Model__c != 'Discount-Fixed Amount'
                           AND Zuora__Price__c > 0];

        for(Zuora__SubscriptionProductCharge__c abonnement : listAbonnements) {
            Zuora__Subscription__c zuoraSubscription = [SELECT IsCollaborator__c FROM Zuora__Subscription__c WHERE Id = :abonnement.zuora__Subscription__r.Id];
            if(zuoraSubscription.IsCollaborator__c == 'Y') {
                abonnement.zuora__Price__c = setProductRatePlanPrice(abonnement.zuora__Subscription__r.Id);
            }
        }

        return listAbonnements;
    }

    private static Double setProductRatePlanPrice(Id zuoraSubscriptionId){
        String PRPChargeId = SubscriptionRenewalActions.getCollaboratorCharge(zuoraSubscriptionId);
        PRPChargeId = PRPChargeId.substring (0, PRPChargeId.indexOf(','));
        String renewSubPreviewResponseJson
            = SubscriptionRenewalActions.renewSubPreview(zuoraSubscriptionId, 1, false, 'Credit_Card', false, PRPChargeId, null, null, null);
        RenewSubPreviewResponse renewSubPreviewResponse = RenewSubPreviewResponse.parse(renewSubPreviewResponseJson);

        return renewSubPreviewResponse.previewResult.invoices[0].amount;
    }

    private static List<Zuora__SubscriptionProductCharge__c> getAbonnementProchaineExpiration(Id accountId) {
        List<Zuora__SubscriptionProductCharge__c> abonnement = [SELECT Id, Zuora__SubscriptionRatePlanChargeName__c, Zuora__Price__c,
                                                                Zuora__Type__c, Zuora__Account__c, Zuora__Account__r.Id, CurrencyIsoCode,
                                                                Zuora__EffectiveStartDate__c,
                                                                Zuora__Subscription__r.Id,
                                                                Zuora__Subscription__r.Zuora__SubscriptionNumber__c,
                                                                Zuora__Subscription__r.Zuora__Status__c,
                                                                Zuora__Subscription__r.BoxNumber__c,
                                                                Zuora__Subscription__r.SUB_Bandwidth__c,
                                                                Zuora__Subscription__r.NbrJoursRestants__c,
                                                                Zuora__Subscription__r.ExpectedRenewalDate__c,
                                                                Zuora__Subscription__r.SUB_T_Due_Date__c
                                                                FROM Zuora__SubscriptionProductCharge__c
                                                                WHERE Zuora__Account__r.Id = :accountId
                                                                AND Zuora__Type__c = 'Recurring'
                                                                AND (Zuora__Subscription__r.Zuora__Status__c = 'Active'
                                                                     OR Zuora__Subscription__r.Zuora__Status__c = 'Suspended')
                                                                AND Zuora__Price__c > 0
                                                                AND Zuora__Model__c != 'Discount-Percentage'
                                                                AND Zuora__Model__c != 'Discount-Fixed Amount'
                                                                ORDER BY Zuora__Subscription__r.NbrJoursRestants__c ASC
                                                                LIMIT 1];

        return abonnement;
    }

    private static List<Zuora__ZInvoice__c> getListeFactures(Id accountId) {
        List<Zuora__ZInvoice__c> listeFactures = new List<Zuora__ZInvoice__c>();
        listeFactures = [SELECT Id, Zuora__Account__c, Zuora__DueDate__c, Zuora__ZuoraId__c,
                         Zuora__TotalAmount__c, CurrencyIsoCode, Zuora__Status__c
                         FROM Zuora__ZInvoice__c
                         WHERE Zuora__Account__c = :accountId
                         AND Zuora__Status__c = 'Posted'
                         AND Zuora__TotalAmount__c > 0
                         AND (Zuora__DueDate__c = THIS_YEAR OR Zuora__DueDate__c = LAST_YEAR)
                         ORDER BY Zuora__DueDate__c DESC];

        return listeFactures;
    }

    @AuraEnabled(cacheable = true)
    public static MonCompteWrapperResponse getMonCompteSummaryData(String userId){
        return new MonCompteWrapperResponse(userId);
    }

    @testVisible
    private class MonCompteWrapperResponse {

        @AuraEnabled
        public Id accountId {get; set;}

        @AuraEnabled
        public List<Zuora__ZInvoice__c> listeFactures = new List<Zuora__ZInvoice__c>();

        @AuraEnabled
        public List<Zuora__SubscriptionProductCharge__c> listeAbonnements = new List<Zuora__SubscriptionProductCharge__c>();

        @AuraEnabled
        public Zuora__SubscriptionProductCharge__c dernierAbonnement {get; set;}

        @AuraEnabled
        public String accountNumber {get; set;}

        MonCompteWrapperResponse(String userId){
            this.accountId = getAccountFromUserId(userId);
            this.listeAbonnements = getListeDesAbonnements(this.accountId);
            this.dernierAbonnement = getAbonnementProchaineExpiration(this.accountId).size() == 0 ? null : getAbonnementProchaineExpiration(this.accountId)[0];
            this.listeFactures = getListeFactures(this.accountId);
            this.accountNumber = getAccountNumber(this.accountId);
        }
    }

    @AuraEnabled
    public static String changePassword(String oldPassword, String newPassword, String verifyNewPassword) {
        System.PageReference resultat = Site.changePassword(newPassword, verifyNewPassword, oldpassword);
        if(resultat != null) {
            return 'succes';
        } else {

            return 'erreur';
        }
    }

}