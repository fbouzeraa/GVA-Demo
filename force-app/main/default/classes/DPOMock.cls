/**
 * Classe pour simuler les appels API vers l'endpoint du DPO
 *
 * @author Yara Bourdoukan
 * @date 7 Décembre 2021
 */
@isTest
global class DPOMock implements HttpCalloutMock {
    public boolean error = false;
    public boolean catchError = false;
    public Integer statusCode;

    public DPOMock(){
        this.error = false;
        this.statusCode = 200;
    }

    public DPOMock(boolean error, boolean catchError, Integer statusCode){
        this.error = error;
        this.catchError = catchError;
        this.statusCode = statusCode;
    }
    global HttpResponse respond(HTTPRequest request){
        String endpoint = request.getEndpoint();

        HttpResponse response = new HttpResponse();
        if(endpoint.contains(DPObjects.getTransactionAPIUrl) && this.statusCode == 200) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/xml');
            response.setBody('<API3G><Code>000</Code><Explanation>ResultsFound</Explanation><Transactions><Transaction><TransactionBookRef>ALCL:B18A9982</TransactionBookRef><TransactionToken>59744796-D317-49CD-BBE9-0FCE82B2F8FA</TransactionToken><TransactionCreatedDate>2022-05-3017:02:57</TransactionCreatedDate><TransactionAmount>60000</TransactionAmount><TransactionCurrency>RWF</TransactionCurrency><TransactionFinalAmount>25,000.00</TransactionFinalAmount><TransactionFinalCurrency>RWF</TransactionFinalCurrency><TransactionCardLastFour>1111</TransactionCardLastFour><TransactionCardFirstSix>41111111</TransactionCardFirstSix><TransactionPartPayment>0</TransactionPartPayment><TransactionCityId>0</TransactionCityId><TransactionPhone>0503725378</TransactionPhone><TransactionPhonePrefix>250</TransactionPhonePrefix><TransactionRef>R4962742</TransactionRef><TransactionStatus>Paid</TransactionStatus><TransactionPaymentDate>2022-05-3017:03:34</TransactionPaymentDate><TransactionCardType>Visa</TransactionCardType><TransactionUserName>System</TransactionUserName><TransactionApprovalNumber>4444444403</TransactionApprovalNumber><TransactionServiceDescription><ServiceDescription>Pay My Bills Start (50 Mbps) 1 month</ServiceDescription></TransactionServiceDescription><TransactionCustomerPhone>2500503725378</TransactionCustomerPhone><TransactionCustomerEmail>nathanc@dpogroup.com</TransactionCustomerEmail><TransactionCustomerName>nathanchemla</TransactionCustomerName><TransactionFraudAlert>004</TransactionFraudAlert><TransactionFraudExplanation>HighRisk(Merchantchecked)</TransactionFraudExplanation><TransactionExpiryDate>2022-05-3014:17:57</TransactionExpiryDate><TransactionAdditionalFields></TransactionAdditionalFields><TransactionAdditionalAirlineFields></TransactionAdditionalAirlineFields><TransactionAuthCode></TransactionAuthCode><TransactionCompanyAccRef></TransactionCompanyAccRef><MetaData></MetaData><Additional><BlockPayment/></Additional><RedirectUrl>http://nathan-shop.dev.directpay.online/paymybills/gvarwanda?billAction=done&amp;order=1653919377</RedirectUrl><BackUrl>http://nathan-shop.dev.directpay.online//paymybills/gvarwanda?billAction=cancel&amp;order=1653919377</BackUrl><DeclinedUrl></DeclinedUrl></Transaction></Transactions></API3G>');

        } else if(endpoint.contains(DPObjects.getTransactionAPIUrl) && this.statusCode != 200) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/xml');
            response.setBody('<API3G><Code>000</Code><Explanation>ResultsFound</Explanation><Transactions><Transaction><TransactionBookRef>ALCL:B18A9982</TransactionBookRef><TransactionToken>59744796-D317-49CD-BBE9-0FCE82B2F8FA</TransactionToken><TransactionCreatedDate>2022-05-3017:02:57</TransactionCreatedDate><TransactionAmount>60000</TransactionAmount><TransactionCurrency>RWF</TransactionCurrency><TransactionFinalAmount>25,000.00</TransactionFinalAmount><TransactionFinalCurrency>RWF</TransactionFinalCurrency><TransactionCardLastFour>1111</TransactionCardLastFour><TransactionCardFirstSix>41111111</TransactionCardFirstSix><TransactionPartPayment>0</TransactionPartPayment><TransactionCityId>0</TransactionCityId><TransactionPhone>0503725378</TransactionPhone><TransactionPhonePrefix>250</TransactionPhonePrefix><TransactionRef>R4962742</TransactionRef><TransactionStatus>Paid</TransactionStatus><TransactionPaymentDate>2022-05-3017:03:34</TransactionPaymentDate><TransactionCardType>Visa</TransactionCardType><TransactionUserName>System</TransactionUserName><TransactionApprovalNumber>4444444403</TransactionApprovalNumber><TransactionServiceDescription><ServiceDescription>Pay My Bills Premium (50 Mbps) 1 month</ServiceDescription></TransactionServiceDescription><TransactionCustomerPhone>2500503725378</TransactionCustomerPhone><TransactionCustomerEmail>nathanc@dpogroup.com</TransactionCustomerEmail><TransactionCustomerName>nathanchemla</TransactionCustomerName><TransactionFraudAlert>004</TransactionFraudAlert><TransactionFraudExplanation>HighRisk(Merchantchecked)</TransactionFraudExplanation><TransactionExpiryDate>2022-05-3014:17:57</TransactionExpiryDate><TransactionAdditionalFields></TransactionAdditionalFields><TransactionAdditionalAirlineFields></TransactionAdditionalAirlineFields><TransactionAuthCode></TransactionAuthCode><TransactionCompanyAccRef></TransactionCompanyAccRef><MetaData></MetaData><Additional><BlockPayment/></Additional><RedirectUrl>http://nathan-shop.dev.directpay.online/paymybills/gvarwanda?billAction=done&amp;order=1653919377</RedirectUrl><BackUrl>http://nathan-shop.dev.directpay.online//paymybills/gvarwanda?billAction=cancel&amp;order=1653919377</BackUrl><DeclinedUrl></DeclinedUrl></Transaction></Transactions></API3G>');

        } else if(endpoint.contains(DPObjects.newTokenAPIUrl) && this.statusCode == 200) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/xml');
            response.setBody('<API3G><Result>000</Result><ResultExplanation>Transaction created</ResultExplanation><TransToken>8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3</TransToken><TransRef>1285DB12G</TransRef></API3G>');
        } else if(endpoint.contains(DPObjects.newTokenAPIUrl) && this.statusCode == 200) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/xml');
            response.setBody('<API3G> <Result> 903 </Result> <ResultExplanation> The transaction passed the Payment Time Limit</ResultExplanation><CustomerCreditType> </CustomerCreditType> <TransactionApproval> </TransactionApproval> <TransactionCurrency> RWF</TransactionCurrency> <TransactionAmount> 25000.00 </TransactionAmount> <FraudAlert>001</FraudAlert> <FraudExplnation> Low Risk (Not checked) </FraudExplnation> <TransactionNetAmount> 0.00 </TransactionNetAmount> <TransactionSettlementDate> 2022/09/05 </TransactionSettlementDate>  <TransactionRollingReserveAmount> 0.00 </TransactionRollingReserveAmount> <TransactionRollingReserveDate> </TransactionRollingReserveDate> <CustomerPhone> 724060578 </CustomerPhone> <CustomerCountry> Rwanda</CustomerCountry> <CustomerAddress> </CustomerAddress> <CustomerCity> Rubavu</CustomerCity> <CustomerZip> </CustomerZip> <MobilePaymentRequest> Not sent</MobilePaymentRequest> <AccRef> ALCL:EB2F416E</AccRef> <TransactionFinalCurrency> </TransactionFinalCurrency> <TransactionFinalAmount> 0.00 </TransactionFinalAmount></API3G>');
        }

        return response;
    }
}