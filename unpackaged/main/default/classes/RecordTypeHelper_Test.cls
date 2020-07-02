@isTest
private class RecordTypeHelper_Test {
     
    @isTest static void getStandardObjectRecordtypeId(){
        
        List<RecordType> recordTypes = [SELECT Id, sobjectType, DeveloperName FROM Recordtype WHERE sobjectType = 'Account'];
        
        for(RecordType rt : recordTypes){
            system.assert(rt.Id == RecordTypeHelper.getRTId('Account'+RecordTypeHelper.CONCAT_STRING+rt.DeveloperName),'The queried recordType id is different from the one returned by the helper class');
        }
        
    }
 
    @isTest static void getNotExistingRecordtypeId(){
        
        List<RecordType> recordTypes = [SELECT Id, sobjectType, DeveloperName FROM Recordtype WHERE sobjectType = 'Account'];
        
        try{    
            for(RecordType rt : recordTypes){
                system.assert(rt.Id == RecordTypeHelper.getRTId('AccountERRRRRRRRR',rt.DeveloperName),'The queried recordType id is different from the one returned by the helper class');
            }
        }catch(Exception e){
            system.assert(e.getTypeName() == 'RecordTypeHelper.RecordTypeNotFoundException', 'Expected Exception of type RecordTypeNotFoundException but found: '+ e.getTypeName());
        }
        
    }
    
    @isTest static void getRTListTest(){
        
        List<RecordType> recordTypes = [SELECT Id, sobjectType, DeveloperName FROM Recordtype WHERE sobjectType = 'Account'];
                
        for(RecordType rt : recordTypes){
            Boolean found = false;
            
            for(RecordType hrt : RecordTypeHelper.getRTList('Account')){
                if(rt.id == hrt.id){
                    found = true;
                    break;
                }
            }
            
            system.assert(found == true, 'Current Record type has not been returned by RecordTypeHelper: '+ rt);
        }
        
    }
    
}