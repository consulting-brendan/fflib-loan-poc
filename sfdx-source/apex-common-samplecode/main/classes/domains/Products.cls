/**
 * Copyright (c) 2013-2016, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
			// Check if borrower qualifies for this product
			if (product.Min_Credit_Score__c != null && 
				creditScore >= product.Min_Credit_Score__c)
			{
				// Among eligible products, select the one with lowest base rate
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