@isTest
private class BatchMRScoreCalculation_Test {
    @testSetup
    static void setup() {
      UtilityTests.testSetup();
      TRG_TriggerDispatcher.skipTriggerMap.put('TransactionTriggerHandler.MRScoreCalculation',true);
      List<Account> accs = new List<Account>();
      Account mrScore1 = UtilityTests.getPersonAccount();
      mrScore1.LastName = 'MRScore1';
      Account mrScore2 = UtilityTests.getPersonAccount();
      mrScore2.LastName = 'MRScore2';
      Account mrScore3 = UtilityTests.getPersonAccount();
      mrScore3.LastName = 'MRScore3';
      insert mrScore1;
      insert mrScore2;
      insert mrScore3;
      List<RICSC_Transaction__c> instrans = new List<RICSC_Transaction__c>();
      RICSC_Transaction__c trCARNor = new RICSC_Transaction__c(RICSC_Account__c=mrScore1.id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='1000',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trCARRep = new RICSC_Transaction__c(RICSC_Account__c=mrScore1.id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_RETURN,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='1000',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trCARNor2 = new RICSC_Transaction__c(RICSC_Account__c=mrScore1.id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='1001',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trCARNor2nullAm = new RICSC_Transaction__c(RICSC_Account__c=mrScore1.id,RICSC_Maison__c='Cartier',RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().adddays(-5).date(),RICSC_SerialNumber__c='1002',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trCARNorbef = new RICSC_Transaction__c(RICSC_Account__c=mrScore1.id,RICSC_Maison__c='Cartier',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().addyears(-6).date(),RICSC_SerialNumber__c='1003',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trJLCNor = new RICSC_Transaction__c(RICSC_Account__c=mrScore2.id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3000',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trJLCNorbef = new RICSC_Transaction__c(RICSC_Account__c=mrScore2.id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().addyears(-7).date(),RICSC_SerialNumber__c='3003',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trJLCNorGR = new RICSC_Transaction__c(RICSC_Account__c=MRScore3.id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3001',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trJLCNorGRnullAm = new RICSC_Transaction__c(RICSC_Account__c=MRScore3.id,RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3002',RICSC_CurrencyKey__c='EUR');
      RICSC_Transaction__c trJLCCSGRnullAm = new RICSC_Transaction__c(RICSC_Account__c=mrScore3.id, RICSC_Maison__c='Jaeger Le Coultre',RICSC_AmountWithTaxEUR__c=1000,RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_REPAIR,RICSC_TransactionDate__c=System.now().date(),RICSC_SerialNumber__c='3003',RICSC_CurrencyKey__c='EUR');
      instrans.add(trCARNor);
      instrans.add(trCARNor2);
      instrans.add(trCARNor2nullAm);
      instrans.add(trCARRep);
      instrans.add(trCARNorbef);
      instrans.add(trJLCNorbef);
      instrans.add(trJLCNor);
      instrans.add(trJLCNorGR);
      instrans.add(trJLCNorGRnullAm);
      instrans.add(trJLCCSGRnullAm);
      insert instrans;
    }

    static testmethod void test() {
      Test.startTest();
      BatchMRScoreCalculation uca = new BatchMRScoreCalculation(true,null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      List<Account> resins = [SELECT Id,RICSC_MasterRecordScore__c FROM Account Where Name = 'MRScore1' OR Name = 'MRScore2' OR Name = 'MRScore3' Order By Name DESC];
      System.assertEquals(2000,resins[0].RICSC_MasterRecordScore__c, 'Wrong MR score');
      System.assertEquals(4000,resins[1].RICSC_MasterRecordScore__c, 'Wrong MR score');
      System.assertEquals(3000,resins[2].RICSC_MasterRecordScore__c, 'Wrong MR score');
    }


}