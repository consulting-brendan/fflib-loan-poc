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

public class ProductsSelector extends fflib_SObjectSelector
	implements IProductsSelector
{
	public static IProductsSelector newInstance()
	{
		return (IProductsSelector) Application.Selector.newInstance(Product__c.SObjectType);
	}
	
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
			Product__c.Id,
			Product__c.Name,
			Product__c.Min_Credit_Score__c,
			Product__c.Base_Rate__c
		};
	}

	public Schema.SObjectType getSObjectType()
	{
		return Product__c.SObjectType;
	}

	public List<Product__c> selectById(Set<Id> idSet)
	{
		return (List<Product__c>) selectSObjectsById(idSet);
	}

	public List<Product__c> selectAll()
	{
		return (List<Product__c>) Database.query(
			newQueryFactory()
				.assertIsAccessible()
				.setEnforceFLS(true)
				.toSOQL());
	}
		
	public List<Product__c> selectByMinCreditScore(Decimal minCreditScore)
	{
		return (List<Product__c>) Database.query(
			newQueryFactory()
				.assertIsAccessible()
				.setEnforceFLS(true)
				.setCondition('Min_Credit_Score__c <= :minCreditScore')
				.toSOQL());
	}

	public List<Product__c> selectProductsNeedingRateNormalization()
	{
		Decimal minRate = Products.MIN_RATE;
		Decimal maxRate = Products.MAX_RATE;
		
		return (List<Product__c>) Database.query(
			newQueryFactory()
				.assertIsAccessible()
				.setEnforceFLS(true)
				.setCondition('Base_Rate__c != null AND (Base_Rate__c < :minRate OR Base_Rate__c > :maxRate)')
				.toSOQL());
	}

	public Integer countProductsNeedingRateNormalization()
	{
		Decimal minRate = Products.MIN_RATE;
		Decimal maxRate = Products.MAX_RATE;
		
		return Database.countQuery(
			'SELECT COUNT() FROM Product__c WHERE Base_Rate__c != null AND (Base_Rate__c < :minRate OR Base_Rate__c > :maxRate) WITH SECURITY_ENFORCED'
		);
	}
}