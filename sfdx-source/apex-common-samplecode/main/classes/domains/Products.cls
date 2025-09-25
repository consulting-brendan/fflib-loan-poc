/**
 * @description Domain class for Product__c implementing business logic for product selection and rating
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Domain class focused on single responsibility: product selection logic based on credit scores
 * • Implements business rule: find best (lowest rate) product that borrower qualifies for based on credit
 * • Uses domain-driven design with meaningful method names like selectBestProductForCreditScore()
 * • Encapsulates complex comparison logic while exposing simple interface to calling domain classes
 * • Demonstrates cross-domain collaboration: called by LoanApplications domain for product decisions
 **/

public with sharing class Products extends fflib_SObjects
	implements IProducts
{
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

	public class Constructor implements fflib_IDomainConstructor
	{
		public fflib_SObjects construct(List<Object> objectList)
		{
			return new Products((List<SObject>) objectList);
		}
	}
} 