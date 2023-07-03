declare module "@salesforce/apex/SubscriptionRenewalActions.upgradeSubscriptionProduct" {
  export default function upgradeSubscriptionProduct(param: {subscriptionId: any, nbPeriodes: any, isPreview: any, withRenew: any, immediateUpgrade: any, modeDePaiement: any, transactionNumber: any, operator: any, dollarPayment: any, CDFPayment: any, dollarRefund: any, CDFRefund: any, bizaOrderId: any, offer: any, options: any, category: any}): Promise<any>;
}
declare module "@salesforce/apex/SubscriptionRenewalActions.downgradeSubscriptionProduct" {
  export default function downgradeSubscriptionProduct(param: {subscriptionId: any, newQuoteID: any, nbPeriodes: any, isPreview: any, modeDePaiement: any, transactionNumber: any, operator: any, dollarPayment: any, CDFPayment: any, dollarRefund: any, CDFRefund: any, bizaOrderId: any, offer: any, options: any, category: any}): Promise<any>;
}
declare module "@salesforce/apex/SubscriptionRenewalActions.renewSubPreview" {
  export default function renewSubPreview(param: {subId: any, nbPeriodes: any, withoutTax: any, paymentMode: any, fromUI: any, PRPId: any, offer: any, options: any, category: any}): Promise<any>;
}
declare module "@salesforce/apex/SubscriptionRenewalActions.renewSubscription" {
  export default function renewSubscription(param: {subscriptionId: any, nbPeriodes: any, modeDePaiement: any, transactionNumber: any, operator: any, dollarPayment: any, CDFPayment: any, dollarRefund: any, CDFRefund: any, bizaOrderId: any, offer: any, options: any, category: any}): Promise<any>;
}
declare module "@salesforce/apex/SubscriptionRenewalActions.addPaymentNumberToSubscription" {
  export default function addPaymentNumberToSubscription(param: {subscriptionId: any, paymentNumber: any}): Promise<any>;
}
declare module "@salesforce/apex/SubscriptionRenewalActions.createErrorLog" {
  export default function createErrorLog(param: {zuoraResponse: any}): Promise<any>;
}
declare module "@salesforce/apex/SubscriptionRenewalActions.retryPayment" {
  export default function retryPayment(param: {zuoraAccountId: any, nbPeriodes: any, currentAmount: any, transactionNumber: any, operator: any, orderNumber: any, invoiceId: any, accountCurrency: any, paymentMode: any, CDFPayment: any, dollarPayment: any, currencyRate: any, dollarRefund: any, CDFRefund: any, fromDistributor: any, AccountId: any}): Promise<any>;
}
declare module "@salesforce/apex/SubscriptionRenewalActions.isPartnerUser" {
  export default function isPartnerUser(): Promise<any>;
}
