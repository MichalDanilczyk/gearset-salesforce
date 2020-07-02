@isTest(SeeAllData=true)
public class RHX_TEST_RICSC_SocialMediaID {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM RICSC_SocialMediaID__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new RICSC_SocialMediaID__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}