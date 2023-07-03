declare module "@salesforce/apex/BizaoPaymentsCall.callRenewSubPreview" {
  export default function callRenewSubPreview(param: {subId: any, nbPeriodes: any, withoutTax: any, paymentMode: any, fromUI: any, operator: any, transactionNumber: any, dollarPayment: any, CDFPayment: any, dollarRefund: any, CDFRefund: any, selectedRenewOffer: any, PRPId: any}): Promise<any>;
}
declare module "@salesforce/apex/BizaoPaymentsCall.callUpgradeSubscriptionProductPreview" {
  export default function callUpgradeSubscriptionProductPreview(param: {subscriptionId: any, nbPeriodes: any, modeDePaiement: any, operator: any, transactionNumber: any, dollarPayment: any, CDFPayment: any, dollarRefund: any, CDFRefund: any, selectedRenewOffer: any}): Promise<any>;
}
declare module "@salesforce/apex/BizaoPaymentsCall.callMobileMoneyPayment" {
  export default function callMobileMoneyPayment(param: {order: any}): Promise<any>;
}
declare module "@salesforce/apex/BizaoPaymentsCall.callBankPayment" {
  export default function callBankPayment(param: {order: any}): Promise<any>;
}
