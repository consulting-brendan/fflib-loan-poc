/**
 * @description Selector class for Loan_Application__c records implementing fflib selector pattern
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Extends fflib_SObjectSelector to inherit standardized querying patterns and security (FLS/CRUD) enforcement
 * • Centralizes all SOQL queries for Loan_Application__c in one place following single responsibility principle
 * • getSObjectFieldList() defines which fields are always selected ensuring consistency across queries
 * • getSObjectType() returns Loan_Application__c.SObjectType for framework integration and type safety
 * • Accessed through Application.Selector factory or newInstance() enabling dependency injection and testing
 **/

public class LoanApplicationsSelector extends fflib_SObjectSelector
	implements ILoanApplicationsSelector
{
	public static ILoanApplicationsSelector newInstance()
	{
		return (ILoanApplicationsSelector) Application.Selector.newInstance(Loan_Application__c.SObjectType);
	}
	
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
			Loan_Application__c.Id,
			Loan_Application__c.Name,
			Loan_Application__c.Borrower__c,
			Loan_Application__c.Amount__c,
			Loan_Application__c.Status__c,
			Loan_Application__c.Product__c,
			Loan_Application__c.Approval_Outcome__c
		};
	}

	public Schema.SObjectType getSObjectType()
	{
		return Loan_Application__c.SObjectType;
	}

	public List<Loan_Application__c> selectById(Set<Id> idSet)
	{
		return (List<Loan_Application__c>) selectSObjectsById(idSet);
	}

	public List<Loan_Application__c> selectByBorrower(Set<Id> borrowerIds)
	{
		return (List<Loan_Application__c>) Database.query(
			newQueryFactory()
				.assertIsAccessible()
				.setEnforceFLS(true)
				.setCondition('Borrower__c IN :borrowerIds')
				.toSOQL());
	}
		
	public List<Loan_Application__c> selectByStatus(String status)
	{
		return (List<Loan_Application__c>) Database.query(
			newQueryFactory()
				.assertIsAccessible()
				.setEnforceFLS(true)
				.setCondition('Status__c = :status')
				.toSOQL());
	}
} 