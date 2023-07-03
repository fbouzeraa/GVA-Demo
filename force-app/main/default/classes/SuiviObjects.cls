/**
 * Classe permettant de définir les Objets Apex correspondant aux objets Suivi utilisés pour
 * effectuer les appels API.
 *
 * Chaque Objet Apex présent dans la classe correspondera à un Objet de Suivi et chaque Propriété Apex correspond à un
 * champ dans l'Objet
 *
 * @author Maroun Yazbeck
 * @date 1 Mars 2021
 */
global class SuiviObjects {
    public static String post = 'POST';
    public static String put = 'PUT';
    public static String get = 'GET';

    public class SuivisListRequest {
        public List<String> Actions;  // Liste des Code Actions à filtrer
        public List<String> Pays;  // Liste des ISO Code des Pays à filtrer

    }

    public class SouscriptionListRequest {
        // Liste des Codes des Souscriptions à filtrer
        public List<String> CodeSouscription;
        // Liste des IDs des Souscriptions à filtrer
        public List<String> Compte;
        // Liste des Statut à filtrer
        public List<String> Statut;
        // Liste des Pays à filtrer
        public List<String> Pays;

    }

    public class SuivisDetailsRequest {
        public list<String> ID;    // ID ligne de Suivi
    }

    public class SuivisUpdateRequest {
        public String ID;    // ID ligne de Suivi
        public String Referenceexterne;
    }

    global class SuiviUpdateResponse {
        public Suivi_de_Souscription__c UpdatedSuivi;
        public boolean Success;
        public List<String> Errors;
    }

    public class SuiviClient {
        public string FilialeGVA;
        public string Nom;
        public string Prenom;
        public string Categorie;
        public string NumeroRegistre;
        public string NumeroFiscal;
        public string IDCompte;
        public string CodeCompte;
    }

    public class SuiviContact {
        public string Nom;
        public string Prenom;
        public string Email;
        public string Telephone1;
        public string Telephone2;
        public string Fonction;
        public string IDContact;
        public list<string> Role;
    }
    public class SuiviSite {
        public string Label;
        public string Nom;
        public string Prenom;
        public string Addresse1;
        public string Addresse2;
        public string CodePostal;
        public string Ville;
        public string BuildingId;
        public string Residence;
        public string Batiment;
        public string Escalier;
        public string Etage;
        public string Porte;
        public string PTO;
    }
    public class SuiviCircuit {

        public string SerialONT;
        public string SerialCPE;
        public string DateSouhaitee;
    }

    public class SuiviService {
        public string ReferenceServiceGVAdmin;
        public string ReferenceGVAAdmin;
        public string ReferenceTypeOption;
        public string ReferenceOption;
        public string DateSouhaitee; // pour action de resiliation et ajout d'option
        public string BwDl;
        public string BwUl;
        public string OldBwDl;
        public string OLDBwUl;
        public string SerialONT;
        public string SerialCPE; // pour les companies
        public string IDSouscription;
        public string CodeSouscription;

    }
    public class suiviDetails {
        public string Id;
        public SuiviClient Compte;
        public SuiviClient CompteChapeau;
        public list<SuiviContact> Contact;
        public SuiviSite Site;
        public SuiviCircuit Circuit;
        public SuiviService Service;

    }
    public class suiviDetailsResponse {
        public string Id;
        public string IDSouscription;
        public string codeSouscription;
        public string StatutSouscription;
        public SuiviClient Compte;
        public SuiviClient CompteChapeau;
        public list<SuiviContact> Contact;
        public SuiviSite Site;
        public SuiviCircuit Circuit;
        public SuiviService Service;
        public boolean Success;
        public string ModeDePaiement;
    }
    public class suiviDetailsError {
        public string Id;
        public boolean Success;
        public List<String> Errors;
    }

}