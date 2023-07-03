@isTest
global class ZuoraMock2 implements HttpCalloutMock {
    public boolean error = false;
    public boolean catchError = false;
    public Integer statusCode;

    public ZuoraMock2(){
        this.error = false;
        this.statusCode = 200;
    }

    public ZuoraMock2(boolean error, boolean catchError, Integer statusCode){
        this.error = error;
        this.catchError = catchError;
        this.statusCode = statusCode;
    }

    global HttpResponse respond(HTTPRequest request){
        String requestType = request.getEndpoint();
        HttpResponse response = new HttpResponse();
        response.setStatusCode(this.statusCode);
        response.setHeader('Content-Type', 'application/json');
        try {
            if(requestType.contains(ZuoraObjects.accountAPIUrl) && !requestType.contains(ZuoraObjects.billAPIUrl) && requestType.contains('summary') && this.statusCode == 200) {
                response.setBody('{"basicInfo": {"id": "8adce421778c21530177ab42b8e67be2","name": "Distributeur Un (shadow / technique)","accountNumber": "A00000650","balance": -60000,"lastInvoiceDate": "2021-02-17","lastPaymentDate": "2021-02-17","lastPaymentAmount": 200000,"currency": "XAF","status": "Active","batch": "Batch1","billCycleDay": 1,"invoiceDeliveryPrefsPrint": false,"invoiceDeliveryPrefsEmail": false,"Threshold1NotificationStatus__c": null,"DistributorID__c": null,"Threshold0Amount__c": null,"Type__c": null, "DateOfBirth__c": null,"Threshold1Amount__c": null,"Threshold0NotificationStatus__c": null,"Segment__c": null,"Company__c": null,"IdentificationType__c": null,"IdentificationNumber__c": null,"defaultPaymentMethod": null},' +
                                 '"billToContact": {"id": "8adce421778c21530177ab42b8f37be3","firstName": "Distributeur","lastName": "Shadow","address1": "","address2": "","city": "","county": "","state": "","zipCode": "","country": "Togo","workEmail": "","workPhone": "","taxRegion": "","fax": "" },"soldToContact": {"id": "8adce421778c21530177ab42b8f37be3","firstName": "Distributeur","lastName": "Shadow","address1": "","address2": "","city": "","county": "","state": "","zipCode": "","country": "Togo","workEmail": "","workPhone": "","taxRegion": "","fax": ""},"taxInfo": {"exemptStatus": "No","exemptCertificateId": "","exemptCertificateType": "","exemptIssuingJurisdiction": "","exemptEffectiveDate": null,"exemptExpirationDate": null,"exemptDescription": "","exemptEntityUseCode": "","companyCode": null,"VATId": ""},' +
                                 '"subscriptions": [{"id": "8adc8f99778c0f580177ab90023e56e2","subscriptionNumber": "A-S00000479","ratePlans": [{"productId": "8adc8f99778c0f580177ab3325e449e8","productName": "Distributeur","productSku": "SKU-00000010","productRatePlanId": "8adce421778c21530177ab38d2506f4d","ratePlanName": "Utilisation du crédit"}],"subscriptionStartDate": "2021-02-16","initialTerm": null,"autoRenew": false,"renewalTerm": null,"termStartDate": "2021-02-16","termEndDate": null,"status": "Active","termType": "EVERGREEN","QuoteNumber__QT": null,"QuoteBusinessType__QT": null,"BoxNumber__c": null,"OpportunityName__QT": null,"RenewalSequenceNumber__c": "0","CompensationDaysAtNextRenewal__c": null,"ExpectedRenewalDate__c": null,"Version__c": null,"CancelReason__c": null,"OpportunityCloseDate__QT": null,"Type__c": "Standard","CpqBundleJsonId__QT": null,"SF_QuoteID__c": null,"QuoteType__QT": null}],' +
                                 '"invoices": [{"id" : "8adccabd778c0f1d0177af4b53f20854", "invoiceNumber" : "INV00000013", "invoiceDate" : "2021-02-17", "dueDate" : "2021-02-17", "amount" : 15000, "balance" : 45000, "status" : "Posted"}],"payments": [{"id": "8adc9dee778c0f5d0177af491abc64e5","paymentType": "External", "status": "Processed","paymentNumber": "P-00000014","effectiveDate": "2021-02-17","paidInvoices": [{"invoiceId": "8adca0eb778c0ef70177ab93736b7472","invoiceNumber": null,"appliedPaymentAmount": 50000}]},{"id": "8adcd9eb778c215b0177ab44078468f5","paymentType": "External","status": "Processed","paymentNumber": "P-00000014","effectiveDate": "2021-02-16","paidInvoices": [{"invoiceId": "8adca0eb778c0ef70177ab93736b7472","invoiceNumber": "INV00000190","appliedPaymentAmount": 30000}]}],"usage": [{"unitOfMeasure": "Each","startDate": "2021-02","quantity": 105000}],"success": true}');

                return response;
            } else if(requestType.contains(ZuoraObjects.paymentAPIUrl) && this.statusCode == 200) {
                response.setBody('{"success": true, "id" : "8adcd9eb778c215b0177ab44078468f5","number":"P-00000014","status":"Processed","type":"External","accountId" : "8adc9a417678e8fa01767cb041332a2e","amount" : 58.000000000,"appliedAmount" : 0.000000000,"unappliedAmount" ' +
                                 ': 580000.00,"refundAmount" : 0.000000000,"creditBalanceAmount" : 0.000000000,"currency" : "XAF","effectiveDate" : "2020-12-21","comment" : null,"paymentMethodId" : "8adcd9eb73a431970173a5b2f4707dc7","paymentMethodSnapshotId" : null,' +
                                 '"authTransactionId" : null,"bankIdentificationNumber" : null,"gatewayId" : null,"gatewayOrderId" : null,"gatewayResponse" : null,"gatewayResponseCode" : null,"gatewayState" : "NotSubmitted","markedForSubmissionOn" : null,"referenceId" : ' +
                                 'null,"secondPaymentReferenceId" : null,"softDescriptor" : null,"softDescriptorPhone" : null,"submittedOn" : null,"settledOn" : null,"cancelledOn" : null,"createdDate" : "2020-12-21 13:17:45","createdById" : "8adcd9eb759733000175b780b0eb1df7",' +
                                 '"updatedDate" : "2020-12-21 13:17:45","updatedById" : "8adcd9eb759733000175b780b0eb1df7","OperatorAgent__c" : null,"SourceOperator__c" : null,"Source__c" : null,"financeInformation" : {"bankAccountAccountingCode" : "Check","bankAccountAccountingCodeType"' +
                                 ' : "Cash","unappliedPaymentAccountingCode" : "Payment en Attente application","unappliedPaymentAccountingCodeType" : "CustomerCashOnAccount","transferredToAccounting" : "No"}}');

                return response;
            } else if(requestType.contains(ZuoraObjects.invoiceAPIUrl)) {
                response.setBody('{"InvoiceDate": "2021-01-10","TaxExemptAmount": 0,"UpdatedDate": "2021-10-20T05:45:45.000+02:00","CreditBalanceAdjustmentAmount": 0,"Status": "Posted","TargetDate": "2016-10-20","AccountId": "8adcba9c772d2f6b01772fca700b4544","IncludesOneTime": true,"InvoiceNumber": "INV00000002","UpdatedById": "2c93808457d787030157e031bb3f4aa5","PaymentAmount": 0,"Id": "2c93808457d787030157e031d86c4c57", "paymentNumber" : "P-00000014","TaxAmount": 0,"IncludesUsage": true,' +
                                 '"CreatedById": "2c93808457d787030157e031bb3f4aa5","CreatedDate": "2021-10-20T05:45:45.000+02:00","Body": "JVBERi0xLjUNCjQgADWQJHQNCiUlRU9GDQo=","Amount": 23.92,"Balance": 23.92,"RefundAmount": 0,"AmountWithoutTax": 23.92,"AdjustmentAmount": 0,"PostedBy": "2c93808457d787030157e031bb3f4aa5","DueDate": "2021-01-10","IncludesRecurring": true,"success" : true}');

                return response;
            } else if(requestType.contains(ZuoraObjects.tokenAPIUrl))  {
                response.setBody('{"access_token": "c652cbc0ea384b9f81856a93a2a74538","token_type": "bearer","expires_in": 3599,"scope": "user.7c4d5433dc234c369a01b9719ecd059f entity.1a2b7a37-3e7d-4cb3-b0e2-883de9e766cc entity.c92ed977-510c-4c48-9b51-8d5e848671e9 service.echo.read tenant.19","jti": "c652cbc0ea384b9f81856a93a2a74539"}');

                return response;
            } else if(requestType.contains(ZuoraObjects.accountAPIUrl) && !requestType.contains(ZuoraObjects.billAPIUrl) && requestType.contains('summary') && this.statusCode == 200) {
                response.setBody('{"basicInfo": {"id": "8adce421778c21530177ab42b8e67be2","name": "Distributeur Un (shadow / technique)","accountNumber": "A00000650","balance": -60000,"lastInvoiceDate": "2021-02-17","lastPaymentDate": "2021-02-17","lastPaymentAmount": 200000,"currency": "XAF","status": "Active","batch": "Batch1","billCycleDay": 1,"invoiceDeliveryPrefsPrint": false,"invoiceDeliveryPrefsEmail": false,"Threshold1NotificationStatus__c": null,"DistributorID__c": null,"Threshold0Amount__c": null,"Type__c": null, "DateOfBirth__c": null,"Threshold1Amount__c": null,"Threshold0NotificationStatus__c": null,"Segment__c": null,"Company__c": null,"IdentificationType__c": null,"IdentificationNumber__c": null,"defaultPaymentMethod": null},' +
                                 '"billToContact": {"id": "8adce421778c21530177ab42b8f37be3","firstName": "Distributeur","lastName": "Shadow","address1": "","address2": "","city": "","county": "","state": "","zipCode": "","country": "Togo","workEmail": "","workPhone": "","taxRegion": "","fax": "" },"soldToContact": {"id": "8adce421778c21530177ab42b8f37be3","firstName": "Distributeur","lastName": "Shadow","address1": "","address2": "","city": "","county": "","state": "","zipCode": "","country": "Togo","workEmail": "","workPhone": "","taxRegion": "","fax": ""},"taxInfo": {"exemptStatus": "No","exemptCertificateId": "","exemptCertificateType": "","exemptIssuingJurisdiction": "","exemptEffectiveDate": null,"exemptExpirationDate": null,"exemptDescription": "","exemptEntityUseCode": "","companyCode": null,"VATId": ""},' +
                                 '"subscriptions": [{"id": "8adc8f99778c0f580177ab90023e56e2","subscriptionNumber": "A-S00000479","ratePlans": [{"productId": "8adc8f99778c0f580177ab3325e449e8","productName": "Distributeur","productSku": "SKU-00000010","productRatePlanId": "8adce421778c21530177ab38d2506f4d","ratePlanName": "Utilisation du crédit"}],"subscriptionStartDate": "2021-02-16","initialTerm": null,"autoRenew": false,"renewalTerm": null,"termStartDate": "2021-02-16","termEndDate": null,"status": "Active","termType": "EVERGREEN","QuoteNumber__QT": null,"QuoteBusinessType__QT": null,"BoxNumber__c": null,"OpportunityName__QT": null,"RenewalSequenceNumber__c": "0","CompensationDaysAtNextRenewal__c": null,"ExpectedRenewalDate__c": null,"Version__c": null,"CancelReason__c": null,"OpportunityCloseDate__QT": null,"Type__c": "Standard","CpqBundleJsonId__QT": null,"SF_QuoteID__c": null,"QuoteType__QT": null}],' +
                                 '"invoices": [{"id": "8adccabd778c0f1d0177af4b53f20854","invoiceNumber": "INV00000013","invoiceDate": "2021-02-17","dueDate": "2021-02-17","amount": 15000,"balance": 0,"status": "Posted"},{ "id": "8adca0eb778c0ef70177ab93736b7472","invoiceNumber": "INV00000013","invoiceDate": "2021-02-16","dueDate": "2021-02-16","amount": 30000,"balance": 0,"status": "Posted"}],"payments": [{"id": "8adc9dee778c0f5d0177af491abc64e5","paymentType": "External", "status": "Processed","paymentNumber": "P-00000014","effectiveDate": "2021-02-17","paidInvoices": [{"invoiceId": "8adca0eb778c0ef70177ab93736b7472","invoiceNumber": null,"appliedPaymentAmount": 50000}]},{"id": "8adcd9eb778c215b0177ab44078468f5","paymentType": "External","status": "Processed","paymentNumber": "P-00000014","effectiveDate": "2021-02-16","paidInvoices": [{"invoiceId": "8adca0eb778c0ef70177ab93736b7472","invoiceNumber": "INV00000190","appliedPaymentAmount": 30000}]}],"usage": [{"unitOfMeasure": "Each","startDate": "2021-02","quantity": 105000}],"success": true}');

                return response;
            } else if(requestType.contains(ZuoraObjects.subscriptionAPIUrl)) {
                response.setBody('{"success": true,"id": "8adcba9c79d4be560179d5fd204e4ac3","accountId": "8adcfb5079d4d5350179d5aae8c26ada","accountNumber": "A00000966","accountName": "Test 2 UP/DOWN","subscriptionNumber": "A-S00000657","termType": "EVERGREEN","invoiceSeparately": false,"contractEffectiveDate": "2021-06-04","serviceActivationDate": "2021-06-04","customerAcceptanceDate": "2021-06-04","subscriptionStartDate": "2021-06-04","autoRenew": false,"renewalSetting": "RENEW_WITH_SPECIFIC_TERM","renewalTerm": null,"renewalTermPeriodType": "Month","contractedMrr": 15000,"Type__c": "Standard","SF_QuoteID__c": "0Q01l000000hhLkCAI",' +
                                 '"ratePlans": [{"id": "8adcba9c79d4be560179d5fd20544ac6","lastChangeType": "Remove","productId": "8adcd9eb759733000175bcd6e24b3222","productName": "CanalBox - Togo","productSku": "SKU-00000006","productRatePlanId": "8adcd9eb759733000175bcd6e3cd3238","ratePlanName": "Premium","ratePlanCharges": [{"id": "8adcba9c79d4be560179d5fd20564ac8","originalChargeId": "8adc9a4179d4be5a0179d5fc5bdb2be9","productRatePlanChargeId": "8adcd9eb759733000175bcd6e3e0323a","number": "C-00001426","name": "Abonnement","type": "Recurring","model": "FlatFee","pricingSummary": "XOF30000","currency": "XOF","price": 30000,"billingDay": "DefaultFromCustomer","listPriceBase": "Per_Billing_Period","billingPeriod": "Month","specificBillingPeriod": null,"billingTiming": "IN_ADVANCE","billingPeriodAlignment": "AlignToCharge"}]},' +
                                 '{"id": "8adcba9c79d4be560179d5fd20a04ace","lastChangeType": "Add","productId": "8adcd9eb759733000175bcd6e24b3222","productName": "CanalBox - Togo","productSku": "SKU-00000006","productRatePlanId": "8adcd9eb759733000175bcd6e4eb324a","ratePlanName": "Start ","ratePlanCharges": [{"id": "8adcba9c79d4be560179d5fd20a04acf","originalChargeId": "8adcba9c79d4be560179d5fd20a04acf","productRatePlanChargeId": "8adcd9eb759733000175bcd6e501324c","number": "C-00001427","name": "Abonnement","type": "Recurring","pricingSummary": "XOF15000","currency": "XOF","price": 15000,"billingDay": "DefaultFromCustomer","listPriceBase": "Per_Billing_Period","billingPeriod": "Month","effectiveStartDate": "2021-08-04","effectiveEndDate": null,"processedThroughDate": "2022-09-04","chargedThroughDate": "2021-10-04","triggerEvent": "ServiceActivation","endDateCondition": "Subscription_End"}]}],"orderNumber": "O-00001513"}');

                return response;
            } else if(requestType.contains(ZuoraObjects.billAPIUrl)) {
                response.setBody('{"invoices": [{"id": "402890555c33b44b015c33bfe9c70044"}],"creditMemos": [{"id": "402890555c33b44b015c33bfe947003c"}],"success": true}');

                return response;
            } else {
                return null;
            }
        }
        catch(Exception e) {
            throw new MyCustomException('HTTP callout not supported for test methods');
        }
    }
    public class MyCustomException extends Exception {}
}