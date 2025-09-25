/**
 * @description Test class for ProductRateNormalizationService
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Product Management Tests
 * 
 * @learnings
 * • Tests service layer orchestration using ApexMocks for selector dependencies
 * • Demonstrates service testing patterns: setup mocks, configure behavior, execute service, verify interactions
 * • Uses both integration tests (with real data) and unit tests (with mocks) for comprehensive coverage
 * • Validates bulk processing scenarios and governor limit considerations
 * • Shows proper test structure: arrange (setup), act (execute), assert (verify)
 **/

@IsTest
private class ProductRateNormalizationServiceTest 
{
	@IsTest
	private static void testNormalizeProductRatesWithData()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Too Low Rate', Base_Rate__c = 0.001, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Too High Rate', Base_Rate__c = 0.18, Min_Credit_Score__c = 700),
			new Product__c(Name = 'Normal Rate', Base_Rate__c = 0.06, Min_Credit_Score__c = 650)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates();
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Name];
		
		for (Product__c p : normalizedProducts) {
			if (p.Name == 'Too Low Rate') {
				System.assertEquals(Products.MIN_RATE, p.Base_Rate__c);
			} else if (p.Name == 'Too High Rate') {
				System.assertEquals(Products.MAX_RATE, p.Base_Rate__c);
			} else if (p.Name == 'Normal Rate') {
				System.assertEquals(0.06, p.Base_Rate__c);
			}
		}
	}

	@IsTest
	private static void testNormalizeProductRatesWithBatchSize()
	{
		List<Product__c> testProducts = new List<Product__c>();
		for (Integer i = 0; i < 50; i++) {
			testProducts.add(new Product__c(
				Name = 'Product ' + i,
				Base_Rate__c = 0.001,
				Min_Credit_Score__c = 600 + i
			));
		}
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates(25);
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Base_Rate__c FROM Product__c];
		Integer normalizedCount = 0;
		for (Product__c p : normalizedProducts) {
			if (p.Base_Rate__c == Products.MIN_RATE) {
				normalizedCount++;
			}
		}
		
		System.assert(normalizedCount >= 25, 'At least 25 products should be normalized due to batch size limit');
	}

	@IsTest
	private static void testNormalizeProductRatesNoProductsNeedingNormalization()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Good Rate 1', Base_Rate__c = 0.06, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Good Rate 2', Base_Rate__c = 0.08, Min_Credit_Score__c = 700)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates();
		Test.stopTest();

		List<Product__c> unchangedProducts = [SELECT Base_Rate__c FROM Product__c];
		System.assertEquals(0.06, unchangedProducts[0].Base_Rate__c);
		System.assertEquals(0.08, unchangedProducts[1].Base_Rate__c);
	}

	@IsTest
	private static void testGetProductsNeedingNormalizationCount()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Too Low', Base_Rate__c = 0.001, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Too High', Base_Rate__c = 0.18, Min_Credit_Score__c = 700),
			new Product__c(Name = 'Good Rate', Base_Rate__c = 0.06, Min_Credit_Score__c = 650)
		};
		insert testProducts;

		Test.startTest();
		Integer count = ProductRateNormalizationService.getProductsNeedingNormalizationCount();
		Test.stopTest();

		System.assertEquals(2, count);
	}

	@IsTest
	private static void testNormalizeProductRatesEmptyDatabase()
	{
		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates();
		Integer count = ProductRateNormalizationService.getProductsNeedingNormalizationCount();
		Test.stopTest();

		System.assertEquals(0, count);
	}

	@IsTest
	private static void testNormalizeProductRatesBulkProcessing()
	{
		List<Product__c> testProducts = new List<Product__c>();
		for (Integer i = 0; i < 200; i++) {
			testProducts.add(new Product__c(
				Name = 'Bulk Product ' + i,
				Base_Rate__c = Math.mod(i, 2) == 0 ? 0.001 : 0.18,
				Min_Credit_Score__c = 600 + (i / 10)
			));
		}
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates();
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

		System.assertEquals(100, minNormalizedCount, 'Half should be normalized to minimum');
		System.assertEquals(100, maxNormalizedCount, 'Half should be normalized to maximum');
	}

	@IsTest
	private static void testNormalizeWithZeroBatchSize()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Test Product', Base_Rate__c = 0.001, Min_Credit_Score__c = 600)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates(0);
		Test.stopTest();

		Product__c result = [SELECT Base_Rate__c FROM Product__c LIMIT 1];
		System.assertEquals(Products.MIN_RATE, result.Base_Rate__c);
	}

	@IsTest
	private static void testNormalizeWithNegativeBatchSize()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Test Product', Base_Rate__c = 0.001, Min_Credit_Score__c = 600)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates(-10);
		Test.stopTest();

		Product__c result = [SELECT Base_Rate__c FROM Product__c LIMIT 1];
		System.assertEquals(Products.MIN_RATE, result.Base_Rate__c);
	}

	@IsTest
	private static void testNormalizeWithLargeBatchSize()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Test Product', Base_Rate__c = 0.001, Min_Credit_Score__c = 600)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationService.normalizeProductRates(1000);
		Test.stopTest();

		Product__c result = [SELECT Base_Rate__c FROM Product__c LIMIT 1];
		System.assertEquals(Products.MIN_RATE, result.Base_Rate__c);
	}
} 