@isTest
private class TRG_TriggerHandlerConfiguration_Test{

    @isTest
    static void testTriggerConfigurations(){
        
        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe(); 
        String scope = GeneralSettings__c.getInstance().Scope__c;            
        List<TRG_TriggerConf__mdt> configs = [SELECT Id, Object__c, Class__c, Scope__c, OrderOfExecution__c, DeveloperName,
                                                                 AfterDelete__c, AfterInsert__c, AfterUndelete__c, AfterUpdate__c, BeforeDelete__c, BeforeInsert__c, BeforeUpdate__c    
                                                                 FROM TRG_TriggerConf__mdt 
                                                                 WHERE IsActive__c = TRUE]; 
        
        for(TRG_TriggerConf__mdt config: configs){
           
            //Object check
            system.assert(true == globalDesc.containskey(config.Object__c), 'Configured object !'+config.Object__c+'! in field Object__c is not available for this Org. Record DevName: ' +config.DeveloperName);
            
            //Order of execution check (Region specific methods use decimal, GL methods use only integer part)
            if(config.Scope__c == 'GL'){
                system.assert(config.OrderOfExecution__c == config.OrderOfExecution__c.round(System.RoundingMode.DOWN), 'Configured Global (GL) metadata uses decimal (reserved to regional) order of execution. '+config.OrderOfExecution__c+'. Record DevName: ' +config.DeveloperName);
            }else{
                system.assert(config.OrderOfExecution__c != config.OrderOfExecution__c.round(System.RoundingMode.DOWN), 'Configured Region specific metadata does not use decimal (reserved to regional) order of execution. '+config.OrderOfExecution__c+'. Record DevName: ' +config.DeveloperName);
            }
            
            //Check that at least one Event is selected
            system.assert(true == config.AfterDelete__c || config.AfterInsert__c || config.AfterUndelete__c || config.AfterUpdate__c || config.BeforeDelete__c || config.BeforeInsert__c || config.BeforeUpdate__c ,
                             'At least one event must be selected. Record DevName: ' +config.DeveloperName);

            //Class Method Check
            try{
                Object obj = Type.forName(config.Class__c.deleteWhitespace()).newInstance( );
                System.assertEquals( true, obj instanceof TRG_TriggerHandlerInterface);

            }catch(NullPointerException e){
                system.assert(false, 'Configured Class does not exist. Class: '+ config.Class__c.deleteWhitespace() + ' . Record DevName: ' +config.DeveloperName);
            }
        }
    }

}