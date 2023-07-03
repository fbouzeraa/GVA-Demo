declare module "@salesforce/apex/BundleCSubscription.getBundleProducts" {
  export default function getBundleProducts(param: {recordId: any, fromQuote: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.getEquipmentList" {
  export default function getEquipmentList(param: {recordId: any, fromQuote: any, material: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.subscribeToC" {
  export default function subscribeToC(param: {recordId: any, offerName: any, listOptions: any, equipments: any, period: any, fromRenewButton: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.getCanalSubscription" {
  export default function getCanalSubscription(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.verifiyOptionsCompatibility" {
  export default function verifiyOptionsCompatibility(param: {recordId: any, fromQuote: any, productName: any, category: any, listOPtions: any, renewable: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.cancelBundleC" {
  export default function cancelBundleC(param: {recordId: any, cancelReason: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.renewBundleC" {
  export default function renewBundleC(param: {recordId: any, prepaidPeriod: any, offer: any, options: any, fromRenewButton: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.suspendBundleC" {
  export default function suspendBundleC(param: {recordId: any, suspensionReason: any, suspensionDate: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.modifyOfferBundleC" {
  export default function modifyOfferBundleC(param: {recordId: any, offerName: any, listOptions: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.fastRenewBundleC" {
  export default function fastRenewBundleC(param: {recordId: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.activateCBundle" {
  export default function activateCBundle(param: {subId: any, activationDate: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.changeMaterialInZuora" {
  export default function changeMaterialInZuora(param: {subscriptionId: any, isPreview: any, modeDePaiement: any, transactionNumber: any, operator: any, dollarPayment: any, CDFPayment: any, dollarRefund: any, CDFRefund: any, equipmentName: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.exchangeMaterialBundleC" {
  export default function exchangeMaterialBundleC(param: {recordId: any, equipmentId: any, equipmentType: any, equipmentIdSF: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.saveEquipementValue" {
  export default function saveEquipementValue(param: {subId: any, equipments: any, options: any, offer: any, period: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.EligMigrationTest" {
  export default function EligMigrationTest(param: {listOfSubId: any, equipmentId: any, countryCodeValue: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.requestMigration" {
  export default function requestMigration(param: {listOfSubIds: any, prepaidPeriod: any, offerValue: any, adultContent: any, options: any, eqipId: any, equipType: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.cancelCanalMigration" {
  export default function cancelCanalMigration(param: {listOfSubIds: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.createSuiviforMigration" {
  export default function createSuiviforMigration(param: {action: any, subId: any, transactionId: any, allInfobody: any, paymentBodyInfo: any}): Promise<any>;
}
declare module "@salesforce/apex/BundleCSubscription.userCanSee" {
  export default function userCanSee(): Promise<any>;
}
