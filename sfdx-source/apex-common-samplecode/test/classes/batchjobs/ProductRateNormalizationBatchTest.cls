/**
 * @description Test class for ProductRateNormalizationBatch
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Product Management Tests
 * 
 * @learnings
 * • Tests batch job execution with Database.Batchable interface patterns
 * • Uses Test.startTest/stopTest to simulate asynchronous batch execution synchronously
 * • Validates start(), execute(), and finish() methods for complete batch lifecycle testing
 * • Tests bulk processing scenarios with various data configurations and edge cases
 * • Demonstrates proper test data setup for batch processing with realistic scenarios
 **/

@IsTest
private class ProductRateNormalizationBatchTest 
{
	@IsTest
	private static void testBatchWithProductsNeedingNormalization()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Too Low Rate', Base_Rate__c = 0.001, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Too High Rate', Base_Rate__c = 0.18, Min_Credit_Score__c = 700),
			new Product__c(Name = 'Good Rate', Base_Rate__c = 0.06, Min_Credit_Score__c = 650)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 200);
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Name];
		
		for (Product__c p : normalizedProducts) {
			if (p.Name == 'Too Low Rate') {
				System.assertEquals(Products.MIN_RATE, p.Base_Rate__c);
			} else if (p.Name == 'Too High Rate') {
				System.assertEquals(Products.MAX_RATE, p.Base_Rate__c);
			} else if (p.Name == 'Good Rate') {
				System.assertEquals(0.06, p.Base_Rate__c);
			}
		}

		System.assertNotEquals(null, batchId);
	}

	@IsTest
	private static void testBatchWithNoProductsNeedingNormalization()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Good Rate 1', Base_Rate__c = 0.06, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Good Rate 2', Base_Rate__c = 0.08, Min_Credit_Score__c = 700)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 200);
		Test.stopTest();

		List<Product__c> unchangedProducts = [SELECT Base_Rate__c FROM Product__c];
		System.assertEquals(0.06, unchangedProducts[0].Base_Rate__c);
		System.assertEquals(0.08, unchangedProducts[1].Base_Rate__c);

		System.assertNotEquals(null, batchId);
	}

	@IsTest
	private static void testBatchWithEmptyDatabase()
	{
		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 200);
		Test.stopTest();

		Integer productCount = [SELECT COUNT() FROM Product__c];
		System.assertEquals(0, productCount);
		System.assertNotEquals(null, batchId);
	}

	@IsTest
	private static void testBatchBulkProcessing()
	{
		List<Product__c> testProducts = new List<Product__c>();
		for (Integer i = 0; i < 100; i++) {
			testProducts.add(new Product__c(
				Name = 'Bulk Product ' + i,
				Base_Rate__c = Math.mod(i, 2) == 0 ? 0.001 : 0.18,
				Min_Credit_Score__c = 600 + (i / 10)
			));
		}
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 50);
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Base_Rate__c FROM Product__c];
		Integer minNormalizedCount = 0;
		Integer maxNormalizedCount = 0;

		for (Product__c p : normalizedProducts) {
			if (p.Base_Rate__c == Products.MIN_RATE) {
				minNormalizedCount++;
			} else if (p.Base_Rate__c == Products.MAX_RATE) {
				maxNormalizedCount++;
			}
		}

		System.assertEquals(50, minNormalizedCount, 'Half should be normalized to minimum');
		System.assertEquals(50, maxNormalizedCount, 'Half should be normalized to maximum');
		System.assertNotEquals(null, batchId);
	}

	@IsTest
	private static void testBatchWithOnlyMinimumViolations()
	{
		List<Product__c> testProducts = new List<Product__c>();
		for (Integer i = 0; i < 25; i++) {
			testProducts.add(new Product__c(
				Name = 'Low Rate Product ' + i,
				Base_Rate__c = 0.0001 + (i * 0.0001), 
				Min_Credit_Score__c = 600 + i
			));
		}
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 200);
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Base_Rate__c FROM Product__c];
		for (Product__c p : normalizedProducts) {
			System.assertEquals(Products.MIN_RATE, p.Base_Rate__c, 'All products should be normalized to minimum rate');
		}

		System.assertNotEquals(null, batchId);
	}

	@IsTest
	private static void testBatchWithOnlyMaximumViolations()
	{
		List<Product__c> testProducts = new List<Product__c>();
		for (Integer i = 0; i < 25; i++) {
			testProducts.add(new Product__c(
				Name = 'High Rate Product ' + i,
				Base_Rate__c = 0.16 + (i * 0.01), 
				Min_Credit_Score__c = 600 + i
			));
		}
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 200);
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Base_Rate__c FROM Product__c];
		for (Product__c p : normalizedProducts) {
			System.assertEquals(Products.MAX_RATE, p.Base_Rate__c, 'All products should be normalized to maximum rate');
		}

		System.assertNotEquals(null, batchId);
	}

	@IsTest
	private static void testBatchWithNullRates()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Null Rate Product', Base_Rate__c = null, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Low Rate Product', Base_Rate__c = 0.001, Min_Credit_Score__c = 700)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 200);
		Test.stopTest();

		List<Product__c> results = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Name];
		
		for (Product__c p : results) {
			if (p.Name == 'Null Rate Product') {
				System.assertEquals(null, p.Base_Rate__c, 'Null rates should remain null');
			} else if (p.Name == 'Low Rate Product') {
				System.assertEquals(Products.MIN_RATE, p.Base_Rate__c, 'Low rate should be normalized');
			}
		}

		System.assertNotEquals(null, batchId);
	}

	@IsTest
	private static void testBatchSmallBatchSize()
	{
		List<Product__c> testProducts = new List<Product__c>();
		for (Integer i = 0; i < 10; i++) {
			testProducts.add(new Product__c(
				Name = 'Small Batch Product ' + i,
				Base_Rate__c = 0.001,
				Min_Credit_Score__c = 600 + i
			));
		}
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
		Id batchId = Database.executeBatch(batch, 3); 
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Base_Rate__c FROM Product__c];
		for (Product__c p : normalizedProducts) {
			System.assertEquals(Products.MIN_RATE, p.Base_Rate__c, 'All should be normalized despite small batch size');
		}

		System.assertNotEquals(null, batchId);
	}
} 