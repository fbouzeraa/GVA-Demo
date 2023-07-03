/*
 * Classe Queue pour envoyer les rapport de caisse au utilisateurs
 */
global class QueueFund implements Queueable, Database.AllowsCallouts {
    List<user> listUsers;

    public QueueFund(List<user> listUsers){
        this.listUsers = listUsers;
    }
    /**
     * Method to execute the queue over list of suivi records
     */
    public void execute(QueueableContext context) {
        if(listUsers != null && listUsers.size() > 0) {
            list<ZuoraObjects.ZuoraWorkflow> listFundReport = new list<ZuoraObjects.ZuoraWorkflow>();

            for(user currentUser : listUsers) {
                //Prepare report request

                ZuoraObjects.ZuoraWorkflow fundReport = new ZuoraObjects.ZuoraWorkflow();
                fundReport.Distributor = currentUser.USR_DistributeurID__c;
                fundReport.ReceipientEmail = currentUser.Email;
                if(currentUser.CountryCode == 'CD') {
                    fundReport.ManageHomeCurrency = true;
                } else {
                    fundReport.ManageHomeCurrency = false;
                }

                listFundReport.add(fundReport);

            }

            if(listFundReport.size() > 0 && listFundReport != null) {
                System.debug('Batch Fund Report executing for ' + listFundReport.size() + ' records');
                for(ZuoraObjects.ZuoraWorkflow report : listFundReport) {
                    HttpResponse response = ZuoraManager.getWorkflowInfo(System.label.rapport_De_Caisse_Id, report);
                    ZuoraResponseObjects.ZuoraWorkflowResponse reportResponse = (ZuoraResponseObjects.ZuoraWorkflowResponse) JSON.deserialize(
                        response.getBody(), ZuoraResponseObjects.ZuoraWorkflowResponse.class);
                    system.debug(report.ReceipientEmail);
                    system.debug(response.getBody());
                    // check response if succeeded or not
                    /*  if(response.getStatusCode() != 200) {
                          system.debug('Erreur dans le Batch ' + reportResponse.errors[0].title);
                       } else {
                          system.debug(System.label.Rapport_De_Caisse_Success_Message);
                       }*/
                }
            }
        }
    }
}