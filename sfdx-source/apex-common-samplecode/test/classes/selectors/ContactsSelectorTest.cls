/**
 * @description Test class for ContactsSelector
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications Tests
 **/

@IsTest
private class ContactsSelectorTest 
{
	@IsTest
	private static void testNewInstance()
	{
		// Test that newInstance returns correct selector type
		IContactsSelector instance = ContactsSelector.newInstance();
		System.assertNotEquals(null, instance);
		System.assert(instance instanceof ContactsSelector);
	}

	@IsTest
	private static void testGetSObjectType()
	{
		ContactsSelector selector = new ContactsSelector();
		Schema.SObjectType result = selector.getSObjectType();
		System.assertEquals(Contact.SObjectType, result);
	}

	@IsTest
	private static void testGetSObjectFieldList()
	{
		ContactsSelector selector = new ContactsSelector();
		List<Schema.SObjectField> fields = selector.getSObjectFieldList();
		
		System.assertNotEquals(null, fields);
		System.assert(fields.size() > 0);
		
		// Verify key fields are included
		Set<Schema.SObjectField> fieldSet = new Set<Schema.SObjectField>(fields);
		System.assert(fieldSet.contains(Contact.Id));
		System.assert(fieldSet.contains(Contact.FirstName));
		System.assert(fieldSet.contains(Contact.LastName));
		System.assert(fieldSet.contains(Contact.Email));
		System.assert(fieldSet.contains(Contact.AccountId));
		System.assert(fieldSet.contains(Contact.Annual_Income__c));
		System.assert(fieldSet.contains(Contact.Credit_Score__c));
	}

	@IsTest
	private static void testSelectById()
	{
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		Contact contact = new Contact(
			FirstName = 'Test',
			LastName = 'Contact',
			Email = 'test@example.com',
			Annual_Income__c = 75000,
			Credit_Score__c = 750,
			AccountId = testAccount.Id
		);
		insert contact;

		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectById(new Set<Id> { contact.Id });
		Test.stopTest();

		System.assertEquals(1, results.size());
		System.assertEquals(contact.Id, results[0].Id);
		System.assertEquals('test@example.com', results[0].Email);
		System.assertEquals(75000, results[0].Annual_Income__c);
		System.assertEquals(750, results[0].Credit_Score__c);
	}

	@IsTest
	private static void testSelectByIdMultiple()
	{
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		List<Contact> contacts = new List<Contact>{
			new Contact(
				FirstName = 'Test1',
				LastName = 'Contact1',
				Email = 'test1@example.com',
				Annual_Income__c = 60000,
				Credit_Score__c = 650,
				AccountId = testAccount.Id
			),
			new Contact(
				FirstName = 'Test2',
				LastName = 'Contact2',
				Email = 'test2@example.com',
				Annual_Income__c = 80000,
				Credit_Score__c = 800,
				AccountId = testAccount.Id
			)
		};
		insert contacts;

		Set<Id> contactIds = new Set<Id>();
		for (Contact c : contacts) {
			contactIds.add(c.Id);
		}

		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectById(contactIds);
		Test.stopTest();

		System.assertEquals(2, results.size());
	}

	@IsTest
	private static void testSelectByIdEmpty()
	{
		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectById(new Set<Id>());
		Test.stopTest();

		System.assertEquals(0, results.size());
	}

	@IsTest
	private static void testSelectByAccount()
	{
		// Create test accounts
		List<Account> testAccounts = new List<Account>{
			new Account(Name = 'Test Account 1'),
			new Account(Name = 'Test Account 2')
		};
		insert testAccounts;

		// Create contacts for the accounts
		List<Contact> contacts = new List<Contact>{
			new Contact(
				FirstName = 'Test1',
				LastName = 'Contact1',
				Email = 'test1@example.com',
				Annual_Income__c = 60000,
				Credit_Score__c = 650,
				AccountId = testAccounts[0].Id
			),
			new Contact(
				FirstName = 'Test2',
				LastName = 'Contact2',
				Email = 'test2@example.com',
				Annual_Income__c = 70000,
				Credit_Score__c = 700,
				AccountId = testAccounts[0].Id
			),
			new Contact(
				FirstName = 'Test3',
				LastName = 'Contact3',
				Email = 'test3@example.com',
				Annual_Income__c = 80000,
				Credit_Score__c = 750,
				AccountId = testAccounts[1].Id
			)
		};
		insert contacts;

		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectByAccount(testAccounts);
		Test.stopTest();

		System.assertEquals(3, results.size());
		
		// Verify all contacts belong to the test accounts
		Set<Id> testAccountIds = new Set<Id>();
		for (Account acc : testAccounts) {
			testAccountIds.add(acc.Id);
		}
		
		for (Contact c : results) {
			System.assert(testAccountIds.contains(c.AccountId));
		}
	}

	@IsTest
	private static void testSelectByAccountSingle()
	{
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		Contact contact = new Contact(
			FirstName = 'Test',
			LastName = 'Contact',
			Email = 'test@example.com',
			Annual_Income__c = 75000,
			Credit_Score__c = 750,
			AccountId = testAccount.Id
		);
		insert contact;

		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectByAccount(new List<Account> { testAccount });
		Test.stopTest();

		System.assertEquals(1, results.size());
		System.assertEquals(contact.Id, results[0].Id);
		System.assertEquals(testAccount.Id, results[0].AccountId);
	}

	@IsTest
	private static void testSelectByAccountEmpty()
	{
		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectByAccount(new List<Account>());
		Test.stopTest();

		System.assertEquals(0, results.size());
	}

	@IsTest
	private static void testSelectByAccountWithNullIds()
	{
		// Create accounts without IDs (not inserted)
		List<Account> accountsWithoutIds = new List<Account>{
			new Account(Name = 'Test Account 1'),
			new Account(Name = 'Test Account 2')
		};

		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectByAccount(accountsWithoutIds);
		Test.stopTest();

		System.assertEquals(0, results.size());
	}

	@IsTest
	private static void testSelectByAccountMixed()
	{
		// Create one inserted account and one not inserted
		Account insertedAccount = new Account(Name = 'Inserted Account');
		insert insertedAccount;
		
		Account notInsertedAccount = new Account(Name = 'Not Inserted Account');

		Contact contact = new Contact(
			FirstName = 'Test',
			LastName = 'Contact',
			Email = 'test@example.com',
			Annual_Income__c = 75000,
			Credit_Score__c = 750,
			AccountId = insertedAccount.Id
		);
		insert contact;

		List<Account> mixedAccounts = new List<Account>{ insertedAccount, notInsertedAccount };

		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectByAccount(mixedAccounts);
		Test.stopTest();

		System.assertEquals(1, results.size());
		System.assertEquals(contact.Id, results[0].Id);
		System.assertEquals(insertedAccount.Id, results[0].AccountId);
	}

	@IsTest
	private static void testIncludesRequiredFields()
	{
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		Contact contact = new Contact(
			FirstName = 'Test',
			LastName = 'Contact',
			Email = 'test@example.com',
			Annual_Income__c = 75000,
			Credit_Score__c = 750,
			AccountId = testAccount.Id
		);
		insert contact;

		Test.startTest();
		List<Contact> results = 
			new ContactsSelector().selectById(new Set<Id> { contact.Id });
		Test.stopTest();

		System.assertEquals(1, results.size());
		Contact result = results[0];
		
		System.assertNotEquals(null, result.Email);
		System.assertNotEquals(null, result.Annual_Income__c);
		System.assertNotEquals(null, result.Credit_Score__c);
		System.assertNotEquals(null, result.AccountId);
	}
} 