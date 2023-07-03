/**
 * cette classe est utilisée pour gérer les erreurs reçues de l'interface
 */
public with sharing class AP01_ErreurInterface {
    /**
     * Méthode utilisée pour inserer une erreur lors d'une exception
     * @param type type de l'erreur DmlException, ListException, MathException,...
     * @param cause cause de l'erreur
     * @param line numéro de ligne d'où l'exception a été levée
     * @param message message d'erreur
     * @param recordId id de l'enregistrement sur lequel l'erreur est levée
     * @param methodName nom de la méthode où l'exception a été levée
     */
    public static Erreur_de_interface__c insertError(string type, string cause, integer line, string message, string recordId, string methodName){

        Erreur_de_interface__c erreur = new Erreur_de_interface__c ();
        erreur.EI_Date_Erreur__c  =  datetime.now();
        erreur.EI_Type__c = type;
        erreur.EI_La_Cause__c = cause;
        erreur.EI_Ligne__c = line;
        erreur.EI_Description__c = message;
        erreur.EI_ID_enregistrement__c = recordId;
        erreur.EI_Nom_du_methode__c = methodName;

        return erreur;

    }

}