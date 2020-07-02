@isTest
public class UtilityLogger_Test {

    @testSetup static void testSetup(){
        UtilityTests.testSetup();
    }

    /**
    * @method       logInfo
    * @scenario     New log insertion, debugLogEnabled = true
    **/
    @isTest static void testlogInfoDebugEnabled() {

        Integer numOfLogsBeforeDML = [SELECT COUNT() FROM Log__c];

        Test.startTest();
        UtilityLogger.logInfo('msg', 'logLevel', 'sourceClass', 'sourceMethod');
        Test.stopTest();

        Integer numOfLogsAfterDML = [SELECT COUNT() FROM Log__c];

        System.assert(numOfLogsAfterDML > numOfLogsBeforeDML);
    }

    /**
    * @method       logInfo
    * @scenario     Skip new log insertion, debugLogEnabled = false
    **/
    @isTest static void testLogInfoDebugDisabled() {

        // disable debugLog
        GeneralSettings__c generalSetting = GeneralSettings__c.getOrgDefaults();
        generalSetting.Logger_DebugEnabled__c = false;
        upsert generalSetting;

        Integer numOfLogsBeforeDML = [SELECT COUNT() FROM Log__c];

        Test.startTest();
        UtilityLogger.logInfo('msg', 'logLevel', 'sourceClass', 'sourceMethod');
        Test.stopTest();

        Integer numOfLogsAfterDML = [SELECT COUNT() FROM Log__c];

        System.assertEquals(numOfLogsAfterDML, numOfLogsBeforeDML);
    }

    /**
    * @method       logException
    * @scenario     New exception log insertion, debugLogEnabled = true
    **/
    @isTest static void testLogExceptionNewExceptionDebugEnabled() {

        Integer numOfExceptionLogsBeforeDML = [SELECT COUNT() FROM Log__c WHERE Type__c = 'Exception'];

        Test.startTest();
        CalloutException e = new CalloutException();
    	e.setMessage('This is a constructed exception!');
        UtilityLogger.logException(e ,'msg', 'sourceClass', 'sourceMethod');
        Test.stopTest();

        Integer numOfExceptionLogsAfterDML = [SELECT COUNT() FROM Log__c WHERE Type__c = 'Exception'];

        System.assertEquals(numOfExceptionLogsBeforeDML + 1, numOfExceptionLogsAfterDML);
    }

    /**
    * @method       logException
    * @scenario     Exception already exists, debugLogEnabled = true. The Count__c
    *               of the already existing exception should be increased by one,
    *               so it will be equal to 2.
    **/
    @isTest static void testLogExceptionExistingExceptionDebugEnabled() {

        Test.startTest();
        CalloutException e = new CalloutException();
    	e.setMessage('Test exception message');

        List<Log__c> logList = new List<Log__c>();

        Log__c log = new Log__c(
                                StackTrace__c = e.getStackTraceString(),
                                Limits__c = 'getLimits()',
                                Message__c = e.getMessage(),
                                Count__c = 1,
                                Type__c = 'Exception',
                                User__c = Userinfo.getUserId(),
                                DebugLevel__c = 'Error',
                                Source__c = 'sourceClass',
                                SourceMethod__c = 'sourceMethod',
                                TransactionID__c = 'testingIdHere'
                            );
        logList.add(log);
        insert logList;

        UtilityLogger.logException(e ,'msg', 'sourceClass', 'sourceMethod');
        Test.stopTest();

        List<Log__c> logs = [SELECT Count__c FROM Log__c WHERE TransactionID__c = 'testingIdHere' AND Type__c = 'Exception'];

        System.assert(logs[0].Count__c == 2);
    }

    /**
    * @method       logException
    * @scenario     Skip method code, debugLogEnabled = false
    **/
    @isTest static void testLogExceptionDebugDisabled() {
        // disable debugLog
        GeneralSettings__c generalSetting = GeneralSettings__c.getOrgDefaults();
        generalSetting.Logger_ExceptionEnabled__c = false;
        upsert generalSetting;

        Integer numOfExceptionLogsBeforeDML = [SELECT COUNT() FROM Log__c WHERE Type__c = 'Exception'];

        Test.startTest();
        CalloutException e = new CalloutException();
    	e.setMessage('This is a constructed exception!');
        UtilityLogger.logException(e ,'msg', 'sourceClass', 'sourceMethod');
        Test.stopTest();

        Integer numOfExceptionLogsAfterDML = [SELECT COUNT() FROM Log__c WHERE Type__c = 'Exception'];

        System.assertEquals(numOfExceptionLogsBeforeDML, numOfExceptionLogsAfterDML);
    }
}