public with sharing class MesOffresController {
   


    @AuraEnabled(cacheable=true)
    public static string sendGeneralSalesConditionsByEmail(String userEmail, String gscStaticRessourceName) {

        //define email fields
        string subject = System.label.GENERAL_SALES_CONDITIONS_EMAIL_SUBJECT;
        string emailBody = System.label.GENERAL_SALES_CONDITIONS_EMAIL_BODY;
        list<String> emails = new List<String>{
          userEmail
        };
        // define the email
        Messaging.singleemailmessage email = new Messaging.singleemailmessage();
        email.setPlainTextBody(emailBody);
        email.setToAddresses(emails);
        email.setSubject(subject);
        email.setSenderDisplayName('Canalbox');


        //attachment body as blob
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = :gscStaticRessourceName LIMIT 1];
        Blob pdfcontent =  sr.body; 

        //define attachment
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setFileName('Condition-Generales-Abonnement-CanalBox.pdf');
        attach.setBody(pdfcontent);

        List<Messaging.SingleEmailMessage> allMails = new List<Messaging.SingleEmailMessage>();
        allMails.add(email);

        for (Messaging.SingleEmailMessage oneMail : allMails) {
           oneMail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attach } );
            Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{ oneMail });
        }
        return System.label.Email_Is_Sent;
    }
}