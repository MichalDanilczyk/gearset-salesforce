/**********************************************************************************************
* @author       Piergiorgio Lisanti
* @date         05/01/2020
* @description  Scheduler for BatchFlagsPropagation class
**********************************************************************************************/
global class BatchFlagsPropagation_Sched implements Schedulable {
    global void execute(SchedulableContext sc){
        Integer batchSize = 50;             
        BatchFlagsPropagation batch = new BatchFlagsPropagation(false, 'SELECT Id, RICSC_RecomputeFlagsPropagation__c FROM Account WHERE isPersonAccount = true AND RICSC_RecomputeFlagsPropagation__c = true');
        ID batchprocessid = Database.executeBatch(batch,batchSize);    
	}
}