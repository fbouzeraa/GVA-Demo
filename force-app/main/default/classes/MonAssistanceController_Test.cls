@isTest
public with sharing class MonAssistanceController_Test {

    private static final Id PERSON_ACCOUNT_RECORD_TYPE_ID =  
                Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();

    private static final Id CASE_INCIDENT_RECORD_TYPE_ID =  
                Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CAS_Incident').getRecordTypeId();
    

    @testSetup
    static void makeData(){
        User adminUser = TestDataFactory.createAdminUser('BF');
        insert adminUser;
        System.runAs(adminUser){
            Test.setMock(HttpCalloutMock.class, new SMSMock());
            User burkinaFasoClientPortalUser = TestDataFactory.createClientPortalUser(adminUser, 'BF');
            burkinaFasoClientPortalUser.USR_BypassVR__c = true;
            insert burkinaFasoClientPortalUser;

            Table_de_routage__c tableDeRoutageMTND = 
                            new Table_de_routage__c(Name='MTND - MAINT - NO RDV',
                                                     TDR_Recommandations__c =  'Replannifier RDV de maintenance Client',
                                                     TDR_Impact__c = 'CoupureFranche',
                                                     TDR_ExitCodeDiagnostiquant__c = True,
                                                    // TDR_ObjetDeLAppel__c = 'RDV maintenance',
                                                    //  TDR_Precisions__c = 'En attente de RDV Maintenance',
                                                    //  TDR_VerificationsTests__c = 'Rdv Non pris',
                                                    TDR_Categorie1__c = 'MAINTENANCE CLIENT',
                                                    TDR_Categorie2__c = 'RDV',
                                                    TDR_Categorie3__c = 'RDVAPrendre',
                                                    TDR_Competence__c = 'Maintenance Client');
            insert tableDeRoutageMTND;

            Table_de_routage__c tableDeRoutageDEMG = 
                            new Table_de_routage__c(Name='DEMG - Déménagement',
                                                     TDR_Impact__c = 'RequeteCommerciale',
                                                    TDR_Categorie1__c = 'Client',
                                                    TDR_Categorie2__c = 'Demenagement',
                                                    TDR_Competence__c = 'BO commercial',
                                                    TDR_Reason__c = 'Déménagement',
                                                    TDR_Type__c = 'Modification d\'abonnement');
            insert tableDeRoutageDEMG;

            Table_de_routage__c tableDeRoutageRECL = 
                            new Table_de_routage__c(Name='RECL - Réclamation client');
            insert tableDeRoutageRECL;

            
        }
    }

    @isTest
    static void shouldCreateACaseWithContactId() {
        User burkinaFasoClientPortalUser = [SELECT Id, ContactId FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, ContactId FROM Case LIMIT 1];
        System.assertEquals(burkinaFasoClientPortalUser.ContactId, portalClientCase.ContactId,'The contact Id case should be the burkinaFasoClientPortalUser.ContactId');
    }

    @isTest
    static void shouldCreateACaseWithAccountId() {
        User burkinaFasoClientPortalUser = [SELECT Id, ContactId FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        Id burkinaFasoClientPortalUserAccountId = getUserAccountId(burkinaFasoClientPortalUser.ContactId);
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, AccountId FROM Case LIMIT 1];
        System.assertEquals(burkinaFasoClientPortalUserAccountId, portalClientCase.AccountId,'The account Id case should be the burkinaFasoClientPortalUser account Id');
    }

    @isTest
    static void shouldCreateACaseWithCreatedDateToday() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CreatedDate FROM Case LIMIT 1];
        System.assert(portalClientCase.CreatedDate != null,'The create date case should not be null');
    }

    @isTest
    static void shouldCreateACaseWithRecortTypeIncident() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, RecordTypeId FROM Case LIMIT 1];
        System.assertEquals(CASE_INCIDENT_RECORD_TYPE_ID , portalClientCase.RecordTypeId,'The RecordTypeId case should not be CAS_Requete');
    }

    @isTest
    static void shouldCreateACaseWithStringExitCodeAUKO_COKO_AUTH() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Exit_Code__c FROM Case LIMIT 1];
        System.assertEquals('MTND - MAINT - NO RDV' , portalClientCase.CAS_Exit_Code__c,'The exit code  case should not be AUKO_COKO_AUTH');
    }

    @isTest
    static void shouldCreateACaseWithLookupExitCodeAUKO_COKO_AUTH() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Exit_Code__c FROM Case LIMIT 1];
        Table_de_routage__c tableDeRoutage = [SELECT Id FROM Table_de_routage__c WHERE Name = 'MTND - MAINT - NO RDV' LIMIT 1];
        System.assertEquals(tableDeRoutage.Id , portalClientCase.Exit_Code__c,'The Exit_Code__c should be tableDeRoutageId of  AUKO_COKO_AUTH');
    }

    @isTest
    static void shouldCreateACaseWithFieldCAS_ExitCodeDiagnostiquant_cEqualTrue() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT CAS_ExitCodeDiagnostiquant__c FROM Case LIMIT 1];
        Table_de_routage__c tableDeRoutage = [SELECT TDR_ExitCodeDiagnostiquant__c FROM Table_de_routage__c WHERE Name = 'MTND - MAINT - NO RDV' LIMIT 1];
        System.assertEquals(tableDeRoutage.TDR_ExitCodeDiagnostiquant__c , portalClientCase.CAS_ExitCodeDiagnostiquant__c,'The CAS_ExitCodeDiagnostiquant__c should be : true');
    }

    @isTest
    static void shouldCreateACaseWithFieldOriginEqualsSelfcareEspacelient() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Origin FROM Case LIMIT 1];
        System.assertEquals('Selfcare Espace client' , portalClientCase.Origin,'The case Origin should be : Selfcare Espace client');
    }
    

    // @isTest
    // static void shouldCreateACaseWithExitCodeNull() {
    //     User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
    //     String result = '';
    //     System.runAs(burkinaFasoClientPortalUser){
    //         try{
    //             result =  MonAssistanceController.createPortalClientCase('NO_Exit_Code');
    //         }catch(Exception e){
    //              System.assert(e.getMessage().contains('The following exception has occurred: Insert failed.'), 'Exception message was wrong');
    //         }
    //     }

    // }

    @isTest
    static void shouldCreateACaseWithCAS_Pays_cBF() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Pays__c FROM Case LIMIT 1];
        System.assertEquals('BF' , portalClientCase.CAS_Pays__c,'The CAS_Pays__c case should be: BF (Burkina faso)');
    }

    @isTest
    static void shouldCreateACaseWithPays_cBurkinaFaso() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Pays__c FROM Case LIMIT 1];
        System.assertEquals('Burkina Faso' , portalClientCase.Pays__c,'The Pays__c case should be: BF (Burkina faso)');
    }

    @isTest
    static void shouldCreateACaseWithCAS_Canal_cEspaceClient() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Canal__c FROM Case LIMIT 1];
        System.assertEquals('Espace client' , portalClientCase.CAS_Canal__c,'The CAS_Canal__c case should be: Espace client');
    }

    @isTest
    static void shouldCreateACaseWithStatusCAS_Nouvelle() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Status FROM Case LIMIT 1];
        System.assertEquals('CAS_Nouvelle' , portalClientCase.Status,'The Status case should be: CAS_Nouvelle');
    }

    @isTest  // TODO Check wchich queue should it be assign
    static void shouldCreateACaseWithOwnerIdNotClear() {
        User burkinaFasoClientPortalUser = [SELECT Id 
                                            FROM User 
                                            WHERE Username = 'BF.client.portal.user@testorg.com' 
                                            LIMIT 1];
        List<Table_de_routage__c> tableDeRoutage = new  List<Table_de_routage__c>();
        System.runAs(burkinaFasoClientPortalUser){
            Test.startTest();
            String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
            Test.stopTest();
            tableDeRoutage =  [SELECT Id, TDR_FileDAttente__c 
                                                            FROM Table_de_routage__c 
                                                            WHERE Name = 'MTND - MAINT - NO RDV'  
                                                            LIMIT 1];
        }
        Case portalClientCase = [SELECT Id, OwnerId FROM Case LIMIT 1];
        System.assertEquals(tableDeRoutage[0].TDR_FileDAttente__c , portalClientCase.OwnerId,'The OwnerId should be: ??? Id');  
    }

    @isTest
    static void shouldCreateACaseWithCAS_Categorie1_cEqualMaintenanceClient() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Categorie1__c FROM Case LIMIT 1];
        System.assertEquals('MAINTENANCE CLIENT' , portalClientCase.CAS_Categorie1__c,'The CAS_Categorie1__c case should be: MAINTENANCE CLIENT');
    }

    @isTest
    static void shouldCreateACaseWithCAS_Categorie2_cEqualRDV() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Categorie2__c FROM Case LIMIT 1];
        System.assertEquals('RDV' , portalClientCase.CAS_Categorie2__c,'The CAS_Categorie2__c case should be: RDV');
    }

    @isTest
    static void shouldCreateACaseWithCAS_Categorie3_cEqualRDVAPrendre() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Categorie3__c FROM Case LIMIT 1];
        System.assertEquals('RDVAPrendre' , portalClientCase.CAS_Categorie3__c,'The CAS_Categorie2__c case should be: RDV');
    }

    @isTest
    static void shouldCreateACaseWithCAS_Recommandations_cEqualReplannifier() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Recommandations__c FROM Case LIMIT 1];
        Table_de_routage__c tableDeRoutage =  [SELECT Id, TDR_Recommandations__c 
                                                FROM Table_de_routage__c 
                                                WHERE Name = 'MTND - MAINT - NO RDV'  
                                                LIMIT 1];
        System.assertEquals(tableDeRoutage.TDR_Recommandations__c , portalClientCase.CAS_Recommandations__c,'The CAS_Recommandations__c case field should be: ');
    }

    @isTest
    static void shouldCreateACaseWithCAS_Impact_cEqualCoupureFranche() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, CAS_Impact__c FROM Case LIMIT 1];
        Table_de_routage__c tableDeRoutage =  [SELECT Id, TDR_Impact__c 
                                                FROM Table_de_routage__c 
                                                WHERE Name = 'MTND - MAINT - NO RDV'  
                                                LIMIT 1];
        System.assertEquals(tableDeRoutage.TDR_Impact__c , portalClientCase.CAS_Impact__c,'The CAS_Impact__c case field should be: CoupureFranche');
    }


    @isTest
    static void shouldCreateACaseWithTypeEqualsModificationAbonnement() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringifyDEMG();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Type FROM Case LIMIT 1];
        Table_de_routage__c tableDeRoutage =  [SELECT Id, TDR_Type__c 
                                                FROM Table_de_routage__c 
                                                WHERE Name = 'DEMG - Déménagement'  
                                                LIMIT 1];
        System.assertEquals(tableDeRoutage.TDR_Type__c , portalClientCase.Type,'The Type case field should be: Modification d\'abonnement');
    }

    @isTest
    static void shouldCreateACaseWithReasonEqualsDemenagement() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringifyDEMG();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Reason FROM Case LIMIT 1];
        Table_de_routage__c tableDeRoutage =  [SELECT Id, TDR_Reason__c 
                                                FROM Table_de_routage__c 
                                                WHERE Name = 'DEMG - Déménagement'  
                                                LIMIT 1];
        System.assertEquals(tableDeRoutage.TDR_Reason__c , portalClientCase.Reason,'The Type case field should be: Modification d\'abonnement');
    }

    @isTest
    static void shouldCreateACaseWithDescriptionContainsAddress() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringifyDEMG();    
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Description FROM Case LIMIT 1];
        System.assert(portalClientCase.Description.contains('16 rue inconnu 38000 Grenoble'),'The Description case field should contain : 16 rue inconnu 38000 Grenoble');
    }

    @isTest
    static void shouldCreateACaseWithDescriptionContainsLatitude() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringifyDEMG();    
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Description FROM Case LIMIT 1];
        System.assert(portalClientCase.Description.contains('Latitude : 45.184745'),'The Description case field should contain : Latitude : 45.184745');
    }

    @isTest
    static void shouldCreateACaseWithDescriptionContainsLongitude() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringifyDEMG();    
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Description FROM Case LIMIT 1];
        System.assert(portalClientCase.Description.contains('Longitude : 5.711851'),'The Description case field should contain : Longitude :  5.711851');
    }

    @isTest
    static void shouldCreateACaseWithDescriptionContainsMovingDate() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringifyDEMG();    
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Description FROM Case LIMIT 1];
        System.debug('portalClientCase.Description : ' + portalClientCase.Description);
        System.assert(portalClientCase.Description.contains('Moving Date : 2022-08-26'),'The Description case field should contain : Moving Date :  2022-08-26');
    }


    @isTest
    static void shouldCreateACaseWithDescriptionEqualsNullOrBlank() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringify();
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Description FROM Case LIMIT 1];
        System.assert(String.isBlank(portalClientCase.Description),'The Description case field should be null or blank');
    }


    @isTest
    static void shouldCreateACaseWithDescriptionContainsDescriptionField() {
        User burkinaFasoClientPortalUser = [SELECT Id FROM User WHERE Username = 'BF.client.portal.user@testorg.com' LIMIT 1];
        String caseInfoWrapperStringify = createCaseInfoWrapperStringifyRECL();    
        System.runAs(burkinaFasoClientPortalUser){
            MonAssistanceController.createPortalClientCase(caseInfoWrapperStringify);
        }
        Case portalClientCase = [SELECT Id, Description FROM Case LIMIT 1];
        System.debug('portalClientCase.Description : ' + portalClientCase.Description);
        System.assert(portalClientCase.Description.contains('Description of the reclamation'),'The Description case field should contain : Description of the reclamation');
    }

    
    




    private static Id getUserContactId(Id userId){
        Id contactId = [SELECT Id, ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
        return contactId;
    }
        
    
    private static Id getUserAccountId(Id contactId){   
        Id accountId = [SELECT Id FROM Account WHERE PersonContactId = :contactId 
                                                AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID 
                                                LIMIT 1].Id;
        return accountId;
    }

    private static String createCaseInfoWrapperStringify() {
        String address = null;
        Double latitude = null;
        Double longitude = null;
        String movingDate = null;
        String description = null;
        MonAssistanceController.CaseInfoWrapper caseInfoWrapper =
            new MonAssistanceController.CaseInfoWrapper('MTND - MAINT - NO RDV', address, latitude, longitude, movingDate, description);
        return JSON.serialize(caseInfoWrapper);
    }

    private static String createCaseInfoWrapperStringifyDEMG() {
        String address = '16 rue inconnu 38000 Grenoble';
        Double latitude = 45.184745;
        Double longitude = 5.711851;
        String movingUnixDate = String.valueOf(Date.newInstance(2022, 8, 26));
        String description = null;
        MonAssistanceController.CaseInfoWrapper caseInfoWrapper =
            new MonAssistanceController.CaseInfoWrapper('DEMG - Déménagement', address, latitude, longitude, movingUnixDate, description);
        return JSON.serialize(caseInfoWrapper);
    }

    private static String createCaseInfoWrapperStringifyRECL() {
        String description = 'Description of the reclamation';
        MonAssistanceController.CaseInfoWrapper caseInfoWrapper =
            new MonAssistanceController.CaseInfoWrapper('RECL - Réclamation client', null, null, null, null, description);
        return JSON.serialize(caseInfoWrapper);
    }

}