@isTest
private class TRG_TriggerDispatcher_Test{

    @testSetup static void setup(){

        UtilityTests.testSetup();
        
    }

    @isTest
    static void testEvents(){
     
        String eventFired = TRG_TriggerDispatcher.getEvent(true, false, true, false, false, false);
        System.assertEquals(eventFired, 'BeforeInsert');

        eventFired = TRG_TriggerDispatcher.getEvent(false, true, false, true, false, false);
        System.assertEquals(eventFired, 'AfterUpdate');
        
        eventFired = TRG_TriggerDispatcher.getEvent(false, true, false, false, true, false);
        System.assertEquals(eventFired, 'AfterDelete');
        
        eventFired = TRG_TriggerDispatcher.getEvent(false, true, false, false, false, true);
        System.assertEquals(eventFired, 'AfterUndelete');

        TRG_TriggerDispatcher.getCustomMetdataConfigurations('Account',eventFired);
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    @isTest
    static void testMainEntry(){

        //Test assumes that it exists at least a CM configuration for the Account object after insert
        String eventFired = TRG_TriggerDispatcher.getEvent(false, true, true, false, false, false);
        System.assertEquals(eventFired, 'AfterInsert');

        Boolean exceptionFired = false;
        try{
            TRG_TriggerDispatcher.mainEntry('Account',false,false,true,true,false,false,true, new List<Account>{new Account()}, new Map<ID,Account>{'0011n000021Ykub' => new Account()}, null, null );
        }catch(Exception e){
            exceptionFired = true;
        }finally{
            system.assertEquals(false, exceptionFired);
        }

    }

    @isTest
    static void testIsTriggerEnabledForCurrentUserDisableAllTriggers(){
        
        TRG_TriggerSettings__c ts = TRG_TriggerSettings__c.getOrgDefaults();
        ts.DisableAllTriggers__c = true;

        upsert ts  TRG_TriggerSettings__c.Id;

        Boolean isEnabled = TRG_TriggerDispatcher.isTriggerEnabledForCurrentUser('Account');
        system.assertEquals(false, isEnabled);
    }

    @isTest
    static void testIsTriggerEnabledForCurrentUser(){

        Boolean isEnabled = TRG_TriggerDispatcher.isTriggerEnabledForCurrentUser('Account');
        system.assertEquals(true, isEnabled);
    }

    @isTest
    static void testIsTriggerEnabledForCurrentUserDisableAccountTrigger(){
        
        TRG_TriggerSettings__c ts = TRG_TriggerSettings__c.getOrgDefaults();
        ts.DisableTriggerObjects__c = 'Account';

        upsert ts  TRG_TriggerSettings__c.Id;

        Boolean isEnabled = TRG_TriggerDispatcher.isTriggerEnabledForCurrentUser('Account');
        system.assertEquals(false, isEnabled);
    }


}