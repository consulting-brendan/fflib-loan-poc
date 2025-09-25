/**
 * @description Interface for Products domain class defining contract for product selection logic
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Simple interface defining essential product domain operations without implementation details
 * • Supports dependency inversion: other domains depend on IProducts interface, not concrete Products class
 * • Enables unit testing by allowing mock implementations of product selection logic
 * • Provides clear contract for product-related business operations across the application
 * • Demonstrates interface segregation principle: focused only on product selection responsibilities
 **/

public interface IProducts extends fflib_ISObjects
{
	List<Product__c> getProducts();
	Product__c selectBestProductForCreditScore(Decimal creditScore);
} 