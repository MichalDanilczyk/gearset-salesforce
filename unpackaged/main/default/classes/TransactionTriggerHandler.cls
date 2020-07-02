/******************************************************************************
@author Silvan Sholla
@date 15/Sep/2019
@description This is a container of all trigger classes on RICSC_Transaction__c object used within the trigger framework.
******************************************************************************/
public with sharing class TransactionTriggerHandler {

    public without sharing class VCARecordSharing implements TRG_TriggerHandlerInterface {

        public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
          Set<Id> accountIds = new Set<Id>();
          for(RICSC_Transaction__c trans : (List<RICSC_Transaction__c>) td.newList){
            if(trans.RICSC_Account__c != null){
              accountIds.add(trans.RICSC_Account__c);
            }
            if(trans.RICSC_GoldenRecord__c != null){
              accountIds.add(trans.RICSC_GoldenRecord__c);
            }
          }
          if(td.isInsert){
            SharingRuleTriggerHelper.AfterInsert(td.newList,accountIds,'RICSC_Transaction__share');
          }
          if(td.isUpdate){
            SharingRuleTriggerHelper.AfterUpdate(td.newList,td.oldMap,accountIds,'RICSC_Transaction__share');
          }
        }
    }

    public without sharing class MRScoreCalculation implements TRG_TriggerHandlerInterface {
        public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
          Set<id> accid = new Set<id>();
          if(td.isInsert){
            for(RICSC_Transaction__c trans : (List<RICSC_Transaction__c>)td.newList){
                accid.add(trans.RICSC_Account__c);
                accid.add(trans.RICSC_GoldenRecord__c);
            }
          }
          else if(td.IsUpdate){

            for(RICSC_Transaction__c tr : (List<RICSC_Transaction__c>)td.newList){
              if(tr.RICSC_GoldenRecord__c != td.oldMap.get(tr.Id).get('RICSC_GoldenRecord__c') ||
                    tr.RICSC_Account__c != td.oldMap.get(tr.Id).get('RICSC_Account__c') ||
                    tr.RICSC_AmountWithTaxEUR__c != td.oldMap.get(tr.Id).get('RICSC_AmountWithTaxEUR__c') ||
                    tr.RICSC_TransactionCategory__c != td.oldMap.get(tr.Id).get('RICSC_TransactionCategory__c') ||
                    tr.RICSC_TransactionDate__c != td.oldMap.get(tr.Id).get('RICSC_TransactionDate__c') ||
                    tr.RICSC_Boutique__c != td.oldMap.get(tr.Id).get('RICSC_Boutique__c') ||
                    tr.RICSC_Maison__c != td.oldMap.get(tr.Id).get('RICSC_Maison__c')){
                      accid.add(tr.RICSC_Account__c);
                      accid.add(tr.RICSC_GoldenRecord__c);
              }
            }
            if(accid.size()==0){
                return;
            }

          }
          Date before5years = System.now().addYears(-5).date();
          List<Account> accounts = [SELECT id,RICSC_MRScoreTurnover__c,RICSC_MRScoreFrequency__c,(SELECT id,RICSC_GoldenRecord__c,RICSC_AmountWithTaxEUR__c,RICSC_TransactionDate__c,RICSC_Maison__c,RICSC_TransactionCategory__c
                                                                          FROM RICSC_TransactionsAccount__r),(SELECT id,RICSC_Account__c,RICSC_AmountWithTaxEUR__c,RICSC_TransactionDate__c,RICSC_Maison__c,RICSC_TransactionCategory__c
                                                                          FROM RICSC_TransactionsGoldenRecord__r)
                                    From Account Where id  In :accid];

          Map<id,Set<Date>> transactionsDatesMap = new Map<id,Set<Date>>();
          for (Account a : accounts){
            a.RICSC_MRScoreTurnover__c=0;
            a.RICSC_MRScoreFrequency__c=0;
            transactionsDatesMap.put(a.id,new Set<Date>());
            Set<RICSC_Transaction__c> traccs = new Set<RICSC_Transaction__c>();
            if (a.RICSC_TransactionsAccount__r.size()>0){
              traccs.addAll(a.RICSC_TransactionsAccount__r);
            }
            if (a.RICSC_TransactionsGoldenRecord__r.size()>0){
              traccs.addAll(a.RICSC_TransactionsGoldenRecord__r);
            }
            for (RICSC_Transaction__c t : traccs){
              if(t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_REPAIR || (t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_SALES && (t.RICSC_AmountWithTaxEUR__c == 0 || t.RICSC_AmountWithTaxEUR__c == null))){
                continue;
              }
              if (t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_SALES){
                  if((t.RICSC_Maison__c==UtilityConstants.MAISON_CARTIER || t.RICSC_Maison__c==UtilityConstants.MAISON_VAN_CLEEF_ARPELS) && t.RICSC_TransactionDate__c != null){
                    if(t.RICSC_TransactionDate__c>=before5years){
                      if (!transactionsDatesMap.get(a.id).contains(t.RICSC_TransactionDate__c)){
                        a.RICSC_MRScoreFrequency__c++;
                        transactionsDatesMap.get(a.id).add(t.RICSC_TransactionDate__c);
                      }
                      if (t.RICSC_AmountWithTaxEUR__c == null){
                        t.RICSC_AmountWithTaxEUR__c = 0;
                      }
                      a.RICSC_MRScoreTurnover__c+=t.RICSC_AmountWithTaxEUR__c;
                      }
                    }
                  else if (t.RICSC_Maison__c==UtilityConstants.MAISON_JAEGER_LE_COULTRE && t.RICSC_TransactionDate__c != null){
                    if (!transactionsDatesMap.get(a.id).contains(t.RICSC_TransactionDate__c)){
                        a.RICSC_MRScoreFrequency__c++;
                        transactionsDatesMap.get(a.id).add(t.RICSC_TransactionDate__c);
                    }
                    if (t.RICSC_AmountWithTaxEUR__c == null){
                      t.RICSC_AmountWithTaxEUR__c = 0;
                    }
                    a.RICSC_MRScoreTurnover__c+=t.RICSC_AmountWithTaxEUR__c;
                  }
              } else if (t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_RETURN && t.RICSC_AmountWithTaxEUR__c != null){
                a.RICSC_MRScoreTurnover__c+=t.RICSC_AmountWithTaxEUR__c;
              }
            }
          }
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.AutomaticDeduplicationProcess',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.ClassCodeCalculation',true);
          Boolean skippingGRManualLinkTrigger = TRG_TriggerDispatcher.skipTriggerMap.containsKey('AccountTriggerHandler.GRManualLink') ? TRG_TriggerDispatcher.skipTriggerMap.get('AccountTriggerHandler.GRManualLink') : false;
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.LocalisationPropagation',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.CalculatingFields',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateCountryOfOriginOnRelatedObjects',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VCARecordSharing',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.HighJewelleryFlagPropagation',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateConsentsOnRecords',true);
          update accounts;
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.AutomaticDeduplicationProcess',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.ClassCodeCalculation',false);
          if(!skippingGRManualLinkTrigger){
            TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',false);
          }
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.LocalisationPropagation',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.CalculatingFields',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateCountryOfOriginOnRelatedObjects',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VCARecordSharing',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.HighJewelleryFlagPropagation',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateConsentsOnRecords',false);
        }
    }

    /******************************************************************************
     * @author Silvan Sholla
     * @date 15/Oct/2019
     * @description  This class contains trigger logic fired after transactions are inserted/modified/deleted.It computes calculated fields on Account records for the following fields:
     * Average Basket, First Sales Date, High Jewelery Pieces,High Jewelery Turnover, Highest High Jewelery ticket, Last Purchase Boutique,Last Purchase Market,Last Sales Date, Total Number of Repairs, Total Number of Sales
     * Top1, Top2, Top3 Boutiques
     * Top 1 , Top 2 ,Top 3 SA
    ******************************************************************************/
    public without sharing class CalculatingFields implements TRG_TriggerHandlerInterface {
      public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

        Set<Id> involvedAccIds = new Set<Id>();
        List<RICSC_Transaction__c> trgLst = td.IsDelete ? (List<RICSC_Transaction__c>) td.oldList : (List<RICSC_Transaction__c>) td.newList;

        for(RICSC_Transaction__c tr : trgLst){
          if(tr.RICSC_Account__c == null && tr.RICSC_GoldenRecord__c == null){
            continue;
          }
          if(td.isInsert){
            if(tr.RICSC_Account__c != null){
              involvedAccIds.add(tr.RICSC_Account__c);
            }
            if(tr.RICSC_GoldenRecord__c != null){
              involvedAccIds.add(tr.RICSC_GoldenRecord__c);
            }
          } else if(td.isUpdate){
              if(tr.RICSC_GoldenRecord__c != td.oldMap.get(tr.Id).get('RICSC_GoldenRecord__c') ||
                    tr.RICSC_Account__c != td.oldMap.get(tr.Id).get('RICSC_Account__c') ||
                    tr.RICSC_AmountWithTaxEUR__c != td.oldMap.get(tr.Id).get('RICSC_AmountWithTaxEUR__c') ||
                    tr.RICSC_TransactionCategory__c != td.oldMap.get(tr.Id).get('RICSC_TransactionCategory__c') ||
                    tr.RICSC_TransactionDate__c != td.oldMap.get(tr.Id).get('RICSC_TransactionDate__c') ||
                    tr.RICSC_Boutique__c != td.oldMap.get(tr.Id).get('RICSC_Boutique__c') ||
                    tr.RICSC_Channel__c != td.oldMap.get(tr.Id).get('RICSC_Channel__c') ||
                    tr.RICSC_Maison__c != td.oldMap.get(tr.Id).get('RICSC_Maison__c') ||
                    tr.RICSC_SalesAssociate__c != td.oldMap.get(tr.Id).get('RICSC_SalesAssociate__c')){

                if(tr.RICSC_Account__c != null){
                  involvedAccIds.add(tr.RICSC_Account__c);
                }
                if(tr.RICSC_GoldenRecord__c != null){
                  involvedAccIds.add(tr.RICSC_GoldenRecord__c);
                }
                //lookup changed Account or GR or both
                if(tr.RICSC_Account__c != td.oldMap.get(tr.Id).get('RICSC_Account__c') &&
                    td.oldMap.get(tr.Id).get('RICSC_Account__c') != null){

                  involvedAccIds.add((td.oldMap.get(tr.Id).get('RICSC_Account__c')).toString());
                }
                if(tr.RICSC_GoldenRecord__c != td.oldMap.get(tr.Id).get('RICSC_GoldenRecord__c') &&
                    td.oldMap.get(tr.Id).get('RICSC_GoldenRecord__c') != null){

                  involvedAccIds.add(td.oldMap.get(tr.Id).get('RICSC_GoldenRecord__c').toString());
                }
            }
          } else if(td.isDelete){
            if(tr.RICSC_Account__c != null){
              involvedAccIds.add(tr.RICSC_Account__c);
            }
            if(tr.RICSC_GoldenRecord__c != null){
              involvedAccIds.add(tr.RICSC_GoldenRecord__c);
            }
          }
        }
        if(involvedAccIds.size()>0){
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.LocalisationPropagation',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateCountryOfOriginOnRelatedObjects',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.HighJewelleryFlagPropagation',true);
          Boolean skippingGRManualLinkTrigger = TRG_TriggerDispatcher.skipTriggerMap.containsKey('AccountTriggerHandler.GRManualLink') ? TRG_TriggerDispatcher.skipTriggerMap.get('AccountTriggerHandler.GRManualLink') : false;
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VCARecordSharing',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateConsentsOnRecords',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',true);
          update CalculatingFieldsHandler.computeFieldsFromTransactionRecords(involvedAccIds);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.LocalisationPropagation',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateCountryOfOriginOnRelatedObjects',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.HighJewelleryFlagPropagation',false);
          if(!skippingGRManualLinkTrigger){
            TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',false);
          }
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VCARecordSharing',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.PropagateConsentsOnRecords',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',false);
        }
    }
  }

