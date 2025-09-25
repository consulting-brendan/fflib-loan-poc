/**
 * Copyright (c) 2013-2015, FinancialForce.com, inc
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

@IsTest
private class ProductsSelectorTest 
{
	@IsTest
	private static void testSelectById()
	{
		// Test data
		Product__c product = new Product__c();
		product.Name = 'CoolItem';
		product.Min_Credit_Score__c = 650;
		product.Base_Rate__c = 0.08;
		insert product;
				
		// Query
		List<Product__c> products = 
			ProductsSelector.newInstance().selectById(new Set<Id> { product.Id });
			
		// Assert
		System.assertEquals(1, products.size());
		System.assertEquals('CoolItem', products[0].Name);		
		System.assertEquals(650, products[0].Min_Credit_Score__c);		
		System.assertEquals(0.08, products[0].Base_Rate__c);		
	}

	@IsTest
	private static void testSelectAll()
	{
		// Test data
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Product 1', Min_Credit_Score__c = 600, Base_Rate__c = 0.05),
			new Product__c(Name = 'Product 2', Min_Credit_Score__c = 700, Base_Rate__c = 0.08),
			new Product__c(Name = 'Product 3', Min_Credit_Score__c = 800, Base_Rate__c = 0.10)
		};
		insert testProducts;
				
		// Query
		List<Product__c> products = ProductsSelector.newInstance().selectAll();
			
		// Assert
		System.assert(products.size() >= 3, 'Should return at least the test products');
		
		// Find our test products
		Map<String, Product__c> productsByName = new Map<String, Product__c>();
		for (Product__c p : products) {
			productsByName.put(p.Name, p);
		}
		
		System.assert(productsByName.containsKey('Product 1'));
		System.assert(productsByName.containsKey('Product 2'));
		System.assert(productsByName.containsKey('Product 3'));
	}

	@IsTest
	private static void testSelectProductsNeedingRateNormalization()
	{
		// Test data - products outside normal range
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Too Low Rate', Min_Credit_Score__c = 600, Base_Rate__c = 0.001), // 0.1%
			new Product__c(Name = 'Too High Rate', Min_Credit_Score__c = 700, Base_Rate__c = 0.18),  // 18%
			new Product__c(Name = 'Normal Rate', Min_Credit_Score__c = 800, Base_Rate__c = 0.06)     // 6%
		};
		insert testProducts;
				
		// Query
		List<Product__c> productsNeedingNormalization = 
			ProductsSelector.newInstance().selectProductsNeedingRateNormalization();
			
		// Assert
		System.assertEquals(2, productsNeedingNormalization.size());
		
		Set<String> productNames = new Set<String>();
		for (Product__c p : productsNeedingNormalization) {
			productNames.add(p.Name);
		}
		
		System.assert(productNames.contains('Too Low Rate'));
		System.assert(productNames.contains('Too High Rate'));
		System.assert(!productNames.contains('Normal Rate'));
	}
}