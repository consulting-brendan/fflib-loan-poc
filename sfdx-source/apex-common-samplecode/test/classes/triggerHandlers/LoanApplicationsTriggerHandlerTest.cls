/**
 * @description Test class for LoanApplicationsTriggerHandler
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications Tests
 * 
 * @learnings
 * • Uses fflib_SObjectDomain.Test.Database for testing trigger logic without actual DML operations
 * • Tests both unit level (individual handler methods) and integration level (full trigger workflow)
 * • Demonstrates fflib trigger testing patterns: onInsert(), onUpdate() simulation with old/new record maps
 * • Validates trigger behavior: defaults application, validation, status change processing, contact updates
 * • Shows error testing using fflib_SObjectDomain.Errors for validation rule verification
 **/

@IsTest
private class LoanApplicationsTriggerHandlerTest 
{
	@IsTest
	private static void testOnApplyDefaultsWithoutDML()
	{
		Loan_Application__c app = new Loan_Application__c(Amount__c = 100000);
		
		LoanApplicationsTriggerHandler handler = new LoanApplicationsTriggerHandler(
			new List<Loan_Application__c>{ app }
		);

		Test.startTest();
		handler.onApplyDefaults();
		Test.stopTest();

		System.assertEquals(LoanApplications.STATUS_DRAFT, app.Status__c);
	}

	@IsTest
	private static void testOnApplyDefaultsDoesNotOverrideExistingStatus()
	{
		Loan_Application__c app = new Loan_Application__c(
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_SUBMITTED
		);
		
		LoanApplicationsTriggerHandler handler = new LoanApplicationsTriggerHandler(
			new List<Loan_Application__c>{ app }
		);

		Test.startTest();
		handler.onApplyDefaults();
		Test.stopTest();

		System.assertEquals(LoanApplications.STATUS_SUBMITTED, app.Status__c);
	}

	@IsTest
	private static void testOnValidateMissingBorrowerWithoutDML()
	{
		Loan_Application__c app = new Loan_Application__c(Amount__c = 100000);
		
		LoanApplicationsTriggerHandler handler = new LoanApplicationsTriggerHandler(
			new List<Loan_Application__c>{ app }
		);

		Test.startTest();
		handler.onValidate();
		Test.stopTest();

		System.assertEquals(1, fflib_SObjectDomain.Errors.getAll().size());
		System.assertEquals('Borrower is required for loan applications.', 
			fflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals(Loan_Application__c.Borrower__c, 
			((fflib_SObjectDomain.FieldError)fflib_SObjectDomain.Errors.getAll()[0]).field);
	}

	@IsTest
	private static void testOnValidateInvalidAmountWithoutDML()
	{
		Contact borrower = new Contact(FirstName = 'Test', LastName = 'Borrower');
		insert borrower;

		Loan_Application__c app = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = -1000
		);
		
		LoanApplicationsTriggerHandler handler = new LoanApplicationsTriggerHandler(
			new List<Loan_Application__c>{ app }
		);

		Test.startTest();
		handler.onValidate();
		Test.stopTest();

		System.assertEquals(1, fflib_SObjectDomain.Errors.getAll().size());
		System.assertEquals('Loan amount must be greater than zero.', 
			fflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals(Loan_Application__c.Amount__c, 
			((fflib_SObjectDomain.FieldError)fflib_SObjectDomain.Errors.getAll()[0]).field);
	}

	@IsTest
	private static void testOnValidateSuccessWithoutDML()
	{
		Contact borrower = new Contact(FirstName = 'Test', LastName = 'Borrower');
		insert borrower;

		Loan_Application__c app = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = 100000
		);
		
		LoanApplicationsTriggerHandler handler = new LoanApplicationsTriggerHandler(
			new List<Loan_Application__c>{ app }
		);

		Test.startTest();
		handler.onValidate();
		Test.stopTest();

		System.assertEquals(0, fflib_SObjectDomain.Errors.getAll().size());
	}

	@IsTest
	private static void testInsertValidationFailedWithoutDML()
	{
		Loan_Application__c app = new Loan_Application__c(Amount__c = 100000);

		fflib_SObjectDomain.Test.Database.onInsert(new List<Loan_Application__c>{ app });
		
		Test.startTest();
		fflib_SObjectDomain.triggerHandler(LoanApplicationsTriggerHandler.class);
		Test.stopTest();

		System.assertEquals(1, fflib_SObjectDomain.Errors.getAll().size());
		System.assertEquals('Borrower is required for loan applications.', 
			fflib_SObjectDomain.Errors.getAll()[0].message);
	}

	@IsTest
	private static void testInsertValidationSuccessWithoutDML()
	{
		Contact borrower = new Contact(FirstName = 'Test', LastName = 'Borrower');
		insert borrower;

		Loan_Application__c app = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = 100000
		);

		fflib_SObjectDomain.Test.Database.onInsert(new List<Loan_Application__c>{ app });
		
		Test.startTest();
		fflib_SObjectDomain.triggerHandler(LoanApplicationsTriggerHandler.class);
		Test.stopTest();

