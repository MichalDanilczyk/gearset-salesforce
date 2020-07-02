public without sharing class UtilityTransaction {
  public static void calculateConventionRate(List<RICSC_Transaction__c> transactions, Set<String> currencyISO){
    List<DatedConversionRate> currencyConventionsToCorporateDatedExchangeRates = Utility.currencyConventionsToCorporateDatedExchangeRates(currencyISO);
    Map< String , CurrencyType> currencyConventionsToCorporateCurrencyType = Utility.currencyConventionsToCorporateCurrencyType(currencyISO);
    for(RICSC_Transaction__c tr : transactions){
      Boolean invalidCurrencyOnVCA = true;
      for(DatedConversionRate datedcurrencies : currencyConventionsToCorporateDatedExchangeRates){
        if(tr.RICSC_Maison__c == UtilityConstants.MAISON_VAN_CLEEF_ARPELS &&
          datedcurrencies.IsoCode == tr.RICSC_CurrencyKey__c &&
          datedcurrencies.NextStartDate != null &&
          datedcurrencies.NextStartDate >= tr.RICSC_ExtCreationDate__c &&
          datedcurrencies.StartDate <= tr.RICSC_ExtCreationDate__c
          )
        {
          Double currencyRate = (Double) datedcurrencies.ConversionRate;
          tr.RICSC_AmountWithTaxEUR__c = tr.RICSC_AmountWithTax__c * (Double)(1/currencyRate);
          tr.RICSC_CurrencyRateEUR__c = (Double)(1/currencyRate);
          InvalidCurrencyOnVCA = false;
        }
      }

      if(tr.RICSC_Maison__c == UtilityConstants.MAISON_VAN_CLEEF_ARPELS && InvalidCurrencyOnVCA == true){
          throw new TypeException(Label.Exception_InvalidCurrencyIsoCode);
      }


      if((tr.RICSC_Maison__c == UtilityConstants.MAISON_CARTIER || tr.RICSC_Maison__c == UtilityConstants.MAISON_JAEGER_LE_COULTRE) &&
          currencyConventionsToCorporateCurrencyType.containsKey(tr.RICSC_CurrencyKey__c))
      {
        Double currencyRate = (Double) currencyConventionsToCorporateCurrencyType.get(tr.RICSC_CurrencyKey__c).get('ConversionRate');
        tr.RICSC_AmountWithTaxEUR__c = tr.RICSC_AmountWithTax__c * (Double)(1/currencyRate);
        tr.RICSC_CurrencyRateEUR__c = (Double)(1/currencyRate);
      }else if(tr.RICSC_Maison__c == UtilityConstants.MAISON_CARTIER || tr.RICSC_Maison__c == UtilityConstants.MAISON_JAEGER_LE_COULTRE){
        throw new TypeException(Label.Exception_InvalidCurrencyIsoCode);
      }
    }
  }
}