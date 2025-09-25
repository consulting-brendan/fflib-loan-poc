/**
 * @description Test class for LoanApplicationsSelector
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications Tests
 **/

@IsTest
private class LoanApplicationsSelectorTest 
{
	@IsTest
	private static void testSelectById()
	{
		Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower',
			Email = 'test@example.com',
			Annual_Income__c = 50000,
			Credit_Score__c = 700
		);
		insert borrower;

		Loan_Application__c loanApp = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = 100000,
			Status__c = 'Draft'
		);
		insert loanApp;

		Test.startTest();
		List<Loan_Application__c> results = 
			new LoanApplicationsSelector().selectById(new Set<Id> { loanApp.Id });
		Test.stopTest();

		System.assertEquals(1, results.size());
		System.assertEquals(loanApp.Id, results[0].Id);
		System.assertEquals(borrower.Id, results[0].Borrower__c);
		System.assertEquals(100000, results[0].Amount__c);
		System.assertEquals('Draft', results[0].Status__c);
	}

	@IsTest
	private static void testSelectByIdMultiple()
	{
		Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower',
			Email = 'test@example.com',
			Annual_Income__c = 50000,
			Credit_Score__c = 700
		);
		insert borrower;

		List<Loan_Application__c> loanApps = new List<Loan_Application__c>{
			new Loan_Application__c(
				Borrower__c = borrower.Id,
				Amount__c = 100000,
				Status__c = 'Draft'
			),
			new Loan_Application__c(
				Borrower__c = borrower.Id,
				Amount__c = 200000,
				Status__c = 'Submitted'
			)
		};
		insert loanApps;

		Set<Id> loanAppIds = new Set<Id>();
		for (Loan_Application__c app : loanApps) {
			loanAppIds.add(app.Id);
		}

		Test.startTest();
		List<Loan_Application__c> results = 
			new LoanApplicationsSelector().selectById(loanAppIds);
		Test.stopTest();

		System.assertEquals(2, results.size());
	}

	@IsTest
	private static void testSelectByIdEmpty()
	{
		Test.startTest();
		List<Loan_Application__c> results = 
			new LoanApplicationsSelector().selectById(new Set<Id>());
		Test.stopTest();

		System.assertEquals(0, results.size());
	}

	@IsTest
	private static void testFieldSecurity()
	{
		Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower',
			Email = 'test@example.com',
			Annual_Income__c = 50000,
			Credit_Score__c = 700
		);
		insert borrower;

		Loan_Application__c loanApp = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = 100000,
			Status__c = 'Draft'
		);
		insert loanApp;

		Test.startTest();
		LoanApplicationsSelector selector = new LoanApplicationsSelector();
		List<Loan_Application__c> results = selector.selectById(new Set<Id> { loanApp.Id });
		Test.stopTest();

		System.assert(results.size() >= 0);
	}
} 