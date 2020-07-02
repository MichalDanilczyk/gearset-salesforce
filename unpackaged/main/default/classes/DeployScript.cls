/******************************************************************************
* @author       Piergiorgio Lisanti
* @date         26/08/2019
* @description  This class executes configured apex processes after Sandbox
*               refresh (implements SandboxPostCopy) or after a deployment.
*               It dynamically reads the environment configuration and executes
*               methods defined in DeployScriptConf__mdt.
*               N.B.: Methods invoked by this class should be idempotent and not
*               override values set in the environemnt!
*
******************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation,PMD.AvoidGlobalModifier,PMD.ApexDoc')
global without sharing class DeployScript implements SandboxPostCopy {

    private Map<String,String> parameters;

    /**
    *   @description    Default constructor
    */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public DeployScript(){}

    /**
    *  @description         constructor with map of parameters -> future use
    *  @param  parameters   Map of additional parameters that can be used in the future
    */
    public DeployScript(Map<String,String> parameters){
        this.parameters = parameters;
    }

    /**
    *   @description        Main entry point for the class. It reads the configuration
    *                       and executes defined proesses
    *   @param  context     context parameter provided upon sbx refresh call
    */
    global void runApexClass(SandboxContext context) {

        if(context!=null && (parameters.get('LogEnabled') == null || parameters.get('LogEnabled').equals('true'))) {
            logInfo('DeployScript START. orgId: '+ context.organizationId() +', sandboxName: '+ context.sandboxName()+', sandboxId: '+context.sandboxId(), UtilityLogger.LOG_LEVEL_INFO);
        }

        //Get scope information
        GeneralSettings__c generalSetting = GeneralSettings__c.getOrgDefaults();
        String scope = generalSetting.Scope__c;

        //Get list of methods to execute in this scope
        DeployScriptConf__mdt[] scopeInfo =
            [   SELECT Class__c, OrderOFExecution__c, ContainsSetupObjectDML__c, ContainsNonSetupObjectDML__c FROM DeployScriptConf__mdt
                WHERE IsActive__c = TRUE AND
                (Scope__c = :scope OR Scope__c = :UtilityConstants.FunctionalScopes.GL.name())
                ORDER BY OrderOFExecution__c ASC
            ];

        for(DeployScriptConf__mdt ssc : scopeInfo) {
            if(parameters.get('FilterSetupObjects') != null &&
                parameters.get('FilterSetupObjects').equals('true') &&
                ssc.ContainsSetupObjectDML__c){
                continue;
            }
            if(parameters.get('FilterNonSetupObjects') != null &&
                parameters.get('FilterNonSetupObjects').equals('true') &&
                ssc.ContainsNonSetupObjectDML__c){
                continue;
            }

            try {
                Type tHandler = Type.forName(ssc.Class__c.deleteWhitespace());
                DeployScriptMethod activeFunction = (DeployScriptMethod) tHandler.newInstance();
                activeFunction.run(parameters);
            } catch(Exception e) {
                logInfo('DeployScript ' + ssc.Class__c + ' ERROR - ' + e.getMessage() + ' - ' + e.getStackTraceString(), UtilityLogger.LOG_LEVEL_ERROR);
            }

        }

    }


    /**
    *  @description  Inits custom setting - General Settings
    */
    public without sharing class InitGeneralSettings implements DeployScriptMethod {

        /**
        *  @description         InitGeneralSettings run method implementation
        *                       It checks if scope variable is set correctly
        *                       it values CS fields with default value when no value is provided
        *  @param  parameters   generic input parameters, not used in current implmentation
        */
        public void run( Map<String,String> parameters )
        {

            //List of fields to set with specific org id or values
	        GeneralSettings__c generalSetting = GeneralSettings__c.getOrgDefaults();

            //Prod check
            Boolean isProd = ([SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox == false);
            String scopeStr = isProd ? UtilityConstants.FunctionalScopes.PRD.name() : UtilityConstants.FunctionalScopes.SBX.name();

            if(String.isBlank(generalSetting.Scope__c) || generalSetting.Scope__c != scopeStr){

                logInfo('DeployScript populateGeneralSettings updates to SCOPE! Changed from: '+ generalSetting.Scope__c + ',to: '+scopeStr, UtilityLogger.LOG_LEVEL_INFO);

                //Update Scope value for the org
                generalSetting.Scope__c = scopeStr;

                //As scope was changed reset other fields to default values
                generalSetting.Logger_DebugEnabled__c = true;
	              generalSetting.Logger_ExceptionEnabled__c = true;

            }

            //FOLLOWING FIELDS ARE UPDATED ONLY IF NO VALUE IS SET FOR THE FIELD

            //Set group ids
            List<Group> groups = [Select Id,DeveloperName From Group where DeveloperName = 'AllInternalUsers' LIMIT 1];
            for(Group g : groups){
                if(g.developerName == 'AllInternalUsers'){
                    DeployScript.setValueIfNull(generalSetting, 'GroupId_AllInternalUsers__c', g.Id);
                }
            }
            //set user inactivity quota for deactivation if not set
            //DeployScript.setValueIfNull(generalSetting, 'ADUserInactivationDays__c', 90);
            //set product portfolio default integration date quota
            DeployScript.setValueIfNull(generalSetting, 'RICSC_ProductPortfolioIntegrationDate__c', date.newInstance(2015, 12, 27));
            DeployScript.setValueIfNull(generalSetting, 'RICSC_VCACRMNonChinaPublicGroupNoMembers__c',
            'RICSC_VCACRMAmericasRegion,RICSC_VCACRMAsiaPacificRegion,RICSC_VCACRMEuropeCIS,RICSC_VCACRMFranceRegion,RICSC_VCACRMHongKongMacao,RICSC_VCACRMHQ,RICSC_VCACRMMiddleEastRegion,RICSC_VCACRMSouthEastAsiaAustralia,RICSC_VCACRMWorld,RICSC_VCACRMChina'
            );
            DeployScript.setValueIfNull(generalSetting, 'RICSC_RunSegmentationAfterDCJob__c', true);
            DeployScript.setValueIfNull(generalSetting, 'RICSC_RunConsentsAlignmentAfterDCJob__c', true);
            upsert generalSetting  GWGL_GeneralSettings__c.Id;

            logInfo('DeployScript populateGeneralSettings completed', UtilityLogger.LOG_LEVEL_INFO);
        }

    }

    /**
    *  @description  Inits trigger setting - Trigger Settings
    */
    public without sharing class InitTriggerSettings implements DeployScriptMethod {

        /**
        *  @description         InitTriggerSettings run method implementation
        *                       It checks if trigger settings are provided as org defaults
        *                       Otherwise populates it with default values
        *  @param  parameters   generic input parameters, not used in current implmentation
        */
        public void run( Map<String,String> parameters )
        {

            //List of fields to set with specific org id or values
	        //GeneralSettings__c generalSetting = GeneralSettings__c.getOrgDefaults();
            //if(String.isBlank(generalSetting.Scope__c)){
            //    throw new Exception('General settings scope field must be populated');
            //}
            //Boolean isProd = generalSetting.Scope__c.equals(UtilityConstants.FunctionalScopes.PRD.name());

            //List of fields to set with specific values
            TRG_TriggerSettings__c triggerSettings = TRG_TriggerSettings__c.getOrgDefaults();
            //FOLLOWING FIELDS ARE UPDATED ONLY IF NO VALUE IS SET FOR THE FIELD
            DeployScript.setValueIfNull(triggerSettings, 'DisableAllProcessBuilders__c', false);
            DeployScript.setValueIfNull(triggerSettings, 'DisableAllTriggers__c', false);
            DeployScript.setValueIfNull(triggerSettings, 'DisableAllWorkflows__c', false);
            DeployScript.setValueIfNull(triggerSettings, 'CheckEnabledOnLeanLoad__c', false);
            DeployScript.setValueIfNull(triggerSettings, 'PrintLimitsInDebug__c', false);
            DeployScript.setValueIfNull(triggerSettings, 'DisableTriggerMethods__c', '');
            DeployScript.setValueIfNull(triggerSettings, 'DisableTriggerObjects__c', '');
            upsert triggerSettings  TRG_TriggerSettings__c.Id;

            logInfo('DeployScript populateTriggerSettings completed', UtilityLogger.LOG_LEVEL_INFO);
        }

    }

    public static SObject  setValueIfNull(sObject settings, String field, Object value) {
        if(value instanceOf Boolean) {
            settings.put(field, settings.get(field) == false && value == true ? value : settings.get(field));
        }
        else if(value instanceOf String) {
            settings.put(field, String.isBlank((String)settings.get(field)) ? value : settings.get(field));
        } else {
            settings.put(field, settings.get(field) == null ? value : settings.get(field));
        }

        return settings;
    }

    /**
    *   @author       Piergiorgio Lisanti
    *   @date         26/Aug/2019
    *   @description  Schedules batch jobs based on configuration provided in static resource named
    *                 Configuration_ClassToScheduleJson. The configuration SR should be a JSON with
    *                 a list of rows in this format:
    *                    {
    *                        "key" : "BatchAutomaticProspectDeletion_Sched",
    *                        "cronExp" : "00 30 00 * * ? *",
    *                        "scope" : "GL"
    *                    }
    *
    *                 In case the same class needs to be scheduled multiple times, just append
    *                   _[0-9][0-9] to the key parameter value
    *
    *                 In case the job is already scheduled with same name and cronExpression
    *                 no action is performed. If the cronExpression is different the old CronTrigger
    *                 is deleted and a new one created.
    */
    @SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity')
    public without sharing class ScheduleBatchJobs implements DeployScriptMethod {

        /**
        *  @description         ScheduleBatchJobs run method implementation
        *  @param  parameters   generic input parameters, not used in current implmentation
        */
        public void run( Map<String,String> parameters )
        {
            Integer scheduledJobsCount = 0;
            Integer abortedJobsCount = 0;

            //Map of already Scheduled jobs
            Map<String, CronTrigger> scheduledJobsMap = new  Map<String, CronTrigger> ();
            for(CronTrigger ct : [Select id, CronExpression, CronJobDetail.name, State From CronTrigger WHERE CronJobDetailId!=null]){
                scheduledJobsMap.put(ct.CronJobDetail.Name, ct);
            }

            //Get Configured static resource
            String jsonMap = Utility.staticResourceToJsonObject('Configuration_ClassToScheduleJson');
            List<CronTriggerConf> scheduleClassInfoList = (List<CronTriggerConf>)JSON.deserialize(jsonMap, List<CronTriggerConf>.class);

            Map<String, CronTriggerConf> scheduleClassInfoMap = new Map<String, CronTriggerConf>();
            for(CronTriggerConf ctf : scheduleClassInfoList){
                scheduleClassInfoMap.put(ctf.key, ctf);
            }

            for(String scheduleKey : scheduleClassInfoMap.keySet()) {

                if(scheduleClassInfoMap.get(scheduleKey).scope != 'GL' &&
                    scheduleClassInfoMap.get(scheduleKey).scope != GeneralSettings__c.getOrgDefaults().Scope__c
                ){
                    logInfo('DeployScript scheduleBatchJob SKIPPED Job ' + scheduleKey + ' with scope ' + scheduleClassInfoMap.get(scheduleKey).scope + ' because it does not match org scope: ' + GeneralSettings__c.getOrgDefaults().Scope__c,  UtilityLogger.LOG_LEVEL_INFO);
                    continue;
                }

                Pattern myPattern = Pattern.compile('^(.*_Sched)(_[0-9]{2})?$');
                Matcher myMatcher = myPattern.matcher(scheduleKey);

                if(!myMatcher.matches()){
                    logInfo('DeployScript scheduleBatchJob ERROR - Expression does not match defined pattern', UtilityLogger.LOG_LEVEL_ERROR);
                    continue;
                }

                String className = myMatcher.group(1);
                String postfix = myMatcher.group(2) != null ? myMatcher.group(2) : '';
                String jobScheduleName = className.replace('_Sched',' AutoSched' + postfix);

                String cronExp = scheduleClassInfoMap.get(scheduleKey).cronExp;

                Type t = Type.forName(className);

                if(t == null){
                    logInfo('DeployScript - scheduleBatchJob: ' + className + ' not found', UtilityLogger.LOG_LEVEL_ERROR);
                    continue;
                }

                //Check if previous scheduling exists and had different cronExpression
                if(scheduledJobsMap.containsKey(jobScheduleName) &&
                    scheduledJobsMap.get(jobScheduleName).CronExpression != cronExp){

                    //Delete old scheduling
                    abortedJobsCount ++;
                    System.abortJob(scheduledJobsMap.get(jobScheduleName).Id);

                }

                scheduledJobsCount ++;
                System.Schedule(jobScheduleName, cronExp, (Schedulable)t.newInstance());

            }

            logInfo('DeployScript scheduleBatchJob completed.\n #Scheduled Jobs: ' + scheduledJobsCount +'\n #Aborted Jobs: '+abortedJobsCount, UtilityLogger.LOG_LEVEL_INFO);

        }

    }


    /**
    *   @author       Piergiorgio Lisanti
    *   @date         03/09/2019
    *   @description  Reloades all caches used by the system to ensure they contain up to date information
    */
    public without sharing class CleanCaches implements DeployScriptMethod {

        /**
        *  @description         CleanCaches run method implementation
        *  @param  parameters   generic input parameters, not used in current implmentation
        */
        public void run( Map<String,String> parameters )
        {
            //Reload Record Types caches
            new RecordTypeHelper.RecordTypeCache().doLoad('ALL');
        }

    }

    @TestVisible
    @SuppressWarnings('PMD.ApexDoc')
    private class CronTriggerConf {
        public String key {get;set;}
        public String cronExp {get;set;}
        public String scope {get;set;}
    }

    /**
    *   @description        Shorthand for logging
    *   @param  message     detailed message to log
    *   @param  logLevel    the level of this log (Debug,Error,...)
    */
    private static void logInfo(String message, String logLevel) {
        UtilityLogger.logInfo(message, logLevel, 'DeployScript', 'N/A');
    }

    /**
    *  @description  Inits Batch Account Scrambling
    */
    public without sharing class InitBatchAccountScrambler implements DeployScriptMethod {

        /**
        *  @description
        *  Batch Account Scramble start on sandbox Refresh
        *  @param  parameters
        */
        public void run( Map<String,String> parameters )
        {
          if(parameters.get('CalledBy') != 'Deployment'){
            BatchAccountScrambler bas = new BatchAccountScrambler(true,null);
            Id batchId = Database.executeBatch(bas);
          }
        }
    }

    public without sharing class VCACRMNonChinaPublicGroupMembersAdded implements DeployScriptMethod {

        /**
        *  @description
        *  Add Group Members to RICSC_VCACRMNonChinaRoles public group
        *  @param  parameters
        */
        public void run( Map<String,String> parameters ){

            List<GroupMember> groupMemberList = new List<GroupMember>();
            GeneralSettings__c gst = GeneralSettings__c.getOrgDefaults();
            List<Group> roles = [SELECT Id FROM Group WHERE Type = 'Role' AND DeveloperName LIKE 'RICSC_VCACRM%' AND DeveloperName NOT IN: gst.RICSC_VCACRMNonChinaPublicGroupNoMembers__c.split(',')];
            Group g = [SELECT Id FROM Group WHERE DeveloperName = 'RICSC_VCACRMNonChinaRoles'];

            for(Group role : roles){
                GroupMember gm = new GroupMember();
                gm.UserOrGroupId = role.id;
                gm.GroupId = g.Id;
                groupMemberList.add(gm);
            }

              insert groupMemberList;
        }
    }

    /**
    *   @author       Piergiorgio Lisanti
    *   @date         30/09/2019
    *   @description  Loads RollupHelper Configurations by reading a csv in static resource
    */
    public without sharing class RollupHelperConfiguration implements DeployScriptMethod {

        public void run( Map<String,String> parameters )
        {
            insert Utility.staticResourceCSVToListOfSobject('rh2__PS_Export_Rollups__c');
        }

    }

}