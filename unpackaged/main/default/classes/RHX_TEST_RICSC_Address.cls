@isTest(SeeAllData=true)
public class RHX_TEST_RICSC_Address {
	static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
			FROM RICSC_Address__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new RICSC_Address__c()
            );
        }
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}