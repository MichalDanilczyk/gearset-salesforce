@isTest
private class DeployScript_Test {

    @testSetup static void testSetup(){
        UtilityTests.testSetup();
    }

    @isTest static void scheduleBatchJobsTest() {

        //Read SR Configuration Jobs
        String jobsConfiguration = Utility.staticResourceToJsonObject('Configuration_ClassToScheduleJson');
        List<DeployScript.CronTriggerConf> cfcList =
            (List<DeployScript.CronTriggerConf>) JSON.deserialize(jobsConfiguration,List<DeployScript.CronTriggerConf>.class);

        //Read currently scheduled jobs
        List<CronTrigger> cronTriggers = [Select id, CronExpression, CronJobDetail.name, State
                                            FROM CronTrigger WHERE CronJobDetailId!=null AND CronJobDetail.name LIKE '%_Sched'];

        //Scramble existing scheduled jobs in order to test different cases
        for(Integer i = 0; i< cronTriggers.size(); i++){
            if(Math.Mod(i,2)==0){
                system.debug('Aborting job: '+ cronTriggers[i].CronJobDetail.name);
                System.abortJob(cronTriggers[i].Id);
            }

            //Schedule a job with same name but different cron expression
            if(i == 0){
                String className = cronTriggers[i].CronJobDetail.name.substringBeforeLast(' ')+'_Sched';
                Type t = Type.forName(className);
                System.schedule(cronTriggers[i].CronJobDetail.name, '00 30 02 L JUN,DEC ? *', (Schedulable)t.newInstance());
            }
        }

        Test.startTest();
        //Execute Script
        DeployScript.ScheduleBatchJobs sbj = new DeployScript.ScheduleBatchJobs();
        sbj.run(null);
        Test.stopTest();

        //Verify that the jobs have been Scheduled

        //Read scheduled jobs after execution
        List<CronTrigger> cronTriggersAfter = [Select id, CronExpression, CronJobDetail.name, State
                                            FROM CronTrigger WHERE CronJobDetailId!=null  AND CronJobDetail.name like  '_Sched'];


        String checkString;
        for(DeployScript.CronTriggerConf cfc : cfcList){

            Boolean isScheduled = false;

            for(CronTrigger ct : cronTriggersAfter){

                checkString = cfc.key.replace('_Sched', ' AutoSched');
                System.debug('jobName: ' +ct.CronJobDetail.Name+', confName: '+ checkString);

                if( ct.CronJobDetail.Name == checkString &&
                    ct.CronExpression == cfc.cronExp
                ){
                    isScheduled = true;
                    break;
                }

            }

            //system.assert(true == isScheduled, 'Job '+checkString+', specified in static resource, has not been scheduled');

        }

    }

    /**
    *   @description    Support class for testing with SandboxContext input
    */
    @SuppressWarnings('PMD.AvoidHardcodingId,PMD.ApexDoc')
    public class MockSandboxContext implements SandboxContext
    {
        public ID organizationId(){return '00D0O000000ZWbN';}
        public ID sandboxId(){return null;}
        public ID sandboxName(){return null;}
    }


    @isTest static void runApexClassTest() {


        DeployScript ds = new DeployScript();
        DeployScript ds2 = new DeployScript(new Map<String,String> {'CalledBy'=>'Deployment'});
        MockSandboxContext context = new MockSandboxContext();

        Test.startTest();
        ds2.runApexClass(context);
        Test.stopTest();

        //InitGeneralSettings and trigger settings checks

        GeneralSettings__c generalSetting = GeneralSettings__c.getOrgDefaults();
        TRG_TriggerSettings__c triggerSettings = TRG_TriggerSettings__c.getOrgDefaults();

        Boolean isProd = ([SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox == false);
        String scopeStr = isProd ? UtilityConstants.FunctionalScopes.PRD.name() : UtilityConstants.FunctionalScopes.SBX.name();

        system.assert(scopeStr.equals(generalSetting.Scope__c) || generalSetting.Scope__c == UtilityConstants.FunctionalScopes.GL.name());
        system.assertEquals(true,  generalSetting.Logger_DebugEnabled__c);
        system.assertEquals(true, generalSetting.Logger_ExceptionEnabled__c);
        system.assert(String.isNotBlank(generalSetting.RICSC_VCACRMNonChinaPublicGroupNoMembers__c));
        system.assert(String.isNotBlank(generalSetting.GroupId_AllInternalUsers__c), 'There should always be a group id of All Internal Users');
        system.assert(triggerSettings!=null, 'Trigger Settings Org Defaults should be populated');
    }

     @isTest static void vCACRMNonChinaPublicGroupMembersAddedTest() {

      Test.startTest();
      DeployScript.VCACRMNonChinaPublicGroupMembersAdded sbj = new DeployScript.VCACRMNonChinaPublicGroupMembersAdded();
      sbj.run(null);
      Test.stopTest();
      GeneralSettings__c gst = GeneralSettings__c.getOrgDefaults();
      Group g = [SELECT Id FROM Group WHERE DeveloperName = :UtilityConstants.NON_CHINA_GROUP_REGULAR_NAME AND Type = 'Regular'];
      // the vca roles that are non china and dont belong to the current list (at least 19)
      List<Group> roles = [SELECT Id FROM Group WHERE Type = 'Role' AND DeveloperName LIKE 'RICSC_VCACRM%' AND DeveloperName NOT IN: gst.RICSC_VCACRMNonChinaPublicGroupNoMembers__c.split(',')];
      List<GroupMember> gm = [SELECT id FROM GroupMember WHERE GroupId = :g.Id];
      system.assertEquals(roles.size(), gm.size());

    }

    @isTest static void testRollupHelperConfiguration() {
        String staticResourceName = 'Configuration_rh2_PS_Export_Rollups_c';
        List<StaticResource> srlst = [SELECT body, name FROM StaticResource WHERE Name = :staticResourceName];
        system.assertEquals(1,srlst.size());
        try{
            List<sObject> conflst = Utility.staticResourceCSVToListOfSobject('rh2__PS_Export_Rollups__c');
            insert conflst;
        } catch (Exception e) {
            //System.assert(false, e.getMessage());
        }
    }
}