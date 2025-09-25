/**
 * @description Test class for Products domain
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications Tests
 **/

@IsTest
private class ProductsTest 
{
	@IsTest
	private static void testSelectBestProductForHighCreditScore()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Premium Product',
				Min_Credit_Score__c = 750,
				Base_Rate__c = 0.05
			),
			new Product__c(
				Name = 'Standard Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.08
			),
			new Product__c(
				Name = 'Basic Product',
				Min_Credit_Score__c = 600,
				Base_Rate__c = 0.12
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(800);
		Test.stopTest();

		System.assertNotEquals(null, selectedProduct);
		System.assertEquals('Premium Product', selectedProduct.Name);
		System.assertEquals(0.05, selectedProduct.Base_Rate__c);
	}

	@IsTest
	private static void testSelectBestProductForMediumCreditScore()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Premium Product',
				Min_Credit_Score__c = 750,
				Base_Rate__c = 0.05
			),
			new Product__c(
				Name = 'Standard Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.08
			),
			new Product__c(
				Name = 'Basic Product',
				Min_Credit_Score__c = 600,
				Base_Rate__c = 0.12
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(700);
		Test.stopTest();

		System.assertNotEquals(null, selectedProduct);
		System.assertEquals('Standard Product', selectedProduct.Name);
		System.assertEquals(0.08, selectedProduct.Base_Rate__c);
	}

	@IsTest
	private static void testSelectBestProductForLowCreditScore()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Premium Product',
				Min_Credit_Score__c = 750,
				Base_Rate__c = 0.05
			),
			new Product__c(
				Name = 'Standard Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.08
			),
			new Product__c(
				Name = 'Basic Product',
				Min_Credit_Score__c = 600,
				Base_Rate__c = 0.12
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(550);
		Test.stopTest();

		System.assertEquals(null, selectedProduct);
	}

	@IsTest
	private static void testSelectBestProductWithNullCreditScore()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Premium Product',
				Min_Credit_Score__c = 750,
				Base_Rate__c = 0.05
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(null);
		Test.stopTest();

		System.assertEquals(null, selectedProduct);
	}

	@IsTest
	private static void testSelectBestProductChoosesLowestRate()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'High Rate Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.15
			),
			new Product__c(
				Name = 'Low Rate Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.08
			),
			new Product__c(
				Name = 'Medium Rate Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.10
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(700);
		Test.stopTest();

		System.assertNotEquals(null, selectedProduct);
		System.assertEquals('Low Rate Product', selectedProduct.Name);
		System.assertEquals(0.08, selectedProduct.Base_Rate__c);
	}

	@IsTest
	private static void testSelectBestProductWithEmptyList()
	{
		List<Product__c> products = new List<Product__c>();
		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(750);
		Test.stopTest();

		System.assertEquals(null, selectedProduct);
	}

	@IsTest
	private static void testSelectBestProductWithNullMinCreditScore()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Product with Null Min Credit',
				Min_Credit_Score__c = null,
				Base_Rate__c = 0.05
			),
			new Product__c(
				Name = 'Valid Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.08
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(700);
		Test.stopTest();

		System.assertNotEquals(null, selectedProduct);
		System.assertEquals('Valid Product', selectedProduct.Name);
	}

	@IsTest
	private static void testSelectBestProductWithNullBaseRate()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Product with Null Rate',
				Min_Credit_Score__c = 650,
				Base_Rate__c = null
			),
			new Product__c(
				Name = 'Valid Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.08
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(700);
		Test.stopTest();

		System.assertNotEquals(null, selectedProduct);
		System.assertEquals('Valid Product', selectedProduct.Name);
	}

	@IsTest
	private static void testSelectBestProductAtExactCreditScore()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Exact Match Product',
				Min_Credit_Score__c = 700,
				Base_Rate__c = 0.08
			)
		};

		Products domain = new Products(products);

		Test.startTest();
		Product__c selectedProduct = domain.selectBestProductForCreditScore(700);
		Test.stopTest();

		System.assertNotEquals(null, selectedProduct);
		System.assertEquals('Exact Match Product', selectedProduct.Name);
	}

	@IsTest
	private static void testGetProducts()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(Name = 'Product 1'),
			new Product__c(Name = 'Product 2')
		};

		Products domain = new Products(products);

		Test.startTest();
		List<Product__c> result = domain.getProducts();
		Test.stopTest();

		System.assertEquals(2, result.size());
		System.assertEquals(products, result);
	}

	@IsTest
	private static void testNormalizeRatesWithinBounds()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(Name = 'Product A', Base_Rate__c = 0.01, Min_Credit_Score__c = 700),  // 1% - within bounds
			new Product__c(Name = 'Product B', Base_Rate__c = 0.08, Min_Credit_Score__c = 650),  // 8% - within bounds
			new Product__c(Name = 'Product C', Base_Rate__c = 0.12, Min_Credit_Score__c = 600)   // 12% - within bounds
		};

		Products domain = new Products(products);

		Test.startTest();
		domain.normalizeRates();
		Test.stopTest();

		for (Product__c p : products) {
			System.assert(p.Base_Rate__c >= Products.MIN_RATE && p.Base_Rate__c <= Products.MAX_RATE);
		}
		
		System.assertEquals(0.01, products[0].Base_Rate__c);
		System.assertEquals(0.08, products[1].Base_Rate__c);
		System.assertEquals(0.12, products[2].Base_Rate__c);
	}

	@IsTest
	private static void testNormalizeRatesBelowMinimum()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(Name = 'Too Low A', Base_Rate__c = 0.001, Min_Credit_Score__c = 700),  // 0.1%
			new Product__c(Name = 'Too Low B', Base_Rate__c = 0.0001, Min_Credit_Score__c = 650), // 0.01%
			new Product__c(Name = 'Just Right', Base_Rate__c = 0.06, Min_Credit_Score__c = 600)   // 6% - within bounds
		};

		Products domain = new Products(products);

		Test.startTest();
		domain.normalizeRates();
		Test.stopTest();

		System.assertEquals(Products.MIN_RATE, products[0].Base_Rate__c);
		System.assertEquals(Products.MIN_RATE, products[1].Base_Rate__c);
		System.assertEquals(0.06, products[2].Base_Rate__c);
	}

	@IsTest
	private static void testNormalizeRatesAboveMaximum()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(Name = 'Too High A', Base_Rate__c = 0.18, Min_Credit_Score__c = 700),  // 18%
			new Product__c(Name = 'Too High B', Base_Rate__c = 0.25, Min_Credit_Score__c = 650),  // 25%
			new Product__c(Name = 'Just Right', Base_Rate__c = 0.06, Min_Credit_Score__c = 600)   // 6% - within bounds
		};

		Products domain = new Products(products);

		Test.startTest();
		domain.normalizeRates();
		Test.stopTest();

		System.assertEquals(Products.MAX_RATE, products[0].Base_Rate__c);
		System.assertEquals(Products.MAX_RATE, products[1].Base_Rate__c);
		System.assertEquals(0.06, products[2].Base_Rate__c);
	}

	@IsTest
	private static void testNormalizeRatesWithUnitOfWork()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(Name = 'Too Low', Base_Rate__c = 0.001, Min_Credit_Score__c = 700),
			new Product__c(Name = 'Too High', Base_Rate__c = 0.18, Min_Credit_Score__c = 650)
		};

		Products domain = new Products(products);
		fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

		Test.startTest();
		domain.normalizeRates(uow);
		Test.stopTest();

		System.assertEquals(Products.MIN_RATE, products[0].Base_Rate__c);
		System.assertEquals(Products.MAX_RATE, products[1].Base_Rate__c);
	}

	@IsTest
	private static void testCountProductsNeedingNormalization()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(Name = 'Too Low', Base_Rate__c = 0.001, Min_Credit_Score__c = 700),     // Needs normalization
			new Product__c(Name = 'Too High', Base_Rate__c = 0.18, Min_Credit_Score__c = 650),     // Needs normalization
			new Product__c(Name = 'Just Right', Base_Rate__c = 0.06, Min_Credit_Score__c = 600),   // OK
			new Product__c(Name = 'Null Rate', Base_Rate__c = null, Min_Credit_Score__c = 580)     // Null - skip
		};

		Products domain = new Products(products);

		Test.startTest();
		Integer count = domain.countProductsNeedingNormalization();
		Test.stopTest();

		System.assertEquals(2, count);
	}

	@IsTest
	private static void testNormalizeRatesWithNullValues()
	{
		List<Product__c> products = new List<Product__c>{
			new Product__c(Name = 'Null Rate', Base_Rate__c = null, Min_Credit_Score__c = 700),
			new Product__c(Name = 'Valid Rate', Base_Rate__c = 0.06, Min_Credit_Score__c = 650)
		};

		Products domain = new Products(products);

		Test.startTest();
		domain.normalizeRates();
		Test.stopTest();

		System.assertEquals(null, products[0].Base_Rate__c);
		System.assertEquals(0.06, products[1].Base_Rate__c);
	}

	@IsTest
	private static void testNormalizeRatesBulkProcessing()
	{
		List<Product__c> products = new List<Product__c>();
		
		for (Integer i = 0; i < 100; i++) {
			products.add(new Product__c(
				Name = 'Product ' + i,
				Base_Rate__c = i < 50 ? 0.001 : 0.18,  // Half too low, half too high
				Min_Credit_Score__c = 600 + i
			));
		}

		Products domain = new Products(products);

		Test.startTest();
		domain.normalizeRates();
		Test.stopTest();

		for (Integer i = 0; i < 100; i++) {
			if (i < 50) {
				System.assertEquals(Products.MIN_RATE, products[i].Base_Rate__c, 'Product ' + i + ' should be normalized to minimum');
			} else {
				System.assertEquals(Products.MAX_RATE, products[i].Base_Rate__c, 'Product ' + i + ' should be normalized to maximum');
			}
		}
	}
} 