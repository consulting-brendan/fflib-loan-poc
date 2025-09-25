/**
 * @description Domain class for Product__c implementing business logic for product selection and rate normalization
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Domain class with dual responsibility: product selection logic and rate normalization business rules
 * • Implements business rules: product selection based on credit scores and rate boundary enforcement
 * • Uses domain-driven design with meaningful method names like selectBestProductForCreditScore() and normalizeRates()
 * • Encapsulates rate normalization logic: MIN_RATE (0.5%) and MAX_RATE (15%) boundary enforcement
 * • Demonstrates bulk-safe operations with governor limit awareness in rate normalization processing
 * • Cross-domain collaboration: called by LoanApplications for selection, services for rate normalization
 **/

public with sharing class Products extends fflib_SObjects
	implements IProducts
{
	public static final Decimal MIN_RATE = 0.005; // 0.5%
	public static final Decimal MAX_RATE = 0.15;  // 15%
	public static IProducts newInstance(List<Product__c> recordList)
	{
		return (IProducts) Application.Domain.newInstance(recordList);
	}
	
	public static IProducts newInstance(Set<Id> recordIdSet)
	{
		return (IProducts) Application.Domain.newInstance(recordIdSet);
	}
	
	public Products(List<Product__c> sObjectList)
	{
		super(sObjectList, Schema.Product__c.SObjectType);
	}

	public List<Product__c> getProducts()
	{
		return (List<Product__c>) getRecords();
	}

	public Product__c selectBestProductForCreditScore(Decimal creditScore)
	{
		if (creditScore == null)
		{
			return null;
		}

		Product__c bestProduct = null;
		Decimal lowestRate = null;

		for (Product__c product : getProducts())
		{
			if (product.Min_Credit_Score__c != null && 
				creditScore >= product.Min_Credit_Score__c)
			{
				if (lowestRate == null || 
					(product.Base_Rate__c != null && product.Base_Rate__c < lowestRate))
				{
					bestProduct = product;
					lowestRate = product.Base_Rate__c;
				}
			}
		}

		return bestProduct;
	}

	public void normalizeRates()
	{
		Integer recordsProcessed = 0;
		
		for (Product__c product : getProducts())
		{
			if (product.Base_Rate__c != null)
			{
				Decimal originalRate = product.Base_Rate__c;
				
				if (product.Base_Rate__c < MIN_RATE)
				{
					product.Base_Rate__c = MIN_RATE;
					recordsProcessed++;
				}
				else if (product.Base_Rate__c > MAX_RATE)
				{
					product.Base_Rate__c = MAX_RATE;
					recordsProcessed++;
				}
			}
		}
	}

	public void normalizeRates(fflib_ISObjectUnitOfWork uow)
	{
		normalizeRates();
		
		for (Product__c product : getProducts())
		{
			uow.registerDirty(product);
		}
	}

	public Integer countProductsNeedingNormalization()
	{
		Integer count = 0;
		
		for (Product__c product : getProducts())
		{
			if (product.Base_Rate__c != null && 
				(product.Base_Rate__c < MIN_RATE || product.Base_Rate__c > MAX_RATE))
			{
				count++;
			}
		}
		
		return count;
	}

	public class Constructor implements fflib_IDomainConstructor
	{
		public fflib_SObjects construct(List<Object> objectList)
		{
			return new Products((List<SObject>) objectList);
		}
	}
} 