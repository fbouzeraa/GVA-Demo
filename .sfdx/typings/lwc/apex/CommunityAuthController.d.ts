declare module "@salesforce/apex/CommunityAuthController.doLogin" {
  export default function doLogin(param: {username: any, password: any}): Promise<any>;
}
declare module "@salesforce/apex/CommunityAuthController.isEmailExist" {
  export default function isEmailExist(param: {username: any}): Promise<any>;
}
declare module "@salesforce/apex/CommunityAuthController.registerUser" {
  export default function registerUser(param: {firstName: any, lastName: any, username: any, email: any, communityNickname: any, password: any}): Promise<any>;
}
declare module "@salesforce/apex/CommunityAuthController.sendWelcomeMail" {
  export default function sendWelcomeMail(param: {usr: any, userId: any}): Promise<any>;
}
