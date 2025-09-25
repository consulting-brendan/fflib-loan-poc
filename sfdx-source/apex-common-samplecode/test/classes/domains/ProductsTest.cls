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
} 