/*
 * @!#  This class is used for bypassing trigger classes or prevent later execution of apex classes
 * @author: Maroun Yazbeck
 * @date: 14/01/2021
 * @test: PAD_Test
 */
public class PAD {

	private static final Set<String> REQUIREDONCE = new Set<String> {};//List of Apex codes that should run only once. Add any code to the list
	private static Set<String> hasRun = new Set<String>();//List of Apex code that has already been run. Keep this list empty.
	public static final String PAD_BYPASSTRIGGER;//List of triggers that can be bypassed
	public static Boolean bypassAllTriggers = false;

	static {
		// System.QueryException: List has no rows for assignment to SObject
		List<User> user = [SELECT USR_BypassTriggers__c, USR_Bypass_Classes__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
		If(user!= null && user.size()>0){
			PAD_BYPASSTRIGGER = ';' + user[0].USR_Bypass_Classes__c+';';
			bypassAllTriggers = user[0].USR_BypassTriggers__c;
		}else{
			PAD_BYPASSTRIGGER = '';
		}

	}

	/** doNotExecuteAfterMe allows a dev to prevent the execution of
	   further declared devs in the same context.
	   ex: A trigger can prevent another trigger to execute after it **/
	public static void doNotExecuteAfterMe(Set<String> devsNot2execSet){
		for(String devNot2exec:devsNot2execSet) {
			REQUIREDONCE.add(devNot2exec);
			hasRun.add(devNot2exec);
		}
	}

	public static boolean canTrigger(String apexName){//If no bypass
		if(REQUIREDONCE.contains(apexName)) {//If it should run Once
			if(hasRun.contains(apexName)) {
				return false;//Already run, should not run
			}
			hasRun.add(apexName);//Never run, can run only if not bypassed
		}
		return(PAD_BYPASSTRIGGER.indexOf(';'+apexName+';')==-1 && !bypassAllTriggers);
	}
}