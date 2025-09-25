/**
 * @description Service for Product Rate Normalization providing synchronous operations
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Product Management
 * 
 * @learnings
 * • Service layer orchestrates business processes by coordinating selectors, domains, and Unit of Work
 * • Provides static facade methods for simple operations while supporting dependency injection via interface
 * • Demonstrates proper layering: service calls selector → creates domain → executes business logic → commits UOW
 * • Handles cross-cutting concerns like transaction management while delegating business logic to domains
 * • Entry point for synchronous rate normalization - batch jobs call this service for actual processing
 **/

public with sharing class ProductRateNormalizationService 
{
	public static void normalizeProductRates()
	{
		normalizeProductRates(null);
	}

	public static void normalizeProductRates(Integer batchSize)
	{
		fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
		
		List<Product__c> productsNeedingNormalization;
		
		if (batchSize != null && batchSize > 0)
		{
			Integer limitSize = Math.min(batchSize, 200);
			String queryString = 'SELECT Id, Name, Base_Rate__c, Min_Credit_Score__c FROM Product__c WHERE Base_Rate__c != null AND (Base_Rate__c < ' + Products.MIN_RATE + ' OR Base_Rate__c > ' + Products.MAX_RATE + ') WITH SECURITY_ENFORCED LIMIT ' + limitSize;
			productsNeedingNormalization = Database.query(queryString);
		}
		else
		{
			productsNeedingNormalization = ProductsSelector.newInstance().selectProductsNeedingRateNormalization();
		}
		
		if (!productsNeedingNormalization.isEmpty())
		{
			IProducts products = Products.newInstance(productsNeedingNormalization);
			products.normalizeRates(uow);
			
			uow.commitWork();
		}
	}

	public static Integer getProductsNeedingNormalizationCount()
	{
		return ProductsSelector.newInstance().countProductsNeedingRateNormalization();
	}
} 