/******************************************************************************
  * @author       Piergiorgio Lisanti
  * @date         15/Nov/2019
  * @description  Refactor: This class contains trigger logic fired after transactions are inserted/modified/deleted.
  *               It computes RICSC_ResidentNonResident__c calculated field on Account records based on related transactions and addresses records.
  *               - Resident --> all transactions in the residency addresses
  *               - Non-Resident --> no transactions in the residency addresses
  *               - Traveller --> only part of transactions in the residency addresses
  ******************************************************************************/
  public without sharing class ResidencyFieldsOnAccount implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Set<Id> accIds = new Set<Id>();
      Set<Id> accIdsGR = new Set<Id>();
      List<RICSC_Transaction__c> involvedTransactions = new List<RICSC_Transaction__c>();
      involvedTransactions = td.isDelete ? (List<RICSC_Transaction__c>) td.oldList : (List<RICSC_Transaction__c>) td.newList;

      for(RICSC_Transaction__c trans : involvedTransactions){
        if(td.isInsert){
          if(trans.RICSC_CountryOfOrigin__c != null ){
            if(trans.RICSC_Account__c != null){
              accIds.add(trans.RICSC_Account__c);
            }
            if(trans.RICSC_GoldenRecord__c != null){
              accIdsGR.add(trans.RICSC_GoldenRecord__c);
            }
          }
        } else if(td.isUpdate){
          if((trans.RICSC_CountryOfOrigin__c != td.oldMap.get(trans.Id).get('RICSC_CountryOfOrigin__c') ||
            trans.RICSC_Account__c != td.oldMap.get(trans.Id).get('RICSC_Account__c')) && trans.RICSC_Account__c != null){
              accIds.add(trans.RICSC_Account__c);
              if(trans.RICSC_Account__c != td.oldMap.get(trans.Id).get('RICSC_Account__c') && td.oldMap.get(trans.Id).get('RICSC_Account__c')!=null){
                accIds.add((Id)td.oldMap.get(trans.Id).get('RICSC_Account__c'));
              }
          }
          if((trans.RICSC_CountryOfOrigin__c != td.oldMap.get(trans.Id).get('RICSC_CountryOfOrigin__c') ||
            trans.RICSC_GoldenRecord__c != td.oldMap.get(trans.Id).get('RICSC_GoldenRecord__c')) && trans.RICSC_GoldenRecord__c != null){

              accIdsGR.add(trans.RICSC_GoldenRecord__c);
              if(trans.RICSC_GoldenRecord__c != td.oldMap.get(trans.Id).get('RICSC_GoldenRecord__c') && td.oldMap.get(trans.Id).get('RICSC_GoldenRecord__c')!=null){
                accIds.add((Id) td.oldMap.get(trans.Id).get('RICSC_GoldenRecord__c'));
              }
          }
        }else if(td.isDelete && trans.RICSC_CountryOfOrigin__c != null){
            if(trans.RICSC_Account__c != null){
              accIds.add(trans.RICSC_Account__c);
            }
            if(trans.RICSC_GoldenRecord__c != null){
              accIdsGR.add(trans.RICSC_GoldenRecord__c);
            }
        }
      }

      if(accIds.size()>0){
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        update CalculatingFieldsHandler.computeResidenceNonResidence(accIds,'RICSC_Account__c',false);
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
      }
      if(accIdsGR.size()>0){
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        update CalculatingFieldsHandler.computeResidenceNonResidence(accIdsGR,'RICSC_GR__c',false);
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
      }
    }
  }

  /******************************************************************************
  * @author       Maurizio D'Antonio
  * @date         28/Oct/2019
  * @description  If the field RICSC_AmountWithTaxEUR__c changes or if a transaction
                  is insert/deleted we need to (re)calculate the segment of the
                  related Golden Record Account.
  ******************************************************************************/
  public without sharing class CalculateGRSegment implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Set<Id> grIds = new Set<Id>();
      List<RICSC_Transaction__c> transactions = new List<RICSC_Transaction__c>();
      if(td.isInsert || td.isUpdate){
         transactions = (List<RICSC_Transaction__c>)td.newList;
      }
      else{
        transactions = (List<RICSC_Transaction__c>)td.oldList;
      }
      for(RICSC_Transaction__c tr : transactions){
        if(td.isInsert || td.isDelete || (td.oldMap.get(tr.Id).get('RICSC_AmountWithTaxEUR__c') != tr.RICSC_AmountWithTaxEUR__c)){
          if(tr.RICSC_GoldenRecord__c != null){
            grIds.add(tr.RICSC_GoldenRecord__c);
          }
          // else if(tr.RICSC_Account__r.RICSC_IsGoldenRecord__c){
          //   grIds.add(tr.RICSC_Account__c);
          // }
        }
      }
      if(grIds.size() > 0){
        UtilityAccount.calculateSegment(grIds, true, false);
      }
    }
  }

  public without sharing class ConventionRateCalculation implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Boolean runIt = false;
      Set<Id> accIds = new Set<Id>();
      List<RICSC_Transaction__c> transactionsAfterUpdate = new List<RICSC_Transaction__c>();
      Set<String> currencyISO = new Set<String>();
      if(td.isInsert){
        for(RICSC_Transaction__c tr : (List<RICSC_Transaction__c>) td.newList){
          if(tr.RICSC_AmountWithTax__c != null && tr.RICSC_CurrencyKey__c != null && tr.RICSC_Maison__c != null){
            accIds.add(tr.RICSC_Account__c);
            transactionsAfterUpdate.add(tr);
            currencyISO.add(tr.RICSC_CurrencyKey__c);
            runIt = true;
          }
        }
      }else if(td.isUpdate){
        for(RICSC_Transaction__c tr : (List<RICSC_Transaction__c>) td.newList){
          if((tr.RICSC_AmountWithTax__c != td.oldMap.get(tr.Id).get('RICSC_AmountWithTax__c') ||
            tr.RICSC_CurrencyKey__c != td.oldMap.get(tr.Id).get('RICSC_CurrencyKey__c') ||
            tr.RICSC_Maison__c != td.oldMap.get(tr.Id).get('RICSC_Maison__c'))
            && tr.RICSC_AmountWithTax__c != null && tr.RICSC_CurrencyKey__c != null && tr.RICSC_Maison__c != null){
            accIds.add(tr.RICSC_Account__c);
            currencyISO.add(tr.RICSC_CurrencyKey__c);
            transactionsAfterUpdate.add(tr);
            runIt = true;
          }
        }
      }

      if(runIt){
        UtilityTransaction.calculateConventionRate(transactionsAfterUpdate, currencyISO);
      }
    }
  }

  /************************************************************************************
  * @author       Silvan Sholla
  * @date         9/9/2019
  * @description  Population of Product portfolio records related to
  *               an account based on linked transaction records.
  *               With The Following Criteria :
  *
  *               1. if there is a match between transaction and asset serial number
  *               and the amount with tax is possitive update asset with values
  *               from transaction
  *               else if there is a match with serial number but the amount with
  *               tax is negative mark product refunded as true
  *
  *               2.If there is not match between transaction and asset serial number
  *               create a new asset with the transaction fields link to the same account
  ***************************************************************************************/

  public without sharing class ProductPortfolioIntegrationTRG implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      List<RICSC_Transaction__c> trList = new List<RICSC_Transaction__c>();
      for(RICSC_Transaction__c tr :(List<RICSC_Transaction__c>) td.newList){
        if((tr.RICSC_TransactionCategory__c == UtilityConstants.TRANSACTION_TYPE_SALES)){
          trList.add(tr);
        }
      }
      TRG_TriggerDispatcher.skipTriggerMap.put('ProductPortfolioTriggerHandler.DuplicateCheck',true);
      Database.upsert(ProductPortfolioIntegration.productPortfolioTransactionPropagation(trList),false);
      TRG_TriggerDispatcher.skipTriggerMap.put('ProductPortfolioTriggerHandler.DuplicateCheck',false);
    }
  }

  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of transaction based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('RICSC_TransactionsAccount__r','RICSC_Account__c','RICSC_GoldenRecord__c','TransactionTriggerHandler',td.newList);
    }
  }
}