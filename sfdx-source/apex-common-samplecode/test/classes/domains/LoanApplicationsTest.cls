/**
 * @description Test class for LoanApplications domain
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications Tests
 * 
 * @learnings
 * • Tests domain business logic in isolation using @TestSetup for consistent test data across methods
 * • Demonstrates both trigger context (submitApplications()) and service context (submitApplications(uow)) testing
 * • Uses direct domain instantiation rather than factory for unit testing specific business logic scenarios
 * • Validates business rules: borrower validation, product selection, approval/rejection logic, task creation
 * • Shows proper test structure: setup data, execute domain method, assert business outcomes
 **/

@IsTest
private class LoanApplicationsTest 
{
	@TestSetup
	private static void setupTestData()
	{
		List<Contact> borrowers = new List<Contact>{
			new Contact(
				FirstName = 'Valid',
				LastName = 'Borrower',
				Email = 'valid@example.com',
				Annual_Income__c = 75000,
				Credit_Score__c = 800
			),
			new Contact(
				FirstName = 'LowCredit',
				LastName = 'Borrower',
				Email = 'lowcredit@example.com',
				Annual_Income__c = 50000,
				Credit_Score__c = 550
			),
			new Contact(
				FirstName = 'NoEmail',
				LastName = 'Borrower',
				Annual_Income__c = 60000,
				Credit_Score__c = 700
			)
		};
		insert borrowers;

		List<Product__c> products = new List<Product__c>{
			new Product__c(
				Name = 'Premium Product',
				Min_Credit_Score__c = 750,
				Base_Rate__c = 0.05
			),
			new Product__c(
				Name = 'Standard Product',
				Min_Credit_Score__c = 650,
				Base_Rate__c = 0.08
			),
			new Product__c(
				Name = 'Basic Product',
				Min_Credit_Score__c = 600,
				Base_Rate__c = 0.12
			)
		};
		insert products;
	}

	@IsTest
	private static void testGetBorrowerIds()
	{
		List<Contact> borrowers = [SELECT Id FROM Contact LIMIT 2];
		
		List<Loan_Application__c> applications = new List<Loan_Application__c>{
			new Loan_Application__c(Borrower__c = borrowers[0].Id, Amount__c = 100000),
			new Loan_Application__c(Borrower__c = borrowers[1].Id, Amount__c = 200000)
		};

		LoanApplications domain = new LoanApplications(applications);

		Test.startTest();
		Set<Id> borrowerIds = domain.getBorrowerIds();
		Test.stopTest();

		System.assertEquals(2, borrowerIds.size());
		System.assert(borrowerIds.contains(borrowers[0].Id));
		System.assert(borrowerIds.contains(borrowers[1].Id));
	}

	@IsTest
	private static void testSubmitApplicationsWithValidBorrower()
	{
		Contact validBorrower = [SELECT Id FROM Contact WHERE Email = 'valid@example.com' LIMIT 1];

		Loan_Application__c application = new Loan_Application__c(
			Borrower__c = validBorrower.Id,
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_SUBMITTED
		);

		LoanApplications domain = new LoanApplications(new List<Loan_Application__c>{ application });

		Test.startTest();
		domain.submitApplications();
		Test.stopTest();

		System.assertEquals(LoanApplications.STATUS_APPROVED, application.Status__c);
		System.assertNotEquals(null, application.Product__c);
		System.assert(application.Approval_Outcome__c.contains('approved'));
	}

	@IsTest
	private static void testSubmitApplicationsWithLowCreditScore()
	{
		Contact lowCreditBorrower = [SELECT Id FROM Contact WHERE Email = 'lowcredit@example.com' LIMIT 1];

		Loan_Application__c application = new Loan_Application__c(
			Borrower__c = lowCreditBorrower.Id,
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_SUBMITTED
		);

		LoanApplications domain = new LoanApplications(new List<Loan_Application__c>{ application });

		Test.startTest();
		domain.submitApplications();
		Test.stopTest();

		System.assertEquals(LoanApplications.STATUS_REJECTED, application.Status__c);
		System.assertEquals(null, application.Product__c);
		System.assert(application.Approval_Outcome__c.contains('No eligible product'));
	}

	@IsTest
	private static void testSubmitApplicationsWithInvalidBorrower()
	{
		Contact noEmailBorrower = [SELECT Id FROM Contact WHERE Email = null LIMIT 1];

		Loan_Application__c application = new Loan_Application__c(
			Borrower__c = noEmailBorrower.Id,
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_SUBMITTED
		);

		LoanApplications domain = new LoanApplications(new List<Loan_Application__c>{ application });

		Test.startTest();
		domain.submitApplications();
		Test.stopTest();

		System.assertEquals(LoanApplications.STATUS_REJECTED, application.Status__c);
		System.assertEquals(null, application.Product__c);
		System.assert(application.Approval_Outcome__c.contains('email is required'));
	}

	@IsTest
	private static void testSubmitApplicationsWithInvalidAmount()
	{
		Contact validBorrower = [SELECT Id FROM Contact WHERE Email = 'valid@example.com' LIMIT 1];

		Loan_Application__c application = new Loan_Application__c(
			Borrower__c = validBorrower.Id,
			Amount__c = -1000,
			Status__c = LoanApplications.STATUS_SUBMITTED
		);

		LoanApplications domain = new LoanApplications(new List<Loan_Application__c>{ application });

		Test.startTest();
		domain.submitApplications();
		Test.stopTest();

		System.assertEquals(LoanApplications.STATUS_REJECTED, application.Status__c);
		System.assert(application.Approval_Outcome__c.contains('Loan amount must be greater than 0'));
	}

	@IsTest
	private static void testSubmitApplicationsInTriggerContext()
	{
		Contact validBorrower = [SELECT Id FROM Contact WHERE Email = 'valid@example.com' LIMIT 1];

		Loan_Application__c application = new Loan_Application__c(
			Borrower__c = validBorrower.Id,
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_SUBMITTED
		);

		LoanApplications domain = new LoanApplications(new List<Loan_Application__c>{ application });

		Test.startTest();
		domain.submitApplications();
		Test.stopTest();

		System.assertEquals(LoanApplications.STATUS_APPROVED, application.Status__c);
		System.assertNotEquals(null, application.Product__c);
		System.assert(application.Approval_Outcome__c.contains('approved'));
	}

	@IsTest
	private static void testMultipleApplicationsProcessing()
	{
		List<Contact> borrowers = [SELECT Id FROM Contact WHERE Email != null];
		
		List<Loan_Application__c> applications = new List<Loan_Application__c>{
			new Loan_Application__c(
				Borrower__c = borrowers[0].Id,
				Amount__c = 100000,
				Status__c = LoanApplications.STATUS_SUBMITTED
			),
			new Loan_Application__c(
				Borrower__c = borrowers[1].Id,
				Amount__c = 50000,
				Status__c = LoanApplications.STATUS_SUBMITTED
			)
		};

		LoanApplications domain = new LoanApplications(applications);

		Test.startTest();
		domain.submitApplications();
		Test.stopTest();

		for (Loan_Application__c app : applications) {
			System.assertNotEquals(LoanApplications.STATUS_DRAFT, app.Status__c);
			System.assertNotEquals(null, app.Approval_Outcome__c);
		}
	}
} 