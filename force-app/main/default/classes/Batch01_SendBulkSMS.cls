/*
 * Classe Batch pour créer des envoyer des SMS aux cibles eligibles
 */
global class Batch01_SendBulkSMS implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, CampaignId, FirstName, LastName, MobilePhone,contact.Account.billingCity,contact.AccountId,contact.Account.ACC_Indicatif__c, contact.Account.ACC_Tech_PersonMobile__c, contact.Account.BillingCountryCode ' +
                                        'FROM CampaignMember ' +
                                        'WHERE CMB_SMS_Envoye__c = false AND (MobilePhone != null OR contact.Account.ACC_Tech_PersonMobile__c != null)');
    }

    global void execute(Database.BatchableContext bc, List<CampaignMember> records){

        if(records != null && records.size() > 0)
        {
            list<Schema.FieldSetMember> listBodyParameters = SObjectType.Zuora__Subscription__c.FieldSets.getMap().get('Parameters_Mapping').getFields();
            // map the call center to the country
            list<Call_Center_Number__mdt> listCallCenters =  Call_Center_Number__mdt.getAll().values();
            Map<string, string> mapCountryCallCenterNumber = new Map<string, string>();
            for(Call_Center_Number__mdt callCenter : listCallCenters) {
                mapCountryCallCenterNumber.put(callCenter.country__c, callCenter.Phone_Number__c);
            }

            // get all Campaigns
            set<id> setCampaignId = new set<id>();
            set<id> setAccountId = new set<id>();
             Map<Id, String> CampaignMemberToAccountMap = new Map<Id, String>();
            for(CampaignMember member : records) {
                setCampaignId.add(member.CampaignId);
                setAccountId.add(member.contact.AccountId);
                CampaignMemberToAccountMap.put(member.Id,member.contact.AccountId);
            }

            // Try to find if a metadata configuration exists for the CampaignId
            List<Conquete_SMS__mdt> conqueteSMS = [ SELECT Campaign_ID__c, Body__c
                                                    FROM Conquete_SMS__mdt
                                                    WHERE Campaign_ID__c IN :setCampaignId];

            // Get Subscriptions related to the existing accounts
            string query = 'SELECT ';
            for(Schema.FieldSetMember field : listBodyParameters) {
                query += field.getFieldPath() + ', ';
            }
            query += 'Id,Zuora__Account__c FROM Zuora__Subscription__c WHERE Zuora__Account__c IN: setAccountId  AND Type__c = \'Standard\' ';
            List<Zuora__Subscription__c> listSub = Database.query(query);

            // put each account with its related subscription
            map<Id, Zuora__Subscription__c> accountToSubscriptionMap = new map<Id, Zuora__Subscription__c>();
            if(listSub != null && listSub.size() > 0) {
                for(Zuora__Subscription__c sub : listSub) {
                    accountToSubscriptionMap.put(sub.Zuora__Account__c, sub);
                }
            }

            // put each text message with its related campaign
            map<Id, string> campaignToTextBodyMap = new map<Id, string>();
            for(Conquete_SMS__mdt conquete : conqueteSMS) {
                campaignToTextBodyMap.put(conquete.Campaign_ID__c, conquete.Body__c);
            }

            // Map to link Mobile Phone to Campaign Member to mark as SMS sent
            Map<string, Id> phoneToCampaignMemberMap = new Map<string, Id>();
            Map<Id, String> campaignMemberToCampaignMap = new Map<Id, String>();
           

            // Map to link sms target by country to Campaign
            map<String, list<SMSObjects.SMSTarget>> campaignToTargetMap = new map<String, list<SMSObjects.SMSTarget>>();

            // group sms target by campaign and by country
            for(campaignMember member : records) {
     
                List<SMSObjects.SMSTarget> targets = new List<SMSObjects.SMSTarget>();

                if(campaignToTargetMap.containsKey(member.contact.Account.BillingCountryCode+'_'+member.CampaignId)) {
                    targets = campaignToTargetMap.get(member.contact.Account.BillingCountryCode+'_'+member.CampaignId);
                }

                SMSObjects.SMSTarget target = new SMSObjects.SMSTarget();

                target.mobilePhone = member.contact.Account.ACC_Tech_PersonMobile__c;
                // Param1 represent the area
                target.PARAM_1 = member.contact.Account.billingCity;
                // Param 4 respresent le numéro du call center
                target.PARAM_4 = mapCountryCallCenterNumber.get(member.contact.Account.BillingCountryCode);

                if(accountToSubscriptionMap != null) {
                    Zuora__Subscription__c sub = accountToSubscriptionMap.get(member.contact.AccountId);
                    // Param2 represent the expected renewal date
                    target.PARAM_2 = sub == null?null : date.valueOf(sub.get(listBodyParameters[1].getFieldPath()));
                    // Param3 reprensent the router number
                    target.PARAM_3 = sub == null?null : string.valueOf(sub.get(listBodyParameters[2].getFieldPath()));

                    if(accountToSubscriptionMap.get(member.contact.AccountId) != null)
                    {
                        if(date.valueOf(accountToSubscriptionMap.get(member.contact.AccountId).get(listBodyParameters[1].getFieldPath())) < date.today())
                        {
                            Integer numberDaysDue = date.valueOf(accountToSubscriptionMap.get(member.contact.AccountId).get(listBodyParameters[1].getFieldPath())).daysBetween(date.today());
                            if(numberDaysDue < 31) {
                                target.PARAM_5 = system.label.days_due;
                            } else if(numberDaysDue < 85) {
                                target.PARAM_5 = system.label.weeks_due;
                            } else {
                                target.PARAM_5 = system.label.months_due;
                            }
                        }
                    }
                }
                targets.add(target);

                phoneToCampaignMemberMap.put(member.contact.Account.ACC_Tech_PersonMobile__c, member.Id);
                campaignMemberToCampaignMap.put(member.Id, member.contact.Account.BillingCountryCode+'_'+member.campaignId);
                campaignToTargetMap.put(member.contact.Account.BillingCountryCode+'_'+member.CampaignId, targets);
                
            }

            list<SMSObjects.SMSRequest> listRequest = new list<SMSObjects.SMSRequest>();

            //create request for each country campaign
            for(list<SMSObjects.SMSTarget> target : campaignToTargetMap.values())
            {
                string campID = campaignMemberToCampaignMap.get(phoneToCampaignMemberMap.get(target[0].mobilePhone)).substringAfter('_');
                System.debug('campID'+ campID);
                string countryCodeValue = campaignMemberToCampaignMap.get(phoneToCampaignMemberMap.get(target[0].mobilePhone)).substringBefore('_');
                SMSObjects.SMSRequest smsRequest = new SMSObjects.SMSRequest();
                SMSObjects.SMSData smsData = new SMSObjects.SMSData();

                // replace the default Site  on the custom metadata body by the specifique Site of the current country
                if(!Test.isRunningTest() && campaignToTextBodyMap.get(campId) != null){
                    smsData.MESSAGE = campaignToTextBodyMap.get(campId).replace(System.Label.Site_Campaign_SMS_BF, System.Label.Site_Campaign_SMS+countryCodeValue.toLowerCase());
                }
                smsData.SMS = target;
                smsData.DYNAMIC = '5';
                smsData.TPOA = System.label.SMS_Sender;
                smsData.DATE_Reserved = string.valueOf(datetime.now());

                smsRequest.DATA = smsData;

                system.debug('smsData.MESSAGE '+smsData.MESSAGE);
                listRequest.add(smsRequest);
            }

            Set<CampaignMember> updatedMembers = new Set<CampaignMember>();
            List<CampaignMember> listOfUpdatedMembers = new List<CampaignMember>();
			List<Log__c> listLog = new List<Log__c>();
            String username = System.label.ALLMYSMS_UserName;
            String password = System.label.ALLMYSMS_AUTH_TOKEN;
            Blob headerValue = Blob.valueOf(username + ':' + password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            for(SMSObjects.SMSRequest req : listRequest) {
                HTTPResponse response = SMSManager.doCallout(SMSObjects.smsBulkAPIUrl, EncodingUtil.urlEncode(JSON.serialize(req), 'UTF-8'));
                if(response != null && !String.isBlank(response.getBody())) {
                    SMSObjects.SMSBulkResponse bulkResponse = (SMSObjects.SMSBulkResponse) System.JSON.deserialize(response.getBody(), SMSObjects.SMSBulkResponse.class);
                    if(bulkResponse != null && (bulkResponse.status == 100 || bulkResponse.status == 101)) {
                        for(SMSObjects.SmsIds sms : bulkResponse.smsIds) {
                            //
                            if(phoneToCampaignMemberMap.get(sms.phoneNumber) != null) {
                                CampaignMember sentMember = new CampaignMember();
                                sentMember.Id = phoneToCampaignMemberMap.get(sms.phoneNumber);
                                sentMember.CMB_SMS_Envoye__c = true;
                                
                                HttpRequest request = new HttpRequest();
                                request.setEndpoint('callout:All_My_Sms/webhook/');
                                request.setHeader('Authorization', authorizationHeader);
                                request.setHeader('cache-control', 'no-cache');
                                request.setMethod('GET');
                                Http http1 = new Http();
                                HTTPResponse response1 = http1.send(request);
                                if(response1.getStatusCode()==200){
                                    sentMember.CAM_accuse_de_reception_SMS__c=true;
                                }
                                System.debug('response1'+response1.getBody());
                                System.debug('getStatusCode'+response1.getStatusCode());
                                System.debug('getStatusCode'+response1.getStatus());
                                
                                
                                updatedMembers.add(sentMember);
                            }

                            
                        }
                    } else {
                        System.debug('Erreur dans le Batch ' + String.valueOf(bulkResponse.status) + ' ' + bulkResponse.statusText);
                    }
                }
                Id CampaignId = campaignMemberToCampaignMap.get(phoneToCampaignMemberMap.get(req.DATA.SMS[0].MOBILEPHONE)).substringAfter('_');
                string countryCode = campaignMemberToCampaignMap.get(phoneToCampaignMemberMap.get(req.DATA.SMS[0].mobilePhone)).substringBefore('_');
                Log__c lg =createSMSLog(JSON.serialize(req),CampaignId, countryCode,'/sendSms/',response.getBody(), (response.getStatusCode() == 100 || response.getStatusCode() == 101)?true : false, null, SMSObjects.get);
                listLog.add(lg);
            }
            system.debug('Size of members to be updated ' + updatedMembers.size());
            if(updatedMembers.size() > 0) {
                listOfUpdatedMembers.addAll(updatedMembers);
                update listOfUpdatedMembers;
                //insert listLog;
            }
			if(listLog.size() > 0) {
                insert listLog;
            }
        }
    }

        public static Log__c createSMSLog(string body, Id IDCampaign,String CountryCode, string URL,
                                         string reponse, boolean success, string reason, string type){

        Log__c newLog = new Log__c();
        newLog.LG_Body__c = body;
        newLog.LG_Campaign__c = IDCampaign;
        newLog.LG_Method_URL__c = URL;
        newLog.LG_Response__c = reponse;
        newLog.LG_Interface__c = 'ALLMYSMS';
        newLog.LG_Success__c = success;
        newLog.LG_Error_Message__c = reason;
        newLog.LG_Method_Type__c = type;
        newLog.LG_CountryCode__c= CountryCode;                                   

        return newLog;
    }
    
    global void finish(Database.BatchableContext bc){}
}
                    // 100  Succès
                    // 101  Le message a été programmé pour un envoi différé
                    // 102	Problème de connexion - Aucun compte ne correspond aux clientcode et apiKey spécifiés
                    // 104	Crédit insuffisant pour traiter cet envoi.A utiliser: XX Crédits, Disponibles: YY Crédits.Veuillez recréditer
                    // votre compte sur AllMySMS.com
                    // 105	Flux JSON vide
                    // 110	URL du fichier vocal vide
                    // 111  Date d’envoi mal formattée
                    // 112	Numéro d’expéditeur invalide
                    // 113  Fichier vocal invalide.Formats acceptés: WAV ou MP3
                    // 114  Aucun numéro de téléphone valide
                    // 115  Taille du fichier vocal incorrect (doit être comprise entre 1Ko et 5Mo)
                    // 116  Durée du fichier vocal invalide (doit être comprise entre 5 et 35 secondes)
                    // 121	Requête rejetée car une requête identique a été envoyée dans un laps de temps de moins de 10 secondes .