/******************************************************************************
* @author       Piergiorgio Lisanti
* @date         26/Aug/2019
* @description  This utility class helps in storing Log records with debug
*               or exception information automatically attached
******************************************************************************/
public without sharing class UtilityLogger {

    private static List<Log__c> debugInfoList = new List<Log__c>();

    private static boolean debugLogEnabled = GeneralSettings__c.getInstance().Logger_DebugEnabled__c;
    private static boolean exceptionLogEnabled = GeneralSettings__c.getInstance().Logger_ExceptionEnabled__c;

    public static final String LOG_TYPE_EXCEPTION   = 'Exception';
    public static final String LOG_TYPE_DEBUG       = 'Debug';

    public static final String LOG_LEVEL_DEBUG      = 'Debug';
    public static final String LOG_LEVEL_INFO       = 'Info';
    public static final String LOG_LEVEL_WARNING    = 'Warning';
    public static final String LOG_LEVEL_ERROR      = 'Error';


    /**
    * @description  Unique transaction id, it is generated the first time this variable
    *               is read during a transaction and stays the same until the end of the
    *               transaction. Used to uniquely identify transactions with external systems
    **/
    public static String transactionID {
        get{
            if (transactionID == null){
                transactionID =  String.valueOf(dateTime.now()) +
                '_' +
                (Long)(Math.random() * 10000000);
            }
            return transactionID;
        }
        private set;        //This value can only be changed from inside this class
    }

    /********************************************************************************************************
    * @description          see logInfo overload below
    * @param msg            the message to log
    * @param logLevel       the logging level
    * @param sourceClass    the source class that requested the log
    * @param sourceMethod   the source method the requested the log
    ********************************************************************************************************/
    public static void logInfo(String msg, String logLevel, String sourceClass, String sourceMethod) {
        logInfo(msg, logLevel, sourceClass, sourceMethod, true);
    }

    /********************************************************************************************************
    * @description  Mehtod used to log Information, if debugLogs are enabled it stores a record with provided
    *               information into Log__c table
    * @param msg            the message to log
    * @param logLevel       the logging level
    * @param sourceClass    the source class that requested the log
    * @param sourceMethod   the source method the requested the log
    * @param insertLogs     boolean parameter that can be used to delay log Insert DML operation
    ********************************************************************************************************/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void logInfo(String msg, String logLevel, String sourceClass, String sourceMethod, Boolean insertLogs) {

        if(debugLogEnabled != true){ return; }

        Log__c log = new Log__c(
                                    Count__c = 1,
                                    Message__c = msg,
                                    Limits__c = getLimits(),
                                    Type__c = LOG_TYPE_DEBUG,
                                    User__c = Userinfo.getUserId(),
                                    DebugLevel__c = logLevel,
                                    Source__c = sourceClass,
                                    SourceMethod__c = sourceMethod,
                                    TransactionID__c = transactionID
                                );

        debugInfoList.add(log);

        if(!debugInfoList.isEmpty() && insertLogs) {
            insert debugInfoList;
            debugInfoList.clear();
        }

    }

    /********************************************************************************************************
    * @description  Mehtod used to log all errors in a Database class dml call when using AllOrNone = false. It logs all errors in 1 dml
    * @param Database.SaveResult[] srList     the list of DatabaseSaveResults
    ********************************************************************************************************/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void logAllErrors(Object[] srList, Boolean isDeleteOperation, String className, String methodName) {

        if(debugLogEnabled != true){ return; }

        for (Object sr : srList) {

            if(!isDeleteOperation){
                Database.SaveResult srTyped = (Database.SaveResult) sr;
                if (!srTyped.isSuccess()) {
                    for(Database.Error e : srTyped.getErrors()) {
                        UtilityLogger.loginfo(e.getMessage(),UtilityLogger.LOG_LEVEL_ERROR,className,methodName, false);
                    }
                }
            } else {
                Database.DeleteResult srTyped = (Database.DeleteResult) sr;
                if (!srTyped.isSuccess()) {
                    for(Database.Error e : srTyped.getErrors()) {
                        UtilityLogger.loginfo(e.getMessage(),UtilityLogger.LOG_LEVEL_ERROR,className,methodName, false);
                    }
                }
            }
        }

        if(!debugInfoList.isEmpty()) {
            insert debugInfoList;
            debugInfoList.clear();
        }

    }

    /********************************************************************************************************
    * @description  Mehtod used to log Exceptions, if debugLogs are enabled it stores a record with provided
    *               exception into Log__c table
    * @param ex             the source exception that needs to be logged
    * @param msg            the message to log
    * @param sourceClass    the source class that requested the log
    * @param sourceMethod   the source method the requested the log
    ********************************************************************************************************/
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void logException(Exception ex, String msg, String sourceClass, String sourceMethod){

        if(exceptionLogEnabled != true){ return; }

        List<Log__c> exceptionList = new List<Log__c>();

        //Checking if the incoming exception has already occured today
        List<Log__c> existingException = checkExistingLog(ex.getMessage(), ex.getStackTraceString(), sourceClass, sourceMethod);

        //If the exception already occurred today then updating existing record
        if(existingException != null && !existingException.isEmpty()) {

            for(Log__c log : existingException) {

                log.Count__c = (log.Count__c != null ? log.Count__c + 1 : 1);

                exceptionList.add(log);
            }
        }else{

            Log__c log = new Log__c(
                                StackTrace__c = ex.getStackTraceString(),
                                Limits__c = getLimits(),
                                Message__c = ex.getMessage(),
                                Count__c = 1,
                                Type__c = LOG_TYPE_EXCEPTION,
                                User__c = Userinfo.getUserId(),
                                RawExceptionInformation__c = String.valueOf(ex),
                                DebugLevel__c = LOG_LEVEL_ERROR,
                                Source__c = sourceClass,
                                SourceMethod__c = sourceMethod,
                                TransactionID__c = transactionID
                            );
            exceptionList.add(log);
        }

        if(!exceptionList.isEmpty()){ upsert exceptionList; }

    }

    private static List<Log__c> checkExistingLog(String msg, String trace, String className, String methodName) {

        List<Log__c> existingLog = new List<Log__c>();

        for(Log__c log : [   SELECT Id, Count__c, Message__c, StackTrace__c FROM Log__c
                                        WHERE CreatedDate = TODAY
                                        AND Source__c =:className
                                        AND SourceMethod__c =:methodName]
                                    ) {

            if( String.isNotBlank(log.Message__c) && log.Message__c.containsIgnoreCase(msg) &&
                String.isNotBlank(log.StackTrace__c) && log.StackTrace__c.deleteWhitespace().containsIgnoreCase(trace.deleteWhitespace())) {

                existingLog.add(log);
                break;
            }
        }

        return existingLog;
    }

    private static String getLimits() {

        String limitstring;

        limitstring =  'Queries: '+ Limits.getQueries() + '/' + Limits.getLimitQueries() +'\n';
        limitstring += 'Query Locator Rows: '+Limits.getQueryLocatorRows() +'/'+Limits.getLimitQueryLocatorRows();
        limitstring += 'Query Rows: '+Limits.getQueryRows()+'/' + Limits.getLimitQueryRows()+'\n';
        limitstring += 'Aggregate Queries: '+Limits.getAggregateQueries()+'/' + Limits.getLimitAggregateQueries();
        limitstring += 'SOSL Queries: '+Limits.getSoslQueries()+'/' + Limits.getLimitSoslQueries();

        limitstring += 'DML Statements: '+Limits.getDMLStatements()+'/' +Limits.getLimitDMLStatements();
        limitstring += 'DML Rows: '+Limits.getDMLRows()+'/' + Limits.getLimitDMLRows()+'\n';

        limitstring += 'Heap Size: '+Limits.getHeapSize()+'/' +Limits.getLimitHeapSize()+'\n';
        limitstring += 'CPU Time: '+Limits.getCpuTime()+'/' +Limits.getLimitCpuTime();

        limitstring += 'Future Calls: '+Limits.getFutureCalls()+'/' +Limits.getLimitFutureCalls();
        limitstring += 'Queueable Calls: '+Limits.getQueueableJobs()+'/' +Limits.getLimitQueueableJobs();

        limitstring += 'Callouts: '+Limits.getCallouts()+'/' +Limits.getLimitCallouts();

        limitstring += 'Email Invocations: '+Limits.getEmailInvocations()+'/' +Limits.getLimitEmailInvocations();

        return limitstring;

    }
}