/**
 * @description Interface for Products domain class defining contract for product selection and rate normalization
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Interface defining essential product domain operations: selection and rate normalization
 * • Supports dependency inversion: other domains depend on IProducts interface, not concrete Products class
 * • Enables unit testing by allowing mock implementations of product logic with ApexMocks
 * • Provides clear contract for product-related business operations across loan and normalization processes
 * • Demonstrates cohesive interface design: related product operations grouped together
 **/

public interface IProducts extends fflib_ISObjects
{
	List<Product__c> getProducts();
	Product__c selectBestProductForCreditScore(Decimal creditScore);
	void normalizeRates();
	void normalizeRates(fflib_ISObjectUnitOfWork uow);
	Integer countProductsNeedingNormalization();
} 