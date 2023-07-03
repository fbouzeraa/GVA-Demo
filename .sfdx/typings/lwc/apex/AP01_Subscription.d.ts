declare module "@salesforce/apex/AP01_Subscription.getCurrentSubFields" {
  export default function getCurrentSubFields(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Subscription.createYSPaymentAndOrder" {
  export default function createYSPaymentAndOrder(param: {subId: any, activationDate: any, finalDate: any, totalAmount: any, paymentMode: any, CDFPayment: any, dollarPayment: any, conversionRate: any, transactionId: any, operator: any, aggregator: any, CDFRefund: any, dollarRefund: any, duree: any, chargeOvrd: any, previewOnly: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Subscription.createYSPreviewSubscription" {
  export default function createYSPreviewSubscription(param: {sub: any, activationDate: any, finalDate: any, removeDate: any, productRP: any, prePaidPeriod: any, chargeOvrd: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Subscription.updateSubscriptionAfterActivation" {
  export default function updateSubscriptionAfterActivation(param: {currentSub: any, dateFin: any, dateDebut: any}): Promise<any>;
}
