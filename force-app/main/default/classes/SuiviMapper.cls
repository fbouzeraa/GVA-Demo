public class SuiviMapper {

/*
 * Methode pour remplir l'object compte après une action faite sur la souscription
 * <p>
 * @param body compte
 * @return objet suiviClient
 * */

    public static suiviObjects.SuiviClient fillSuiviAccount(account currentAccount){
        // create Client section
        string categorie;
        // if(currentAccount.RecordType.DeveloperName == System.label.Personal_Account_RecordType) {
        categorie = 'Particulier';
        // } else {
        //  categorie = 'Entreprise';
        // }

        suiviObjects.SuiviClient accountSuivi = new suiviObjects.SuiviClient();
        if(currentAccount.RecordType.DeveloperName == System.label.Personal_Account_RecordType) {
            accountSuivi.Nom = currentAccount.FirstName;
            accountSuivi.Prenom = currentAccount.LastName;
        } else {
            accountSuivi.Nom = currentAccount.Name;
            accountSuivi.Prenom = currentAccount.Name;
        }
        accountSuivi.Categorie = categorie;
        accountSuivi.FilialeGVA = currentAccount.ACC_Entreprise__c;
        accountSuivi.CodeCompte = currentAccount.ACC_AccountNumber__c;
        accountSuivi.IDCompte = currentAccount.Id;

        //To Do
        //accountSuivi.NumeroFiscal  ,  accountSuivi.NumeroRegistre
        return accountSuivi;
    }

    /*
     * Methode pour remplir l'object compte après une action faite sur la souscription
     * <p>
     * @param body compte
     * @return objet suiviClient
     * */

    public static suiviObjects.SuiviClient fillSuiviParentAccount(account currentAccount){
        // create Client section
        string categorie;
        //  if(currentAccount.ACC_ChampCompteParent__r.RecordType.DeveloperName == System.label.Personal_Account_RecordType) {
        categorie = 'Particulier';
        /* } else {
             categorie = 'Entreprise';
           }*/

        suiviObjects.SuiviClient parentAccountSuivi = new suiviObjects.SuiviClient();
        parentAccountSuivi.Nom = currentAccount.ACC_ChampCompteParent__r.FirstName;
        parentAccountSuivi.Prenom = currentAccount.ACC_ChampCompteParent__r.LastName;
        parentAccountSuivi.Categorie = categorie;
        parentAccountSuivi.FilialeGVA = currentAccount.ACC_ChampCompteParent__r.ACC_Entreprise__c;
        parentAccountSuivi.CodeCompte = currentAccount.ACC_ChampCompteParent__r.ACC_AccountNumber__c;
        parentAccountSuivi.IDCompte = currentAccount.ACC_ChampCompteParent__c;

        //To Do
        //accountSuivi.NumeroFiscal  ,  accountSuivi.NumeroRegistre
        return parentAccountSuivi;
    }

    /**
     * Methode pour remplir la liste contact après une action faite sur la souscription
     * <p>
     * @param listContacts list de contacts
     * @return liste object suiviContact
     * */

    public static list<suiviObjects.SuiviContact> fillSuiviContact( list<Contact> listContacts){
        //create Contact section
        list<suiviObjects.SuiviContact> listRelatedContacts = new list<suiviObjects.SuiviContact>();

        for(Contact con : listContacts) {
            suiviObjects.SuiviContact currentContact = new suiviObjects.SuiviContact();
            currentContact.Nom = con.FirstName;
            currentContact.Prenom = con.LastName;
            currentContact.Email = con.Email;
            currentContact.Telephone1 = con.Phone;
            currentContact.IDContact = con.Id;
            if(con.CON_Role__c != null) {
                if(con.CON_Role__c.contains(';')) {
                    currentContact.Role = String.valueOf(con.CON_Role__c).split(';');
                } else {
                    currentContact.Role = new list<string> {String.valueOf(con.CON_Role__c)};
                }
            }
            //To Do
            //currentContact.Fonction

            listRelatedContacts.add(currentContact);
        }

        return listRelatedContacts;
    }

    /**
     * Methode pour remplir la l'objet cicuit après une action faite sur la souscription
     * <p>
     * @param sub l'abonnement
     * @return liste object SuiviCircuit
     * */

    public static SuiviObjects.SuiviCircuit fillSuiviCircuit(Zuora__Subscription__c sub, string boxNumber){
        //create circuit
        SuiviObjects.SuiviCircuit circuit = new SuiviObjects.SuiviCircuit();
        circuit.DateSouhaitee  = sub.CreatedDate.format('yyyy-MM-dd');
        circuit.SerialONT = boxNumber;

        return circuit;
    }
    /**
     * Methode pour remplir la l'objet site après une action faite sur la souscription
     * <p>
     * @param currentAccount cntenu du compte
     * @return liste object SuiviSite
     * */

    public static SuiviObjects.SuiviSite fillSuiviSite(Account currentAccount){
        //create circuit
        SuiviObjects.SuiviSite site = new SuiviObjects.SuiviSite();
        site.Addresse1 = currentAccount.BillingStreet;
        site.BuildingId = currentAccount.ACC_BuildingID__c;
        site.PTO = currentAccount.ACC_NumeroPTO_cc__c;
        // site.Etage = string.valueOf(currentAccount.ACC_NumeroDEtage__c);
        site.Escalier = currentAccount.ACC_Escalier__c;
        site.Porte = currentAccount.ACC_Porte__c;
        site.Nom = currentAccount.LastName;
        site.Prenom = currentAccount.FirstName;
        site.Ville = currentAccount.BillingCity;

        return site;
    }

    /**
     * Methode pour remplir la l'objet service après une action faite sur la souscription
     * <p>
     * @param uploadBw
     * @param downloadBW
     * @return liste object SuiviService
     * */

    public static SuiviObjects.SuiviService fillSuiviService(Zuora__Subscription__c sub, string uploadBw, string downloadBw){
        //create circuit
        SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
        service.IDSouscription = sub.Id;
        service.codeSouscription = sub.Zuora__SubscriptionNumber__c;
        service.BwUl = uploadBW;
        service.BwDl = downloadBw;

        return service;
    }

    /**
     * Methode pour remplir le champs SV_Details après la création d'une souscription
     * <p>
     * @param currentAccount compte,
     * @param listContacts liste de contact,
     * @param sub l'abonnement
     * @param parentAccount le compte chapeau
     * @param uploadBw
     * @param downloadBw
     * @return string
     * */

    public static string fillSuiviOnCreation(string boxNumber, Account currentAccount, list<Contact> listContacts, Zuora__Subscription__c sub, string uploadBw, string downloadBw){

        SuiviObjects.suiviDetails newSubSuivi = new SuiviObjects.suiviDetails();
        newSubSuivi.compte = fillSuiviAccount(currentAccount);
        if(currentAccount.ACC_ChampCompteParent__c != null) {
            newSubSuivi.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        newSubSuivi.contact = fillSuiviContact(listContacts);
        newSubSuivi.circuit = fillSuiviCircuit(sub, boxNumber);
        newSubSuivi.site = fillSuiviSite(currentAccount);
        newSubSuivi.service = fillSuiviService(sub, uploadBw, downloadBw);

        return JSON.serialize(newSubSuivi, true);

    }
    /**
     * Methode pour remplir le champs SV_Details après la résiliation d'une souscription
     * <p>
     * @param currentAccount le compte,
     * @param listContacts liste des contacts,
     * @param suivi suivi de souscription
     * @return string
     * */

    public static string fillSuiviResilier(Account currentAccount, list<Contact> listContacts, Suivi_de_Souscription__c suivi){
        SuiviObjects.suiviDetails resilierSubSuivi = new SuiviObjects.suiviDetails();
        resilierSubSuivi.compte = fillSuiviAccount(currentAccount);
        if(currentAccount.ACC_ChampCompteParent__c != null) {
            resilierSubSuivi.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        resilierSubSuivi.contact = fillSuiviContact(listContacts);

        /*if(suivi!=null)
           {
            SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
            service.DateSouhaitee  = suivi.CreatedDate.format('yyyy-MM-dd');
            service.referenceServiceGVAdmin = suivi.SV_Reference_Externe__c;
            resilierSubSuivi.service = service;
           }*/
        return JSON.serialize(resilierSubSuivi, true);

    }

    /**
     * Methode pour remplir le champs SV_Details après la suspension d'une souscription
     * <p>
     * @param currentAccount le compte,
     * @param listContacts liste des contacts,
     * @param suivi suivi de souscription
     * @return string
     * */

    public static string fillSuiviSuspendue(Account currentAccount, list<Contact> listContacts, Suivi_de_Souscription__c suivi){

        SuiviObjects.suiviDetails suspendSubSuivi = new SuiviObjects.suiviDetails();
        suspendSubSuivi.compte = fillSuiviAccount(currentAccount);
        if(currentAccount.ACC_ChampCompteParent__c != null) {
            suspendSubSuivi.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        suspendSubSuivi.contact = fillSuiviContact(listContacts);

        if(suivi != null) {
            SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
            service.referenceServiceGVAdmin = suivi.SV_Reference_Externe__c;
            suspendSubSuivi.service = service;
        }

        return JSON.serialize(suspendSubSuivi, true);

    }
    /**
     * Methode pour remplir le champs SV_Details après l'upgrade d'une souscription
     * <p>
     * @param currentAccount le compte,
     * @param listContacts liste des contacts,
     * @param suivi suivi de souscription
     * @param compteParent
     * @param uploadBw
     * @param downloadBw
     * @return string
     * */

    public static string fillSuiviUpgradeDowngrade(Account currentAccount, list<Contact> listContacts, Suivi_de_Souscription__c suivi,
                                                   string uploadBw, string downloadBw, string oldUploadBw, string oldDownloadBw){

        SuiviObjects.suiviDetails upgradeSubSuivi = new SuiviObjects.suiviDetails();
        upgradeSubSuivi.compte = fillSuiviAccount(currentAccount);
        if(currentAccount.ACC_ChampCompteParent__c != null) {
            upgradeSubSuivi.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        upgradeSubSuivi.contact = fillSuiviContact(listContacts);

        SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
        if(suivi != null) {
            service.referenceServiceGVAdmin = suivi.SV_Reference_Externe__c;
        }
        service.BwUl = uploadBw;
        service.BwDl = downloadBw;
        service.OldBwDl = oldUploadBw;
        service.OLDBwUl = oldDownloadBw;

        upgradeSubSuivi.service = service;

        return JSON.serialize(upgradeSubSuivi, true);

    }
    /**
     * Methode pour remplir le champs SV_Details après le demenagement
     * <p>
     * @param currentAccount le compte,
     * @param listContacts liste des contacts,
     * @param compteParent
     * @param uploadBw
     * @param downloadBw
     * @return string
     * */

    public static string fillSuiviDemenagement(Account currentAccount, list<Contact> listContacts,
                                               Zuora__Subscription__c sub, string uploadBw, string downloadBw){

        SuiviObjects.suiviDetails suiviDemenagement = new SuiviObjects.suiviDetails();
        suiviDemenagement.compte = fillSuiviAccount(currentAccount);
        if(currentAccount.ACC_ChampCompteParent__c != null) {
            suiviDemenagement.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        suiviDemenagement.contact = fillSuiviContact(listContacts);
        suiviDemenagement.service = fillSuiviService(Sub, uploadBw, downloadBw);
        suiviDemenagement.Site = fillSuiviSite(currentAccount);

        return JSON.serialize(suiviDemenagement, true);

    }

    /**
     * Methode pour remplir le champs SV_Details après l'echange de materiel'
     * <p>
     * @param currentAccount le compte,
     * @param listContacts liste des contacts,
     * @param suivi suivi de souscription
     * @param compteParent
     * @param boxNumber
     * @return string
     * */

    public static string fillSuiviEchange(Account currentAccount, list<Contact> listContacts, Suivi_de_Souscription__c suivi, string boxNumber){

        SuiviObjects.suiviDetails echangeSuivi = new SuiviObjects.suiviDetails();
        echangeSuivi.compte = fillSuiviAccount(currentAccount);

        if(currentAccount.ACC_ChampCompteParent__c != null) {
            echangeSuivi.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        echangeSuivi.contact = fillSuiviContact(listContacts);
        SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
        if(suivi != null) {
            service.referenceServiceGVAdmin = suivi.SV_Reference_Externe__c;

        }
        service.serialONT = boxNumber;
        //service.serialCPE=
        echangeSuivi.service = service;

        return JSON.serialize(echangeSuivi, true);

    }

/**
 * Methode pour remplir le champs SV_Details après un réabonnement
 * <p>
 * @param currentAccount le compte,
 * @param listContacts liste des contacts,
 * @param suivi suivi de souscription
 * @return string
 * */

    public static string fillSuiviRenew(Account currentAccount, list<Contact> listContacts, Suivi_de_Souscription__c suivi){

        SuiviObjects.suiviDetails renewSuivi = new SuiviObjects.suiviDetails();
        renewSuivi.compte = fillSuiviAccount(currentAccount);
        if(currentAccount.ACC_ChampCompteParent__c != null) {
            renewSuivi.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        renewSuivi.contact = fillSuiviContact(listContacts);

        if(suivi != null) {
            SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
            service.referenceServiceGVAdmin = suivi.SV_Reference_Externe__c;
            renewSuivi.service = service;
        }

        return JSON.serialize(renewSuivi, true);

    }
    /**
     * Methode pour remplir le champs SV_Details après la résiliation d'une souscription
     * <p>
     * @param currentAccount le compte,
     * @param listContacts liste des contacts,
     * @param suivi suivi de souscription
     * @return string
     * */

    public static string fillSuiviAdditionalProd(Account currentAccount, list<Contact> listContacts, Suivi_de_Souscription__c suivi){
        SuiviObjects.suiviDetails technicalSubSuivi = new SuiviObjects.suiviDetails();
        technicalSubSuivi.compte = fillSuiviAccount(currentAccount);
        if(currentAccount.ACC_ChampCompteParent__c != null) {
            technicalSubSuivi.compteChapeau = fillSuiviParentAccount(currentAccount);
        }
        technicalSubSuivi.contact = fillSuiviContact(listContacts);
        if(suivi != null) {
            SuiviObjects.SuiviService service = new SuiviObjects.SuiviService();
            service.DateSouhaitee  = suivi.CreatedDate.format('yyyy-MM-dd');
            service.referenceServiceGVAdmin = suivi.SV_Reference_Externe__c;
            technicalSubSuivi.service = service;
        }

        return JSON.serialize(technicalSubSuivi, true);

    }
}