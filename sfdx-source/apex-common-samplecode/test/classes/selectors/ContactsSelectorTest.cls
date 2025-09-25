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