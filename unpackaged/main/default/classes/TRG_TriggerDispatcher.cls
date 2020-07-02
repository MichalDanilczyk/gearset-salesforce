/******************************************************************************
* @author       Piergiorgio Lisanti
* @date         22/Aug/2019
* @description  This class is part of the Trigger Framework and controls the
*               execution of triggers based on configuration for current user.
*               It invokes configured handler classes depending on the
*               Trigger Object and Trigger event
******************************************************************************/
public without sharing class TRG_TriggerDispatcher {

    public static Map<String, Boolean> skipTriggerMap = new Map<String, Boolean>();
    private static final String SCOPE = GeneralSettings__c.getInstance().Scope__c;
    private static final TRG_TriggerSettings__c SETTINGS = TRG_TriggerSettings__c.getInstance();

    /******************************************************************************
    * @description  Entry point to be invoked by the trigger following the
    *               Trigger Framework
    * @param        TriggerObject - String denoting the object type of trigger.
    * @param        IsBefore, IsDelete, IsAfter, IsInsert, IsUpdate, IsExecuting -
                    Boolean denoting the trigger event that caused the trigger
    * @param        newList, oldlist - SObject list that hold the old and new values
                    of the records contained by the trigger
    * @param        newmap, oldmap - Map that holds the old data map and new data map
                    of the records contained by the trigger
    ******************************************************************************/
    @SuppressWarnings('PMD.ExcessiveParameterList,PMD.ApexDoc,PMD.CyclomaticComplexity')
    public static void mainEntry(
        String triggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isUndelete, Boolean isExecuting,
        List<SObject> newList, Map<ID,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldMap)
    {

        try{

            TriggerData td = new TriggerData(isBefore, isDelete, isAfter, isInsert, isUpdate, isUndelete,
                                    isExecuting,newList, newMap, oldList, oldMap);

            String eventFired = getEvent(isBefore, isAfter, isInsert, isUpdate, isDelete, isUndelete);

            //Check that Trigger is enabled for current user
            if(!isTriggerEnabledForCurrentUser(triggerObject)){
                System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry : ' + triggerObject + ' on ' + eventFired + ' - All Trigger - SKIPPED - Reason: TriggerSettings for current user');
                return;
            }

            //The Custom Metadata contains for the specified Scope, Object and Event the right sequence of method that needs to be performed
            for(TRG_TriggerConf__mdt thc : TRG_TriggerDispatcher.getCustomMetdataConfigurations(triggerObject, eventFired)){

                if(skipTriggerMap != null && skipTriggerMap.containsKey(triggerObject) && skipTriggerMap.get(triggerObject) == true ){
                    System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry : ' + thc.Object__c + ' on ' + eventFired + ' - All Trigger - SKIPPED - Reason: TriggerMap');
                    break;
                }

                if(skipTriggerMap != null && skipTriggerMap.containsKey(thc.Class__c.deleteWhitespace()) && skipTriggerMap.get(thc.Class__c.deleteWhitespace()) == true ){
                    System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry : ' + thc.Object__c + ' on ' + eventFired + ' - ' + thc.Class__c+' - SKIPPED - Reason: TriggerMap method');
                    continue;
                }

                //Check if Trigger Method enabled for current user
                if(String.IsNotBlank(SETTINGS.DisableTriggerMethods__c) && SETTINGS.DisableTriggerMethods__c.split('\r\n').contains(thc.Class__c)){
                    System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry : ' + thc.Object__c + ' on ' + eventFired + ' - ' + thc.Class__c+' - SKIPPED - Reason: TriggerSettings Methods for current user');
                    continue;
                }

                //Check that Trigger is enabled for current user
                if(!isTriggerEnabledOnLeanLoad(thc)){
                    System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry : ' + triggerObject + ' on ' + eventFired + ' - All Trigger - SKIPPED - Reason: TriggerSettings:CheckEnabledOnLeanLoad');
                    continue;
                }

                System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry : ' + thc.Object__c + ' on ' + eventFired + ' - ' + thc.Class__c+' - START');
                Long startTime = System.CurrentTimeMillis();
                Type tHandler = Type.forName(thc.Class__c.deleteWhitespace());

                if(SETTINGS.PrintLimitsInDebug__c){
                  System.debug('==> Starting trigger for ' + thc.Object__c + ' - ' + thc.Class__c);
                  System.debug('==> CPU time: ' + Limits.getCpuTime() + ' with limit of ' + Limits.getLimitCpuTime());
                  System.debug('==> Queries: ' + Limits.getQueries() + ' with limit of ' + Limits.getLimitQueries());
                  System.debug('==> DML statements: ' + Limits.getDmlStatements() + ' with limit of ' + Limits.getLimitDmlStatements());
                  System.debug('==> DML rows: ' + Limits.getDmlRows() + ' with limit of ' + Limits.getLimitDmlRows());
                  System.debug('==> Heap size: ' + Limits.getHeapSize() + ' with limit of ' + Limits.getLimitHeapSize());
                }

                TRG_TriggerHandlerInterface activeFunction = (TRG_TriggerHandlerInterface) tHandler.newInstance();
                activeFunction.runTriggerHandler(td);

                if(SETTINGS.PrintLimitsInDebug__c){
                  System.debug('==> Ended trigger for ' + thc.Object__c + ' - ' + thc.Class__c);
                  System.debug('==> CPU time: ' + Limits.getCpuTime() + ' with limit of ' + Limits.getLimitCpuTime());
                  System.debug('==> Queries: ' + Limits.getQueries() + ' with limit of ' + Limits.getLimitQueries());
                  System.debug('==> DML statements: ' + Limits.getDmlStatements() + ' with limit of ' + Limits.getLimitDmlStatements());
                  System.debug('==> DML rows: ' + Limits.getDmlRows() + ' with limit of ' + Limits.getLimitDmlRows());
                  System.debug('==> Heap size: ' + Limits.getHeapSize() + ' with limit of ' + Limits.getLimitHeapSize());
                }

                System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry : ' + thc.Object__c + ' on ' + eventFired + ' - ' + thc.Class__c + ' - END - '+(System.CurrentTimeMillis() - startTime)+' ms');
            }

        }catch(Exception e){

            System.debug(LoggingLevel.ERROR, 'TriggerDispatcher.mainEntry - EXCEPTION : Exception type caught: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'TriggerDispatcher.mainEntry - EXCEPTION : Message: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'TriggerDispatcher.mainEntry - EXCEPTION : Cause: ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'TriggerDispatcher.mainEntry - EXCEPTION : Line number: ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR, 'TriggerDispatcher.mainEntry - EXCEPTION : Stack trace: ' + e.getStackTraceString());

            throw e;

        }

    }

    @TestVisible
    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static List<TRG_TriggerConf__mdt> getCustomMetdataConfigurations(String triggerObject, String eventFired){

        String triggerConfigurationQuery = 'SELECT Id, Object__c, Class__c, EnabledOnLeanLoad__c, OrderOFExecution__c FROM TRG_TriggerConf__mdt';
        triggerConfigurationQuery += ' WHERE (Scope__c =: SCOPE OR Scope__c =\'GL\') AND IsActive__c = TRUE';
        triggerConfigurationQuery += ' AND Object__c =: triggerObject';
        triggerConfigurationQuery += ' AND ' + eventFired + '__c = TRUE';
        triggerConfigurationQuery += ' ORDER BY OrderOFExecution__c ASC';

        System.debug(LoggingLevel.INFO, 'TriggerDispatcher.mainEntry - QUERY : '+triggerConfigurationQuery);

        return Database.query(triggerConfigurationQuery);

    }

    @TestVisible
    private static Boolean isTriggerEnabledForCurrentUser(String triggerObject){

        if( SETTINGS.DisableAllTriggers__c == true ){ return false; }

        if( String.IsNotBlank(SETTINGS.DisableTriggerObjects__c) &&
            SETTINGS.DisableTriggerObjects__c.split('\r\n').contains(triggerObject)
        ){
            return false;
        }

        return true;
    }

    @TestVisible
    private static Boolean isTriggerEnabledOnLeanLoad(TRG_TriggerConf__mdt thc){

        if( !thc.EnabledOnLeanLoad__c && SETTINGS.CheckEnabledOnLeanLoad__c){ return false; }

        return true;
    }

    @TestVisible
    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static String getEvent(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete){

        String queryEvent = (isBefore) ? 'Before' : 'After';

        if(isInsert){
            return queryEvent+'Insert';
        } else if(isUpdate){
            return queryEvent+'Update';
        } else if(isDelete){
            return queryEvent+'Delete';
        }else{
            return queryEvent+'Undelete';
        }

    }

    @SuppressWarnings('PMD.ApexDoc')
    public class TriggerData {

        public Boolean isBefore {get; private set;}
        public Boolean isAfter {get; private set;}

        public Boolean isDelete {get; private set;}
        public Boolean isInsert {get; private set;}
        public Boolean isUpdate {get; private set;}
        public Boolean isUndelete {get; private set;}

        public Boolean isExecuting {get; private set;}


        public List<SObject> newList {get; private set;}
        public Map<Id,SObject> newMap {get; private set;}
        public List<SObject> oldList {get; private set;}
        public Map<Id,SObject> oldMap {get; private set;}

        @SuppressWarnings('PMD.ExcessiveParameterList')
        private TriggerData(
            Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert,Boolean isUpdate, Boolean isUndelete, Boolean isExecuting,
            List<SObject> newList, Map<Id,SObject> newMap, List<SObject> oldList, Map<Id,SObject> oldMap
            ) {

            this.isBefore = isBefore;
            this.isAfter = isAfter;
            this.isDelete = isDelete;
            this.isInsert = isInsert;
            this.isUpdate = isUpdate;
            this.isUndelete = isUndelete;
            this.isExecuting = isExecuting;

            this.newList = newList;
            this.newMap = newMap;
            this.oldList = oldList;
            this.oldMap = oldMap;
        }
    }

}