		System.assertEquals(0, fflib_SObjectDomain.Errors.getAll().size());
		System.assertEquals(LoanApplications.STATUS_DRAFT, app.Status__c);
	}

	@IsTest
	private static void testStatusChangeFromDraftToSubmittedWithDML()
	{
		Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower',
			Email = 'test@example.com',
			Annual_Income__c = 75000,
			Credit_Score__c = 800
		);
		insert borrower;

		Product__c product = new Product__c(
			Name = 'Test Product',
			Min_Credit_Score__c = 750,
			Base_Rate__c = 0.05
		);
		insert product;

		Loan_Application__c app = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_DRAFT
		);
		insert app;

		app.Status__c = LoanApplications.STATUS_SUBMITTED;

		Test.startTest();
		update app;
		Test.stopTest();

		app = [SELECT Id, Status__c, Product__c, Approval_Outcome__c FROM Loan_Application__c WHERE Id = :app.Id];
		
		System.assertEquals(LoanApplications.STATUS_APPROVED, app.Status__c);
		System.assertEquals(product.Id, app.Product__c);
		System.assert(app.Approval_Outcome__c.contains('approved'));

		List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :app.Id];
		System.assertEquals(1, tasks.size());
		System.assertEquals('Prepare documents', tasks[0].Subject);
	}

	@IsTest
	private static void testStatusChangeRejectionWithDML()
	{
		Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower',
			Email = 'test@example.com',
			Annual_Income__c = 75000,
			Credit_Score__c = 550
		);
		insert borrower;

		Loan_Application__c app = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_DRAFT
		);
		insert app;

		app.Status__c = LoanApplications.STATUS_SUBMITTED;

		Test.startTest();
		update app;
		Test.stopTest();

		app = [SELECT Id, Status__c, Product__c, Approval_Outcome__c FROM Loan_Application__c WHERE Id = :app.Id];
		
		System.assertEquals(LoanApplications.STATUS_REJECTED, app.Status__c);
		System.assertEquals(null, app.Product__c);
		System.assert(app.Approval_Outcome__c.contains('No eligible product'));

		List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :app.Id];
		System.assertEquals(0, tasks.size());
	}

	@IsTest
	private static void testUpdateContactActivityAfterApproval()
	{
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower',
			Email = 'test@example.com',
			Annual_Income__c = 75000,
			Credit_Score__c = 800,
			AccountId = testAccount.Id
		);
		insert borrower;

		Product__c product = new Product__c(
			Name = 'Test Product',
			Min_Credit_Score__c = 750,
			Base_Rate__c = 0.05
		);
		insert product;

		Loan_Application__c app = new Loan_Application__c(
			Borrower__c = borrower.Id,
			Amount__c = 100000,
			Status__c = LoanApplications.STATUS_SUBMITTED,
			Product__c = product.Id
		);
		insert app;

		app.Status__c = LoanApplications.STATUS_APPROVED;

		Test.startTest();
		update app;
		Test.stopTest();

		Contact updatedBorrower = [SELECT Id, Description FROM Contact WHERE Id = :borrower.Id];
		String expectedDescription = Contacts.ACCOUNT_ACTIVITY_DESCRIPTION + ' ' + System.today();
		System.assertEquals(expectedDescription, updatedBorrower.Description);
	}

	@IsTest
	private static void testMultipleApplicationsProcessing()
	{
		List<Contact> borrowers = new List<Contact>{
			new Contact(
				FirstName = 'Valid1',
				LastName = 'Borrower1',
				Email = 'valid1@example.com',
				Annual_Income__c = 75000,
				Credit_Score__c = 800
			),
			new Contact(
				FirstName = 'Valid2',
				LastName = 'Borrower2',
				Email = 'valid2@example.com',
				Annual_Income__c = 75000,
				Credit_Score__c = 750
			)
		};
		insert borrowers;

		Product__c product = new Product__c(
			Name = 'Test Product',
			Min_Credit_Score__c = 750,
			Base_Rate__c = 0.05
		);
		insert product;

		List<Loan_Application__c> apps = new List<Loan_Application__c>{
			new Loan_Application__c(
				Borrower__c = borrowers[0].Id,
				Amount__c = 100000,
				Status__c = LoanApplications.STATUS_DRAFT
			),
			new Loan_Application__c(
				Borrower__c = borrowers[1].Id,
				Amount__c = 200000,
				Status__c = LoanApplications.STATUS_DRAFT
			)
		};
		insert apps;

		for (Loan_Application__c app : apps) {
			app.Status__c = LoanApplications.STATUS_SUBMITTED;
		}

		Test.startTest();
		update apps;
		Test.stopTest();

		List<Loan_Application__c> updatedApps = [
			SELECT Id, Status__c, Product__c, Approval_Outcome__c 
			FROM Loan_Application__c 
			WHERE Id IN :apps
		];

		for (Loan_Application__c app : updatedApps) {
			System.assertEquals(LoanApplications.STATUS_APPROVED, app.Status__c);
			System.assertEquals(product.Id, app.Product__c);
		}

		List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :apps];
		System.assertEquals(2, tasks.size());
	}
} 