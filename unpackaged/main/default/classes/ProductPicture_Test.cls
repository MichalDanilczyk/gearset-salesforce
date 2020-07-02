@isTest
public with sharing class ProductPicture_Test {

    static testmethod void getProductPictureInfosForLWC(){
      List<Product2> prod = UtilityTests.getProducts(2);
      prod[0].RICSC_FrontPictureURL__c = 'www.testurl.turl';
      prod[0].Name = 'TestProductWithURL';
      prod[1].Name = 'TestProductWithoutURL';
      insert prod;
      List<Product2> prodId = [SELECT id FROM Product2 WHERE Name = 'TestProductWithURL' OR Name = 'TestProductWithoutURL' ORDER BY Name DESC];

      List<RICSC_Transaction__c> trans = UtilityTests.getTransactions(2);
      trans[0].RICSC_ProductName__c=prodId[0].id;
      trans[1].RICSC_ProductName__c=prodId[1].id;
      insert trans;
      List<RICSC_Transaction__c> tranId = [SELECT id FROM RICSC_Transaction__c WHERE RICSC_ProductName__c =: prodId[0].id OR RICSC_ProductName__c =: prodId[1].id];
      ProductPicture.CustomWrapper transres1 = ProductPicture.getProductURL(tranId[0].id);
      ProductPicture.CustomWrapper transres2 = ProductPicture.getProductURL(tranId[1].id);
      System.assertEquals(transres1.name,'TestProductWithURL');
      System.assertEquals(transres1.url,'www.testurl.turl');
      System.assertEquals(transres2.name,'TestProductWithoutURL');
      System.assertEquals(transres2.url,'');
      List<RICSC_Wishlist__c> wishs = UtilityTests.getWishlists(2);
      wishs[0].RICSC_ProductName__c=prodId[0].id;
      wishs[1].RICSC_ProductName__c=prodId[1].id;
      insert wishs;
      List<RICSC_Wishlist__c> wishId = [SELECT id FROM RICSC_Wishlist__c WHERE RICSC_ProductName__c =: prodId[0].id OR RICSC_ProductName__c =: prodId[1].id];
      ProductPicture.CustomWrapper wishres1 = ProductPicture.getProductURL(wishId[0].id);
      ProductPicture.CustomWrapper wishres2 = ProductPicture.getProductURL(wishId[1].id);
      System.assertEquals(wishres1.name,'TestProductWithURL');
      System.assertEquals(wishres1.url,'www.testurl.turl');
      System.assertEquals(wishres2.name,'TestProductWithoutURL');
      System.assertEquals(wishres2.url,'');
      List<Asset> assets = UtilityTests.getAssets(2);
      assets[0].Product2Id=prodId[0].id;
      assets[0].Name = 'TEstAsset0';
      assets[1].Product2Id=prodId[1].id;
      assets[1].Name = 'TEstAsset1';
      insert assets;
      List<Asset> assetId = [SELECT id FROM Asset WHERE Product2Id =: prodId[0].id OR Product2Id =: prodId[1].id];
      ProductPicture.CustomWrapper assetres1 = ProductPicture.getProductURL(assetId[0].id);
      ProductPicture.CustomWrapper assetres2 = ProductPicture.getProductURL(assetId[1].id);
      System.assertEquals(assetres1.name,'TestProductWithURL');
      System.assertEquals(assetres1.url,'www.testurl.turl');
      System.assertEquals(assetres2.name,'TestProductWithoutURL');
      System.assertEquals(assetres2.url,'');
    }

}