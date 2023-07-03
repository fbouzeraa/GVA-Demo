public class VFC02_InvoiceController {
    ApexPages.standardController m_sc = null;

    public String pdfBase64 { get; private set; }
    public boolean showPdf { get; private set; }
    public PageReference pg { get; private set; }
    /*
     * Methode pour afficher le contenu de la facture en format PDF
     * */
    public VFC02_InvoiceController(ApexPages.standardController controller) {
        m_sc = controller;
        showPdf = false;

        Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=Facture.pdf');
        id recordId = ApexPages.currentPage().getParameters().get('id');
        // get invoice id of a sub
        list<Zuora__Subscription__c> sub = [ SELECT id, SUB_T_Original_InvoiceId__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                             FROM Zuora__Subscription__c
                                             WHERE id = :recordId
                                             OR (Zuora__Account__c = :recordId
                                                 AND Zuora__Status__c IN ('Active', 'Suspended')  AND Zuora__SubscriptionNumber__c like 'A-S%')
                                             ORDER BY Zuora__SubscriptionNumber__c DESC ];

        if(sub.size() > 0 && sub != null) {
            list<Zuora__ZInvoice__c> listInvoice = [SELECT Name, Zuora__ZuoraId__c
                                                    FROM Zuora__ZInvoice__c
                                                    WHERE Zuora__BillingAccount__c = :sub[0].Zuora__CustomerAccount__c
                                                    ORDER BY CreatedDate DESC];
            // in case of renew
            if(sub[0].Id == recordId) {
                string invoiceId;

                if(listInvoice.size() > 0 && listInvoice != null) {
                    if(invoiceId != listInvoice[0].Zuora__ZuoraId__c) {
                        invoiceId = listInvoice[0].Zuora__ZuoraId__c;
                    }
                    // get invoice of renew sub
                    pdfBase64 = EncodingUtil.Base64Encode(getInvoiceBody(invoiceId));
                    showPdf = true;
                } else {
                    showPdf = false;
                    pdfBase64 = system.label.Invoice_Id_Not_Found;
                }

            } else {

                if(sub[0].SUB_T_Original_InvoiceId__c == null) {

                    string invoiceId = getOriginalInvoiceId(sub[0].Id);
                    if(invoiceId == system.label.Invoice_Id_Not_Found) {
                        showPdf = false;
                        pdfBase64 = system.label.Invoice_Id_Not_Found;
                    } else {
                        // get invoice of original sub
                        pdfBase64 = EncodingUtil.Base64Encode(getInvoiceBody(invoiceId));
                        showPdf = true;
                    }
                } else {
                    // get original sub invoice Id
                    pdfBase64 = EncodingUtil.Base64Encode(getInvoiceBody(sub[0].SUB_T_Original_InvoiceId__c));
                    showPdf = true;
                }
            }
        } else {
            showPdf = false;
            pdfBase64 = system.label.Bill_Not_Found;
            /* blob invoiceNotFound= blob.toPdf(system.label.Bill_Not_Found);
               pdfBase64 = EncodingUtil.Base64Encode(invoiceNotFound);*/
        }
    }

    /**
     * methode pour envoyer le contenu de la facture par email
     * @param recordId id de l'enregistrement (abonnement ou compte)
     * @param fromAccount boolean pour indiquer si le bouton est sur le compte ou non
     * @return string statut de l'email envoyé
     */
    @RemoteAction
    public static string sendInvoiceByEmail(id recordId, Boolean fromAccount) {
        list<Zuora__Subscription__c> sub = [ SELECT Zuora__Account__r.PersonEmail, Id, SUB_T_Original_InvoiceId__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                             FROM Zuora__Subscription__c
                                             WHERE (id = :recordId AND SUB_T_Payment_Number__c != NULL)
                                             OR (Zuora__Account__c = :recordId AND Zuora__Status__c IN ('Active', 'Suspended') AND Zuora__SubscriptionNumber__c like 'A-S%')
                                             ORDER by Zuora__SubscriptionNumber__c DESC
        ];

        string invoiceId;
        if(sub != null && sub.size() != 0) {
            list<Zuora__ZInvoice__c> listInvoice = [SELECT Name, Zuora__ZuoraId__c
                                                    FROM Zuora__ZInvoice__c
                                                    WHERE Zuora__BillingAccount__c = :sub[0].Zuora__CustomerAccount__c
                                                    ORDER BY CreatedDate DESC];
            if(sub[0].Zuora__Account__r.PersonEmail != null) {
                //invoice of main sub
                if(fromAccount) {
                    if(sub[0].SUB_T_Original_InvoiceId__c == null) {
                        invoiceId = getOriginalInvoiceId(sub[0].Id);

                    } else {
                        invoiceId = sub[0].SUB_T_Original_InvoiceId__c;
                    }

                }
                //invoice of renewal
                else {
                    if(listInvoice.size() > 0 && listInvoice != null) {
                        invoiceId = listInvoice[0].Zuora__ZuoraId__c;
                    }

                }
                //define email fields
                string subject = System.label.Invoice_Email_Subject;
                string emailBody = System.label.Invoice_Email_Body;
                list<String> emails = new List<String> {
                    sub[0].Zuora__Account__r.PersonEmail
                };
                // define the email
                Messaging.singleemailmessage email = new Messaging.singleemailmessage();
                email.setPlainTextBody(emailBody);
                email.setToAddresses(emails);
                email.setSubject(subject);

                //attachment body as blob
                Blob pdfcontent = getInvoiceBody(invoiceId);

                //define attachment
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setFileName('Facture.pdf');
                attach.setBody(pdfcontent);

                List<Messaging.SingleEmailMessage> allMails = new List<Messaging.SingleEmailMessage>();
                allMails.add(email);

                for(Messaging.SingleEmailMessage oneMail : allMails) {
                    oneMail.setFileAttachments(new List<Messaging.EmailFileAttachment> { attach } );
                    Messaging.sendEmail( new List<Messaging.SingleEmailMessage> { oneMail });
                }

                return system.label.Email_Is_Sent;
            } else {
                return system.label.Empty_Email_Address; //email n'est pas saisie
            }
        } else {
            return system.label.Bill_Not_Found;
        }
    }
    public PageReference doCancel() {
        return m_sc.cancel();
    }

    /**
     * methode pour envoyer le contenu de la facture par email
     * @param recordId id de la facture
     * @param userEmail E-mail qui recevera la facture
     * @return string statut de l'email envoyé
     */
    @AuraEnabled(cacheable = true)
    public static string sendInvoiceByEmailFromInvoiceId(String invoiceId, String userEmail) {
        //define email fields
        string subject = System.label.Invoice_Email_Subject;
        string emailBody = System.label.Invoice_Email_Body;
        list<String> emails = new List<String> {
            userEmail
        };
        // define the email
        Messaging.singleemailmessage email = new Messaging.singleemailmessage();
        email.setPlainTextBody(emailBody);
        email.setToAddresses(emails);
        email.setSubject(subject);
        email.setSenderDisplayName('Canalbox');

        //attachment body as blob
        Blob pdfcontent = getInvoiceBody(invoiceId);

        //define attachment
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setFileName('Facture.pdf');
        attach.setBody(pdfcontent);

        List<Messaging.SingleEmailMessage> allMails = new List<Messaging.SingleEmailMessage>();
        allMails.add(email);

        for(Messaging.SingleEmailMessage oneMail : allMails) {
            oneMail.setFileAttachments(new List<Messaging.EmailFileAttachment> { attach } );
            Messaging.sendEmail( new List<Messaging.SingleEmailMessage> { oneMail });
        }

        return system.label.Email_Is_Sent;
    }

    /**
     * methode pour télécharger une facture
     * @param recordId id de la facture
     * @return PDF à base 64 à télécharger
     */
    @AuraEnabled(cacheable = true)
    public static string downloadPDFInvoice(String invoiceId) {
        Blob pdfcontent = getInvoiceBody(invoiceId);
        String base64Pdf = EncodingUtil.base64Encode(pdfcontent);

        return base64Pdf;
    }

    /**
     * Methode utilisée pour obtenir id du paiement.
     * <p>
     * @param subscriptionId Id de la souscription
     * @return payementId
     **/
    @AuraEnabled
    public static string getOriginalInvoiceId(id subscriptionId) {
        string invoiceId;
        //get payment number of a sub
        List<Zuora__Subscription__c> currentSub = [
            SELECT Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Name, SUB_T_Original_InvoiceId__c, Zuora__ServiceActivationDate__c
            FROM zuora__Subscription__c
            WHERE id = :subscriptionId AND Zuora__Status__c = 'Active'
        ];

        if(currentSub != null && currentSub.size() > 0) {
            // get all payment number of an account
            HttpResponse response = ZuoraManager.getAccountSummary(currentSub[0].Zuora__CustomerAccount__r.Zuora__Zuora_Id__c);
            ZuoraResponseObjects.ZuoraGetAccount getAccountInfoResponse = new ZuoraResponseObjects.ZuoraGetAccount();
            getAccountInfoResponse = (ZuoraResponseObjects.ZuoraGetAccount) JSON.deserialize(
                response.getBody(), ZuoraResponseObjects.ZuoraGetAccount.class);
            if(getAccountInfoResponse.success) {
                for(ZuoraResponseObjects.ZuoraPayment zpayment : getAccountInfoResponse.payments) {
                    //check if the founded payment effective date is the activation date of the current sub
                    if(zpayment.effectiveDate == string.valueOf(currentSub[0].Zuora__ServiceActivationDate__c)) {
                        for(ZuoraResponseObjects.ZuoraPaymentInvoice paymentInvoice : zpayment.paidInvoices) {
                            //get invoice id of invoice on which the payment is applied
                            invoiceId = paymentInvoice.invoiceId;
                            break;
                        }
                        break;
                    }
                }
            }
        }
        if(invoiceId != null) {
            return invoiceId;
        } else {
            return system.label.Invoice_Id_Not_Found; //il n'existe pas un reabo
        }
    }
    /**
     * methode pour obtenir le contenu de la facture
     * <p>
     * @param invoiceId id de la facture
     * @return appel API
     * */
    public static blob getInvoiceBody(string invoiceId) {
        string response = ZuoraManager.getInvoiceBody(invoiceId).getBody();
        ZuoraResponseObjects.ZuoraInvoices invoiceResponse = new ZuoraResponseObjects.ZuoraInvoices();
        invoiceResponse = (ZuoraResponseObjects.ZuoraInvoices) JSON.deserialize(
            response, ZuoraResponseObjects.ZuoraInvoices.class);

        return invoiceResponse.Body;
    }
}