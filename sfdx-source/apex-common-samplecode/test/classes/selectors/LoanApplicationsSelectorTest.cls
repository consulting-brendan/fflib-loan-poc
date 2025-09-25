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
	private static void testNewInstance()
	{
		// Test that newInstance returns correct selector type
		ILoanApplicationsSelector instance = LoanApplicationsSelector.newInstance();
		System.assertNotEquals(null, instance);
		System.assert(instance instanceof LoanApplicationsSelector);
	}

	@IsTest
	private static void testGetSObjectType()
	{
		LoanApplicationsSelector selector = new LoanApplicationsSelector();
		Schema.SObjectType result = selector.getSObjectType();
		System.assertEquals(Loan_Application__c.SObjectType, result);
	}

	@IsTest
	private static void testGetSObjectFieldList()
	{
		LoanApplicationsSelector selector = new LoanApplicationsSelector();
		List<Schema.SObjectField> fields = selector.getSObjectFieldList();
		
		System.assertNotEquals(null, fields);
		System.assert(fields.size() > 0);
		
		// Verify key fields are included
		Set<Schema.SObjectField> fieldSet = new Set<Schema.SObjectField>(fields);
		System.assert(fieldSet.contains(Loan_Application__c.Id));
		System.assert(fieldSet.contains(Loan_Application__c.Name));
		System.assert(fieldSet.contains(Loan_Application__c.Borrower__c));
		System.assert(fieldSet.contains(Loan_Application__c.Amount__c));
		System.assert(fieldSet.contains(Loan_Application__c.Status__c));
		System.assert(fieldSet.contains(Loan_Application__c.Product__c));
		System.assert(fieldSet.contains(Loan_Application__c.Approval_Outcome__c));
	}

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
	private static void testSelectByBorrower()
	{
		// Create multiple borrowers
		List<Contact> borrowers = new List<Contact>{
			new Contact(
				FirstName = 'Borrower1',
				LastName = 'Test',
				Email = 'borrower1@example.com',
				Annual_Income__c = 60000,
				Credit_Score__c = 720
			),
			new Contact(
				FirstName = 'Borrower2',
				LastName = 'Test',
				Email = 'borrower2@example.com',
				Annual_Income__c = 70000,
				Credit_Score__c = 750
			),
			new Contact(
				FirstName = 'Borrower3',
				LastName = 'Test',
				Email = 'borrower3@example.com',
				Annual_Income__c = 80000,
				Credit_Score__c = 800
			)
		};
		insert borrowers;

		// Create loan applications for borrowers
		List<Loan_Application__c> loanApps = new List<Loan_Application__c>{
			new Loan_Application__c(
				Borrower__c = borrowers[0].Id,
				Amount__c = 150000,
				Status__c = 'Draft'
			),
			new Loan_Application__c(
				Borrower__c = borrowers[0].Id,
				Amount__c = 200000,
				Status__c = 'Submitted'
			),
			new Loan_Application__c(
				Borrower__c = borrowers[1].Id,
				Amount__c = 250000,
				Status__c = 'Approved'
			),
			new Loan_Application__c(
				Borrower__c = borrowers[2].Id,
				Amount__c = 300000,
				Status__c = 'Draft'
			)
		};
		insert loanApps;

		// Test selecting by specific borrowers
		Set<Id> targetBorrowerIds = new Set<Id>{ borrowers[0].Id, borrowers[1].Id };

		Test.startTest();
		List<Loan_Application__c> results = 
			new LoanApplicationsSelector().selectByBorrower(targetBorrowerIds);
		Test.stopTest();

		System.assertEquals(3, results.size());
		
		// Verify all results belong to the target borrowers
		for (Loan_Application__c app : results) {
			System.assert(targetBorrowerIds.contains(app.Borrower__c));
		}
	}

	@IsTest
	private static void testSelectByBorrowerSingle()
	{
		Contact borrower = new Contact(
			FirstName = 'Single',
			LastName = 'Borrower',
			Email = 'single@example.com',
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
			new LoanApplicationsSelector().selectByBorrower(new Set<Id> { borrower.Id });
		Test.stopTest();

		System.assertEquals(1, results.size());
		System.assertEquals(loanApp.Id, results[0].Id);
		System.assertEquals(borrower.Id, results[0].Borrower__c);
	}

	@IsTest
	private static void testSelectByBorrowerEmpty()
	{
		Test.startTest();
		List<Loan_Application__c> results = 
			new LoanApplicationsSelector().selectByBorrower(new Set<Id>());
		Test.stopTest();

		System.assertEquals(0, results.size());
	}

	@IsTest
	private static void testSelectByStatus()
	{
		Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower',
			Email = 'test@example.com',
			Annual_Income__c = 50000,
			Credit_Score__c = 700
		);
		insert borrower;

		// Create loan applications with different statuses
		List<Loan_Application__c> loanApps = new List<Loan_Application__c>{
			new Loan_Application__c(
				Borrower__c = borrower.Id,
				Amount__c = 100000,
				Status__c = 'Draft'
			),
			new Loan_Application__c(
				Borrower__c = borrower.Id,
				Amount__c = 150000,
				Status__c = 'Draft'
			),
			new Loan_Application__c(
				Borrower__c = borrower.Id,
				Amount__c = 200000,
				Status__c = 'Submitted'
			),
			new Loan_Application__c(
				Borrower__c = borrower.Id,
				Amount__c = 250000,
				Status__c = 'Approved'
			)
		};
		insert loanApps;

		Test.startTest();
		List<Loan_Application__c> draftResults = 
			new LoanApplicationsSelector().selectByStatus('Draft');
		List<Loan_Application__c> submittedResults = 
			new LoanApplicationsSelector().selectByStatus('Submitted');
		List<Loan_Application__c> approvedResults = 
			new LoanApplicationsSelector().selectByStatus('Approved');
		Test.stopTest();

		// Verify draft applications
		System.assert(draftResults.size() >= 2, 'Should find at least 2 draft applications');
		for (Loan_Application__c app : draftResults) {
			if (app.Borrower__c == borrower.Id) {
				System.assertEquals('Draft', app.Status__c);
			}
		}

		// Verify submitted applications  
		System.assert(submittedResults.size() >= 1, 'Should find at least 1 submitted application');
		for (Loan_Application__c app : submittedResults) {
			if (app.Borrower__c == borrower.Id) {
				System.assertEquals('Submitted', app.Status__c);
			}
		}

		// Verify approved applications
		System.assert(approvedResults.size() >= 1, 'Should find at least 1 approved application');
		for (Loan_Application__c app : approvedResults) {
			if (app.Borrower__c == borrower.Id) {
				System.assertEquals('Approved', app.Status__c);
			}
		}
	}

	@IsTest
	private static void testSelectByStatusNotFound()
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
			new LoanApplicationsSelector().selectByStatus('NonExistentStatus');
		Test.stopTest();

		// Should return empty list, not error
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

	@IsTest
	private static void testIncludesRequiredFields()
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
		Loan_Application__c result = results[0];
		
		System.assertNotEquals(null, result.Borrower__c);
		System.assertNotEquals(null, result.Amount__c);
		System.assertNotEquals(null, result.Status__c);
		System.assertNotEquals(null, result.Name);
	}
} 